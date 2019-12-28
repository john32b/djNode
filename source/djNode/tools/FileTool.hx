 /**--------------------------------------------------------
 * FileTool
 * @author: johndimi, <johndimi@outlook.com>
 * --------------------------------------------------------
 * - Various Helpers for File and Path operations
 * 
 ========================================================*/
package djNode.tools;

import js.lib.Error;
import js.Node;
import js.node.Buffer;
import js.node.Crypto;
import js.node.Fs;
import js.node.fs.Stats;
import js.node.Path;
import js.node.fs.WriteStream;

@:dce
class FileTool
{
	/**
	   Recursively creates a directory structure
	   <inPath> will be created if it does not exist
	   e.g. createRecursiveDir("c:\\myfolder\\temp1\\temp2\\temp3");
	   @param	inPath The path to be created
	   @throws String
	**/
	public static function createRecursiveDir(inPath:String) 
	{	
		#if !js
		throw "Not supported yet";
		#end
		
		var paths:Array<String> = Path.normalize(inPath).split(Path.sep);
		var cM = paths.length;
		if (cM <= 0) throw 'Path "$inPath" is invalid';
		var c = 0;
		var p1 = "";	// Cummulative path for iterations 
		// Check to see if the path is drive path (win32 only)
		
		// FIXME: I need to update this for linux too
		if (paths[0].indexOf(":") > 0) 
		{
			try {
				Fs.statSync(paths[0]);
			}catch (e:Error) {
				throw 'Drive "${paths[0]}" does not exist!';
			}
			c = 1; //skip the first iteration because it's a drive
			p1 = paths[0] + Path.sep;
		}
		try while (c < cM) {
			p1 = Path.join(p1, paths[c]);
			if (pathExists(p1) == false) {
				Fs.mkdirSync(p1);
			}
			c++;
		} catch (e:Error) throw 'Cannot create "$inPath"';
	}//---------------------------------------------------;
	
	/**
	* Remove directory recursively.
	* + Deletes all files and subfolders
	* @throws
	*/
	public static function deleteRecursiveDir(dir_path:String)
	{
		if (pathExists(dir_path))
		{
			var contents = Fs.readdirSync(dir_path);
			for (entry in contents)
			{
				var entry_path = Path.join(dir_path, entry);
				if (Fs.lstatSync(entry_path).isDirectory()){
					deleteRecursiveDir(entry_path);
				}else{
					Fs.unlinkSync(entry_path);
				}
			}
			Fs.rmdirSync(dir_path);
		}
	}//---------------------------------------------------;
	
	/**
	 * Check to see if the program can write to target folder
	 */
	public static function hasWriteAccess(path:String):Bool
	{
		try{
			Fs.accessSync(path, 2);
		}catch (e:Error)
		{
			return false;
		}
			return true;
		 //fs.constants
		  //O_RDONLY: 0,
		  //O_WRONLY: 1,
		  //O_RDWR: 2,
		  //S_IFMT: 61440,
		  //S_IFREG: 32768,
		  //S_IFDIR: 16384,
		  //S_IFCHR: 8192,
		  //S_IFLNK: 40960,
		  //O_CREAT: 256,
		  //O_EXCL: 1024,
		  //O_TRUNC: 512,
		  //O_APPEND: 8,
		  //F_OK: 0,
		  //R_OK: 4,
		  //W_OK: 2,
		  //X_OK: 1,
		  //UV_FS_COPYFILE_EXCL: 1,
		  //COPYFILE_EXCL: 1 
	}//---------------------------------------------------;
	
	
	/**
	   Since nodeJS is deprecating existsSync. So I wrote this.
	   @param	path
	   @return
	**/
	public static function pathExists(path:String):Bool
	{
		try {
			Fs.statSync(path);
		}catch (e:Error) {
			return false;
		}
		return true;
	}//---------------------------------------------------;
	
	/**
	 * @SYNC
	 * Move a file and callback when done.
	 * @param	source
	 * @param	dest
	 * @param	onComplete
	 * @param	onProgress
	 */
	public static function moveFile(source:String, dest:String) 
	{
		#if !js
			throw "Not supported yet";
		#end
		
		try{
			Fs.renameSync(source, dest);
		}catch (e:Error)
		{
			copyFileSync(source, dest);
			
			try{
				Fs.unlinkSync(source);
			}catch (e:Error){
				LOG.log('Could not delete "$source" while moving.', 3);
			}
		}
		
	}//---------------------------------------------------;

	
	
	public static function copyFile(source:String, dest:String, callback:String->Void)
	{
		var r = Fs.createReadStream(source);
		var w = Fs.createWriteStream(dest);
		var _c = false;
		var done = (e:Error)->{
			if (!_c){
				if (e != null) 
				callback(e.message);
					else 
				callback(null);
			}
			_c = true;
		};
		r.once('error', done);
		w.once('error', done);
		w.once('close', done);
		r.pipe(w);
	}//---------------------------------------------------;
	
	
	/**
	 * @SYNC
	 * Copies a file. Destination will be created or overwritten
	 * @param	source
	 * @param	dest
	 */
	public static function copyFileSync(source:String, dest:String) 
	{	
		// SYNC:
		Fs.writeFileSync(dest, Fs.readFileSync(source));
		
		/*
		// ASYNC:
		var _in  = Fs.createReadStream(source);
		var _out = Fs.createWriteStream(dest);
		_in.pipe(_out);
		_in.once("end", function() {
			_in.unpipe(); 
			_out.end();
			onComplete();
		});	
		*/
	}//---------------------------------------------------;

	
	/**
	   Appends a part of a file into another file.
	   @param	inputFile Source file
	   @param	outputFile Target file (will be created if not exist)
	   @param	readStart Byte position of the source file to start copying from
	   @param	readLen Bytes in length to copy. 0 for rest of the file
	   @param	callback (s:String) if not NULL, then ERROR
	**/
	public static function copyFilePart(
				inputFile:String, outputFile:String, 
				readStart:Int = 0, readLen:Int = 0, 
				callback:String->Void):Void
	{
		var dest_stream:WriteStream;
		var BUFFERSIZE:Int = 65536;
		var inputSize:Int = 0;
		
		try{
			inputSize = Std.int(Fs.statSync(inputFile).size);
		}catch (e:Error){
			return callback(e.message);
		}
		// - Autogen read len to the rest of the file
		if (readLen == 0) {
			readLen = inputSize - readStart;
		} else if (readLen + readStart > inputSize) {
			return callback('Trying to copy more bytes than the input file has.');
		}
		LOG.log('Copying `$inputFile` Bytes [$readStart [len]-> $readLen] to `$outputFile`');
		// --
		dest_stream = Fs.createWriteStream(outputFile, {
			//flags:forceNewFile?FsOpenFlag.WriteCreate:FsOpenFlag.AppendCreate
			flags:FsOpenFlag.AppendCreate
		});
		dest_stream.once("error", (err:Error)->{
			callback('Cannot create/write to `$outputFile`');
		});
		// -
		Fs.open(inputFile, FsOpenFlag.Read, function(err:Error, data:Int) {
			if (err != null){
				return callback('Could not open file `$inputFile`');
			}
			var buffer:Buffer;
			var bytesCopied:Int = 0;
			var bytesLeft:Int = readLen;
			while (bytesLeft > 0) {
				if (bytesLeft >= BUFFERSIZE) {
					buffer = Buffer.allocUnsafe(BUFFERSIZE);
					
				}else{
					buffer = Buffer.allocUnsafe(bytesLeft);
				}
				bytesCopied += Fs.readSync(data, buffer, 0, buffer.byteLength, readStart + bytesCopied);
				bytesLeft -= buffer.byteLength;
				dest_stream.write(buffer);
			}
			Fs.closeSync(data);
			dest_stream.end();
			dest_stream.once("close", ()->callback(null));
		});
	}//---------------------------------------------------;
	
	
	
	
	/**
	 * Returns the full path filename of every file in a folder
	 * PRE: Folder Exists
	 * @param inPath Get files from this folder only
	 * @param fullPath If true the result Array will include the full path of each file. False for just the filenames
	 */ 
	public static function getFileListFromDir(inPath:String, fullPath:Bool = false):Array<String> 
	{
		#if !js
		throw "Not supported yet";
		#end
		
		var allfiles = Fs.readdirSync(Path.normalize(inPath));
		var ret:Array<String> = [];
		for (f in allfiles)
		{
			if (Fs.statSync(Path.join(inPath, f)).isFile()) 
			{
				if (fullPath)
					ret.push(Path.join(inPath, f)); 
				else
					ret.push(f);
			}
		}
		return ret;
	}//---------------------------------------------------;
	
	/**
	   DeepScan a folder for files. Returns <Array> with FullPaths of all files found
	   @param	rootPath The Root Path to start
	   @param	ext If set, it will only return files matching these extensions. 
				Use Lowercase for defining, Matches are Case Insensitive
				e.g. ['.cue','.mp3']
	   @return
	**/
	public static function getFileListFromDirR(rootPath:String, ?ext:Array<String>):Array<String>
	{
		var res:Array<String> = [];
		
		// - Push files to `res` and call again for folders
		function pushFiles(path:String)
		{
			var files = Fs.readdirSync(Path.normalize(path));
			
			for (f in files)
			{
				// File Full Path
				var fp = Path.join(path, f);
				try{
				if (Fs.statSync(fp).isDirectory()){
					pushFiles(fp);
				}else{
					if (ext != null)
					{
						if (ext.indexOf(getFileExt(f)) >-1)
							res.push(fp);
					}else
					{
						res.push(fp);
					}
				}}catch (e:Error){
					// Probably some not accessible file/folder
					return;
				}
			}
		}// --
		
		pushFiles(rootPath);
		
		return res;
	}//---------------------------------------------------;
	
	
	
	/** 
	 * 
	 * Basic and fast multiple file getter from folders
	 * Returns Array<full file path>
	 * Returns Empty Array if no files found
	 * 
	   Working:
	   -------------------
		(*.*)		-> get all files from folder
		(*.ext)		-> return all files with 'ext' extension
		(name.*)	-> return all files with filename "name" and all extensions
		(*)			-> return extentionless files
	 
	 **/
	public static function getFileListFromWildcard(path:String):Array<String>
	{
		#if !js
		throw "Not supported yet";
		#end
		
		// The returned object
		var fileList:Array<String> = new Array();
		var basePath = Path.dirname(path);
		var extToGet = getFileExt(path);
		var baseToGet:String;
		var exp = ~/(\S*)\./;
		if (exp.match(Path.basename(path))) {
			baseToGet = exp.matched(1);
			if (baseToGet.length > 1 && baseToGet.indexOf('*') > 0)
				throw "Advanced search is currently unsupported, use basic [*.*] or [*.ext]";
		}
		else 
			baseToGet = "*";

		var allfiles = Fs.readdirSync(Path.normalize(basePath));		
		var stats:Stats;
		
		for (i in allfiles) {
			try {
				stats = Fs.statSync(Path.join(basePath, i));
			}catch (e:Dynamic) { // Skip locked files. Will this cause trouble if I ever need ALL files??
				// LOG.log('Encountered a Locked File! "$i"', 2);
				continue;
			}
			
			if (stats.isFile()) {		
				if (baseToGet != "*") 
					if (exp.match(i)) { 
						if (baseToGet != exp.matched(1)) continue; }
					else continue;
				if (extToGet == ".*") { fileList.push(Path.join(basePath,i)); continue; }
				if (extToGet == Path.extname(i).toLowerCase())
				{ fileList.push(Path.join(basePath,i)); continue; }
			}
		}
		// Returns full filepaths
		return fileList;
	}//---------------------------------------------------;
	
	/**
	 * SYNC - Calculate a File's MD5 
	**/
	public static function getFileMD5(file:String):String
	{
		var BUFFER_SIZE:Int = 8192;
		var fd = Fs.openSync(file, 'r');
		var hash = Crypto.createHash('md5');
		var buffer:Buffer = Buffer.alloc(BUFFER_SIZE);
		try{
			var bytesRead = 0;
			do{
				bytesRead = Fs.readSync(fd, buffer, 0, BUFFER_SIZE, null);
				hash.update(buffer.slice(0, bytesRead));
			}while (bytesRead == BUFFER_SIZE);
		}catch (e:Error)
		{
			Fs.closeSync(fd);
			return null;
		}
		
		Fs.closeSync(fd);
		return hash.digest('hex');
	}//---------------------------------------------------;
	
	/**
	 * Returns lowercase extension
	 * e.g. ".mp3",".jpg"
	 * @param	file
	 * @return
	 */
	public static function getFileExt(file:String):String 
	{
		return Path.extname(file).toLowerCase();
	}//---------------------------------------------------;
	
	/**
	 * Get file path without the LAST extension
	 * e.g.  folder/file1.bin.zip -> folder/file1.bin
	 * e.g.  folder/file1.bin -> folder/file1
	 * @param	file
	 * @return
	 */
	public static function getPathNoExt(file:String):String 
	{
		return Path.join(Path.parse(file).dir, Path.parse(file).name);
	}//---------------------------------------------------;
	
	
	/**
	   Return the full path of a file that is relative to the application path.
	   e.g (appFileToFullPath('settings.ini') ==> 'c:\code\application\settings.ini')
	       where 'c:\code\application' is where the app is
	   @param	filePath Short Path of file
	**/
	public static function appFileToFullPath(filePath:String)
	{
		return Path.join(Path.dirname(Sys.programPath()), filePath);
	}//---------------------------------------------------;
	
	
	
	/**
	   Ensures that filename does not exist in the path it is in
	   by adding a symbol (_) at the end of the filename until unique
	   - Works with folders too
	   @param	filename
	   @return
	**/
	public static function getUniquePath(filename:String):String
	{
		while (Fs.existsSync(filename)) {
			var o = Path.parse(filename);
			filename = Path.join(o.dir, o.name + "_" + o.ext);
		}
		return filename;
	}//---------------------------------------------------;

}