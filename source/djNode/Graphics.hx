/**
 * Terminal Graphics
 * ---------------
 * 
 * - Draws simple graphics on the terminal
 * - Boxes, Lines, Borders
 * 
**/

package djNode;

import djNode.Terminal;


class Graphics
{
	static var _isInited(default,null):Bool = false;
		
	// This class creates a terminal object
	public static var t:Terminal = null;
	
	// Default Colors
	public static var colorBG:Color = Color.black;
	public static var colorFG:Color = Color.white;

	// Border Decorations
	public static var borderStyles:Array<Dynamic>;	// Set on init();
	
	// Terminal max width and height in characters
	public static var MAX_WIDTH(default, null):Int;
	public static var MAX_HEIGHT(default, null):Int;
	
	// -- General purpose helper vars
	static var _s1:String;
	static var _s2:String;
	static var _s3:String;
	static var _r1:Int;
	
	//====================================================;
	// FUNCTIONS 
	//====================================================;
	
	/**
	 * Graphics.hx requires a one time initialization.
	 */
	public static function init():Void
	{
		if (_isInited) return;
		
		// Create a pointer
		t = BaseApp.TERMINAL;
		
		//-- set the border styles here
		borderStyles = new Array();
		borderStyles[1] = 			// style (1) normal border
		{ 	up:  ["╔","═","╗"],
			down:["╚","═","╝"],
			side:["║","║"]
		};
		borderStyles[2] =  			// style (2) thin border
		{ 	up:  ["┌","─","┐"],
			down:["└","─","┘"],
			side:["│","│"]
		};
		
		MAX_WIDTH  = t.getWidth();
		MAX_HEIGHT = t.getHeight();
		
		_isInited = true;
	}//---------------------------------------------------;
	
	/** 
	 * Draws a solid block
	 * @note: Does not reset after drawing. Do that manually calling Terminal.reset();
	 * @param fillString: Default " "(blank), you can fill a box with whatever string you want
	 */ 
	public static function drawRect(x:Int, y:Int, width:Int, height:Int,?color:Color,?fillString:String):Void
	{
		t.reset();
		
		if (fillString == null) fillString = " ";
		if (color == null) color = colorBG;
		
		var s:String = StringTools.lpad("", fillString, width);
			
		t.bg(color);
			
		for (ff in y...y + height) {
			t.move(x, ff);
			t.print(s);
		}
		
	}//---------------------------------------------------;
	
	
	// Simple rects overlap function,
	// from my old actionscript lib.
	public static function rectsOverlap(ax:Int, ay:Int, aw:Int, ah:Int,
										bx:Int, by:Int, bw:Int, bh:Int):Bool
	{
		if(ax + aw > bx )
			if(ax < bx + bw)
				if(ay + ah > by)
					if (ay < by + bh)
						return true;

		return false;
	}//---------------------------------------------------;

	/**
	 * 
	 * Draws a border, just the border, does not fill inside.
	 * @note: Does not reset after drawing. Do that manually calling Terminal.reset();
	 * 
	 * @param	x X coordinate origin point
	 * @param	y Y coordinate origin point
	 * @param	width Width of the box
	 * @param	height Height of the box
	 * @param	style Style to use, styles are set here in Graphics.hx [0,1,2]
	 * @param	fg Foreground color to use
	 * @param	bg Background color to use
	 */
	public static function drawBorder(x:Int, y:Int, width:Int, height:Int, ?style:Int, ?fg:Color, ?bg:Color ):Void
	{
		// Always reset first
		t.reset();
			
		if (bg == null) bg = colorBG;
		if (fg == null) fg = colorFG;	
		if (style < 1) style = 1;	//default style
			
			//set the colors
			t.bg(bg).fg(fg);
			
			//draw the top
			t.move(x, y);
			t.print( 	borderStyles[style].up[0] +
						StringTools.lpad("", borderStyles[style].up[1], width - 2) +
						borderStyles[style].up[2] );		
			//draw the body
			var ff = 0;
			while (++ff < height) {
				t.move(x, y + ff);
				t.print(borderStyles[style].side[0]);
				t.forward(width - 2);
				t.print(borderStyles[style].side[1]);	
			}
			
			//draw the bottom
			t.move(x, y + height -1);
			t.print( 	borderStyles[style].down[0] +
						StringTools.lpad("", borderStyles[style].down[1], width - 2) +
						borderStyles[style].down[2] );
						
	}//---------------------------------------------------;
	
	
	/**
	 * Draws an array of strings.
	 * @usage Useful for printing ASCII fonts.
	 */
	public static function drawArray(ar:Array<String>, x:Int, y:Int):Void
	{
		for (i in 0...ar.length)
		{
			t.move(x, y + i);
			t.print(ar[i]);
		}
	}//---------------------------------------------------;
	
	/** 
	 * Draws a simple Progress bar
	 */
	@:deprecated("Use ProgressBar.hx")
	public static function drawProgressBar(x:Int, y:Int, width:Int, percent:Float)
	{
		ProgressBar.draw(x, y, width, percent);
	}//---------------------------------------------------;	

	
	/**
	 * Temporary solution for hiding the cursor,
	 * this just moves it out of the way
	 */
	public static function hideCursor():Void
	{
		// BUG: Window terminal can't actually hide the cursor,
		//		so I move it to the bottom right of the window.
		// t.move(MAX_WIDTH,MAX_HEIGHT-1);
		t.move(1, 1);
	}//---------------------------------------------------;
	
}// -- end class --