/********************************************************************
 * Extra Print Functions
 * 
 * - Basic Tables
 * - Basic Header and Text 
 * 
 * 
 * 
 * TODO IMPROVEMENTS:
 * ------------------
 * 
 * 	- Make table tc() work with inline tags
 * 
 *******************************************************************/

package djNode.utils;

import djA.StrT;
import djNode.Terminal;
import js.lib.Error;

@:dce
@:access(djNode.Terminal)
class Print2 
{
	public static final NO_NEWLINE = "@n";
	
	// Pointer to the global Terminal Object
	// Public in case you need it?
	public var T(default, null):Terminal;
	
	// Global Print Padding for (table,p,list)
	// Setting a header sets this, or you can set this manually
	public var lpad:Int = 0;
	
	/**
	   USERSET
	   Header styles used in h() function
		.templ:String: The template
		.pad0:Int: Start from this much pad from root pad
		.pad1:Int: After the header, set this much padding
		.line:String: Color of the line, <null> for no line
	*/
	public static var H_STYLES = [
		{
			templ:'<cyan>>> <bold,white,:darkblue> {1} <!>',
			pad0:1, pad1:4, line:null // line:'1:cyan'
		},
		{
			templ:'<:blue,black> > <!> <blue>{1}<!>',
			pad0:4, pad1:7, line:null
		}
	];
	
	/**
	   USERSET
	   Styles uses in the ps() function
	   Replacements can be {1}, {2}, {3}
	**/
	public static var PS_STYLES = [
		'<:green,white>[ {1} ]<!>',
		'<:red,white>[ {1} ]<!>'
	];
	
	//====================================================;
	
	public function new() 
	{
		T = BaseApp.TERMINAL;
	}//---------------------------------------------------;
	
	
	/**
	 * Print Header -- From Predefined Template Source --
	 * Basically the same as pt(), but applies paddings as well
	 * @param	size 0+
	 * @param	text
	 */
	public function H(text:String,size:Int = 0)
	{
		var s = H_STYLES[size];
		lpad = s.pad0;
		ptem(s.templ, text);
		
		if (s.line != null)
		{
			var r = s.line.split(':');
			var l = Std.parseInt(r[0]);
			if (l == 1) {
				l = T.PARSED_NOTAG.length;
			}
			if (l > 0) 
			{
				T.fg(TColor.createByName(r[1]));
				if (lpad > 0) T.forward(lpad);
				T.println(StrT.line(l));
				T.resetFg();
			}
		}
		lpad = s.pad1;
	}//---------------------------------------------------;
	
	/**
	 * Print Normal Text. Supports <tags>
	 * !Assumes cursor at newline
	 */
	public function p(text:String):Print2
	{	
		if (lpad > 0) T.forward(lpad);
		T.ptag(text).endl();
		return this;
	}//---------------------------------------------------;
	
	/**
	 * New Line
	 * @return
	 */
	public function br():Print2
	{
		T.endl(); return this;
	}//---------------------------------------------------;
	
	
	/**
	 * Draw a line
	 * !Assumes cursor at newline
	 * @param	len
	 * @return
	 */
	public function line(len:Int = 40):Print2
	{
		if (lpad > 0) T.forward(lpad);
		T.println(StrT.line(len));
		return this;
	}//---------------------------------------------------;
	
	/**
	    Print Styled - Another markup syntax to print text
		Format: "|index|text| |index2|text| |index2|othertext"
		- You can use predefined styles read from `PS_STYLES` to style text
		- Returns the no-color string (useful for logging)
		- First style is index 0
			e.g.
			print2('|0|Extracting| File into |1|folder|');
	**/
	public function ps(str:String):String
	{
		var r = ~/\|(\d+\|.+?)\|/g;
		var _col = r.map(str, (r1)-> {
			var ss = r1.matched(1); 
			var _a = ss.indexOf('|');
			var _ind = Std.parseInt(ss.substr(0, _a));
			var _str = ss.substr(_a + 1); 
			return parseTempl(PS_STYLES[_ind], _str);
		});
		p(_col);
		return T.PARSED_NOTAG;
	}//---------------------------------------------------;
	
	/**
	 * Print Text through a template. A template string is a string with {1}, {2}, {3} tags
	 * Check parseTempl() for help
	 */
	public function ptem(tem:String, t1:Any, ?t2:Any, ?t3:Any)
	{
		p(parseTempl(tem, t1, t2, t3));
	}//---------------------------------------------------;
	
	
	/**
	 * Parse a Template String. A template string is a string with {1}, {2}, {3} tags
	 * It replaces these tags with the String Arguments
	 * Only up to 3 Slots are supported. No more.
	 * The {1} parameter is mandatory, 2,3 optional
	 * e.g. parseTempl("Status:{1}, Time:{2}", "active", "11:22") ==> "Status:active, Time:11:22"
	 * --
	 * NEW: You can set a Fixed Length with {1:PAD} and it will pad the string
	 * 		Short strings will be padded, long string will be cut.
	 *      e.g parseTempl("Task:{1:20} | Success:{2:2}","Compress","FAIL");
	 * 		  ==>   "Task:Compress            | Success:F~"
	 * @param	tem Template Guide
	 * @param	t1 Text to put at {1}
	 * @param	t2 Optional text to put at {2}
	 * @param	t3 Optional text to put at {3}
	 */
	public function parseTempl(tem:String, t1:Any, ?t2:Any, ?t3:Any):String
	{
		var r = ~/\{(\d+):?(\d+)?\}/g;
		return r.map(tem, (r1)->
		{
			var m = r.matched(1);
			var part:String = switch (Std.parseInt(m)) {
				case 1: t1;
				case 2: t2;
				case 3: t3;
				default : throw "Templates support up to three(3) capture groups";
			}
			if (r1.matched(2) != null) { // Some padding is required. 
				part = djA.StrT.padString(part, Std.parseInt(r1.matched(2)));
			}
			
			return part;
		});
	}//---------------------------------------------------;


		
	
	/********************************************************************
	 * TABLES
	 * ------
	 * - Define column areas and then print text to rows/cells
	 * - Purpose is to quickly align text fields in columns
	 * 
	 * Example:
	 * --------
	 * 	.table('C,10,2|C,20,5');
	 *  .tline();
	 *  .tr(["Column1","Column2"]);
	 *  .tline();
	 *  .tr(['data0','data1']);
	 *  .tc('data0');
	 *  .tc('data1'); .tr();
	 * 
	 *******************************************************************/
	
	// Table Data | {align:String,width:Int,pad:Int,xpos:Int} | xpos from table start x
	var _table:Array<Dynamic> = null;
	// Table Active cell | Starts at 0
	var _tActiveCell:Int;
	// Total table width (pads + widths)
	var _table_width:Int;
	
	/**
	   Initialize a Table | CSV Data
	   >> MAKE SURE to create a table at the start of a line  <<
	   @param	DATA Align:{L,C,R},Width:Int,?LeftPad:Int | .. same | e.g. "L,20,2|R,20|C,30,3"
	**/
	public function table(DATA:String)
	{
		_table = [];
		_tActiveCell = 0; // Active cell 
		var xpos = 0; // For individual cells
		for (c in DATA.split('|')) {
			var D = c.split(',');
				if (D.length == 2) D.push('0'); // Add the default 0 left pad if missing
			var w = Std.parseInt(D[1]);
			var pad = Std.parseInt(D[2]);
			var al = switch(D[0]){
				case "R": "r";
				case "C": "c";
				default : "l";
			};
			_table.push({
				align:al,
				width:w,
				pad:pad,
				xpos:pad + xpos
			});
			xpos += w + pad;
		}
		_table_width = xpos;
		//trace("Declared table", _table,_table_width);
	}//---------------------------------------------------;
	
	/**
	   Put an entire row of data at current row of table
	   * INCREMENTS ROW *
	   * If you want colors, do it manually beforehand *
	   @param	cells If null it will just increment the row
	**/
	public function tr(?cells:Array<String>)
	{
		if (_table == null) throw "Table not defined";
		_tActiveCell = 0;
		if (cells == null) {
			// I want to go to the next line without overwriting anything at the current line
			// OK it can go beyond the table end
			T.forward(_table_width).endl();
			return;
		}
		for (c in cells) tc(c);
		T.endl();
	}//---------------------------------------------------;
	
	/**
	   Write to a <Table Cell>
	   * DOES NOT INCREMENT ROW *
	   * If you want colors, do it manually beforehand, it messes with width-pad *
	   @param	text Text to put
	   @param	cell Cell index, starting at 1. Auto = 0 (next available). WARNING will stop at the last one.
	   @param	charpad Character for rest of spaces in the table cell. Default is blank.
	**/
	public function tc(text:String, ind:Int = 0, charpad:String = " ")
	{
		if (_table == null) throw "Table not defined";
		if (ind == 0) ind = _tActiveCell; else ind--; // (starting at index 1) -1 to get to 0
		if (ind >= _table.length) {
			trace('Table Cell ($_tActiveCell) Overflow, for text ($text)');
			return;
		}
		var d = _table[ind];
		T.back(_table_width + lpad + 1);	// Go back way left, to the start of the parent
		if (lpad > 0) T.forward(lpad);
		if (d.xpos > 0) T.forward(d.xpos); // I need to check because even 0 value will increment 1
		T.print(StrT.padString(text, d.width, d.align.toLowerCase(), charpad));
			_tActiveCell++;
	}//---------------------------------------------------;
	
	/**
	   Draw a decorative line (autowidth to full table)
	   >> Assumes cusrsor ready at new line <<
	**/
	public function tline()
	{
		if (_table == null) throw "Table not defined";
		line(_table_width);
		_tActiveCell = 0;
	}//---------------------------------------------------;
	
}// --