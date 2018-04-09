 /**--------------------------------------------------------
 * FileTool
 * @author: johndimi, <johndimi@outlook.com> , @jondmt
 * --------------------------------------------------------
 * - Various Helpers for File and Path operations
 * 
 ========================================================*/
package djNode.tools;

import js.Error;
import js.Node;
import js.node.Fs;
import js.node.fs.Stats;
import js.node.Path;

//import dj.tools.LOG;


class FileTool
{
	
	// Recursivly creates a directory structure
	// <inPath> will be created if it does not exist
	// e.g. createRecursiveDir("c:\\myfolder\\temp1\\temp2\\temp3");
	public static function createRecursiveDir(inPath:String):Void {
		
		#if !js
		throw "Not supported yet";
		#end
		
		var paths:Array<String> = Path.normalize(inPath).split(Path.sep);
		var cM = paths.length;
		if (cM <= 0) throw "Path is empty!";
		var c = 0;
		var p1 = "";	// Cummulative path for iterations 
		// Check to see if the path is drive path (win32 only)
		
		// FIXME: I need to update this for linux too
		if (paths[0].indexOf(":") > 0) 
		{
			try {
				Fs.statSync(paths[0]);
			}catch (e:Error) {
				throw 'Drive ${paths[0]} does not exist!!';	
			}
			c = 1; //skip the first iteration because it's a drive
			p1 = paths[0] + Path.sep;
		}
		
		while (c < cM) {
			p1 = Path.join(p1, paths[c]);
			if (pathExists(p1) == false) {
				Fs.mkdirSync(p1);
			}
			c++;
		}
	}//---------------------------------------------------;
	
	// --
	// Since NODE is deprecating existsSync, I am writing a very simple one.
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
	 * @UNSAFE doesn't check for errors 
	 * Move a file and callback when done.
	 * @param	source
	 * @param	dest
	 * @param	onComplete
	 * @param	onProgress
	 */
	public static function moveFile(source:String, dest:String, onComplete:Void->Void, ?onProgress:Void->Void):Void {

		#if !js
		throw "Not supported yet";
		#end
		
		Fs.rename(source, dest, function(er:Error) {
			if (er != null) {
				copyFile(source, dest, function() {	
					try {
						Fs.unlinkSync(source);
					}catch (e:Dynamic) {
						LOG.log('Could not delete "$source" while moving');
					}
					onComplete();
				}, onProgress);
			} else {
				//It smart moved ok.
				onComplete();
			}
		});
	}//---------------------------------------------------;

	/**
	 * @UNSAFE doesn't check for errors 
	 * Copies a file and callsback when done
	 * @param	source
	 * @param	dest
	 * @param	onComplete
	 * @param	onProgress
	 */
	public static function copyFile(source:String, dest:String, onComplete:Void->Void, ?onProgress:Void->Void) 
	{	
		#if !js
		throw "Not supported yet";
		#end
		
		var _in  = Fs.createReadStream(source);
		var _out = Fs.createWriteStream(dest);
		_in.pipe(_out);
		_in.once("end", function() {
			_in.unpipe(); 
			_out.end();
			onComplete();
		});	
		
		if (onProgress != null) // TODO: FIX onProgress 
			_out.on("data", function(data:Dynamic) onProgress());
	}//---------------------------------------------------;

	/*
	 * Returns the full path filename of every file in a folder
	 */ 
	public static function getFileListFromDir(inPath:String):Array<String> {
		
		#if !js
		throw "Not supported yet";
		#end

		var allfiles = Fs.readdirSync(Path.normalize(inPath));
		var fileList:Array<String> = new Array();
		for (i in allfiles) {
			var stats = Fs.statSync(Path.join(inPath, i));
			if (stats.isFile()) fileList.push(i);
		}
		return fileList; /// TODO, does it return the full path?
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
		var extToGet = getFileExt(path).toLowerCase();
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
				if (extToGet == "*") { fileList.push(Path.join(basePath,i)); continue; }
				if (extToGet == Path.extname(i).substr(1).toLowerCase())
				{ fileList.push(Path.join(basePath,i)); continue; }
			}
		}
		// Returns full filepaths
		return fileList;
	}//---------------------------------------------------;
	
	
	/**
	 * Returns lowercase extension, with no '.'
	 * e.g. "mp3","jpg"
	 * @param	file
	 * @return
	 */
	public static function getFileExt(file:String):String 
	{
		return Path.extname(file).substr(1).toLowerCase();
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
	

}