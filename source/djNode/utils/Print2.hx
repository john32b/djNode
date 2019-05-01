package djNode.utils;

import djNode.Terminal;
import djNode.tools.StrTool;

/**
 * Extra Print Functions
 * ...
 *  - Set a slot style
 *  - Call e.g. printf("Compressing %1 and %1 on %2",file1,file2,path); // file1,file2=style1, path=style2
 */
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
	public function prints(str:String, A:Array<String>)
	{
		var c:Int = 0;
		var r = ~/\{(-?\d+):?(-?\d+)?\}/g;
		
		str = r.map(str, (r1)->
		{
			var part = A[c++];
			
			if (r1.matched(2) != null) { // Some padding is required. 
				part = StrTool.padString(part, Std.parseInt(r1.matched(2)));
			}
			
			var ind = Std.parseInt(r1.matched(1));
			if (ind < 0) { // Negative Index : no style at all
				return part; 
			}
			
			// Proceed building the final string
			var st = styles[ind];	// Get style of text
			var f = '~${st.fg}~'; 	// Foreground color is ALWAYS SET
			if (st.bg != null) f += '~bg_${st.bg}~';
			if (st.l != null) f += '${st.l}';
			f += part;
			if (st.r != null) f += '${st.r}';
			f += '~!~';
			return T.sprintf(f);
		});
		
		T.printf(g_leftpad  + str);
	}//---------------------------------------------------;

	
}// --