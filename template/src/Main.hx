package;

import djNode.*;
import djNode.term.UserAsk;
import djNode.tools.LOG;

class Main extends BaseApp
{	
	// If the program needs realtime keyboard input, set it to true,
	// The program will request an ENTER input at start.
	// This will fix the keyboard bug
	var useKeyboardFix:Bool = false ;
	
	//---------------------------------------------------;
	
	override function init():Void 
	{
		info_program_name = "Template";
		info_program_version = "1.0";
		info_program_desc = "Template program description";
		require_input_rule = "opt";
		require_output_rule = "opt";
		
		super.init();
		
		t.pageDown();
		Graphics.init();
	}//---------------------------------------------------;
	// --
	override function create():Void { 
		if (useKeyboardFix) Keyboard.QUICKFIX(createFinal); 
			else createFinal();
	}//---------------------------------------------------;
	// --
	// User code star here:
	function createFinal() 
	{
		printBanner();
		
		// -- Program code here -- //
		
	}//---------------------------------------------------;
	
	
	// --
	static function main()  {
		LOG.flag_socket_log = false;
		LOG.logFile = "_log.txt";
		new Main();
	}//---------------------------------------------------;
}