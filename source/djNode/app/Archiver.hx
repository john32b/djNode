package djNode.app;
import djNode.tools.HTool;
import djNode.utils.CLIApp;
import djNode.utils.ISendingProgress;


/**
 * Generic Archiver,
 * Needs to be extended
 * ...
 */
class Archiver implements ISendingProgress
{
	// This will be auto-set whenever compress() is complete and returns TRUE
	// Dev: The extended objects should set this upon compression complete
	public var COMPRESSED_SIZE(default, null):Float = 0;
	
	// Holds the archive path that was worked on --useful to have--
	public var ARCHIVE_PATH	(default, null):String;
	
	// Hold the current operation ID ("compress","restore")
	var operation:String;
	
	// Progress (-1) for when the process is not started yet
	public var progress(default, set):Int = -1;
	function set_progress(val){
		if (val == progress) return val;
		progress = val;
		HTool.sCall(onProgress, val);
		return val;
	}
	
	var exePath:String;
	
	public var ERROR(default, null):String;
	public var onProgress:Int->Void;
	public var onComplete:Void->Void;
	public var onFail:String->Void;

	var app:CLIApp;
	
	public function new(_exePath:String)
	{
		exePath = _exePath;
		app = new CLIApp(exePath);
	}//---------------------------------------------------;

	public function compress(files:Array<String>, archive:String, cs:String = null):Bool return false;
	
	public function extract(archive:String, output:String, files:Array<String> = null):Bool return false;
	
	public function append(archive:String, files:Array<String>):Bool return false;
	
	public function kill()
	{
		if (app != null) {
			app.kill();
		}
	}//---------------------------------------------------;
	
}// -