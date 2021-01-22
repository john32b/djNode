/****
 * 7ZIP 
 * Interface for the CLI app
 * -------
 * @requires: 7za.exe, or 7zip installation
 * @supports: nodeJS
 * @platform: windows
 * 
 * @DEVNOTES
 * 	- 7za.exe is the standalone version of 7zip
 *  - Guide: https://sevenzip.osdn.jp/chm/cmdline/index.htm
 * 
 *  - Check `Archiver` for callbacks
 * ---------------------------------------*/

package djNode.app;
import djNode.tools.HTool;
import djNode.tools.LOG;
import djNode.utils.CLIApp;
import djNode.utils.Registry;
import js.lib.Error;
import js.node.ChildProcess;
import js.node.Fs;
import js.node.Path;
import js.node.stream.Readable.IReadable;
import js.node.stream.Writable.IWritable;

@:dce
class SevenZip extends Archiver
{
	// Inner Helper special string ID to use on update/compress
	static var S01 = ">update";	
	
	// Folder where the exe is in
	public static var PATH:String = "";
	
	// Standalone exe version.
	static var WIN32_EXE:String = "7za.exe"; 
	
	// Custom call on Successful app close
	var extraClose:Void->Void;
	
	// True: Log only errors
	static var FLAG_LOG_QUIET:Bool = true;
	//---------------------------------------------------;
	
	/**
	   Check if 7zip is installed and if so get its path
	**/
	public static function pathFromReg():Bool
	{
		PATH = Registry.getValue("HKEY_CURRENT_USER\\Software\\7-Zip", "Path");
		if (PATH != null) {
			WIN32_EXE = '7z.exe';
			LOG.log('7Zip path read from registry [OK] : $PATH');
			return true;
		}
		return false;
	}//---------------------------------------------------;
	
	/**
	   Get a generic compression string
	   @param	level 1 is the lowest, 9 is the highest
	**/
	public static function getCompressionString(l:Int = 4)
	{
		HTool.inRange(l, 1, 9);
		return '-mx${l}';
	}//---------------------------------------------------;
	
	
	public function new()
	{
		super(Path.join(PATH, WIN32_EXE));
		
		app.onClose = (s)->{
			
			if (!s) // ERROR
			{
				ERROR = app.ERROR;
				if (onFail != null) 
					onFail(ERROR);
				return;
			}
			
			if (extraClose != null) {
				extraClose();
				extraClose = null;
			}
			
			HTool.sCall(onComplete);
		};		
	}//---------------------------------------------------;
	
	//-- Call this when streaming to pipes
	function prepNoLog()
	{
		app.LOG_STDERR = false;
		app.LOG_STDOUT = false;
	}//---------------------------------------------------;
	
	/**
	   7Zip Specific, capture progress from STDOUT
	   - Updates progress (uses setter to call onProgress)
	**/
	function app_captureProgress()
	{
		progress = 0;
		// - Progress capture is the same on all operations ::
		// - STDOUT :
		// - 24% 13 + Devil Dice (USA).cue
		var expr = ~/(\d+)%/;		
		app.onStdOut = (data)->{
			if (expr.match(data)) {
				progress = Std.parseInt(expr.matched(1)); // Triggers setter and sends to user
			}	
		};
	}//---------------------------------------------------;
	
	/**
	   Compress a bunch of files into an archive
	   
	   # DEVNOTES
			- WARNING: If archive exists, it will APPEND files.
			- If a file in files[] does not exist, it will NOT ERROR
			- The files are going to be put at the ROOT of the archive.
			  even if input files are from multiple directories
			  
	   @return  preliminary success, await for callbacks
	   @param	files Files to add
	   @param	archive Final archive filename
	   @param	cs (Compression String) a Valid Compression String | e.g. "-m4x"
	**/
	override public function compress(files:Array<String>, archive:String, cs:String = null):Bool
	{
		ARCHIVE_PATH = archive;
		operation = "compress";
		
		app_captureProgress();
		
		extraClose = ()->
		{
			// Since stdout gives me the compressed size,
			// capture in case I need it later
			// - STDOUT Example :
			// - .......Files read from disk: 1\nArchive size: 544561 bytes (532 KiB)\nEverything is Ok
			var r = ~/Archive size: (\d+)/;
			if (r.match(app.stdOutLog))
			{
				COMPRESSED_SIZE = Std.parseFloat(r.matched(1));
				if (!FLAG_LOG_QUIET)
				LOG.log('$ARCHIVE_PATH Compressed size = $COMPRESSED_SIZE');
			}
		}
		
		if (!FLAG_LOG_QUIET)
		LOG.log('Compressing "$files" to "$archive" ... Compression:$cs' );
		
		// 7Zip does not have a command to replace the archive
		// so I delete it manually if it exists
		if (cs == S01)
		{
			cs = null;
			operation = "update";
		}else
		{
			if (Fs.existsSync(archive)) {
				Fs.unlinkSync(archive);
			}
		}
		
		var p:Array<String> = [
			'a', 						// Add
			'-bsp1' 					// Redirect PROGRESS outout to STDOUT
		];
		if (cs != null) p = p.concat(cs.split(' '));
		p.push(archive);
		p = p.concat(files);
		app.start(p);
		return true;
	}//---------------------------------------------------;
	
	
	/**
	   Extract file(s) from an archive. Overwrites output
	   ! NOTE: USES (e) parameter in 7zip. Does not restore folder structure
	   @return preliminary success, await for callbacks
	   @param	archive To Extract
	   @param	output Path (will be created)
	   @param	files Optional, if set will extract those files only
	**/
	override public function extract(archive:String, output:String, files:Array<String> = null):Bool 
	{
		ARCHIVE_PATH = archive;
		operation = "extract";
		
		app_captureProgress();
		
		var p:Array<String> = [
			'e',			// Extract
			archive,
			'-bsp1',		// Progress in stdout
			'-aoa',			// Overwrite
			'-o$output'		// Target folder. DEV: Does not need "" works with spaces just fine
		];
		var _inf = "";
		if (files == null) {
			_inf = 'all files';
		}else {
			_inf = files.join(',');
			p = p.concat(files);
		}
		if (!FLAG_LOG_QUIET)
		LOG.log('Extracting [$_inf] from "$archive" to "$output"' );
		app.start(p);
		return true;
	}//---------------------------------------------------;
	
	
	/**
	   Append files in an archive
	   - It uses the SAME compression as the archive
	   - Best use this on NON-SOLID archives (default solid = off in this class)
	   @param	archive
	   @param	files
	   @return
	**/
	override public function append(archive:String, files:Array<String>):Bool 
	{
		compress(files, archive, S01);
		return true;
	}//---------------------------------------------------;
	
	
	

	
	
	
	/// NEW:
	/**
	   
	   @param	a The Archive Path
	   @param	getSize If TRUE will prepend uncompressed filesize on the return array
						["566267|File.txt", "2300|folder\file.dat"]
						Just use split('|') to separate and parseint to get size
	   @return NULL for error, Empty Array for no Files.
	**/
	public function getFileList(a:String, getSize:Bool = false):Array<String>
	{
		if (!FLAG_LOG_QUIET)
		LOG.log('Getting file list from `$a`');
		var stdo:String = try ChildProcess.execSync('"${exePath}" l "$a"', {stdio:['ignore', 'pipe', 'ignore']}) catch (e:Error) return null;
		var ar:Array<String> = stdo.toString().split('\n');	// NOTE: toString() is needed, else error
		
		var l = 0;
		while (l < ar.length) {
			if (ar[l++].indexOf('---------') == 0) break; // A line before the file list
			// l is now where the entries start
		}
		// Line example
		// 2019-05-12 01:04:09 ....A         5049               Folder\filename.cfg
		// 2019-05-10 21:16:55 ....A        10423       692492  file.txt
		var files:Array<String> = [];
		
		while (l < ar.length) {
			if (ar[l].indexOf('---------') == 0) break; // Entries End
			// Skip Folders
			if (ar[l].charAt(20) == "D") { l++;  continue; }	
			
			// Trim the first 25 characters to reach the filesize
			var size:Int = Std.parseInt(ar[l].substr(26, 13));
			var name = StringTools.rtrim(ar[l].substr(53));
			if (getSize){
				files.push('$size|$name'); 
			}else{
				files.push(name);
			}
			l++;
		}
		return files;
	}//---------------------------------------------------;
	
	/**
		Get the checksum of a file inside the archive.
	   
	   @param	arc The archive
	   @param	file full path of the file inside the archive e.g. "folder/file.dat"
	   @param	type (CRC32|CRC64|SHA1|SHA256)
	   @return  Checksum, Warning make sure the file exists in the archive, else random string will be returned
	**/
	public function getHash(arc:String, file:String, type:String = "CRC32"):String
	{
		var stdo:String = ChildProcess.execSync('"${exePath}" e "$arc" "$file" -so | "${exePath}" h -si -scrc${type}');
		return hashParse(stdo.toString());	// Note: To String is needed, else it errors.
	}//---------------------------------------------------;
	
	
	/**
	   Get a file Checksum
	   @param	file The path of the file to get the Checksum
	   @param	type (CRC32|CRC64|SHA1|SHA256)
	   @return
	**/
	public function getHashFile(file:String, type:String = "CRC32"):String
	{
		var stdo:String = ChildProcess.execSync('"${exePath}" h "$file" -scrc${type}');
		return hashParse(stdo.toString());
	}//---------------------------------------------------;
	
	/**
	   Get hash from a data stream
	   @param	type type (CRC32|CRC64|SHA1|SHA256)
	   @param	callback Null for error, other for value
	**/
	public function getHashPipe(type:String = "CRC32", callback:String->Void):IWritable
	{
		extraClose = ()->{
			callback(hashParse(app.stdOutLog));
		};
		app.start([
			'h', '-si', '-scrc${type}'
		]);
		return app.proc.stdin;
	}//---------------------------------------------------;
	
	// From a (h) call, get the HASH value
	function hashParse(stdout:String):String
	{
		var ar:Array<String> = stdout.split('\n');
		var l = 0;
		while (l < ar.length) {
			if (ar[l++].indexOf('--------') == 0) break; // A line before the file list
			// l is now where the entries start
		}
		var r = ~/^(\S+)/i;
		if (r.match(ar[l])) {
			return r.matched(1);
		}
		return null;
	}//---------------------------------------------------;
	
	
	/**
	   Extract to STDOUT Stream.
	   @param	arc Archive to Extract
	   @param	file If set, will extract this file from within the archive
	**/
	public function extractToPipe(arc:String, file:String = null):IReadable
	{
		prepNoLog();
		var p:Array<String> = [
			'e', arc
		];
		var _inf = "";
		if (file == null) {
			_inf = 'all files';
		}else {
			_inf = file;
			p.push(file);
		}
		if (!FLAG_LOG_QUIET)
		LOG.log('Extracting [$_inf] from "$arc" to PIPE');
		p.push('-so');
		app.start(p);
		return app.proc.stdout;
	}//---------------------------------------------------;
	
	/**
	   Compresses from STDIN stream.
	   Updates Archive, It will APPEND files, so be careful
	   ! COMPRESSED_SIZE available after
	   @param	arc Archive Path to create
	   @param	fname name of the file to be created inside the archive
	   @param	cs Valid Compression String
	   @return
	**/
	public function compressFromPipe(arc:String, fname:String, cs:String = null):IWritable
	{
		var p:Array<String> = [
			'a', arc
		];
		if (cs != null) p = p.concat(cs.split(' '));
		p.push('-si${fname}');
		if (!FLAG_LOG_QUIET)
		LOG.log('Compressing from PIPE to "$arc" ... Compression:$cs' );
		
		COMPRESSED_SIZE  = 0;// Zero it out because I'll check it later for 0
		
		extraClose = ()->
		{
			var r = ~/Archive size: (\d+)/;
			if (r.match(app.stdOutLog)){
				COMPRESSED_SIZE = Std.parseFloat(r.matched(1));
				if (!FLAG_LOG_QUIET)
					LOG.log('$ARCHIVE_PATH Compressed size = $COMPRESSED_SIZE');
			}
			// Either got match, or no match will enter this:
			if (COMPRESSED_SIZE == 0) {
				onComplete = null;
				ERROR = 'Could not write data to "$arc"';
				if (onFail != null) onFail(ERROR);
			}			
		};
		
		app.start(p);
		return app.proc.stdin;
	}//---------------------------------------------------;
	
}// --