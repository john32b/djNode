package djNode.utils;
import js.node.ChildProcess;

/**
 * Various Process Utilities
 */
class ProcUtil 
{

	
	/**
	   Return an array with all PID occurrences of an executable.
	   You can also use this to check if a program is running
	   @param	exe Single executable name. Case Insensitive e.g. "notepad.exe". 
	   @return
	**/
	public static function getTaskPIDs(exe:String):Array<String>
	{
		var PIDS:Array<String> = [];
		
		try{
			var pres:String = ChildProcess.execSync("tasklist");
			var lines:Array<String> = pres.toString().split('\n');
			var reg = ~/(\S+)\s*(\d+)/ig;
			for (l in lines) {
				if (reg.match(l)) {
					if (reg.matched(1).toLowerCase() == exe.toLowerCase())
						PIDS.push(reg.matched(2));
				}
			}
			
		}catch (e:Dynamic) {
			trace(e);
		}
		
		return PIDS;
	}//---------------------------------------------------;
	
	/**
	   Kills task with target PID
	**/
	public static function killPID(?pid:String, ?pidList:Array<String>, force:Bool = false, children:Bool = false)
	{
		/**
			Taskkill quick notes:
			/F  = force 
			/T  = subchilren
			/PID x = pid
		**/
		var com = "TASKKILL ";
		if (pid != null) pidList = [pid];
		for (i in pidList) com += '/PID $i ';
		if (force) pid += '/F ';
		if (children) pid += '/T ';
		ChildProcess.execSync(com);
	}//---------------------------------------------------;
	
	/** 
	   Kill a task by it's name
	   e.g. killTask("firefox.exe");
	 **/
	public static function killTask(taskName:String, force:Bool = false)
	{
		try{
			var com = 'TASKKILL $taskName';
			if (force) com += ' /F';
			ChildProcess.execSync(com);
		}catch (e:Dynamic) {
			trace(e);
		}
	}//---------------------------------------------------;
	
}