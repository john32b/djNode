/** 
 * - Keyboard
 * -------------------
 * - Basic keyboard wrapper for the CLI
 * --------------------
 * @Author: johndimi <johndimi@outlook.com>
 * 
 * Features:
 * ---------
 * 
 * Get and respond to keypresses
 * Get special keypresses like arrow keys, or escape.
 * 
 *****************************************************/
package djNode;

import js.Node;
import js.node.stream.Readable.IReadable;

//====================================================;
// ENUMS
//====================================================;
enum Keycodes {
	up; down; left; right;
	home; insert; delete; end;
	pageup; pagedown;
	backsp; tab; enter; space;
	esc; ctrlC; acute;
	F1; F2; F3; F4; F5;
	other;
}


/**
 * Keyboard interaction helper class
 * 
 * ---------------------------------- */

class Keyboard
{
	// Pointer to process.stdin
	var stdin:IReadable;
	
	// User set
	public var _listener:String->Void;
	
	//====================================================;
	// FUNCTIONS
	//====================================================;
	
	// Force the user to press enter to continue the program
	// this is to fix the std.input bug
	public static function QUICKFIX(callback:Void->Void)
	{
		BaseApp.global_terminal.savePos();		
		BaseApp.global_terminal.printf("~line~ #~darkgray~ Quickfix for stdin problem..\n~!~ # Press ~yellow~[ENTER]~!~..\n");
		var kb = new Keyboard();
		kb._listener = function(s:String) {
			kb.stop();
			BaseApp.global_terminal.restorePos();
			BaseApp.global_terminal.clearScreen(0);
			// Return to user
			callback();
		}
		kb.start();
	}//---------------------------------------------------;
	
	public function new(?listener:String->Void)  {	
		_listener = listener;
		stdin = null;
		// stdin = Node.process.stdin;
		// stdin.setEncoding("utf8");
		// untyped(stdin.setNoDelay());
	}//----------
	/**
	 * Start capturing keyboard inputs
	 * @param realtime If true then the callback will fire on keypress
	 */
	public function start(realtime:Bool = true):Void {
		stdin = Node.process.stdin;
		untyped(stdin.setRawMode(realtime));
		stdin.setEncoding("utf8");
		stdin.on("data", _listener);
		stdin.resume();
	}//---------------------------------------------------;
	public function stop():Void {
		if (stdin == null) return;
		stdin.pause();
		untyped(stdin.setRawMode(false));
		stdin.removeAllListeners("data");
	}//---------------------------------------------------;
	// Flush the buffer
	public function flush():Void  {
		if (stdin == null) return;
		stdin.pause();
		stdin.resume();
	}//---------------------------------------------------;
	// Free up memory,
	public function kill():Void {
		stop();
		stdin = null;
	}//---------------------------------------------------;
	public function getSpecialChar(c:String):Keycodes {	
		if (c.charCodeAt(1) == null) {
			switch(c.charCodeAt(0)) {
				case 3:	 return Keycodes.ctrlC;
				case 8:  return Keycodes.backsp;
				case 9:  return Keycodes.tab;
				case 13: return Keycodes.enter;
				case 27: return Keycodes.esc;
				case 32: return Keycodes.space;
				case 96: return Keycodes.acute;
				case 127: return Keycodes.backsp;
			}
			return null;
		}//--
		
		if ((c.charCodeAt(0) == 27) && (c.charCodeAt(1) == 91))
		{
			switch(c.charCodeAt(2))
			{
				case 65: return Keycodes.up;
				case 66: return Keycodes.down;
				case 67: return Keycodes.right;
				case 68: return Keycodes.left;
				case 49: return Keycodes.home;
				case 51: return Keycodes.delete;
				case 52: return Keycodes.end;
				case 53: return Keycodes.pageup;
				case 54: return Keycodes.pagedown;
				
				case 91: /* Check for F keys */
					switch(c.charCodeAt(3))
					{
						case 65: return Keycodes.F1;
						case 66: return Keycodes.F2;
						case 67: return Keycodes.F3;
						case 68: return Keycodes.F4;
						case 69: return Keycodes.F5;
					}
			}//--
		
			return null;
			
		} //-- end if, special chars
		
		return null;
	}//---------------------------------------------------;

}//-- end --