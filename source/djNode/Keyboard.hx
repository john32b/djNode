/** 
 * - Keyboard
 * -------------------
 * - Basic Lightweight keyboard helper
 * - Can capture basic keys
 * --------------------
 * @Author: johndimi <johndimi@outlook.com>
 * 
 *****************************************************/

package djNode;

import js.Node;
import js.node.stream.Readable.IReadable;


/**
   Some Keycodes that Keyboard.toKeyCodeID() can report
**/
enum KeycodeID {
	up; down; left; right;
	home; insert; delete; end;
	pageup; pagedown;
	backsp; tab; enter; space;
	esc; ctrlC; acute;
	F1; F2; F3; F4; F5; F6; F7; F8; F9; F10; F11; F12;
	other;
}


/**
   Keycodes to check against Keyboard.onData()
**/
class Keycode
{	
	public static var CTRLC = "\u0003";
	public static var ESC 	= "\u001b";
	
	public static var UP 	= "\u001b[A";
	public static var DOWN 	= "\u001b[B";
	public static var LEFT 	= "\u001b[C";
	public static var RIGHT = "\u001b[D";
	
	public static var BACKSP 	= "\u0008";
	public static var TAB 		= "\u0009";
	public static var ENTER 	= "\u000d";
	public static var DELETE 	= "\u007f";
	
	/**
	   Return the KeyCode enum of the captured key NULL if nothing
	   @param	key The key data, as it was sent from stdin
	   @return
	**/
	public static function toKeyCodeID(key:String):KeycodeID
	{
		
		/*
		   Test Key Inputs
		   
			trace(  key.charCodeAt(0) + " - " + 
					key.charCodeAt(1) + " - " + 
					key.charCodeAt(2) + " - " +
					key.charCodeAt(3));
		*/
	
				
		if (key.charCodeAt(1) == null) 
		{
			switch(key.charCodeAt(0)) {
				case 3:	 return KeycodeID.ctrlC;
				case 8:  return KeycodeID.backsp;
				case 9:  return KeycodeID.tab;
				case 13: return KeycodeID.enter;
				case 27: return KeycodeID.esc;
				case 32: return KeycodeID.space;
				case 96: return KeycodeID.acute;
				case 127: return KeycodeID.backsp;
			}
			
		}else
		
		if ((key.charCodeAt(0) == 27) && (key.charCodeAt(1) == 91))
		{
			
			switch(key.charCodeAt(2))
			{
				case 65: return KeycodeID.up;
				case 66: return KeycodeID.down;
				case 67: return KeycodeID.right;
				case 68: return KeycodeID.left;
				case 49: 
					switch(key.charCodeAt(3))
					{
						case 55 : return KeycodeID.F6;
						case 56 : return KeycodeID.F7;
						case 57 : return KeycodeID.F8;
						case 126: return KeycodeID.home;
					}
				case 50: 
					switch(key.charCodeAt(3))
					{
						case 48 : return KeycodeID.F9;
						case 49 : return KeycodeID.F10;
						case 51 : return KeycodeID.F11;
						case 52 : return KeycodeID.F12;
						case 126: return KeycodeID.insert;
					}
				case 51: return KeycodeID.delete;
				case 52: return KeycodeID.end;
				case 53: return KeycodeID.pageup;
				case 54: return KeycodeID.pagedown;
				
				case 91: // F Keys
					switch(key.charCodeAt(3))
					{
						case 65: return KeycodeID.F1;
						case 66: return KeycodeID.F2;
						case 67: return KeycodeID.F3;
						case 68: return KeycodeID.F4;
						case 69: return KeycodeID.F5;
					}
			}
			
		}// -
		
		return null;
	}//---------------------------------------------------;
}// --



 /**
    Keyboard Capture Helper Class
	-
	+ realtime 
	+ onEnter
	-
 **/
	
class Keyboard
{
	// Pointer to process.stdin
	static var stdin:IReadable;
	
	// User callback on key data
	public static var onData:String->Void = null;
	
	// If this is set, it will be called whenever the capture breaks by a keystroke
	public static var onBreak:Void->Void = null;

	// If true, pressing CTRLC when realtime capturing will stop the capture
	public static var FLAG_CAN_BREAK:Bool = true;
	
	
	/**
	   Start Capturing input from the STDIN
	   @param	realtime If true will callback every keystroke, false for word by word
	**/
	public static function startCapture(realtime:Bool = true, callback:String->Void = null)
	{
		stop();
		if (callback != null) onData = callback;
		stdin = Node.process.stdin;
		untyped(stdin.setRawMode(realtime));
		stdin.setEncoding("utf8");	// hex, ascii, binary, utf8
		stdin.on("data", onKeyData);
		stdin.resume();
	}//---------------------------------------------------;

	// --
	static function onKeyData(data:String)
	{
		if (FLAG_CAN_BREAK && (data == Keycode.CTRLC))
		{
			stop();
			if (onBreak != null) onBreak();
			onBreak = null;
			return;
		}
		
		if (onData != null) onData(data);
	}//---------------------------------------------------;
	

	/**
	   Stop Capturing the Keyboard
	**/
	public static function stop()
	{
		if (stdin == null) return;
		stdin.pause();
		untyped(stdin.setRawMode(false));
		stdin.removeAllListeners("data");
	}//---------------------------------------------------;
	

	/**
	   Flush the keyboard buffer
	**/
	public static function flush()
	{
		if (stdin == null) return;
		stdin.pause();
		stdin.resume();
	}//---------------------------------------------------;

}//-- end --