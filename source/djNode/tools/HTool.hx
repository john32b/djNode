/**
   Generic Small Haxe Tools
   -----------
   - Combatible with all targets
   
**/


package djNode.tools;
import haxe.macro.Expr;
import haxe.macro.Context;

@:dce
class HTool
{

	/**
	 * <IN PLACE> Copy an object's fields into target object. Overwrites the target object's fields. 
	 * Can work with Static Classes as well (as destination)
	 * @param	node The Master object to copy fields from
	 * @param	into The Target object to copy fields to
	 * @return	The resulting object
	 */
	public static function copyFields(from:Dynamic, into:Dynamic):Dynamic
	{
		if (from == null)
		{
			// trace("Warning: No fields to copy from source, returning destination object");
			return into;
		}
		
		if (into == null) 
		{
			trace("Warning: No fields on the target, copying source object");
			into = Reflect.copy(from);
		}else
		{
			for (f in Reflect.fields(from)) {
				if (Reflect.field(from, f) != null)
					Reflect.setField(into, f, Reflect.field(from, f));
			}
		}
		
		return into;
	}//---------------------------------------------------;
	
	//--
	public static function isEmpty(str:String):Bool
	{
		return (str==null || str.length==0);
	}//---------------------------------------------------;
	
	// --
	public static function randAr<T>(ar:Array<T>):T
	{
		return ar[Std.random(ar.length)];
	}//---------------------------------------------------;
		
	/**
	   Get filename and line of last thrown error
	**/
	public static function getExStackThrownInfo()
	{
		var str = "";
		var a = haxe.CallStack.toString(haxe.CallStack.exceptionStack());
		var r = ~/.*\/(.+) line (\d+)/;
		if (r.match(a.split('\n')[1])) str = r.matched(1) + ":" + r.matched(2);
		return str;
	}//---------------------------------------------------;
	
	/**
	   SafeCall
	   Adds a null check to a function call
	   e.g.
		sCall(onComplete,parameter) ==gets converted==>
		if(onComplete!=null) onComplete(parameter);
	**/
	macro public static function sCall(cb:Expr,ar:Array<Expr>)
	{
		var e:Expr = {
			expr:ECall(cb, ar),
			pos:Context.currentPos()
		};
		
		return macro { if ($cb != null) $e; };
	}//---------------------------------------------------;
	
	/**
	   Adds a null check to a function, and calls it from a Timer,
	   So it will hop out of the current call stack
	**/
	macro public static function tCall(cb:Expr,ar:Array<Expr>)
	{
		var e:Expr = {
			expr:ECall(cb, ar),
			pos:Context.currentPos()
		};
		
		return macro { if ($cb != null) haxe.Timer.delay(()->$e, 1); };
	}//---------------------------------------------------;
	
	
}// --