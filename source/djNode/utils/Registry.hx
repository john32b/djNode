package djNode.utils;

import js.node.ChildProcess;

/**
 * Windows Registry Helpers
 * ...
 */
class Registry 
{

	
	public static function getValue(Key:String, Value:String):String
	{
		var res = CLIApp.quickExecS('reg.exe QUERY $Key /v $Value');
		if (res == null) return null;
		res = res.toString();
		var a = res.split('\n')[2];
		
		// e.g. 
		// Path    REG_BINRY    C:\Program Files\7-Zip
		var r = ~/.+\s+REG_\w+\s+(.+)/i;
		if (r.match(a))
		{
			return r.matched(1);
		}
		return null;
	}//---------------------------------------------------;
	
	
	/**
	   Sets a DWORD value to a key,
	   It will force - overwrite if exists
	   @param	Key
	   @param	Value
	   @return  success
	**/
	public static function setValueDWord(Key:String, Value:String, Data:String):Bool
	{
		var res = CLIApp.quickExecS('reg.exe ADD $Key /v $Value /t REG_DWORD /d $Data /f');
		return (res != null);
	}//---------------------------------------------------;
	
	
	
	public static function deleteKey(Key:String):Bool
	{
		var res = CLIApp.quickExecS('reg.exe DELETE $Key /f');
		return (res != null);
	}//---------------------------------------------------;
	
}