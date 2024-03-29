
/********************************************************************
 * BaseApp.hx
 * Generic Template for the Main Entry Class
 *
 * Features:
 * ------------
 * - Easy way to declare and handle input parameters
 * - Supports <actions> <options> <input> <output> as input
 * . Supports basic wildcard for <input> (*.ext) or (file.*)
 * - Automatic generation of help/usage text
 *
 * Help
 * ------------
 * 	- Override init() and set ARGS and PROGRAM_INFO there
 *
 * Uncaught Exceptions
 * --------------------
 *  - Currently , no handler, will crash and display stack , for debugging
 *  - Install npm package source-map-support | npm install source-map-support
 *  - In the code do : js.Lib.require('source-map-support').install();
 *  - This will convert all stack traces to point to haxe files
 *  - For custom errors you must do : throw new Error("message");
 * 
 *******************************************************************/

package djNode;

import djA.StrT;
import js.lib.Error;
import js.Node;
import js.node.Path;

import djNode.Keyboard;
import djNode.tools.FileTool;
import djNode.Terminal;
import djNode.tools.LOG;


class BaseApp
{
	// djNode Version
	public static inline var VERSION = "0.6.2";

	// Instance
	public static var app:BaseApp;

	// Keep one terminal object for the entire app.
	// All other classes should link to this one, instead of creating new terminals.
	public static var TERMINAL(default, null):Terminal;

	// Default line length, used in printhelp and 3
	inline static var LINE_LEN = 40;

	// Spacing formatter on the help screen
	// Aligns the Description of Options, Actions to this many chars from the left
	var HELP_MARGIN:Int = 16;

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
		inputRule:"no",
		outputRule:"no",
		requireAction:false,
		resolveWildcards:true,
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
	// Same as `argsOptions.o`
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
	
	// #NEW 0.6.1
	// Called automatically just before the program exits along with exit CODE
	// 0=normal exit | 1223=user ctrl+c | other = critical error
	// Useful sometimes e.g. when you want to close a file handle before a crash
	// 	!! don't forget to null this and be careful when using it !!
	public var onExit_:Int->Void;

	//====================================================;

	public function new()
	{
		BaseApp.app = this;
		LOG.init();
		FLAG_USE_SLASH_FOR_OPTION = false;
		T = TERMINAL = new Terminal();

		// Normal Exit, code 0 is OK, other is Error
		// This will be called on normal exits + uncaught exceptions
		Node.process.once("exit", onExit);

		// User pressed CTRL+C
		Node.process.once("SIGINT", function() { Sys.exit(1223); } ); // 1223 : The operation was canceled by the user.

		Node.process.once("uncaughtException", function(err:Dynamic) {
			
			#if (!debug)
			var e = " Critical Error :: ";
			if (Std.is(err, Error)) e += err.message; else e += cast err;
			exitError(e);
			#else
			onExit(1); // Trigger user shutdown
			if (Std.is(err, Error)) throw err; // NPM:source-map-support should handle it if present
			#end
		});
		

		// -- Start --
		try{
			init();
		}catch (e:String) {
			printBanner(true);
			if (e == "HELP") { printHelp(); Sys.exit(0); }
			exitError(e, true); // this will also exit
		}

		// -- Log Parameters
		// --------------------
		LOG.log('- Inputs : ' + argsInput.join(', '));
		LOG.log('- Output : ' + argsOutput);
		LOG.log('- Action  set : ' + argsAction);
		LOG.log('- Options set : ');
		for (o in Reflect.fields(argsOptions)) {
			LOG.log('\t\t' + o + ' : ' + Reflect.getProperty(argsOptions, o));
		}
		LOG.log(StrT.line(LINE_LEN));

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
		ARGS.Options.unshift(['o', "-output", "yes"]);

		// -- Shortcuts
		var P = PROGRAM_INFO;
		var A = ARGS;

		if (P.executable == null)
		{
			P.executable = Path.basename(Node.__filename);
		}

		LOG.log('Creating Application [ ${P.name} ,v${P.version} ]');

		// -- Read Arguments ::
		var cc = 0;
		var arguments = Sys.args();
		var arg:String;
		while ( (arg = arguments[cc++]) != null)
		{
			// # <option>, options start with `-` or `/`
			if (arg.charAt(0) == _sb[0])
			{
				if (arg.toLowerCase().indexOf(_sb[1]) == 1) // '--help' or '/?'
					throw 'HELP';

				var o = getArgOption(arg.substr(1));
				if (o == null) throw 'Illegal argument [$arg]';
				if (o[2] != null) { // Requires Parameter
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
				// NEW 0.6.1 : Allow multiple Actions, All the following keywords that match an action will be handled as Inputs
				// if (argsAction != null) throw 'You can only set one <action>';
				if (argsAction == null) {
					argsAction = a[0];
					continue;
				}
			}

			// # [input]
			// -- Whatever isn't an <action> or <option> is an input
			argsInput.push(arg);

		}//- end while ----

		// -- Some Post Logic

		// Quick access to Output?
		if (argsOptions.o != null) argsOutput = argsOptions.o;


		// # Check Arguments :: ------

		// - Get Input Wildcard
		if (ARGS.resolveWildcards)
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
			if (o[2] == null) { // Option not expecting argument
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
	  Called whenever the program exits, normally or with errors
	  You can override to clean up things
	  # Common Codes:
		- 0 		: The operation completed successfully.
		- 1 		: Incorrect function ( generic error )
		- 1223 		: User Cancel (with ctrl+c) 
	**/
	function onExit(code:Int)
	{
		if (onExit_ != null) onExit_(code);
		LOG.log("==> [EXIT] with code " + code);
		LOG.end();
		T.reset();
		T.cursorShow(); // Just in case
	}//---------------------------------------------------;


	/**
		Shows Basic program usage.
		Autogenerated based on `ARGS` object
		-- Example Output , goto [A0001]
	**/
	function printHelp()
	{
		var A = ARGS; var P = PROGRAM_INFO;
		// > Quick Create blank space
		var sp = (s)->StrT.rep(s, " ");
		// > Description string, apply padding to linebreaks
		// > Add the string (b) at the end of the FIRST line
		var __fixDescFormat = (s:String, b:String) -> {
			var S = StrT.isEmpty(s)?"...":(~/(\n)/g.replace(s, '\n ' + sp(HELP_MARGIN)));
			var g = S.split('\n');
			g[0] += b;
			return g.join('\n');
		};

		// -- Program usage
		// -----------------------------
		T.ptag('<green> Program Usage:\n');
		var s = '   ${P.executable} ';
		if (A.Actions.length > 0) 	s += "<action> ";
		if (A.Options.length > 1) 	s += "[<options>...] ";
		if (A.inputRule != "no") {
			s += (A.inputRule == "multi"?"[<inputs>...] ":"<input> ");
		}
		if (A.outputRule != "no") {
			s += _sb[0] + "o <output> ";
		}
		T.ptag('<bold,white>$s<!>\n').fg(darkgray).println(StrT.line(LINE_LEN));

		// -- Print Input/Output Help --
		// -----------------------------
		
		var _prtIO = (r, lab, txt) ->  {
			if (r == "no") return false;
			T.ptag('<yellow> [$lab] <!> is ' + ((r == "opt")?"optional.":"required.")); 
			if (r == "multi") T.ptag("<darkgray> (multiple supported)");
			T.endl();
			if (txt != null) {
				txt = "<gray>\t " + ~/(\n)/g.replace(txt, "\n\t "); // append a tab (\t) to newlines (\n)
				T.ptag(txt).endl();
			}
			return true;
		}//---------------------------
		
		var a = _prtIO(A.inputRule, 'input', A.helpInput);
		var b = _prtIO(A.outputRule, 'output', A.helpOutput);
		// If it printed any of the 'input/output' help text, print a line afterwards
		// DEV: I can't inline the check, because I need them both to be executed.
		if(a || b) {
			T.ptag(' <darkgray>' + StrT.line(LINE_LEN)).endl();
		}
		
		T.reset();

		// -- Print <actions>
		// -----------------------------
		if (A.Actions.length > 0) {
			T.ptag("<magenta> [actions] ");
			T.ptag("<darkmagenta>(you can set one action at a time)<!>\n");
			for (i in A.Actions) {
				if (i[1].charAt(0) == "-") continue;
				i[1] = __fixDescFormat(i[1], i[2] == null?'':'<darkgray> | auto ext:[${i[2]}] <!>');
				T.fg(white).bold();
				T.ptag(' ' + i[0] + sp(HELP_MARGIN - i[0].length)).reset().ptag(i[1]);
				T.endl();
			}
		}// --
		// -- Print <options>
		// -----------------------------
		if (A.Options.length > 1) {
			T.ptag("<cyan> [options] ");
			T.ptag("<darkcyan>(you can set multiple options)<!>\n");
			for (i in A.Options) {
				if (i[1].charAt(0) == "-") continue;
				i[1] = __fixDescFormat(i[1], i[2] == null?'':'<darkgray> (requires parameter) <!>');
				T.fg(white).bold();
				T.ptag(' ' + _sb[0] +  i[0] + sp(HELP_MARGIN - i[0].length - 1)).reset().ptag(i[1]);
				T.endl();
			}
		}// --

		// -- Finally
		// -----------------------------
		if (ARGS.helpText != null)
		{
			T.endl();
			T.ptag('${ARGS.helpText}\n');
		}
	}//---------------------------------------------------;


	/**
	   Prints program information from the `PROGRAM_INFO` object
	   @param	longer Include Description and Author
	**/
	function printBanner(longer:Bool = false)
	{
		var P = PROGRAM_INFO; // Shorter code
		var col = "cyan";
		T.endl(); // one blank line at first
		T.ptag('<:$col,black>==<!><$col,bold> ${P.name} <darkgray>v${P.version}<!>');
		if (longer)
		{
			if (P.author != null) T.ptag(' by ${P.author}');
			T.endl();
			if (P.info != null) T.ptag(' - ${P.info}\n');
			if (P.desc != null) T.ptag(' - ${P.desc}\n');
		}else
		{
			T.endl();
		}

		T.ptag('<$darkgray>' + StrT.line(LINE_LEN) + '<!>\n');
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
			if (ext != null && a[2] != null) {
				if (a[2].split(',').indexOf(ext.toLowerCase()) >= 0) return a;
			}
		}
		return null;
	}//---------------------------------------------------;

	//====================================================;
	// USER FUNCTIONS
	//====================================================;

	/**
	 * Display a message and Exit immediately.
	 * Message can have color tags like
	 **/
	public function exitError(text:String, showHelp:Bool = false):Void
	{
		T.ptag('\n<:darkred,white> ERROR <!> $text<!>\n');
		if (showHelp) T.ptag('<darkgray>' + StrT.line(LINE_LEN) + '\n<yellow> ${_sb[0]}${_sb[1]} <!> for usage info\n');
		LOG.FLAG_STDOUT = false; // In case this was on. I don't want to log to stdout again for the next log:
		LOG.log(T.PARSED_NOTAG, 4);
		Sys.exit(1);
	}//---------------------------------------------------;

	/**
	 * Check to see if this is running as Admin
	 */
	function isAdmin():Bool
	{
		var res = djNode.utils.CLIApp.quickExecS('fsutil dirty query %systemdrive% >nul');
		return(res != null);
	}//---------------------------------------------------;

	/**
	   Automatically call the matching function of an action
	   - You need to define the function in the extended class
	   - Function name = "action_" + Action
	**/
	function autoCallAction()
	{
		var fn = Reflect.field(this, "action_" + argsAction);
		if (fn != null && Reflect.isFunction(fn))
		{
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
		T.ptag('\n<darkgray>Press any key to quit.<!>\n');
		Keyboard.startCapture(true, (e) -> Sys.exit(0) );
	}//---------------------------------------------------;



	/**
	   Get Relative to App Path
	   e.g. Getting a config file that is on the same dir as the app .js file
	**/
	public function getAppPathJoin(p:String)
	{
		return Path.join(js.Node.__dirname, p);
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

	requireAction:Bool,		// An action IS required; either by implicit setting or by auto-guessed by file extension

	resolveWildcards:Bool,	// If true, wildcards for files {* | *.* | *.ext} will be resolved.

	helpInput:String,		// Help text displayed for [input] on the the -help screen. \n supported (optional)
	helpOutput:String,		// Help text displayed for [input] on the the -help screen. \n supported (optional)
	helpText:String,		// Text displayed below program usage on the -help screen (optional)

							// ^DEV: Use "\n" for linebreaks for help texts

	Actions:Array<Array<String>>,	// Holds Actions in an array of arrays.
									//
									// [ActionID, ActionDescription, Extensions]
									//  String    String			 String (csv)
									//
									// e.g. ["e","Extracts input file into output folder"]
									//
									// - You can put color tags in the description e.g. <yellow>word<!>
									// - If description starts with '-' help will not print this action
									// - [Extensions]
									// 		- Will AutoAssociate an extension with an action, so if you
									//  		 skip setting an action, it can be guessed by the input file
									// 	 		 extension.
									// 		- Separate multiple extensions with a comma (,)
									// 		- Null (don't set) for no extensions
									// 		- e.g. ["e","Extracts file", "zip,7z"] ::
									//		# node app.js input.zip
									//		#  ^ will automatically call "e" action

	Options:Array<Array<String>>    // Holds Options in an array of arrays.
									//
									// [ OptionID, OptionDescription, RequireValue ]
									//   String    String             String
									//
									// e.g. ["t","Set Temp Folder","1"] ::
									//			node app.js -t c:\temp\
									//      ["q","Quick operation mode",false] ::
									//			node app.js -q
									// - You can put color tags in the description e.g. <yellow>word<!>
									// - [RequireValue]
									// 		This option requires an additional parameter (just one)
									//  	Set any string for YES, e.g. "yes"
};