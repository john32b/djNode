/**----------------------------------------------
 * - Terminal.hx
 * ----------------------------------------------
 * - Useful Terminal functionality wrapper
 * ----------------------------------------------
 * @Author: johndimi, <johndimi@outlook.com>
 * 
 * Features:
 * ===========
 * . Printing text
 * . Text and Background Colors
 * . Easy Formatted Text with custom Tags
 * . Manipulating the cursor
 * . Colors in Windows and Linux terminals,
 * . Clearing portions of the terminal
 * 
 * Notes:
 * ============
 * 	References: http://tldp.org/HOWTO/Bash-Prompt-HOWTO/
 * 				http://ascii-table.com/ansi-escape-sequences.php
 *  			http://www.termsys.demon.co.uk/vtansi.htm
 *  			http://misc.flogisoft.com/bash/tip_colors_and_formatting
 * 				http://pueblo.sourceforge.net/doc/manual/ansi_color_codes.html
 * 				https://en.wikipedia.org/wiki/ANSI_escape_code  <--
 * 				https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences <<-- Windows
 *
 * 
 * 	Cursor Position :
 * 
 * 		Pos (x:1,y:1) starts NOT from the top left of the terminal window, 
 * 		but rather the next line of the prompt.
 * 		To GUARANTEE a (1,1) position pageDown() first.
 * 
 * 
 * Examples :
 * ================
 *   
 * 	= Tags in Strings for inline coloring : 
 *    e.g. printf("~red~Color Red~:white~White BG~!~");
 * 		   is the equivalent of:
 * 	       fg(Color.red).print("Color Red").bg(Color.white).print("White BG").reset();
 * 
 ========================================================*/
package djNode;

import StringTools;

#if debug
  import djNode.tools.LOG;
#end

#if cs 
  import cs.system.Console;
  import cs.system.ConsoleColor;
#elseif js
  import js.Node;
#elseif cpp
  import cpp.Lib;
#elseif neko
  import neko.Lib;
#end


/*
 * Supported Terminal colors
 **/
@:enum
abstract Color(String) from String to String
{
	var black = "black";	var white = "white";
	var gray = "gray"; 		var darkgray = "darkgray";
	var red = "red"; 		var darkred = "darkred";
	var green = "green"; 	var darkgreen = "darkgreen";
	var blue = "blue"; 		var darkblue = "darkblue";
	var yellow = "yellow"; 	var darkyellow = "darkyellow";
	var cyan = "cyan"; 		var darkcyan = "darkcyan";
	var magenta = "magenta"; var darkmagenta = "darkmagenta";	
}//---------------------------------------------------;

@:dce
class Terminal
{
	
	//====================================================;
	// VARS
	//====================================================;

	// Map colors to escape codes
	var COLORS_FG:Map<Color,String>;
	var COLORS_BG:Map<Color,String>;	
	
	// The escape Sequence can also be '\033[', or even '\e[' in linux ''
	// I am not using the escape sequence as a reference anywhere, as hard typing is faster.
	static inline var ESCAPE_SEQ 	= '\x1B['; 	
	static inline var _BOLD 		= '\x1B[1m';
	static inline var _DIM 			= '\x1B[2m';
	static inline var _UNDERL		= '\x1B[4m';
	static inline var _BLINK 		= '\x1B[5m';
	static inline var _HIDDEN 		= '\x1B[8m';
	
	static inline var _RESET_ALL 	= '\x1B[0m';	// All Attributes off
	static inline var _RESET_FG	 	= '\x1B[39m';	// Foreground to default
	static inline var _RESET_BG 	= '\x1B[49m';	// Background to default
	static inline var _RESET_BOLD 	= '\x1B[21m';
	static inline var _RESET_DIM 	= '\x1B[22m';
	static inline var _RESET_UNDERL	= '\x1B[24m';
	static inline var _RESET_BLINK	= '\x1B[25m';
	static inline var _RESET_HIDDEN	= '\x1B[28m';
	
	// Hold all the available colors.
	static var AVAIL_COLORS:Array<String> = [ 
		Color.black, Color.white, Color.gray, Color.darkgray,
		Color.red, Color.darkred, Color.green, Color.darkgreen,
		Color.blue, Color.darkblue, Color.cyan, Color.darkcyan,
		Color.magenta, Color.darkmagenta, Color.yellow, Color.darkyellow
	];
	
	//---------------------------------------------------;
	// -- User overridable
	//---------------------------------------------------;
	
	// Used in the sprintf() and printLine() , User can modify these.
	public static var DEFAULT_LINE_WIDTH:Int     = 50;
	public static var DEFAULT_LINE_SYMBOL:String = "-";
	
	// Used in H1...3() and list()
	public static var LIST_SYMBOL:String	=	"*";
	public static var H1_SYMBOL:String		=	"#";
	public static var H2_SYMBOL:String		=	"+";
	public static var H3_SYMBOL:String		=	"=";
	
	//====================================================;
	// FUNCTIONS
	//====================================================;
	
	public function new() 
	{
		// Set the foregrounds
		COLORS_FG = [
			Color.darkgray => 	'\x1B[90m',
			Color.red => 		'\x1B[91m',
			Color.green => 		'\x1B[92m',
			Color.yellow => 	'\x1B[93m',
			Color.blue => 		'\x1B[94m',
			Color.magenta => 	'\x1B[95m',
			Color.cyan => 		'\x1B[96m',
			Color.white => 		'\x1B[97m',
			Color.black => 		'\x1B[30m',
			Color.darkred => 	'\x1B[31m',
			Color.darkgreen => 	'\x1B[32m',
			Color.darkyellow => '\x1B[33m',
			Color.darkblue => 	'\x1B[34m',
			Color.darkmagenta=> '\x1B[35m',
			Color.darkcyan => 	'\x1B[36m',
			Color.gray => 		'\x1B[37m'
		];
		
		//- Set the backgrounds
		COLORS_BG = [
			Color.darkgray => 	'\x1B[100m',
			Color.red =>		'\x1B[101m',
			Color.green =>		'\x1B[102m',
			Color.yellow =>		'\x1B[103m',
			Color.blue =>		'\x1B[104m',
			Color.magenta =>	'\x1B[105m',
			Color.cyan =>		'\x1B[106m',
			Color.white => 		'\x1B[107m',
			Color.black =>		'\x1B[40m',
			Color.darkred => 	'\x1B[41m',
			Color.darkgreen =>	'\x1B[42m',
			Color.darkyellow => '\x1B[43m',
			Color.darkblue => 	'\x1B[44m',
			Color.darkmagenta=> '\x1B[45m',
			Color.darkcyan => 	'\x1B[46m',
			Color.gray => 		'\x1B[47m'
		];
	
	}//---------------------------------------------------;
	

	/**
	 * Demo all available colors on the stdout.
	 * WARNING: Will erase the terminal
	 */
	public function demoPrintColors():Void
	{
		var distanceBetweenColumns = 15;
		println("Available Colors").drawLine();
		
		//-- Draw the foreground colors
		for (i in AVAIL_COLORS) {
			if (i == Color.black) bg(Color.gray); else bg(Color.black);
			fg(i).print(i).endl().resetFg();
		}
		
		moveR(0, -AVAIL_COLORS.length);
	
		//-- Draw the background colors:
		for (i in AVAIL_COLORS) {
			forward(distanceBetweenColumns);
			if (i == Color.white || i == Color.yellow) fg(Color.darkgray); else fg(Color.white);
			bg(i).print(i).endl().resetBg();
		}
		
		drawLine();
	}//---------------------------------------------------;
	
	
	/**
	   Resize the Terminal Window,
	   - Not all terminals are resizable
	   - Window default 'cmd' is resizable OK
	   - 
	**/
	public function resizeTerminal(w:Int, h:Int)
	{
		Sys.command('mode con: cols=$w lines=$h');
		// print('\033[8;$h;$w');
	}//---------------------------------------------------;
	
	/**
	   Set the title of the terminal window
	**/
	public function setTitle(s:String)
	{
		Sys.command('title $s');
	}//---------------------------------------------------;
	
	/**
	 * Get Maximum Terminal window width
	 */
	public function getWidth():Int
	{
		#if js
			return untyped(Node.process.stdout.columns);
		#elseif cs
			return Console.WindowWidth;
		#else
			return 80;	//Failsafe default
		#end
	}//---------------------------------------------------;
	
	/**
	 * Get Maximum Terminal window height
	 */	
	public function getHeight():Int
	{
		#if js
			return untyped(Node.process.stdout.rows);
		#elseif cs
			return Console.WindowHeight;
		#else
			return 25; //Failsafe default
		#end
	}//---------------------------------------------------;
	
	/**
	 * Writes to the terminal, unformatted
	 */
	public inline function print(str:String):Terminal
	{
		//Sys.print(str);
		
		#if js
			Node.process.stdout.write(str);
		#elseif cpp
			Lib.print(str);
		#else
			Sys.print(str);
		#end
		
		return this;
	}//---------------------------------------------------;
	
	/**
	 * Writes to the terminal, then changes line, unformatted
	 * todo: Do I really need this?
	 */
	public inline function println(str:String):Terminal
	{
		print(str + "\n");
		return this;
	}//---------------------------------------------------;
	
	/**
	 * Sets the color of the cursor (Foreground color)
	 * @param col, If this is null, the FG is being reset.
	 */
	public function fg(?col:Color):Terminal
	{
		if (col == null) return resetFg();
		return print(COLORS_FG.get(col));
	}//---------------------------------------------------;
	
	/**
	 * Sets the color of the background
	 * @param col, If this is null, the BG is being reset.
	 */
	public function bg(?col:Color):Terminal
	{
		if (col == null) return resetBg();
		return print(COLORS_BG.get(col));
	}//---------------------------------------------------;

	// This is mostly unused.
	public function bold():Terminal
	{
		return print(_BOLD);
	}//---------------------------------------------------;

	//--- Resets ---//
	public inline function resetFg():Terminal	{ return print(_RESET_FG); }
	public inline function resetBg():Terminal 	{ return print(_RESET_BG); }
	public inline function resetBold():Terminal	{ return print(_RESET_BOLD); }
	
	/**
	 * Reset all colors and styles to default.
	 */ 
	public inline function reset():Terminal			
	{ 
		return print(_RESET_ALL);
		//Console.ResetColor();
		//Console.ForegroundColor = ConsoleColor.White;
	}//---------------------------------------------------;
	
	/**
	 * Moves the curson to the next line of the Terminal
	 */
	public inline function endl():Terminal
	{
		return print("\n");
	}//---------------------------------------------------;
	
	
	/** 
	 * Cursor Control Functions 
	 **/
	public inline function up(x:Int = 1):Terminal 		{ return print('\x1B[${x}A'); }
	public inline function down(x:Int = 1):Terminal 	{ return print('\x1B[${x}B'); }
	public inline function forward(x:Int = 1):Terminal  { return print('\x1B[${x}C'); }
	public inline function back(x:Int = 1):Terminal 	{ return print('\x1B[${x}D'); }
	
	//----------------------------------------------------;
	
	/**
	 * Moves the cursor to a specific X and Y position on the Terminal
	 * Starting from (1,1)
	 */
	public function move(x:Int, y:Int):Terminal
	{
		#if js
			untyped(Node.process.stdout.cursorTo(x-1, y-1));
			return this;
		#elseif cs
			Console.SetCursorPosition(x, y);
			return this;
		#else
			return print('\x1B[${y};${x}f');
		#end
	}//---------------------------------------------------;
	
	/**
	   Move Relative to current position
	**/
	public function moveR(x:Int, y:Int):Terminal
	{
		#if js
			untyped(Node.process.stdout.moveCursor(x, y));
		#else
		
			var c = '';
			if (x < 0) c += ESCAPE_SEQ + ( -x) + 'D';
			else if (x > 0) c += ESCAPE_SEQ + ( x ) + 'C';	
			if (y < 0) c += ESCAPE_SEQ + ( -y) + 'A';
			else if (y > 0) c += ESCAPE_SEQ + ( y) + 'B';
			print(c);

		#end
		
		return this;
	}//---------------------------------------------------;
	
	
	/**
	 * Stores the position of the cursor, for later use
	 * with restorePos()
	 * BUG: On Windows CMD, SAVE/RESTORE, does not consider scrolling,
	 * 		meaning, it will restore to the save exact (x,y) of terminal space
	 * 		-Use with caution-, best used on single lines
	 */
	public inline function savePos():Terminal
	{
		return print('\x1B[s');
	}//---------------------------------------------------;

	/**
	 * Restores the cursor to the position it was stored
	 * by savePos()
	 * BUG: On Windows CMD, SAVE/RESTORE, does not consider scrolling,
	 * 		meaning, it will restore to the save exact (x,y) of terminal space
	 * 		-Use with caution-, best used on single lines
	 */
	public inline function restorePos():Terminal
	{
		return print('\x1B[u');
	}//---------------------------------------------------;
	
	/**
	 * Scrolls the Terminal down, it doesn't erase anything.
	 * -- it just scrolls down to window height --
	 */
	public function pageDown(h:Int = 0):Terminal
	{
		if (h == 0) h = getHeight();
		print(StringTools.lpad("", "\n", h));
		return moveR(0, -h);
	}//---------------------------------------------------;

	/**
	 * Clears the next X characters from the current stored cursor rosition
	 * @param num Number of Characters to clear
	 */
	public function clearFromHere(num:Int):Terminal
	{
		savePos().print(StringTools.lpad("", " ", num));
		return restorePos();
	}//---------------------------------------------------;
	
	/**
	 * Clears the line the cursor is at.
	 * - Cursor position does not change !
	 * @param type 	0:Clear all forward
	 * 				1:Clear all back
	 * 				2:Clear entire line (default)
	 */
	public function clearLine(type:Int = 2):Terminal
	{
		//#if js
			// Node.process.stdout.clearLine(			
			// -1 - to the left from cursor
			//  1 - to the right from cursor
			//  0 - the entire line
		//#else
			return print('\x1B[${type}K');
		//#end
	}//---------------------------------------------------;
	
	/**
	 * Clears the screen
	 * @param type 	0:Clear all forward
	 * 				1:Clear all back, 
	 * 				2:Clear entire screen, move cursor to 1,1 (default)
	 */
	public function clearScreen(type:Int = 2):Terminal
	{
		#if js
			if (type > 0) move(1, 1);
			untyped(Node.process.stdout.clearScreenDown());
			return this;
		#elseif cs
			Console.Clear();
			return this;
		#else
			return print('\x1B[${type}J');
		#end
	}//---------------------------------------------------;
	
	//====================================================;
	// STYLING
	//====================================================;
	
	/**
	 * Prints a horizontal line in current place
	 * The line has a default width of 40 chars
	 * NewLine at the end.
	 * @param symbol optional custom symbol
	 * @param length optional custom length
	 */
	public function drawLine(?symbol:String, ?length:Int):Terminal 
	{
		if (symbol == null) symbol = DEFAULT_LINE_SYMBOL;
		if (length == null) length = DEFAULT_LINE_WIDTH;
		return print(StringTools.lpad("", symbol, length)).endl();
	}//---------------------------------------------------;
	
	/**
	 * Write a text with Header 1 formatting
	 * @param text
	 */
	public function H1(text:String, color:String = "darkmagenta")
	{		
		printf('~black~~:$color~ $H1_SYMBOL~white~ $text ~!~\n~line~');
	}//---------------------------------------------------;
	
	/**
	 * Write a text with Header 2 styling
	 * @param text
	 */
	public function H2(text:String, color:String = "cyan")
	{
		printf(' ~:$color~~black~$H2_SYMBOL~!~ ~$color~$text~!~\n ~line2~');
	}//---------------------------------------------------;
	
	/**
	 * Write a text with Header 2 styling
	 * @param text
	 */
	public function H3(text:String, color:String = "blue")
	{
		printf('~$color~ $H3_SYMBOL ~!~$text\n ~line2~');
	}//---------------------------------------------------;
	
	/**
	 * Add a list styled element
	 * @param text The label to add
	 */
	public function list(text:String, color:String = "green")
	{
		printf('~$color~  $LIST_SYMBOL ~!~$text\n');
	}//---------------------------------------------------;
	
	/**
	 * Print formatted text,
	 * Check sprintf() for rules
	 */
	public inline function printf(str:String):Terminal
	{
		return print(sprintf(str));
	}//---------------------------------------------------;
	

	
	public function cursorHide():Terminal
	{
		return print("\x1B[?25l");
	}//---------------------------------------------------;
	public function cursorShow():Terminal
	{
		return print("\x1B[?25h");
	}//---------------------------------------------------;
	
	/**
	 * Translates Special inline Tags to Special terminal codes and strings
	 * Returns the new translated string. Useful to adding color codes.
	 * 
	 * Tags:
	 * 	~!~			; Reset ALL
	 *  ~!.~		; Reset Foreground color
	 *  ~!:~		; Reset background color
	 *  ~line~		; Prints a Line
	 *  ~line2~		; Prints a Line Style 2
	 *  ~b~			; Bold
	 *  ~!b~		; Reset Bold
	 *  ~COLOR~		; where COLOR is a valid COLOR name	; Foreground Color
	 *  ~=COLOR~ 	; where COLOR is a valid COLOR name ; Background Color
	 * 
	 * Examples:
	 * "~yellow~This is yellow. ~red~And this is red~!~"
	 * "~line~\nText\n~line~"
	 * 
	 */
	public function sprintf(str:String):String
	{
		// Match anything between ~ ~
		return(~/~(\S[^~]*)~/g.map(str, function(reg) {
			var s:String = reg.matched(1);
			switch(s) {
			case "!"	: return _RESET_ALL;
			case "!."	: return _RESET_FG;
			case "!:"	: return _RESET_BG;
			case "b"	: return _BOLD;
			case "!b"	: return _RESET_BOLD;
			case "line":  return StringTools.lpad("", DEFAULT_LINE_SYMBOL, DEFAULT_LINE_WIDTH) + "\n";
			case "line2": return StringTools.lpad("", DEFAULT_LINE_SYMBOL, Math.ceil(DEFAULT_LINE_WIDTH / 2)) + "\n";
			
			// Proceed checking for colors or bg colors:
			default :
			try{
			 if (s.charAt(0) == ":")
				return COLORS_BG.get(s.substr(1));
			 else 
				return COLORS_FG.get(s);
			 }catch (e:Dynamic) {
				// Error getting the color, user must have typoed.
				return "";
				#if debug
				LOG.log("Parse error, check for typos, str=" + str, 2);
				#end
			 }
			}//end switch
		}));
	}//---------------------------------------------------;
	

}//-- end class--//