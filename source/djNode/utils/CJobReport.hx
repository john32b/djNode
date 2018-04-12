/**
 * == CJobReport
 * =  Capture a CJob's status and report information on the terminal
 * ------------
 * 
 * - Prints task progress
 * - Erases all output after completion
 * 
 * Example :
 * --------------
 * 	
 * 	// Just create this giving it a job in the constructor
 *  // Everything else is automatic
 * 	var r = new CJobReport(job);
 * 	r.onStart = function(j){ print(j.name + " has started!");}
 *  job.start();
 * 
 *------------------------------------------------------*/
package;
import djNode.BaseApp;
import djNode.Terminal;
import djNode.task.CJob;

class CJobReport 
{

	// Pointer to the job
	var job:CJob;
	
	// Pointer to a terminal
	var T:Terminal;
	
	// How many lines since the stored Position it wrote,
	// Need to know this todelete lines
	// var linesPrinted:Int = 1;
	
	// Capture a job
	// printInfo: if True will print Job Info
	public function new(j:CJob) 
	{
		T = BaseApp.TERMINAL;
		j.onJobStatus = statusListener;
	}//---------------------------------------------------;
	
	// User code for before starting
	// Useful to printing more specific details
	dynamic public function onStart(j:CJob) {}
	
	// User code for after ending
	// Useful to printing more specific details
	dynamic public function onComplete(j:CJob, success:Bool) {}
	
	// --
	function statusListener(status:CJobStatus, j:CJob)
	{
		switch(status)
		{
			case CJobStatus.start:
				onStart(j);
				lastTaskname = null;
				
				T.savePos();
				T.endl().endl(); // Reserve two lines just in case
			
			case CJobStatus.taskStart:
				
				if (j.TASK_LAST.FLAG_PROGRESS_DISABLE)
				{
					lastTaskname = null;
				}
				
				var tname:String = 
					j.TASK_LAST.desc == null ?
					j.TASK_LAST.name : j.TASK_LAST.desc;
					
				// Just print the Task Name on the second line
				T.restorePos().down().clearLine();
				T.printf('~yellow~$tname~!fg~');
			
			case CJobStatus.progress:
				
				T.restorePos().clearLine();
				T.printf('Tasks : ~yellow~ ${j.TASKS_COMPLETE} / ${j.TASKS_TOTAL}~!fg~ ');
				T.printf('[ ~magenta~${j.PROGRESS_TOTAL}%~!fg~ ]');
				
			case CJobStatus.complete:
				
				T.restorePos();
				T.clearScreen(0);
				T.fg('green').print("[Complete]").resetFg().endl();
				onComplete(j, true);
	
			case CJobStatus.fail:
			
				T.restorePos();
				T.clearScreen(0);
				T.fg('red').print("[Failed]").resetFg().endl();
				onComplete(j, false);
				
		}
		
	}//---------------------------------------------------;
	
	
		function print_progress
	
}// --