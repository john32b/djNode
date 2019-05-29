package djNode.utils;

import djNode.Terminal;
import djNode.tools.StrTool;
import js.Error;

/**
 * Extra Print Functions
 * ...
 *  - Set a slot style
 *  - Call e.g. printf("Compressing %1 and %1 on %2",file1,file2,path); // file1,file2=style1, path=style2
 */
@:dce
@:access(djNode.Terminal)
class Print2 
{
	
	// Pointer to an initialized Terminal Object
	var T:Terminal;
	var styles:Array<Dynamic>;
	
	// Global left pad for all types by this object
	// use setLeftPad() to set
	var g_leftpad:String = "";
	
	public var leftPad(default, set):Int = 0;
	function set_leftPad(v){
		g_leftpad = StringTools.lpad("", " ", v);
		return leftPad = v;
	}
	
	public function new(t:Terminal) 
	{
		T = t;
		styles = [];
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
	   - If string ends with `$$` then NO NEWLINE
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
	public function print1(str:String, A:Array<String>)
	{
		var c:Int = 0;
		var r = ~/\{(-?\d+):?(-?\d+)?\}/g;
		var B:Array<String> = [];

		var _col = r.map(str, (r1)->
		{
			var part = A[c++];
			
			if (r1.matched(2) != null) { // Some padding is required. 
				part = StrTool.padString(part, Std.parseInt(r1.matched(2)));
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
		
		T.print(g_leftpad  + _col + '\n');
		
		var i = 0;
		return r.map(str, r->B[i++]); // Create and return the no color string
	}//---------------------------------------------------;

	/**
	    Another markup syntax
		- Puts Newline at the end
		- If string ends with `$$` then NO NEWLINE
		- Styles need to be set
		- Produces and returns non-colorized string
		e.g.
		print2('|1|Extracting| File into |2|folder|');
	**/
	public function print2(str:String):String
	{
		var r = ~/\|(\d+\|.+?)\|/g;
		var A:Array<String> = [];
		var nl:Bool = true;
		if (str.substr( -2) == "$$") {
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
		
		T.print('$_col\n');
		
		var i = 0;
		return r.map(str, r->A[i++]); // Create and return the no color string
	}//---------------------------------------------------;
	
}// --