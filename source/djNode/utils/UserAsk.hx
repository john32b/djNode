package djNode.utils;

import djNode.BaseApp;
import djNode.Keyboard;
import djNode.Terminal;
import djNode.tools.HTool;
import djNode.tools.LOG;

/**
 * Utilities, User Interaction
 */
class UserAsk
{
	// Pointer to the main terminal object
	static var t:Terminal;
	
	/**
	 * Display a list of array options and await result.
	 * Returns Index of choices[] selected
	 * -- Writes no newline at the beggining --
	 * @param	choices Array of lines
	 * @param	callback Callback this function with the ARRAY INDEX selected, 1st is 0
	 */
	public static function multipleChoice(choices:Array<String>, callback:Int->Void):Void
	{
		var maxoptions = 0;
		var t = BaseApp.TERMINAL;
		
		// If the options are more than the screen height
		if (maxoptions > t.getHeight() - 2) {
			LOG.log("Warning, Screen will overflow ", 2);
		}
		
		// Write options, starting at 1
		for (i in choices) {
			maxoptions++;
			t.fg(yellow).print(' $maxoptions. ');
			t.fg(white).print(i).endl().reset();
		}
	
		t.reset().print(' Select one from [1-$maxoptions] : ');
		t.savePos();
		
		Keyboard.onData =  function(k:String) {	
			
			// Is it a number from 1 to maxoptions?
			// Return.
			// else, clear and ask again.
			
			var userSel:Int = Std.parseInt(k);
			
			// Restore the position either way, if correct it will write the number with green
			// Else it will await new input
			
			t.restorePos();
			t.clearLine(0);
				
			if (userSel > 0 && userSel <= maxoptions)
			{
				// If I tell it to print k, it will print the \n as well
				t.fg(green).print('$userSel').reset().endl();
				Keyboard.stop();
				//callback(userSel);
				HTool.tCall(callback, userSel);
			}

		};
		
		Keyboard.startCapture(false);
		
	}//---------------------------------------------------;
	
	
	/**
	 * Presents a (Y/N) at current terminal place and awaits for user input
	 * --no newline at start--
	 * --no newline at end--
	 * @param	callback True for YES, False for No. If <null> will hold program and be SYNC
	 * @param	question Custom Question, will not be printed if ommited
	 */
	public static function yesNo(?callback:Bool->Void, ?question:String):Bool
	{
		var t = BaseApp.TERMINAL;
		if (question != null) {
			t.fg(white);
			t.print(' $question');
		}
		t.fg(yellow);
		t.print(' (Y/N) : ');

		if(callback!=null) 
		{
			Keyboard.onData = function(k:String) {
				if (k.toLowerCase() == "y") {
					t.fg(green).print("Y").reset();
					Keyboard.stop();
					callback(true);
				}else if (k.toLowerCase() == "n") {
					t.fg(red).print("N").reset();
					Keyboard.stop();
					callback(false);
				}};
			Keyboard.startCapture(true);
			}
		else {
			// There is a bug in default windows terminal
			// Use t.restorepos() then t.up() to align the cursor
			t.savePos();
			var r = "";
			while(r=="") {
				r = Keyboard.readOnceSync();
				trace("len" , r.length,r);
				r = r.toLowerCase();
				if(r.length==1){
					if(r.charAt(0)=="y") return true; else
					if(r.charAt(0)=="n") return false;
				}
				r="";	// capture again
				t.restorePos().clearLine(0);
			}
		}
		return false; 
	}//---------------------------------------------------;
	
}//-- end class --//