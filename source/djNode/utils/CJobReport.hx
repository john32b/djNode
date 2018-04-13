/**
 * == CJobReport
 * =  Capture a CJob's status and report information on the terminal
 * ------------
 * 
 * - Prints task progress
 * - Erases all output after completion
 * - Currently only shows ONE progress bar for the total job progress
 * 
 * Example :
 * --------------
 * 	
 * 	// Just create this giving it a job in the constructor
 *  // Everything else is automatic
 * 
 * 	var r = new CJobReport(job);
 * 	r.onStart = function(j){ print(j.name + " has started!");}
 *  job.start();
 * 
 * 
 * What it Prints :
 * ----------------
 * 		Tasks 3/4 [########...] [60%]
 * 		TaskNameDescription
 * 
 * when it completes it writes a [complete] or [failed]
 * 
 *------------------------------------------------------*/
package djNode.utils;

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
				
				T.savePos();
				T.endl().endl(); // Reserve two lines just in case
				T.cursorHide();
			
			case CJobStatus.taskStart:
				
				if (j.TASK_LAST.FLAG_PROGRESS_DISABLE)
				{
					return;
				}
				
				var tname:String = 
					j.TASK_LAST.desc == null ?
					j.TASK_LAST.name : j.TASK_LAST.desc;
					
				// Just print the Task Name/Desc on the second line
				// First one is reserved for progress
				T.restorePos().down().clearLine();
				T.printf('~yellow~$tname~!fg~');
			
			case CJobStatus.progress:
				
				T.restorePos().clearLine();
				T.printf('Tasks : ~yellow~ ${j.TASKS_COMPLETE}/${j.TASKS_TOTAL}~!fg~ ');
				ProgressBar.print(20, Std.int(j.PROGRESS_TOTAL));
				T.printf(' [~magenta~${j.PROGRESS_TOTAL}%~!fg~]');
				
			case CJobStatus.complete:
				
				T.cursorShow();
				T.restorePos();
				T.clearScreen(0);
				T.fg('green').print("[Complete]").resetFg().endl();
				onComplete(j, true);
	
			case CJobStatus.fail:
			
				T.cursorShow();
				T.restorePos();
				T.clearScreen(0);
				T.fg('red').print("[Failed]").resetFg().endl();
				onComplete(j, false);
				
			default:
		}
		
	}//---------------------------------------------------;
	
	
}// --