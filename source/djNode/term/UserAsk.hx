package djNode.term;

import djNode.BaseApp;
import djNode.Keyboard;
import djNode.Terminal;
import djNode.tools.LOG;

/**
 * @STATIC class
 * Terminal Based, simple user input
 */
class UserAsk
{
	// Pointer to the main terminal object
	static var t:Terminal;
	static var kb:Keyboard;
	
	public static var callback_quit:Void->Void = null;
	//====================================================;
	// FUNCTIONS
	//====================================================;

	public static function init() 
	{
		t = BaseApp.global_terminal;
		if (kb == null) {
			kb = new Keyboard();
		}
	}//---------------------------------------------------;
	
	/**
	 * Display a list of array options and await result.
	 * -- Writes no newline at the beggining --
	 * @param	callback Callback this function with the ARRAY INDEX selected, 1st is 0
	 * @param	choices
	 */
	public static function multipleChoice(choices:Array<String>, callback:Int->Void, ?additionalChars:Array<String>):Void
	{
		var maxoptions = 0;
		
		// If the options are more than the screen height
		if (maxoptions > t.getHeight() - 2) {
			LOG.log("Warning, Screen will overflow ", 2);
		}
		
		// Write options, starting at 1
		for (i in choices) {
			maxoptions++;
			t.fg(Color.yellow).print(' $maxoptions. ');
			t.fg(Color.white).print(i).endl().reset();
		}
	
		t.reset().print(' Select one from [1-$maxoptions] : ');
		t.savePos();
		
		kb._listener = function(k:String) {	
			
			// Is it a number from 1 to maxoptions?
			// Return.
			// else, clear and ask again.
			
			checkEscapeKeys(k);
			
			var userSel:Int = Std.parseInt(k);
			
			// Restore the position either way, if correct it will write the number with green
			// Else it will await new input
			
			t.restorePos();
			t.clearLine(0);
				
			if (userSel > 0 && userSel <= maxoptions)
			{
				// If I tell it to print k, it will print the \n as well
				t.fg(Color.green).print('$userSel').reset().endl();
				kb.stop();
				callback(userSel-1);
			}

		};
		
		kb.start(false);
		
	}//---------------------------------------------------;
	
	
	/**
	 * --no newline at start--
	 * --no newline at end--
	 * @param	callback
	 * @param	question
	 */
	public static function yesNo(callback:Bool->Void, ?question:String):Void
	{
		if (question != null) {
			t.fg(Color.white);
			t.print(' $question');
		}
		t.fg(Color.yellow);
		t.print(' (Y/N) : ');
		kb._listener = function(k:String) {
			checkEscapeKeys(k);
		if (k.toLowerCase() == "y") {
			t.fg(Color.green).print("Y").reset();
			kb.stop();
			callback(true);
		}else if (k.toLowerCase() == "n") {
			t.fg(Color.red).print("N").reset();
			kb.stop();
			callback(false);
		}};
		kb.start();

	}//---------------------------------------------------;

	// --
	static function checkEscapeKeys(k:String):Void
	{
		if (kb.getSpecialChar(k) == Keycodes.ctrlC)
		{
			if (callback_quit != null) callback_quit(); 
			else {
				t.fg(Color.red).print(" -- Process Exit -- \n").reset();
				Sys.exit(1);
			}
		}
	}//---------------------------------------------------;
	
}//-- end class --//