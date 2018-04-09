package djNode.tools;

/**
 * Various Helper Math Functions
 * ...
 * @singleton
 */

class MathTool
{
	/**
	 * Return a random number which is in between a range
	 * 
	 * @param	from Minimum
	 * @param	to Maximum
	 */
	public static inline function randomRange(from:Int, to:Int):Int
	{
		return Math.ceil(Math.random() * (to - from)) + from;
	}//---------------------------------------------------;
	
}//-- end class --//