/****
 * FreeArc interface
 * -------
 * johndimi, johndimi@outlook.com
 * -------
 * @requires: [Arc.exe]
 * @supportedplatforms: nodeJS
 * @architectures: Windows
 * 
 * FreeArc is a modern general-purpose archiver. 
 *  Main advantage of FreeArc is fast but efficient
 *  compression and rich set of features.
 *  http://freearc.org/
 * 
 * 
 * @events: progress: (int), percent complete
 * ---------------------------------------*/
 
package djNode.app;

import djNode.tools.LOG;
import djNode.app.AppSpawner;
import js.Node;
import js.node.Path;


class Arc extends AppSpawner implements IArchiver
{
	// Require 'Arc.exe' on executable path
	private var win32_exe:String = "Arc.exe";
	// Debug flag, If true, then use fast compression
	public var flag_quick_compress:Bool = false;
	
	// Final path of the executable e.g. "c:/bin/app.exe"
	var compiledPathExe:String;
	//---------------------------------------------------;
	public function new()
	{
		super();
		#if debug
		flag_quick_compress = true;
		#end
		
		compiledPathExe = Path.join(dir_exe, win32_exe);
		
		LOG.log('ARC Compiled path exe = $compiledPathExe ');
	}//---------------------------------------------------;
	
	// -- Compress a list of files
	// If multiple files, destination will be the name of the first file
	public function compress(ar:Array<String>, ?destinationFile:String):Void 
	{
		if (destinationFile == null) {
			destinationFile = ar[0] + ".arc";
			// TODO, does that file already exist? if so add a _counter until it doesnt ?
		}
		
		LOG.log('Compressing "$ar" to "$destinationFile" ... ' );
		
		// NOTE: Possible problem if input files at different directories!
		var sourceFolder = Path.dirname(ar[0]);
		
		//-md32, Megabytes of dictionary
		//-m0, no compression, 1=fast, 2,3,(4=default)
		
		var params:Array<String>;
		if(flag_quick_compress)
			params = ["a", "-m1", "-md8", "-s", "-o+", destinationFile , '-dp$sourceFolder'];
		else
			params = ["a", "-m4", "-md32", "-s", "-o+", destinationFile , '-dp$sourceFolder'];
			
		for (i in ar) params.push(Path.basename(i));
		
		spawnProc(compiledPathExe, params);
		listen_progress();
	}//---------------------------------------------------;
	
	// -- Uncompress an ARC archive
	public function uncompress(input:String, ?destinationFolder:String):Void 
	{
		if (destinationFolder == null) {
			destinationFolder = Path.dirname(input);
		}
		
		spawnProc(	compiledPathExe,
					["e", "-o+", input, '-dp$destinationFolder']);
		listen_progress();
	}//---------------------------------------------------;
	
	/**
	 * Get an array with the list of files included in an ARC file
	 * Ver 0.1
	 * -------
	 * + Does not support nested folders, Just the root folder contents
	 * @param	filename
	 * @param	callback
	 */
	public function getFileList(filename:String, callback:Array<String>->Void)
	{
		AppSpawner.quickExec(compiledPathExe + ' l $filename', 
			function(s:Bool, out:String, err:String) {
			/* STD OUT ==
			 * FreeArc 0.67 (March 15 2014) listing archive: c:\temp\doom.arc
				Date/time                  Size Filename
				----------------------------------------
				2015-12-13 15:18:44       4,480 crushdata.json
				2015-12-13 15:17:43   2,639,529 Track02.ogg
				2015-12-13 15:17:51   1,601,991 Track03.ogg
				2015-12-13 15:18:05   3,640,301 Track04.ogg
				2015-12-13 15:18:18   2,889,499 Track05.ogg
				2015-12-13 15:18:27   1,807,526 Track06.ogg
				2015-12-13 15:18:30     743,577 Track07.ogg
				2015-12-13 15:18:44   3,126,641 Track08.ogg
				----------------------------------------
				8 files, 16,453,544 bytes, 14,843,058 compressed
				All OK
			*/
				
			// -- Break the output into lines
			//  - Trim the first and last lines that do not display files
			//  - Get the last characters of each line ( the filename ) in
			//    into an aray and return that.
			var reg:EReg = ~/(\S*)$/;
			var lines:Array<String> = [];
			
			lines = out.split("\r");
			lines = lines.splice(3, lines.length - 8);
			lines = lines.map(function(s) {
				if (reg.match(s)) {
					return reg.matched(0);
				} return null;
			});
			callback(lines);		
		});
	}//---------------------------------------------------;

	/**
	 * Call this after the process has been created.
	 */
	private function listen_progress(?oper:String):Void
	{	
		var expr = ~/(\d{1,3})%\s*$/; // Compressing Track222.bin  39%  

		proc.stdout.setEncoding("utf8");
		proc.stdout.on("data", function(data:String) {
			if (expr.match(data)) {
				// Sends the percent completed
				events.emit("progress", Std.parseInt(expr.matched(1)));
			}	
		});
	}//---------------------------------------------------;
	
}//--end class--