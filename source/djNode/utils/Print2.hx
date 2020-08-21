/********************************************************************
 * Extra Print Functions
 * 
 * - Basic Tables
 * - Basic Header and Text 
 * 
 * 
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
	var T:Terminal;
	
	// Global Print Padding for (table,p,list)
	// Setting a header sets this, or you can set this manually
	public var lpad:Int = 0;
	
	// templ, pad0, pad1,
	// line:null or "len:color"
	public var H_STYLES = [
		{
			templ:'<cyan>>> <bold,white,:darkblue> {1} <!>',
			pad0:1, // Start from this much pad from root pad
			pad1:4,  // At newline, set this much padding
			line:'1:cyan'
		},
		{
			templ:'<:blue,black> > <!> <blue>{1}<!>',
			pad0:4,
			pad1:7,
			line:null
		}
	];
	
	
	var styles:Array<Dynamic>;
	
	//---------------------------------------------------;
	
	public function new() 
	{
		T = BaseApp.TERMINAL;
		styles = [];
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
	 * Print Normal Text
	 * !Assumes cursor at newline
	 * @param	text
	 * @return
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
	 * Print a Parsed Template using current 
	 */
	public function ptem(tem:String, t1:String, ?t2:String, ?t3:String)
	{
		p(parseTempl(tem, t1, t2, t3));
	}//---------------------------------------------------;
	
	
	/**
	 * Parse a Template String. A template string is a string with {1}, {2}, {3} tags
	 * It replaces these tags with the String Arguments
	 * Only up to 3 Slots are supported. No more.
	 * The {1} parameter is mandatory, 2,3 optional
	 * e.g. parseTempl("Status:{1}, Time:{2}", "active", "11:22") ==> "Status:active, Time:11:22"
	 * @param	tem Template Guide
	 * @param	t1 Text to put at {1}
	 * @param	t2 Optional text to put at {2}
	 * @param	t3 Optional text to put at {3}
	 */
	public function parseTempl(tem:String, t1:String, ?t2:String, ?t3:String):String
	{
		var r = ~/\{(-?\d+):?(-?\d+)?\}/g;
		return r.map(tem, (r1)->
		{
			var m = r.matched(1);
			var part = switch (Std.parseInt(m)) {
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
	/**
	   Create a style
	   @param	no Index from 0+
	   @param	fg Foreground color
	   @param	bg Background color (without the bg_ prefix)
	   @param	left Left Strings e.g. " [ "
	   @param	right Right Strings
	**/
	public function style(no:Int, fg:String, ?bg:String, ?left:String, ?right:String)
	{
		styles[no] = {
			fg:fg,
			bg:bg,
			l:left,
			r:right
		};
	}//---------------------------------------------------;
	
	/**
	   Print Styled Text.
	   - Puts Newline at the end
	   - If string ends with `@n` then NO NEWLINE
	   Make sure you set some styles with style(..);
	   examples:
	      prints( "id:{0}  title:{1:10} | end ", ["001", "Entry name one"] ) =>
			"id:001  title:Entry nam- | end"
		  prints( "id:{0}  title:{1} | {2} ", ["002", "Entry name two", "end"] ) =>
			"id:002  title:Entry name two | end"
		  (-1) negative ID for no styling.
			
	   @param	str Input String. {n} Will use style n , {0:X} will apply padding with X length
	   @param	A Strings here will be printed IN ORDER whenever a {n} occurs
	**/
	//public function print1(str:String, A:Array<String>)
	//{
		/*
		var c:Int = 0;
		var r = ~/\{(-?\d+):?(-?\d+)?\}/g;
		var B:Array<String> = [];

		var nl:Bool = true;
		if (str.substr( -2) == NO_NEWLINE) {
			str = str.substr(0, -2);
			nl = false;
		}

		var _col = r.map(str, (r1)->
		{
			var part = A[c++];
			
			if (r1.matched(2) != null) { // Some padding is required. 
				part = StrT.padString(part, Std.parseInt(r1.matched(2)));
			}
			
			B.push(part);
			
			var ind = Std.parseInt(r1.matched(1));
			if (ind < 0) { // Negative Index : no style at all
				return part; 
			}
			
			// Proceed building the final string
			var st = styles[ind];
			var f = try T.COLORS_FG.get(st.fg) catch (e:Error) {
				trace('print2() : Style Invalid Index [$ind]'); return ":INDEX_ERROR:";
			}
			if (st.bg != null) f += T.COLORS_BG.get(st.bg);
			if (st.l != null) f += '${st.l}';
			f += part;
			if (st.r != null) f += '${st.r}';
			f += Terminal._RESET_ALL;
			return T.sprintf(f);
		});
	
		T.print(g_leftpad  + _col);
		if(nl) T.endl();
		
		var i = 0;
		return r.map(str, r->B[i++]); // Create and return the no color string
		*/
	//}//---------------------------------------------------;

	/**
	    Another markup syntax
		- Puts Newline at the end
		- If string ends with `@n` then NO NEWLINE
		- Styles need to be set
		- Produces and returns the non-colorized string (useful for logging)
		e.g.
		print2('|1|Extracting| File into |2|folder|');
	**/
	public function print2(str:String):String
	{
		var r = ~/\|(\d+\|.+?)\|/g;
		var A:Array<String> = [];
		var nl:Bool = true;
		if (str.substr( -2) == NO_NEWLINE) {
			str = str.substr(0, -2);
			nl = false;
		}
		
		var _col = r.map(str, (r1)-> 
		{
			var ss = r1.matched(1); 
			var _a = ss.indexOf('|');
			var _num = ss.substr(0, _a);
			var _str = ss.substr(_a + 1); 
			A.push(_str);
			var st = styles[Std.parseInt(_num)];
			var _ret = try T.COLORS_FG.get(st.fg) catch (e:Error) {
				trace('print2() : Style Invalid Index [$_num]'); return ":INDEX_ERROR:";
			}
			if (st.bg != null) _ret += T.COLORS_BG.get(st.bg);
			_ret += _str;
			_ret += Terminal._RESET_ALL;

			return _ret;
		});
		
		T.print(_col);
		if(nl) T.endl();
				
		var i = 0;
		return r.map(str, r->A[i++]); // Create and return the no color string
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
	   @param	DATA Align:{L,C,R},Width:Int,?LeftPad:Int | .. same
				e.g. "L,20,2|R,20|C,30,3"
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
				case "R": "right";
				case "C": "center";
				default : "left";
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
	   * If you want colors, do it manually beforehand *
	   @param	text 
	   @param	cell Cell index, starting at 1. Auto = 0 (next available). WARNING will stop at the last one.
	**/
	public function tc(text:String, ind:Int = 0)
	{
		if (_table == null) throw "Table not defined";
		if (ind == 0) ind = _tActiveCell; else ind--;
		if (ind >= _table.length) {
			trace('Table Cell ($_tActiveCell) Overflow, for text ($text)');
			return;
		}
		var d = _table[ind];
		T.back(_table_width + lpad + 1);	// Go back way left, to the start of the parent
		if (lpad > 0) T.forward(lpad);
		if (d.xpos > 0) T.forward(d.xpos); // I need to check because even 0 value will increment 1
		T.print(StrT.padString(text, d.width, d.align));
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