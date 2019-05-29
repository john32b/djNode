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
		var stdo:String = ChildProcess.execSync('reg.exe QUERY $Key /v $Value');
		stdo = stdo.toString();
		var a = stdo.split('\n')[2];
		// e.g. 
		// Path    REG_BINRY    C:\Program Files\7-Zip
		var r = ~/.+\s+REG_\w+\s+(.+)/i;
		if (r.match(a))
		{
			return r.matched(1);
		}
		return null;
	}//---------------------------------------------------;
	
}