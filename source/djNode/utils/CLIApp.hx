/**
 * CLI Application Spawner
 * ------------------------
 * 
 * . Spawns CLI applications
 * . Reports Realtime StdOut and StdErr
 * . Static functions for quickly calling/checking
 *
 * @supports : nodeJS
 * 
 * ---------------------------------------*/

package djNode.utils;

import djNode.tools.HTool;
import djNode.tools.LOG;
import js.Error;
import js.Node;
import js.node.ChildProcess;
import js.node.Path;
import js.node.Process;
import js.node.stream.Writable;


class CLIApp
{
	// The process
	public var proc(default, null):js.node.child_process.ChildProcess;
	
	// Keep the FULL path of the executable (e.g. "c:\bin\ffmpeg.exe")
	// This is what will be executed
	public var exePath(default, null):String;
	
	// #USERSET
	// Set before starting the process
	public var onStdErr:String->Void;
	public var onStdOut:String->Void;

	// #USERSET
	// - If true will log STDERR/STDOUT output (stdOutLog/stdErrLog)
	// - Do not use if you work with streams
	// - Will autoset the stream to UTF8
	// - Togglable in case you need to access STDOUT
	public var LOG_STDERR:Bool = true;
	public var LOG_STDOUT:Bool = true;
	
	public var stdOutLog(default, null):String;
	public var stdErrLog(default, null):String;
	
	/** In case of error, read this */
	public var ERROR(default, null):String;
	
	/** Called when program exits. (success) */
	public var onClose:Bool->Void;
	
	/** Some programs output on STDERR, (ffmpeg)
	 *  If true, will read from that in case of Error */
	public var FLAG_ERRORS_ON_STDERR:Bool = false;
	
	// For debugging purposes, store the last start() comman
	public var log_last_call(default, null):String;
	//---------------------------------------------------;

	/**
	   Create
	   @param exec The executable FULL PATH or RELATIVE PATH
	   @param path The folder the executable is in
	**/
	public function new(exec:String, path:String = "") 
	{
		exePath = Path.join(path, exec);
 	}//---------------------------------------------------;
	
	/**
	   Start the child process
	   @param	arguments Put arguments inside a string Array
	   @param	workingDir Optional
	**/
	public function start(?args:Array<String>, ?workingDir:String)
	{
		if (args == null) args = [];
		
		log_last_call = '$exePath ' + args.join(' ');
		
		LOG.log('RUN: ' + log_last_call);
		
		// HELP:
		// https://nodejs.org/api/child_process.html#child_process_child_process_spawn_command_args_options
		proc = ChildProcess.spawn(exePath, args, { cwd:workingDir });
		
		/*
		 * The 'error' event is emitted whenever: 
		 * - The process could not be spawned, or
		 * - The process could not be killed, or
		 * - Sending a message to the child process failed.
		 */
		proc.once("error", function(er:Error){
			ERROR = "Exit Error : " + er.message;
			LOG.log('Process `$exePath` [ ERROR ] - $ERROR', 3);
			HTool.sCall(onClose,false);
			kill();	// Destroy other listeners that may fire upon other exit events
		});
		
		/*
		 * The 'close' event is emitted when the stdio streams of a child process have been closed. 
		 * This is distinct from the 'exit' event, 
		 * since multiple processes might share the same stdio streams.
		 */
		proc.once("close", function(code:Int, killsig:String) {
			// NOTE: Do I really need to check for a Kill Signal
			if (code != 0)
			{
				var r = FLAG_ERRORS_ON_STDERR?stdErrLog:stdOutLog;
				// Compact output and log 40 last characters
				var c = ~/(\s\s+|\n)/g.replace(r, "");
				ERROR = 'ExitCode:($code) , StdOut/Err:' + c.substr( -80);
				LOG.log('Process `$exePath` End - [ ERROR ] - $ERROR', 3);
				HTool.sCall(onClose,false);
			}else{
				LOG.log('Process `$exePath` End - [ OK ]');
				HTool.sCall(onClose, true);
			}
			kill();	// Destroy other listeners that may fire upon other exit events
		});
		
		stdOutLog = "";
		stdErrLog = "";
		
		if (onStdErr != null)
		{
			proc.stderr.setEncoding("utf8");
			proc.stderr.on("data", onStdErr);
		}
				
		if (onStdOut != null)
		{
			proc.stdout.setEncoding("utf8");
			proc.stdout.on("data", onStdOut);
		}
				
		if (LOG_STDERR)
		{
			proc.stderr.setEncoding("utf8");
			proc.stderr.on("data", (d)->stdErrLog += d);
		}
		
		if (LOG_STDOUT)
		{
			proc.stdout.setEncoding("utf8");
			proc.stdout.on("data", (d)->stdOutLog += d);
		}
	
	}//---------------------------------------------------;
	
	/**
	 * Force kill the CLI APP
	**/
	public function kill()
	{
		if (proc != null)
		{
			proc.removeAllListeners();
			proc.kill();
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
		ChildProcess.exec(path,  function (error:Dynamic, stdout:Dynamic, stderr:Dynamic) {
			callback(error == null, stdout, stderr);
		});
	}//---------------------------------------------------;
	
	/**
	   Run and return the STDOUT
	   @param	path
	   @return
	**/
	public static function quickExecS(path:String):String
	{
		try{
			return ChildProcess.execSync(path);
		}catch (e:Dynamic)
		{
			return null;
		}
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
	

	public function exists(p:String = ""):Bool
	{
		return CLIApp.checkRun(exePath + " " + p);
	}//---------------------------------------------------;		
	
	
	/**
	   LINUX ONLY 
	   Check to see if "pk" package is installed on the system
	   or other way is
	   dpkg-query -W -f='${Status}' ffmpeg
	   @param	packageName 
	**/
	#if linux 
	public static function checkLinuxPackage(packageName:String):Bool 
	{
		
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
		return false;
	}//---------------------------------------------------;
	#end

}//-- end class --//