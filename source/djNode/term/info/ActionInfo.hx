package djNode.term.info;
import djNode.task.Task;
import djNode.Terminal.Color;
import djNode.tools.LOG;

/**
 * Write simple formatted info on the terminal for actions
 * supports progress report
 * 
 * e.g.
 * Compressing : file.arc
 * Extracting : 100% [ complete ]
 */
class ActionInfo
{
	//====================================================;
	// USER SET 
	//====================================================;
	
	// -- Theming --
	
	// Optional info text after a task status
	public var color_info:String = "gray";
	// Implies a black background and gray text
	// Main color accent
	public var color_accent:String = "yellow";
	// Padding form the left all the lines should start
	public var padding_string:String = " ";
	// Action : Result
	public var symbol_separator:String = ":";
	// ----
	// Pointer to a terminal object
	var t:Terminal;
	// Is the info waiting for a result. ( progress or whatever )
	var _waitResult:Bool;
	//====================================================;
	
	public function new() 
	{
		t = BaseApp.global_terminal;
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
		__checkWaitStatus();
		t.printf('$padding_string$action $symbol_separator ');
		if (pairColor != null)
		t.printf('~$pairColor~' + Std.string(info) + '\n~!~');
		else
		t.printf('~$color_accent~' + Std.string(info) + '\n~!~');
	}//---------------------------------------------------;
	
	
	public function deletePrevLine()
	{
		t.up(1);
		// t.back(t.getWidth()); // go to the start of the line
		t.clearLine(2);
	}//---------------------------------------------------;
	
	// --
	// Print a one line quick action
	public function quickAction(action:String, success:Bool, ?info:String)
	{
		__checkWaitStatus();
		
		t.printf('$padding_string$action $symbol_separator ');

		__printSuccess(success);
		
		if (info != null) {
			t.printf('~$color_info~ , $info~!~\n');
		}
	}//---------------------------------------------------;
	
	
	//====================================================;
	// Actions
	//====================================================;
	
	/**
	 * Display the first part of an info, save the cursor position and 
	 * wait for actionEnd or actionProgres
	 * @param	action
	 */
	public function actionStart(action:String)
	{
		__checkWaitStatus();
		
		t.printf('$padding_string$action $symbol_separator ');
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
			t.printf('~$color_info~ , $info~!~\n');
		}else{
			t.endl();
		}
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
		t.printf('~$color_accent~[$progress]~!~');
		if (info != null) {
			t.printf('~$color_info~ , $info~!~\n');
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
	
	// Display generic task progress using the task's name
	//--
	public function genericProgress(status:String, task:Task, useInline:Bool = false )
	{
		if (status == "fail") {	
			actionEnd(false);
		}else	
		if (status == "start") {
			// Show the info in the same line, be sure to add a new line before calling this
			if (useInline) {
				deletePrevLine();
			}
			actionStart(task.name);
		}else
		if (status == "complete") {
			actionEnd(true);
		}else
		if (status == "progress") {
			if (task.progress_type == "percent") {
				actionProgress('% ${task.progress_percent}');
			}
			else if (task.progress_type == "steps") {
				actionProgress('${task.progress_steps_current}/${task.progress_steps_total}');
			}
		}
	}//---------------------------------------------------;
	
	
	//====================================================;
	// Helpers  
	//====================================================;
	
	function __printSuccess(success:Bool)
	{
		if (success) {
			t.printf('~green~[OK]~!~');
		}else {
			t.printf('~red~[FAIL]~!~');	
		}
	}//---------------------------------------------------;
	
	// -- UNUSED --
	function __printStyled(str:String,bgColor:String)
	{
		t.printf('~bg_$bgColor~~white~[$str]~!~');
	}//---------------------------------------------------;
	

	// --
	// Checks if waiting is off,
	// counters if it's true
	// Completely ignore any calls on RELEASE
	#if (!debug) inline #end function __checkWaitStatus()
	{
		#if debug
		if (_waitResult) {
			LOG.log("Should not print a new line while waiting result", 2);
			t.restorePos();
			__printStyled("aborted", "darkred");
			t.endl();
			_waitResult = false;
		}
		#end
	}//---------------------------------------------------;
}// --