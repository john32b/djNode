/**
 * == ActionInfo
 * =  Write simple formatted info on the terminal for Actions 
 * 
 * e.g. :
 * 
 *  [Action] : [Result] <info>
 * 	"Compressing : file.arc"
 * 	"Extracting : 100% [ complete ]"
 * 
 * ------
 * 
 * - Write an action line at once
 * 		.printPair();
 * 		.quickAction();
 * 
 * - Keep updating the same action line
 * 		.actionStart();
 * 		.actionProgress();
 * 		.actionEnd();
 * 
 */

 
package djNode.utils;

import djNode.Terminal.Color;
import djNode.tools.LOG;


class ActionInfo
{
	// -- Theming :
	public var style:ActionInfoStyle = 
	{
		accentColor:"yellow",
		infoColor:"darkgray",
		prefix:" ",
		separator:":"
	};
	
	// Pointer to a terminal object
	var t:Terminal;
	
	// Is the info waiting for a result. ( progress or whatever )
	var _waitResult:Bool;
	
	//====================================================;
	
	// --
	public function new() 
	{
		t = BaseApp.TERMINAL;
		_waitResult = false;
	}//---------------------------------------------------;
	
	
	/**
	 * Print an action on the terminal
	 * -- Note the line should be at newline --
	 * @param	name
	 * @param	sub
	 * @param   pairColor override the default color for the pair value
	 */
	public function printPair(action:String, info:Dynamic = "", ?pairColor:String)
	{
		t.printf('${style.prefix}$action ${style.separator} ');
		if (pairColor == null) t.fg(style.accentColor); else t.fg(pairColor);
		t.printf(Std.string(info) + '\n~!~');
	}//---------------------------------------------------;
	

	// --
	// Print a one line quick action
	public function quickAction(action:String, success:Bool, ?info:String)
	{
		t.printf('${style.prefix}$action ${style.separator} ');

		__printSuccess(success);
		
		if (info != null) {
			t.printf('~${style.infoColor}~ , $info~!~');
		}
		
		t.endl();
	}//---------------------------------------------------;
	
	/**
	 * Display the first part of an info, save the cursor position and 
	 * wait for actionEnd or actionProgres
	 * @param	action
	 */
	public function actionStart(action:String)
	{
		t.printf('${style.prefix}$action ${style.separator} ');
		t.savePos();
		_waitResult = true;
	}//---------------------------------------------------;
	
	/**
	 * End an action
	 * @param	success true or false
	 * @param	info Optional info text
	 */
	public function actionEnd(success:Bool, ?info:String)
	{
		if (_waitResult) {
			t.restorePos();
			t.clearLine(0);
		}
		__printSuccess(success);
		
		if (info != null) {
			t.printf('~${style.infoColor}~ , $info~!~');
		}
		
		t.endl();
		_waitResult = false;
	}//---------------------------------------------------;
	
	/**
	 * Progress is in string format, user is responsible for formatting it.
	 * @param	progress It will be enclosed into [ ]
	 * @param	info Optional info to be displayed after the progress
	 */
	public function actionProgress(progress:String, ?info:String)
	{
		t.restorePos();
		t.printf('~${style.accentColor}~[$progress]~!~');
		if (info != null) {
			t.printf('~${style.infoColor}~ , $info~!~');
		}
	}//---------------------------------------------------;
	
	// -- 
	// Reset the output line if it's waiting
	public function reset()
	{
		if (_waitResult)
		{
			t.restorePos();
			t.clearLine(2);
			t.back(t.getWidth()); // go to the start of the line
			_waitResult = false;
		}
	}//---------------------------------------------------;
	
	// Helper
	// --
	function __printSuccess(success:Bool)
	{
		if (success) {
			t.printf('~green~[OK]~!~');
		}else {
			t.printf('~red~[FAIL]~!~');	
		}
	}//---------------------------------------------------;
	
}// --



// Style parameters for an action
// 
// Action : Result 
// 
typedef ActionInfoStyle = 
{
	accentColor:String,
	infoColor:String,
	prefix:String,		// Before writing "ACTION"
	separator:String	// Between action and result
}
