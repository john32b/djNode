/**----------------------------------------------
 * - Baseapp.hx
 * ----------------------------------------------
 * - Basic application extender
 * ----------------------------------------------
 * @Author: johndimi, <johndimi@outlook.com>, @jondmt
 * 
 * 
 * Features:
 * ===========
 * . Extend this class
 * . Handles input parameters, check examples
 * 
 * Notes:
 * ============
 * 
 * Version History
 * ================
 * 
 ========================================================*/
package djNode;

import js.Node;
import js.node.Path;
import haxe.PosInfos;
import djNode.Keyboard;
import djNode.tools.FileTool;
import djNode.tools.StrTool;
import djNode.Terminal;
import djNode.tools.LOG;


/**
 * Generic Template for command line applications
 * -----------
 * Features:
 *  User sets what type of arguments should be accepted
 *  Easy retrieval of arguments,
 *  Supports basic wildcard for input files (*.ext) or (file.*)
 *  Semi-automated usage info
 * 
 */
class BaseApp
{
	// Keep one terminal object for the entire app.
	// All other classes should link to this one, instead of creating new terminals.
	public static var global_terminal(default, null):Terminal;
	// Pointer to the global terminal, small varname for quick acess
	var t:Terminal;
	
	// The filename of the executable. e.g. "program.js"
	public var executable_name(default, null):String;
	
	// Used only in criticalError();
	var flag_critical_exit(default,null):Bool;
	// Set when the user forces the app to quit
	var flag_force_exit(default,null):Bool;
	// Autoset by program if inputs were discovered with * inputs
	var flag_params_Input_discovered(default,null):Bool = false;
	// ---------
	
	// Holds all the options got.
	var params_Options:Map<String,AcceptedArgument>; // # USER READ
	// List of input files got
	var params_Input:Array<String>;		// # USER READ
	// Holds the action got. ONLY 1 ACTION at a time
	var params_Action:String = null;	// # USER READ
	// The output file/dir got
	var params_Output:String = null; 	// # USER READ
	// Valid arguments set by user
	// use addParam() to add accepted parameters
	var params_Accept:Map<String,AcceptedArgument>;
	// - Stores what extensions trigger which actions,
	// 	 Comma separated / e.g. ['EX,zip,7z,arc,rar'] // EX action for zip,7z,arc,rar
	// use setActionByFileExt() to add stuff
	var params_autoActionExt:Array<String>;

	
	//-- Helpers
	// Number of available actions
	var _number_of_actions:Int = 0; 
	// Number of available options
	var _number_of_options:Int = 0;
	
	//---------------------------------------------------;
	// - User set params
	//---------------------------------------------------;
	// Set these vars on the overrided init() function.
	
	// Does the program requires an action to be set
	var flag_param_require_action:Bool = false;
	// Set the Rules of requiring input and outputs
	// [ no, yes, opt, multi]
	var require_output_rule:String = "no";
	var require_input_rule:String = "no";
	
	var support_multiple_inputs:Bool = false;

	// Use can set these, for a brief description of the input
	// . You can use format tags to these, like colors etc.
	// . You can use \n for a newline.
	var help_text_input:String = null;
	// . and the output help text, same rules as help_text_input
	var help_text_output:String = null;
	
	// Some program info
	var info_program_name:String = "UnnamedApp";
	var info_program_version:String = "0.0";
	var info_program_desc:String = "";
	var info_author:String = "";
	
	//----------------------------------------------------;
	// FUNCTIONS
	//----------------------------------------------------;
	
	/**
	 * @IMPORTANT--
	 * Don't Initialize anything on new()
	 * override the init() function instead
	 */
	public function new() 
	{
		// -- Init Basic --

		LOG.init();

		BaseApp.global_terminal = new Terminal();
		t = BaseApp.global_terminal;
			
		executable_name = Path.basename(Node.process.argv[1]);
		params_Options = new Map();
		params_Input = new Array();
		params_Accept = new Map();
		params_autoActionExt = new Array();
			
		Node.process.once("exit", onExit);
		Node.process.once("SIGINT", function() { flag_force_exit = true; Sys.exit(1); } );
		
		// -- Start execution --
		
		// - Catches errors, 
		Node.process.once("uncaughtException", function(err:Dynamic) {
			// Callstack is kind of useless, since it points to the compiled file??
			//#if debug
				//var ss = CallStack.toString(CallStack.callStack().slice(0, 6));	// Get the last 6 stacks
				//LOG.log("Callstack:\n" + Std.string(ss), 4);
				//t.printf('~!~~yellow~ - CALLSTACK - ~!~');
				//t.print(Std.string(ss)).endl();

			//#end
			LOG.log("Critical Error", 4);
			LOG.logObj(err, 4);
			criticalError(err.message);
		});
			
		init();
	
		LOG.log('Creating Application [ $info_program_name ,v$info_program_version ]');
		
		create(); 
	
		// If the build is on debug, the program will wait a CTRL+C to exit
		// If release, the program will exit normally
	}//---------------------------------------------------;
	
	/** 
	 * User program entry point
	 * Override this.
	 */
	function create():Void
	{
	}//---------------------------------------------------;

	/**
	 * This gets and inits the parameters passed to the program
	 * @Override to set custom parameters BUT DO IT BEFORE CALLING SUPER.INIT()
	 */
	function init():Void
	{
		LOG.log("Initializing BaseApp");
		
		addParam('-help', "Display Usage info", "This screen", false, false, true);
		addParam('-o',    "output", "Set the output for the app", true);
	
		// Format the helper text, so that they line up properly
		if (help_text_input != null)
		help_text_input =  "\t " + ~/(\n)/g.replace(help_text_input, "\n\t ");
		
		if (help_text_output != null)
		help_text_output = "\t " + ~/(\n)/g.replace(help_text_output, "\n\t ");
	
		// - This is an odd way of getting  
		//   the parameter errors but it works well.
		try {
			getParameters();
		}catch (e:String) {
			if (e == "HELP") {
				showUsage();
				Sys.exit(1);
			}
			printBanner(true);
			criticalError(e, true);
		}
		
	}//---------------------------------------------------;
	
	/**
	 * Adds a parameter to expect on program execution
	 * Action or Option
	 * The program can perform ONE action at a time,
	 * but many options at once
	 * 
	 * @param	command	The string to trigger this parameter [ -option, action ]
	 * @param	name Short name of the action or option
	 * @param	description A brief description, [ use "#nl" markup for next line ]
	 * @param	requireValue (bool) if a value is expected after this // false
	 * @param	isDefault (bool) If program will always set this to apply // false
	 */
	function addParam(command:String, name:String, ?description:String, 
						?requireValue:Bool, ?isDefault:Bool, hidden:Bool = false):Void
	{
		// Safeguard, check parameter, useful only in development.
		#if debug
		var reg = ~/([\s\r\n])/g;
		if (reg.match(command)) {
			throw "Command string must contain no whitespace or new line char";
		}
		#end
		
		var p = new AcceptedArgument();
			if (command.substr(0, 1) == "-") {
				p.type = "option"; 
				_number_of_options++;
				p.requireValue = (requireValue == true); //Avoid it being null
			}else {
				p.type = "action";
				_number_of_actions++;
				p.requireValue = false; // Assert that actions NEVER require a parameter
			}
			
			p.command = command;
			p.hidden = hidden;
			p.name = name;
			p.description = (description != null) ? description : "...";
			p.description = ~/#nl/g.replace(p.description, "\n\t");
			p.isdefault = (isDefault == true);	// Avoid null
			params_Accept.set(command, p);	
	}//---------------------------------------------------;

	// --
	// Get The value of an option parameter
	// An option parameter start with a dash "-t";
	// You should call this WITH the dash as well.
	function getOptionParameter(opt:String):String
	{
		if (params_Options.exists(opt))
			return params_Options.get(opt).parameter;
		else
			return null;
	}//---------------------------------------------------;
	
	// Autosets the action according to the input file extention
	// Be careful!, 
	// - only one action per entry and only once
	// - If multiple files it will only consider the first of the inputs,
	//   so you have to double check for integrity.
	//
	// #USER CALL FROM DERIVED BASEAPP
	//
	// e.g.
	//      this will match the "ecm" filename to the action named "fix"
	// 		setActionByFileExt("fix", ["ecm"]);
	// --
	function setActionByFileExt(action:String, fileExtensions:Array<String>):Void {
		var str = action;
		for (i in fileExtensions) {
			str += ',' + i.toLowerCase();
		}
		params_autoActionExt.push(str);
	}//---------------------------------------------------;

	//---
	function getParameters()
	{
		LOG.log("Getting Parameters", 1);
		
		var cc:Int = 2;
		var arg:String = Node.process.argv[cc];
		
		//-- Get Arguments 
		// ===========================
		
		while ( arg != null)
		{
			if (params_Accept.exists(arg)) 
			{
				if (arg == "-help") throw "HELP";
				
				var par = params_Accept.get(arg);
				
				if (par.type == "action")
					params_Action = par.command;
				else// if (par.type == "option") // it's always an option.
				{				
					// Now if the option requires extra values
					if (par.requireValue) {
						var nextArg = Node.process.argv[++cc];
						if (nextArg == null || params_Accept.exists(nextArg))
							throw 'Argument $arg requires a parameter';
						par.parameter = nextArg;
					}
					
					//Assert: check to see if same option exists already
					if (params_Options.exists(arg)) params_Options.remove(arg);
						params_Options.set(par.command, par);
					
				}//--endif type==option
					
			}//--endif argument exists in AcceptedParameters
			else if (arg.substr(0, 1) == "-") {
				//Catch type insensitive arguments
				if (arg.toLowerCase().indexOf("-help") == 0) throw "HELP";
				throw 'Illegal argument [$arg]';
				
			}else {
				
				//Since it didn't exist in accepted params, 
				//it must be an input
				params_Input.push(arg);
			}
			
			arg = Node.process.argv[++cc];
		}//--arguments pars
		
		
		//-- Check Arguments 
		// ===========================
		
		// Get the output dir to separate var
		if (params_Options.exists('-o')) {
			params_Output = params_Options.get('-o').parameter;
			// Since I got the var, delete it from the map, I don't need it anymore
			params_Options.remove('-o');
		}
		
		// Process the default arguments
		for (i in params_Accept) {
			if (i.isdefault == true) {
				if (i.type == "action") 
					if (params_Action == null) params_Action = i.command;
				if ( i.type == "option") 
					if (params_Options.exists(i.command) == false)
						params_Options.set(i.command, i);
			}
		}//--
		
		// Check for multiple * inputs.
		if (params_Input.length>0)
		if (params_Input[0].indexOf('*') >= 0) {
			var temp = params_Input[0];
			params_Input = FileTool.getFileListFromAsterisk(params_Input[0]);
			if (params_Input.length == 0) {
				throw "Input '" + temp + "' returned 0 files.";
			}
			flag_params_Input_discovered = true;
		}
		
		// Get the autoaction only from the first file of many
		// - all files should be of the same extension -
		if (params_Action == null && params_Input[0] != null) {
			// get the extension of the first file
			var _ext = Path.extname(params_Input[0].toLowerCase()).substr(1);	
			for (i in params_autoActionExt) {
				var str:Array<String> = i.split(',');
				var _c = 0;
				// skip the first
				while (++_c < str.length) {
					if (str[_c] == _ext)
						params_Action = str[0];
				}
			}
		}
		
		if (params_Action == null && flag_param_require_action == true)
			throw "Setting an action is required";

		if (require_output_rule == "yes" && params_Output == null)
			throw "Output is required";
			
		if (["yes", "multi"].indexOf(require_input_rule) >= 0 && params_Input.length == 0)
			throw "Input is required";
	
	}//---------------------------------------------------;
	
	// Shows Basic program usage.
	// It auto generates it, by reading the expected arguments
	// ----------------------------------------------------
	function showUsage() 
	{
		// -- local function
		function __printUsageParameter(par:AcceptedArgument):Void {
			if (par.hidden) return;
			t.fg(Color.white).print(' ${par.command}\t');
			t.print(par.name).reset();
			if (par.isdefault) t.fg(Color.yellow).print(" [default]");
			if (par.requireValue) t.fg(Color.gray).print(" [requires parameter] ");
			t.fg(Color.darkgray).print('\n\t${par.description}\n').reset();
		}//---------------------------------
		
		function __getInfoTextFromRule(rule:String):String {
			if (rule == "yes") return "is required.";
			return "is optional.";
		}//----------------------------------
		
		// Somethings to do before displaying usage:
		// Testing to remove the -o from usage, it's redundant
		if (params_Accept.exists('-o')) {
			params_Accept.remove('-o');
			_number_of_options--;
		}
		
		//helpers, for input & output info text.
		var _r1:Bool = null;
		var _r2:Bool = null;
		
		//-- Start printing the info --
		printBanner(true);
		var s:String = '\t $executable_name ';
		if (_number_of_actions > 0) s += '<action> ';
		if (_number_of_options > 1) s += '<opt> <opt.parameter> ... <opt N>\n\t\t';
		if (["yes", "opt", "multi"].indexOf(require_input_rule) >= 0) {
			 _r1 = true;
			if (support_multiple_inputs)
				s += '<input> .. <input N> ';
			else
				s += '<input> ';
			
		}
		if (["yes", "opt"].indexOf(require_output_rule) >= 0) { 
			s += '-o <output> '; _r2 = true;
		}
		t.printf(' ~green~Program Usage:~!~\n');
		t.print(s).endl().printf(' ~darkgray~~line2~');
		
		// -- Proceed showing infos:
		
		if (_r1) {// -- Show the input info
			t.printf('~yellow~ <input> ~!~');
			t.print(__getInfoTextFromRule(require_input_rule)).reset();
			if (help_text_input != null)
				t.endl().printf(help_text_input);
			t.endl();
		}
		
		if (_r2) { // -- Show the output info
			t.printf('~yellow~ <output> ~!~');
			t.print(__getInfoTextFromRule(require_output_rule)).reset();
			if (help_text_output != null)
				t.endl().printf(help_text_output);
			t.endl();
		}

		t.printf(' ~darkgray~~line2~');
		
		// -- <actions>
		if (_number_of_actions > 0) {
		t.printf(" ~magenta~<actions> ~!fg~");
		t.printf("~darkmagenta~you can set one action at a time ~!~\n");
		for (i in params_Accept)
			if (i.type == "action") __printUsageParameter(i);
		}
		
		// -- <options>
		if (_number_of_options > 1) {	// The first element is always the help, so skip it.
		t.printf(" ~cyan~<options> ~!fg~");
		t.printf("~darkcyan~you can set many options~!~\n");
		for (i in params_Accept)
			if (i.type == "option") __printUsageParameter(i);
		}
		
		/* UNCOMMENT this to show additional usage info
		/* =============================================
		 *
		if (params_autoActionExt.length>0) {
			t.fg(Color.darkred).print(" Auto-set actions by input extension:\n");
			for (i in params_autoActionExt)
			{
				var str = i.split(',');
				var actionName = params_Accept.get(str[0]).name;
				str.shift();
				var _pp = str.join(",");
				
				t.reset().fg(Color.white).print(' <$actionName> ');
				t.fg(Color.gray).print(' [$_pp]\n');
			}
		} 
		/* */
		
		//t.printf(' ~line~~!~');
		//t.color(Color.darkgray).print(" (Swatches are Case Sensitive)").reset();
		
		useExample();
	}//---------------------------------------------------;

	
	function useExample()
	{
		// override
	}//---------------------------------------------------;
	
	
	/**
	 * Prints the program banner
	 * 
	 * @param longer if true, it will print the description and author as well
	 */
	function printBanner(longer:Bool=false) /* override this */ 
	{ 
		var col = "white";
		var lineCol = "darkgray";
		var titletext = '$info_program_name v$info_program_version';
		t.endl(); // one blank line at first
		t.printf('== ~$col~$titletext~!~\n');
		//t.printf(' ~darkgray~~line2~');
		if (longer && info_program_desc != "") 
			t.printf(' - $info_program_desc\n');
		if (longer && info_author != "")
			t.printf(' - $info_author\n');
		t.printf(' ~$lineCol~~line~~!~');
	}//---------------------------------------------------;
	
	// Basic progress indication
	// -------------------------
	function _logProgress_start(str:String) {
		t.reset().fg(Color.white).print(str).savePos();
		t.fg(Color.yellow);	//this is the color for the _updates;
	}//---------------------------------------------------;
	function _logProgress_update(str:Dynamic) {
	  t.restorePos().clearLine(0).print('$str');
	}//---------------------------------------------------;
	function _logProgress_end(success:Bool,?customMessage:String) {
		t.restorePos().clearLine(0);
		if (success) {
		 t.fg(Color.green);
		 if (customMessage == null) customMessage = "[complete]";
		} else {
		 t.fg(Color.red);
		 if (customMessage == null) customMessage = "[fail]";
		}
		t.print(customMessage).endl().reset();
	}//---------------------------------------------------;

	/** 
	 * Appends to global Logger and displays message on the screen
	 */
	function log(msg:String,?pos:PosInfos):Void
	{
		LOG.log(msg, 1, pos);
		t.println(' - $msg');
	}//---------------------------------------------------;

	/**
	 * A critical error has occured.
	 * Stop Program execution.
	 * TODO: Why is this a function?, inline it?
	 **/
	function criticalError(text:String, showHelp:Bool = false):Void
	{
	  t.printf('~bg_darkred~~white~ ERROR ~!~ ~red~$text\n');
	  if (showHelp) {
		  t.printf('~darkgray~ ~line2~~yellow~ -help ~!~ for usage info\n');		  
	  }
	  flag_critical_exit = true;
	  Sys.exit(1);
	}//---------------------------------------------------;
		
	/**
	 * Awaits any key and then exits the program
	 * Useful for preventing terminals from auto-closing.
	 */
	function WaitKeyQuit():Void {
	   var key:Keyboard;
	   t.fg(Color.darkgray).endl().println("Press any key to quit.");
	   t.reset();
	   key = new Keyboard(function(e:String) { Sys.exit(0); } );
	   key.start();
	}//---------------------------------------------------;
	
	/**
	 * Auto called whenever program exits,
	 **/
	function onExit():Void
	{
		if (flag_force_exit)
			LOG.log("App Quit - User Quit");
		else
			LOG.log("App Quit -  Normally");
			
		LOG.end();
		t.reset();
	}//---------------------------------------------------;

}//--end class--//



/**
 * Basic Term application helper
 * Provides easy Argument parsing and 
 * basic logging functions
 * -------------------------------------------------
 */

class AcceptedArgument 
{
	public var isdefault:Bool;		// if true, then this will always apply.
	public var hidden:Bool;			// show this param on the HELP screen
	public var command:String;		// Text string, e,g, "-x".
	public var name:String;			// Full name of parameter, e.g. "Extract".
	public var type:String;			// [action,option]
	public var description:String;	// Brief description.
	public var parameter:String;	// optional parameter for option.
	public var requireValue:Bool;	// if true, this option requires a value afterwards.
	
	public function new() { }
}//----------------------------------------------
