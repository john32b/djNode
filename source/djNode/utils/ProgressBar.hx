package djNode.utils;

/**
 * Progress Bar Functions
 * ...
 * @author John Dimi
 */
class ProgressBar 
{
	
	// Helper, Precalculated Color Code string
	static var _cc:String;
	
	// --
	public function new() 
	{
		
	}//---------------------------------------------------;
	
	
	/**
	   Prints a generic progress bar at cursor position
	**/
	public static function print(width:Int,percent:Float)
	{
		var _r1 = Math.ceil( (width / 100) * percent);
		// TODO: Parameterize the symbols for bg and fg ("#","-")
		var _s1 = StringTools.lpad("", " ", _r1);    		// downloaded bytes
		var _s2 = StringTools.rpad("", "-", width - _r1);	// blank 
		// -precalculate the color string, for speed
		if (_cc == null) 
			_cc = t.sprintf('~!~~darkgray~~bg_gray~');
		t.move(x, y).print('$_cc$_s1').resetBg().print(_s2);		
		
	}//---------------------------------------------------;
	
	
	/**
	   Draws a progress bar at X.Y coordinates on the screen
	**/
	public static function draw(x:Int, y:Int, width:Int, percent:Float)
	{
		
	}//---------------------------------------------------;
	
}