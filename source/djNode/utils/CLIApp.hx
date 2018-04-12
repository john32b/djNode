/**
 * CLI Application Spawner
 * ------------------------
 * 
 * . Spawns CLI applications
 * . Reports Realtime StdOut and StdErr
 * . Static functions for quickly calling/checking
 *
 * @supports : nodeJS
 * @events
 * 
 * 		`close` 	: ExitOK:<Bool>, ErrorMessage:<String>
 * 
 * ---------------------------------------*/

package djNode.utils;

import djNode.tools.LOG;
import js.Node;
import js.node.ChildProcess;
import js.node.child_process.ChildProcess as ChildProcessObject;
import js.node.events.EventEmitter;
import js.node.Path;
import js.node.Process;


class CLIApp
{
	
	// You should listen to this to get various events
	public var events:IEventEmitter;
	
	// The process
	var proc:ChildProcessObject;
	
	// Keep the FULL path of the executable (e.g. "c:\bin\ffmpeg.exe")
	// This is what will be executed
	var exePath:String;
	
	// #USERSET
	// Set before starting the process
	public var onStdErr:String->Void;
	public var onStdOut:String->Void;
	
	//---------------------------------------------------;

	/**
	   Create
	   @param	exec The executable FULL PATH or RELATIVE PATH
	**/
	public function new(?exec:String) 
	{
		events = new EventEmitter();		
		exePath = exec;
 	}//---------------------------------------------------;


	/**
	   Start the child process
	   @param	arguments
	   @param	workingDir
	**/
	public function start(?arguments:Array<String>, ?workingDir:String)
	{
		LOG.log('Process `$exePath` Start');
		
		// https://nodejs.org/api/child_process.html#child_process_child_process_spawn_command_args_options
		proc = ChildProcess.spawn(exePath, arguments);
		// Haxe BUG: Can't set Options.
		// { cwd:workingDir, windowsHide:true });
		
		/*
		 * The 'error' event is emitted whenever: 
		 * - The process could not be spawned, or
		 * - The process could not be killed, or
		 * - Sending a message to the child process failed.
		 */
		proc.once("error", function(er:Dynamic){
			events.emit("close", false, er.message);
			kill();
		});
		
		
		/*
		 * The 'close' event is emitted when the stdio streams of a child process have been closed. 
		 * This is distinct from the 'exit' event, 
		 * since multiple processes might share the same stdio streams.
		 */
		proc.once("close", function(code:Int, signal:String){
			
			if (code != 0 || signal != null) // Error
			{
				LOG.log('Process `$exePath` End - [ ERROR ] `{$signal}`', 3);
				events.emit("close", false, signal);
			}else{
				LOG.log('Process `$exePath` End - [ OK ]');
				events.emit("close", true);
			}
			kill();
		});
		
		
		if (onStdErr != null)
		{
			proc.stderr.setEncoding("utf8");
			proc.stderr.on("data", onStdErr);
		}
		
				
		if (onStdOut != null)
		{
			proc.stderr.setEncoding("utf8");
			proc.stderr.on("data", onStdOut);
		}
		
	}//---------------------------------------------------;
	
	/**
	   Free up resources
	**/
	function kill()
	{
		if (proc != null)
		{
			proc.removeAllListeners("close");
			proc.removeAllListeners("stdOut");
			proc.removeAllListeners("stdErr");
			proc = null;
		}
		
	}//---------------------------------------------------;
	
	// Statics
	//====================================================;
	
	/**
		Fires an application and lets it run until it exits
		Also captures the output
		Callbacks: success -> stdout -> stderr
		@param	path
		@param	callback Error, stdout, stderr
	**/
	public static function quickExec(path:String, callback:Bool->String->String->Void)
	{
		// Encoding is utf8 by default
		var pr = ChildProcess.exec(path,  function (error:Dynamic, stdout:Dynamic, stderr:Dynamic) {
			callback(error == null, stdout, stderr);
		});
	}//---------------------------------------------------;
	
	/**
	   Tries to just run a command/CLI app
	   If process started and exited then it returns TRUE
	   @return Success
	**/
	public static function checkRun(execStr:String):Bool
	{
		try{
			var pr = ChildProcess.execSync(execStr, {
				timeout:10000,
				stdio:'ignore'	// If not set, the stdout will be written to the main stdout.
			});
			return true;
		}catch (er:Dynamic){
			return false;
		}
	}//---------------------------------------------------;
	

	/**
	   LINUX ONLY 
	   Check to see if "pk" package is installed on the system
	   or other way is
	   dpkg-query -W -f='${Status}' ffmpeg
	   @param	packageName 
	**/
	public static function checkLinuxPackage(packageName:String):Bool 
	{
		#if linux 
		var res = ChildProcess.execSync("dpkg-query -W -f='${Status}'" + packageName, {
			encoding:'utf8',
			timeout :10000,	// 10 seconds
		});
				  
		if (res == null) return false;
		
		if (~/ok/.match(res))
		{
			LOG.log('Package Check ${packageName} [OK]');
			return true;
		}
		
		LOG.log('Package Check ${packageName} [ERROR]');
		
		#end
		
		return false;
	}//---------------------------------------------------;

}//-- end class --//