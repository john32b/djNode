/**----------------------------------------------
 * BaseApp
 * ===========
 * = Generic Template for the Main Entry Class
 * 
 * Features:
 * ------------
 * - Easy retrieval of arguments 
 * . Extend this class
 * . Handles input parameters, check examples
 * . Supports basic wildcard for input files (*.ext) or (file.*)
 * . Semi-automated usage info
 * 
 * Notes:
 * ------------
 * 
 * 	- Override init() and set ARGS and PROGRAM_INFO there
 * 
 * Examples:
 * ------------
 * 
 * 	
 * 
 ========================================================*/
package djNode;

import js.Error;
import js.Node;
import js.node.Path;
import djNode.Keyboard;
import djNode.tools.FileTool;
import djNode.Terminal;
import djNode.tools.LOG;


class BaseApp
{
	// Keep one terminal object for the entire app.
	// All other classes should link to this one, instead of creating new terminals.
	public static var TERMINAL(default, null):Terminal;
	
	// Pointer to the global terminal, small varname for quick access from within this class
	var T(default, null):Terminal;
	
	
	// #USERSET
	// Fill this object up (check the typedef for more info)
	var PROGRAM_INFO:AppInfo = {
		name:"nodeJS Application",
		version:"0.1",
		executable:"app.js"
	}
	
	// #USERSET
	// Fill this object up, (check the typedef for more info)
	var ARGS:AppArguments = {
		inputRule:"opt",
		outputRule:"opt",	
		requireAction:false,
		supportWildcards:true,
		supportStrayArgs:false,	// Not Implemented
		helpInput:null,
		helpOutput:null,
		Actions:[],
		Options:[
			['-o', "output", "", "yes"]
		]
	};
	
	// Holds Array of all inputs
	// In case of Wildcards (*.*) they are going to be processed in place
	// and the fetched files will populate the array
	var argsInput:Array<String> = [];
	
	// Holds argument Output <string> can be file or folder etc
	var argsOutput:String = null;
	
	// Holds all argument <options>
	// - Option Names are Fields
	// - Option Value is parameter, or Bool (set or not)
	var argsOptions:Dynamic = {};
	
	// Holds the currently enabled <action>
	// Holds Action.NAME ( second Array index )
	var argsAction:String = null;
	
	
	/**
	 * 
	 */
	public function new() 
	{
		LOG.init();
		TERMINAL = new Terminal();
		T = TERMINAL;
		
		// Normal Exit, code 0 is OK, other is Error
		Node.process.once("exit", function(code) {
			LOG.log("==> [EXIT] with code " + code);
			onExit();
		});
		
		// User pressed CTRL+C
		Node.process.once("SIGINT", function() { Sys.exit(1); } );
		
		// Can also be user errors that bubbled up here.
		// Critical Error, will exit the program
		Node.process.once("uncaughtException", function(err:Dynamic) 
		{
				//#if debug
				//+ This info isn't really useful?
				//var ss = haxe.CallStack.toString(haxe.CallStack.callStack().slice(0, 6));	// Get the last 6 stacks
				//LOG.log("Callstack:\n" + Std.string(ss), 4);
				//T.printf('~!~~yellow~ - CALLSTACK - ~!~');
				//T.print(Std.string(ss)).endl();
				//#end
				
				LOG.log("Critical Error - ", 4);
				
				if (Std.is(err, Error)) {
					LOG.log(err.message, 4);
					exitError(err.message);
				}	
					LOG.log(err, 4);
					exitError(err);
		});

		// -- Start --
		try{
			init();
		}catch (e:String) {
			printBanner(true);
			if (e == "HELP") { printHelp(); Sys.exit(0); }
			exitError(e, true); // this will also exit
		}
		
		onStart();
		
	}//---------------------------------------------------;
	
	/**
	  Read Program Arguments, and initialize
	  User must have set ARGS and PROGRAM_INFO before calling this
	  @throw Argument Errors
	**/
	function init()
	{
		// Just in case the program starts with non-standard colors
		T.reset();
		
		// -- Shortcuts
		var P = PROGRAM_INFO;
		var A = ARGS;
		
		LOG.log('Creating Application [ ${P.name} ,v${P.version} ]');
		
		// -- Read Arguments ::
		var cc:Int = 2; // Start Reading from index 2. The first real user argument
		var arg:String;
		while ( (arg = Node.process.argv[cc++]) != null)
		{			
			// # <option>, options start with `-`
			if (arg.charAt(0) == "-")
			{
				// :: Build In <options> 
				if (arg.toLowerCase().indexOf("-help") == 0) throw 'HELP';
			
				var o = getArgOption(arg);
				if (o == null) throw 'Illegal argument [$arg]';
				if (o[3] != null) {
					var nextArg:String = Node.process.argv[cc++];	
					if (nextArg == null || getArgOption(nextArg) != null) {
						throw 'Argument [$arg] requires a parameter';
					}
					Reflect.setField(argsOptions, o[0].substr(1), nextArg);
					if (o[0] == "-o") argsOutput = nextArg;
				}else{
					Reflect.setField(argsOptions, o[0].substr(1), true);
				}
				
				continue;
			}
			
			// # <action>
			var a = getArgAction(arg);
			if (a != null)
			{
				if (argsAction != null) throw 'You can only set one <action>';
				argsAction = a[0];
				continue;
			}
			
			// # <input>
			// -- Whatever isn't an <action> or <option> is an input
			argsInput.push(arg);
			
		}//- end while ----
		
		
		// # Check Arguments :: ------
		
		// - Get Input Wildcard
		for(i in argsInput)
		{
			if (i.indexOf('*') >= 0 )
			{
				if (argsInput.length > 1){
					throw 'Multiple Inputs with wildcards are not supported';
				}
				
				argsInput = FileTool.getFileListFromWildcard(i);
				if (argsInput.length == 0) throw 'Wildcard `$i` returned 0 files';
				break;
			}
		}
		
		// - AutoGet Action based on Filename
		if (argsAction == null && argsInput.length > 0)
		{
			// Check if any action has a default extension and set the current active Action
			var act = getArgAction(null, Path.extname(argsInput[0].toLowerCase()).substr(1));
			if (act != null) argsAction = act[1];
		}
		
		// - Check Inputs
		if (argsInput.length == 0 && ["yes", "multi"].indexOf(A.inputRule) >= 0)
		{
			throw "Input is required";
		}
		
		// - Check Output
		if (argsOutput == null && A.outputRule == "yes")
		{
			throw "Output is required";
		}
		
		// - Check Actions
		if (A.requireAction && argsAction == null)
		{
			throw "Setting an action is required";
		}
		
	}//---------------------------------------------------;
	
	/**
	 * 
	**/
	function onStart()
	{
	}//---------------------------------------------------;
	
	/**
	  Called whenever the program exists, normally or with errors
	  You can override to clean up wh
	**/
	function onExit()
	{
		LOG.end();
		T.reset();
	}//---------------------------------------------------;
	
	
	
	/**
	 * Awaits any key and then exits the program
	 * Useful for preventing terminals from auto-closing.
	 */
	function waitKeyQuit():Void 
	{
		T.fg(Color.darkgray).endl().println("Press any key to quit.");
		T.reset();
		Keyboard.startCapture(true, function(e:String) { Sys.exit(0); });
	}//---------------------------------------------------;
	
	/**
		Shows Basic program usage.
		Autogenerated based on `ARGS` object
		-- Example Output , goto [A0001]
	**/
	function printHelp()
	{
		var A = ARGS;
		
		// -- Some Local Functions ::
		
			function __getInfoRule(rule:String):String {
				return(rule == "opt"?"is optional.":"is required.");
			}//----------------------------------
			function __fixDescFormat(s:String):String{
				if (s != null && s.length > 0){
					return ~/(\n)/g.replace(s, "\n\t");
				}else{
					return "...";
				}
			}//----------------------------------
			
		// -- Prepare some things to be printed ::
		
			// -- Modify some fields to correct spacings
			if (A.helpInput != null){
				A.helpInput = "~darkgray~\t " + ~/(\n)/g.replace(A.helpInput, "\n\t ");
			}
			if (A.helpOutput != null){
				A.helpOutput = "~darkgray~\t " + ~/(\n)/g.replace(A.helpOutput, "\n\t ");
			}
			
			// - Remove the `-o` option from expected parameters
			//	 I need to do this so it won't get printed
			//   its always the first element, and this function is only called once.
			A.Options.shift();	
			
			// - Fix <action> and <option> descriptions
			for (a in A.Actions) a[2] = __fixDescFormat(a[2]);
			for (a in A.Options) a[2] = __fixDescFormat(a[2]);
			
		
		// -- Start Printing ::
		
		T.printf(' ~green~Program Usage: ~!~ \n');
		
		var s:String = '   ${PROGRAM_INFO.executable} ';
		if (A.Actions.length > 0) 	s += "<action> ";
		if (A.Options.length > 0) 	s += "-<option> <parameter> ...\n      ";
		if (A.inputRule != "no") {
			s += "<input> ";
			if (A.inputRule == "multi") s += "... ";
		}
		if (A.outputRule != "no"){
			s += "-o <output> ";
		}
		T.print(s).endl().printf("~darkgray~ ~line2~");
		
		// -- 
		if (A.inputRule != "no") {
			T.printf('~yellow~ <input> ~!~'); 
			T.print(__getInfoRule(A.inputRule));
			if (A.inputRule == "multi") T.printf("~darkcyan~ <multiple supported>");
			T.endl();
			if (A.helpInput != null) T.printf(A.helpInput).endl();
		}
		// --
		if (A.outputRule != "no") {
			T.printf('~yellow~ <output> ~!~'); T.print(__getInfoRule(A.outputRule)).endl();
			if (A.helpOutput != null) T.printf(A.helpOutput).endl();
		}
		
		T.printf(' ~darkgray~~line2~');
		T.reset();
		
		// - Print <actions>
		if (A.Actions.length > 0) {
			T.printf(" ~magenta~<actions> ~!fg~");
			T.printf("~darkmagenta~you can set one action at a time ~!~\n");
			for (i in A.Actions) {
				T.printf('~white~ ${i[0]}\t ${i[1]}');
				if (i[3] != null) T.printf('  ~gray~ Auto Ext : (${i[3]})');
				T.printf('\n\t~darkgray~ ${i[2]}\n').reset();
			}
		}// --
		
		// - Print <options>
		if (A.Options.length > 0) {
			T.printf(" ~cyan~<options> ~!fg~");
			T.printf("~darkcyan~you can set many options~!~\n");
			for (i in A.Options) {
				T.printf('~white~ ${i[0]}\t ${i[1]}');
				if (i[3] != null) T.printf('~gray~ [requires parameter] ');
				T.printf('\n\t~darkgray~ ${i[2]}\n').reset();
			}
		}// --
		
	}//---------------------------------------------------;
	
	
	function printBanner(longer:Bool = false)
	{
		var P = PROGRAM_INFO;
		var col = "white"; var lineCol = "darkgray"; 
		T.endl(); // one blank line at first
		T.printf('== ~$col~${P.name} v${P.version}~!~\n');
		//t.printf(' ~lineCol~~line2~');
		if (longer && P.desc != null) 
			T.printf(' - ${P.desc}\n');
		if (longer && P.author != null)
			T.printf(' - ${P.author}\n');
		T.printf(' ~$lineCol~~line~~!~');
	}//---------------------------------------------------;
	
	
	/**
	 **/
	function exitError(text:String, showHelp:Bool = false):Void
	{
		T.printf('~bg_darkred~~white~ ERROR ~!~ ~red~$text\n');
		if (showHelp) T.printf('~darkgray~ ~line2~~yellow~ -help ~!~ for usage info\n');
		Sys.exit(1);
	}//---------------------------------------------------;
	
	// Search an <OPTION> object on the ARGS object
	function getArgOption(tag:String):Array<String>
	{
		for (o in ARGS.Options) { if (o[0] == tag) return o; }
		return null;
	}//---------------------------------------------------;
	// --
	// Search an <ACTION> object on the ARGS object
	function getArgAction(?tag:String,?ext:String):Array<String>
	{
		for (a in ARGS.Actions){
			// Search by same tag
			if (tag != null && a[0] == tag) return a; 
			// Search by same ext
			if (ext != null && a[3] != null) {
				if (a[3].split(',').indexOf(ext.toLowerCase()) >= 0) return a;
			}
		}
		return null;
	}//---------------------------------------------------;
	
}//--end class--//



/**
   Application Information
   Typedef for BaseApp.PROGRAM_INFO object
**/
typedef AppInfo = 
{
	name:String,		// Name
	?desc:String,		// Description
	?version:String,	// Version
	?author:String,		// Author
	?contact:String,	// Contact Info
	?date:String,		// Build Date
	?executable:String	// Name of the executable
};



/**
   Application Arguments 
   Typedef for BaseApp.ARGS object
**/
typedef AppArguments = 
{
	
	inputRule:String,		// no, yes, opt, multi
	outputRule:String,		// no, yes, opt
	
	requireAction:Bool,		// An action IS required, either be implicit setting or by file extension
	
	supportWildcards:Bool,	// If true, <*.*> and <*.ext> will be resolved. Else ERROR
	
	supportStrayArgs:Bool,	// If true, program will not ERROR on undeclared <actions,options>
							// # NOT IMPLEMENTED ! !
	
							// # For these two . use "\n" for linebreaks.
	helpInput:String,		// Help text displayed for <input> on the the -help screen
	helpOutput:String,		// Help text displayed for <input> on the the -help screen
	
	Actions:Array<Array<String>>,	// Holds Actions in an array of arrays.
									//
									// [ActionID, ActionName, ActionDescription, Extensions]
									//  string,   string,     string,			 string
									//
									// e.g. ["e","Extract","Extracts input file into output folder"] =>
									//			node app.js e archive.zip -o c:\
									//
									// `Extensions` ("" for none)
									// - Will AutoAssociate an extension with an action, so if you
									//   skip setting an action, it can be guessed by the input file
									//   extension.
									// - Separate multiple extensions with a comma (,)
									// - Null (don't set) for no extensions
									//
									// - e.g. ["e","Extract","Extracts file", "zip,7z"] =>
									//		node app.js input.zip 
	
									
	Options:Array<Array<String>>   // Holds Options in an array of arrays.
									//
									// [ OptionID, OptionName, OptionDescription, RequireValue ]
									//   string,   string,     string,            String
									//
									// e.g. ["-t","Temp","Set Temp Folder","1"] => 
									//			node app.js -t c:\temp\
									//      ["-q","Quick","Quick operation mode",false] =>
									//			node app.js -q
									// `RequireValue`
									// 	This option requires an additional parameter (just one)
									//  Set any string for YES, e.g. "yes"
};





/* [A0001] - Example PrintHelp() output :
	
== CD Crush v1.1.2
 - Dramatically reduce the filesize of CD image games
 - JohnDimi, twitter@jondmt
 --------------------------------------------------
 Program Usage:
		 app <action> -<option> <parameter> <option2> ..
				<input> <input2> ... -o <output>
 -------------------------
 <input> is required.
		 Action is determined by input file extension.   <-- USER set
		 Supports multiple inputs and wildcards (*.cue)	 <-- USER set
 <output> is optional.
		 Specify output directory.						 <-- USER set
 -------------------------
 <actions> you can set one action at a time
 c      Crush
		Crush a cd image file (.cue .ccd files)
 r      Restore
		Restore a crushed image (.arc files)
 <options> you can set many options
 -t     Temp Directory [requires parameter]
		Set a custom working directory
 -f     Restore to Folders
		Restore ARC files to separate folders
 -q     Audio compression quality [requires parameter]
		1 - Ogg Vorbis, 96kbps VBR
		2 - Ogg Vorbis, 128kbps VBR
		3 - Ogg Vorbis, 196kbps VBR
		4 - FLAC, Lossless
 */