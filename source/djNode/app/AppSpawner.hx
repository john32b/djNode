/****
 * Application Spawner
 * -------
 * johndimi, <johndimi@outlook.com>, @jondmt
 * -------
 * @requires: hxnodejs
 * @supportedplatforms: nodeJS
 * @architectures: Windows, Linux
 * 
 * !BASE CLASS!, override this.
 * 
 * . Spawns an external application,
 * . Windows and Linux support for calling the application
 * . Checks for application availability,
 * .		. Exists in Folder
 * .		. Exists in PATH (Windows)
 * .		. Exists in Installed packages (Linux, dpkg based)
 *
 * @events: check (bool), true if executable is found, false if not
 * 			close (bool), true if exited normally, false if not
 * 
 * ---------------------------------------*/

package djNode.app;

import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.Node;
import js.node.ChildProcess.spawn;
import js.node.ChildProcess.exec;
import js.node.child_process.ChildProcess;
import js.node.events.EventEmitter;
import js.node.Path;
import js.node.Process;


/**
 * Helper class to spawn a process,
 * 
 * - Checks if executable exists
 * - Unified calls for linux and windows
 * - MUST BE OVERRIDED -
 */

class AppSpawner
{
	
	// Emits:
	// --------
	// check : BOOL, Whether app is exists or not
	// close : BOOL, App closed gracefuly or not, if not there is another parameter with error
	public var events:IEventEmitter;
	
	// Handle of the process
	var proc:ChildProcess;
	// The path of the nodejs executable
	// This is useful if I want to call the binaries if I am on another working folder
	var dir_exe:String;
	// linux, win32
	var platform:String;

	// - check : BOOL, auto-check for the program?
	// - type: 
	//	  package , check if the package with name $param exists [ linux ]
	//	  folder  , check if the $param is valid e.g. "c:/programfiles/app.exe"  [ both ]
	//	  custom  , call a user overrider function to check for the app [ both ]
	//	  onpath  , try to run the program as is, perhaps it's on the path or program folder [ both ]
	// - param: parameter for type
	var audit = { 
		linux : { check:false, type:"", param:"" },
		win32 : { check:false, type:"", param:"" } 
	};
	
	
	// In case of error, this gets occupied with the error data
	public var error_log(default, null):String;
	
	// In case of error, this gets occupied with an error code (user custom created)
	// "01"
	public var error_code(default, null):String;
	//---------------------------------------------------;

	// --
	public function new() 
	{
		events = new EventEmitter();
		dir_exe = Path.dirname(Node.process.argv[1]);
		platform = Node.process.platform;
	}//---------------------------------------------------;

	// --
	// -- quickExec v.0.1
	// Fires an application and let it run until it exits
	// Also captures the output
	// Callbacks: success -> stdout -> stderr
	public static function quickExec(path:String, callback:Bool->String->String->Void)
	{
		// Encoding is utf8 by default
		var pr:ChildProcess = exec(path,  function (error:Dynamic, stdout:Dynamic, stderr:Dynamic) {
			callback(error == null, stdout, stderr);
		});
	}//---------------------------------------------------;
	
	// --
	// Quicker way to spawn an app from derived classes.
	function spawnProc(path:String, ?params:Array<String>)
	{
		proc = spawn(path, params);
		proc.once("error", function(a:Dynamic) { 
			LOG.log("Child Process - Error", 3);
			error_log = '$a';
			error_code = "error";
			events.emit("close", false);
			kill();
		});
		listen_exit();
	}//---------------------------------------------------;
	
	
	// -- Called when the child exits --
	function listen_exit():Void
	{
		proc.once("close", function(exit:Dynamic, sig:String) {
			if (exit != 0 || sig != null){
				error_log = sig;
				error_code = "error";
				LOG.log("Child Process Close - [ ERROR ] - " + error_log, 3);
				events.emit("close", false);
			}
			else {
				LOG.log("Child Process Close - [ OK ]");
				events.emit("close", true);
			}
			kill();
		} );
	}//---------------------------------------------------;	
	
	// -- 
	// Try to free up memory
	function kill()
	{
		if(proc!=null)
		{
			proc.removeAllListeners("close");
			proc = null;
		}
		
	}//---------------------------------------------------;
	
	//====================================================;
	// CHECK FUNCTIONS 
	//====================================================;
	
	// -- Checks to see if the application exists
	//  - This is optional and is offered as a safeguard
	public function checkApp():Void 
	{
		LOG.log("Checking app..");
		
		switch (platform)  {
			
			case "linux": {
				if(audit.linux.check){
					switch(audit.linux.type) {
						case "folder": check_allArch_infolder(audit.linux.param);
						case "onpath": check_allArch_onpath(audit.linux.param);
						case "package": check_linux_package(audit.linux.param);
						case "custom": check_linux_custom();
						default: onAppCheckResult(false, "Wrong audit type");
					}
				}else onAppCheckResult(true);
			}

			case "win32": {
				if(audit.win32.check){
					switch(audit.win32.type){
						case "onpath": check_allArch_onpath(audit.win32.param);
						case "folder": check_allArch_infolder(audit.win32.param);
						case "custom": check_win32_custom();
						default: onAppCheckResult(false, "Wrong audit type");
					}
					}else onAppCheckResult(true);
			}

			default:{
				onAppCheckResult(false,"Unsupported platform");
			}
		}//.end switch
	}//---------------------------------------------------;

	// --
	function onAppCheckResult(status:Bool = true, ?msg:String):Void 
	{
		if (status == true) {
			LOG.log("AppCheck [OK]");
			events.emit("check", true);
		}else {
			LOG.log("AppCheck [ERROR]");
			events.emit("check", false, msg);
		}
	}//---------------------------------------------------;
	
	// --
	// Try to run the application once without params
	// This should be used if the app would start and exit immidiately, not blocking
	// Usefull in some cases ( like ffmpeg )
	function check_allArch_onpath(exeToCheck:String)
	{
		LOG.log('Checking on Path for $exeToCheck');
		// Try to spawn the program
		AppSpawner.quickExec(exeToCheck, function(status:Bool,so:String,se:String) {
			onAppCheckResult(status, 'Can\'t find [$exeToCheck]');
		});
	}//---------------------------------------------------;
	
	
	/**
	 * Check to see if "pk" package is installed on the system
	 *	or other way is
	 *	dpkg-query -W -f='${Status}' ffmpeg
	 **/
	function check_linux_package(packageName:String):Void {

		#if linux // -- don't forget to set a linux compiler flag if on linux
		
		var res:String = "";
		var p:ChildProcess = spawn("dpkg-query",
				[ "-W",
				  "-f='${Status}'", packageName ]);
				  
		p.stdout.on("data", function(data) { res = data; } );
		p.stdout.setEncoding("utf8");
		p.on("exit", function(code:Dynamic, sig:Dynamic) {
				if(~/ok/.match(res))
					onAppCheckResult();
				else
					onAppCheckResult(false, 'Could not find [$packageName] in installed packages.');
		} );
		
		#end
	}//---------------------------------------------------;

	/* 
	 * Check to see if program exists in specific folder
	 */
	function check_allArch_infolder(path:String):Void {
		if (FileTool.pathExists( Path.normalize(path) ))
				onAppCheckResult(true);
			else
				onAppCheckResult(false,'Can\'t find [$path]');
	}//---------------------------------------------------;

	// -- Override these --
	function check_win32_custom():Void { onAppCheckResult(false,"--"); }
	function check_linux_custom():Void { onAppCheckResult(false,"--"); }
	
	// --
	// VERY OLD, SOON TO BE DELETED --
	// Checks to see if a string exists in the system %PATH%
	// This function is bullshit, I am disabling this.
	/*
	function check_win32_PATHVAR(pathToCheck:String):Void {
		var reg_slashes = ~/\\/g;
		// Replace all slashes to forward slash, just in case
		pathToCheck = reg_slashes.replace(pathToCheck, "/"); 
		var reg_exist = new EReg(pathToCheck, "i");
		var path:String = Node.process.env['Path'];
		path = reg_slashes.replace(path, "/");
		
		if (reg_exist.match(path)) {
			onAppCheckResult();
		}else {
			onAppCheckResult(false, 'Could not find $pathToCheck on %PATH%');
		}
		return;
	}//---------------------------------------------------; */

}//-- end class --//