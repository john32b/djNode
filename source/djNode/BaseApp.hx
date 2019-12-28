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
 * Changes since last ver:
 * ----------------
 * 	- Options no longer require an initial `-` when declared
 *  - NEW: FLAG_USE_SLASH_FOR_OPTION, Can set this on init()
 *         Help will require `/?` or `-help` depending 
 * 
 ========================================================*/
package djNode;

import haxe.CallStack;
import js.lib.Error;
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
	
	// Spacing formatter on the help screen
	// Aligns the Description of Options,Actions to this many chars from the left 
	var HELP_MARGIN:Int = 12;
	
	// Pointer to the global terminal, small varname for quick access from within this class
	var T(default, null):Terminal;
	
	// # USERSET
	// If true will require '/' for options, else '-'
	var FLAG_USE_SLASH_FOR_OPTION(default, set):Bool; // Default at new() to use setter
	function set_FLAG_USE_SLASH_FOR_OPTION(v){
		FLAG_USE_SLASH_FOR_OPTION = v;
		if (v){
			_sb = ['/', '?'];
		}else{
			_sb = ['-', 'help'];
		}
		return v;
	};
	
	// #USERSET
	// Fill this object up (check the typedef for more info)
	var PROGRAM_INFO:AppInfo = {
		name:"CLI Application",
		version:"0.1",
	}
	
	// #USERSET
	// Fill this object up, (Check the typedef "AppArguments" for more info)
	var ARGS:AppArguments = {
		inputRule:"opt",
		outputRule:"opt",
		requireAction:false,
		supportWildcards:true,
		supportStrayArgs:false,	// Not Implemented
		helpInput:null,
		helpOutput:null,
		helpText:null,
		Actions:[],
		Options:[]
	};
	
	// Holds Array of all inputs
	// In case of Wildcards (*.*) they are going to be processed in place
	// and the fetched files will populate the array
	var argsInput:Array<String> = [];
	
	// Holds argument Output <string> can be file or folder etc
	// Same as argsOptions.o
	var argsOutput:String = null;
	
	// Holds all argument <options>
	// - Option Names are Fields
	// - Option Value is parameter, or Bool (set or not)
	var argsOptions:Dynamic = {};
	
	// Holds the currently enabled <action>
	// Holds Action.NAME ( second Array index )
	var argsAction:String = null;

	// Autoset, Special Parameters symbols
	// [0] what to declare options with (-,/)
	// [1] help string (? or help)
	@:noCompletion var _sb:Array<String>;
	
	/**
	 * 
	 */
	public function new() 
	{
		FLAG_USE_SLASH_FOR_OPTION = false;
		
		LOG.init();
		TERMINAL = new Terminal();
		T = TERMINAL;

		#if nodejs
		
		// Normal Exit, code 0 is OK, other is Error
		Node.process.once("exit", function(code) {
			LOG.log("==> [EXIT] with code " + code);
			onExit(cast code);
		});
		
		// User pressed CTRL+C
		Node.process.once("SIGINT", function() { Sys.exit(1223); } );
		
		// JStack Library
		// Use the JSTACK_NO_SHUTDOWN define to use custom handlers
		Node.process.once("uncaughtException", function(err:Dynamic) 
		{
			var e:String = " ** Uncaught Exception ** \n";
			if (Std.is(err, Error)) e += err.message; else e += cast err;
			exitError(e);
		});
		
		#end

		// -- Start --
		try{
			init();
		}catch (e:String) {
			printBanner(true);
			if (e == "HELP") { printHelp(); Sys.exit(0); }
			exitError(e, true); // this will also exit
		}
		
		// -- Log Arguments Got
		
		LOG.log('- Inputs : ' + argsInput.join(', '));
		LOG.log('- Output : ' + argsOutput);
		LOG.log('- Action  set : ' + argsAction);
		LOG.log('- Options set : ');
		for (o in Reflect.fields(argsOptions)) {
			LOG.log('\t\t' + o + ' : ' + Reflect.getProperty(argsOptions, o));
		}
		LOG.log('-------------');
		
		// Clear the CallStack
		Node.process.nextTick(onStart);
		
	}//---------------------------------------------------;
	
	/**
	  Read Program Arguments, and initialize
	  - User must have set ARGS and PROGRAM_INFO before calling this
	  - Override this, and call it at the end
	  @throws Argument Errors
	**/
	function init()
	{
		// Just in case the program starts with non-standard colors
		T.reset();
		
		// HACK, Push the output parameter now.
		//  - Why: Have the 'ARGS.Options' object empty when user adds parameters in it
		//  - NOTE: '-output' the dash makes it not appear in help
		ARGS.Options.unshift(['o', "-output", "", "yes"]);
		
		// -- Shortcuts
		var P = PROGRAM_INFO;
		var A = ARGS;
		
		LOG.log('Creating Application [ ${P.name} ,v${P.version} ]');
		
		// -- Read Arguments ::
		var cc:Int = 0;
		var arguments = Sys.args();
		var arg:String;
		while ( (arg = arguments[cc++]) != null)
		{
			// # <option>, options start with `-` or `/`
			if (arg.charAt(0) == _sb[0])
			{
				// :: Build In <options> 
				if (arg.toLowerCase().indexOf(_sb[1]) == 1)
					throw 'HELP';
				
				var o = getArgOption(arg.substr(1));
				if (o == null) throw 'Illegal argument [$arg]';
				if (o[3] != null) { // Requires Parameter
					var nextArg:String = arguments[cc++];	
					if (nextArg == null || getArgOption(nextArg) != null) {
						throw 'Argument [$arg] requires a parameter';
					}
					Reflect.setField(argsOptions, o[0], nextArg);
				}else{
					Reflect.setField(argsOptions, o[0], true);
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
		
		// -- Some Post Logic
		
		// Quick access to Output?
		if (argsOptions.o != null) argsOutput = argsOptions.o;
		
		
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
			if (act != null) argsAction = act[0];
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
		
		// - Make options not set to fields with `false` for quick look up
		for (o in ARGS.Options) {
			if (o[3] == null) { // Option not expecting argument
				if (!Reflect.hasField(argsOptions, o[0])) {
					Reflect.setField(argsOptions, o[0], false);
				}
			}
		}
	}//---------------------------------------------------;
	
	/**
	 * User code
	 * Override and start program
	**/
	function onStart() {}
	
	/**
	  Called whenever the program exists, normally or with errors
	  You can override to clean up things
	  # Common Codes:
		- 0 		: The operation completed successfully.
		- 1 		: Incorrect function ( generic error )
		- 1223 		: User Cancel
	**/
	function onExit(code:Int)
	{
		LOG.end();
		T.reset();
		T.cursorShow(); // Just in case
	}//---------------------------------------------------;
	
	
	/**
	   Automatically call the matching function of an action
	   - You need to define the function in the extended class
	   - Function name = "action_" + Action
	   @param p If TRUE will print some info on the action 
	**/	
	function autoCallAction(p:Bool = false)
	{
		var fn = Reflect.field(this, "action_" + argsAction);
		if (fn != null && Reflect.isFunction(fn))
		{
			if(p) T.printf('~yellow~+ ~!~Action <~yellow~' + getArgAction(argsAction)[1] + '~!~>\n');
			return Reflect.callMethod(this, fn, []);
		}
		return null;
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
		var sp = function(s){return StringTools.lpad("", " ", s); }	
		
		var A = ARGS; var P = PROGRAM_INFO;
		
		// -- Some Local Functions ::
		
			function __getInfoRule(rule:String):String {
				return(rule == "opt"?"is optional.":"is required.");
			}//----------------------------------
			function __fixDescFormat(s:String):String{
				if (s != null && s.length > 0){
					return ~/(\n)/g.replace(s, '\n ' + sp(HELP_MARGIN));
				}else{
					return "...";
				}
			}//----------------------------------
			
		// -- Prepare some things to be printed ::
		
			// -- Modify some fields to correct spacings
			if (A.helpInput != null){
				A.helpInput = "~gray~\t " + ~/(\n)/g.replace(A.helpInput, "\n\t ");
			}
			if (A.helpOutput != null){
				A.helpOutput = "~gray~\t " + ~/(\n)/g.replace(A.helpOutput, "\n\t ");
			}
		
			
			// - Fix <action> and <option> descriptions
			for (a in A.Actions) a[2] = __fixDescFormat(a[2]);
			for (a in A.Options) a[2] = __fixDescFormat(a[2]);
			
		
		// -- Start Printing ::
		
		T.printf(' ~green~Program Usage: ~white~ \n');
		
		if (P.executable == null) P.executable = "app.js";
		var s:String = '   ${P.executable} ';
		if (A.Actions.length > 0) 	s += "<action> ";
		if (A.Options.length > 0) 	s += _sb[0] + "<option> <parameter> ...\n      ";
		if (A.inputRule != "no") {
			s += "<input> ";
			if (A.inputRule == "multi") s += "... ";
		}
		if (A.outputRule != "no"){
			s += _sb[0] + "o <output> ";
		}
		
		
		T.print(s).endl().printf("~darkgray~ ~line2~");
		
		// -- 
		var _pp = false;
		if (A.inputRule != "no") {
			_pp = true;
			T.printf('~yellow~ <input> ~!~'); 
			T.print(__getInfoRule(A.inputRule));
			if (A.inputRule == "multi") T.printf("~darkcyan~ <multiple supported>");
			T.endl();
			if (A.helpInput != null) T.printf(A.helpInput).endl();
		}
		// --
		if (A.outputRule != "no") {
			_pp = true;
			T.printf('~yellow~ <output> ~!~'); T.print(__getInfoRule(A.outputRule)).endl();
			if (A.helpOutput != null) T.printf(A.helpOutput).endl();
		}
		
		if(_pp) T.printf(' ~darkgray~~line2~');
		T.reset();
		
		// - Print <actions>
		if (A.Actions.length > 0) {
			T.printf(" ~magenta~<actions> ~!.~");
			T.printf("~darkmagenta~you can set one action at a time ~!~\n");
			for (i in A.Actions) {
				if (i[1].charAt(0) == "-") continue;
				T.printf('~white~ ${i[0]}' + sp(HELP_MARGIN - i[0].length) + '${i[1]}');
				if (i[3] != null) T.printf('~darkgray~ ~ auto ext:[${i[3]}]');
				T.endl().print(sp(HELP_MARGIN));
				T.printf('~gray~ ${i[2]}\n').reset();
			}
		}// --
		
		// - Print <options>
		if (A.Options.length > 0) {
			T.printf(" ~cyan~<options> ~!.~");
			T.printf("~darkcyan~you can set many options~!~\n");
			for (i in A.Options) 
			{
				// Skip printing <options> whose name starts with `-`
				if (i[1].charAt(0) == "-") continue;
				T.printf('~white~ ${_sb[0]}${i[0]}' + sp(HELP_MARGIN - i[0].length - 1) + '${i[1]}');
				if (i[3] != null) T.printf('~darkgray~ [requires parameter] ');
				T.endl().print(sp(HELP_MARGIN));
				T.printf('~gray~ ${i[2]}\n').reset();
			}
		}// --
		
		
		if (ARGS.helpText != null) 
		{
			T.endl();
			T.print('${ARGS.helpText}\n');
		}
		
	}//---------------------------------------------------;
	
	
	/**
	   Prints program information from the `PROGRAM_INFO` object
	   @param	longer Include Description and Author
	**/
	function printBanner(longer:Bool = false)
	{
		var P = PROGRAM_INFO;
		var col = "cyan"; var lineCol = "darkgray"; 
		T.endl(); // one blank line at first
		T.printf('~:$col~~black~==~!~~$col~~b~ ${P.name} ~darkgray~v${P.version}~!~');
		
		if (longer)
		{
			if (P.author != null) T.print(' by ${P.author}'); 
			T.endl();
			if (P.info != null) T.print(' - ${P.info}\n');
			if (P.desc != null) T.print(' - ${P.desc}\n');
		}else
		{
			T.endl();
		}
		
		T.printf(' ~$lineCol~~line~~!~');
	}//---------------------------------------------------;
	
	
	/**
	 **/
	function exitError(text:String, showHelp:Bool = false):Void
	{
		T.printf('\n~:darkred~~white~ ERROR ~!~ ~red~$text\n');
		if (showHelp) T.printf('~darkgray~ ~line2~~yellow~ ${_sb[0]}${_sb[1]} ~!~ for usage info\n');
		LOG.log(text, 4);
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
	?info:String,		// Project Info or contact ( currently same as desc )
	?desc:String,		// Description ( currently same as info )
	?version:String,	// Version
	?author:String,		// Author
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
	
	supportStrayArgs:Bool,	// If true, program will not ERROR on undeclared <options>
							// # NOT IMPLEMENTED ! !
	
							// DEV: Use "\n" for linebreaks for help texts
							
	helpInput:String,		// Help text displayed for <input> on the the -help screen (optional)
	helpOutput:String,		// Help text displayed for <input> on the the -help screen (optional)
	helpText:String,		// Text displayed below program usage on the -help screen (optional)
	
	Actions:Array<Array<String>>,	// Holds Actions in an array of arrays.
									//
									// [ActionID, ActionName, ActionDescription, Extensions]
									//  string,   string,     string,			 string
									//
									// e.g. ["e","Extract","Extracts input file into output folder"] =>
									//			node app.js e archive.zip -o c:\
									//
									// = `Extensions`
									// - Will AutoAssociate an extension with an action, so if you
									//   skip setting an action, it can be guessed by the input file
									//   extension.
									// - Separate multiple extensions with a comma (,)
									// - Null (don't set) for no extensions
									// - e.g. ["e","Extract","Extracts file", "zip,7z"] =>
									//		node app.js input.zip 
									// =
									// - `ActionName` if starting with '-' will not show in help
									//
									
	Options:Array<Array<String>>    // Holds Options in an array of arrays.
									//
									// [ OptionID, OptionName, OptionDescription, RequireValue ]
									//   string,   string,     string,            String
									//
									// e.g. ["t","Temp","Set Temp Folder","1"] => 
									//			node app.js -t c:\temp\
									//      ["q","Quick","Quick operation mode",false] =>
									//			node app.js -q
									// `RequireValue`
									// 		This option requires an additional parameter (just one)
									//  	Set any string for YES, e.g. "yes"
									// `OptionName` ,  if starting with '-' will not show in help
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