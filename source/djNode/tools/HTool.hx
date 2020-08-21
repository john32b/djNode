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
	   Get filename and line of last thrown error
	   !! NEEDS `jstack` haxelib to work
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
		sCall(onComplete,parameter) == gets converted==>
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
	
	macro public static function inRange(cb:Expr, a:Int, b:Int)
	{
		return macro {
			if ($cb < $v{a}) $cb = $v{a} else if ($cb > $v{b}) $cb = $v{b};
		};
	}//---------------------------------------------------;
	
}// --