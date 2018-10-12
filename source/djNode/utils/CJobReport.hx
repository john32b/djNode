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
import djNode.task.CTask;
import js.Node;

class CJobReport 
{

	// Don't update the main job progress too often, if multiple tasks
	// are reporting progress at once. Limit to this time minimum.
	public static var UPDATE_MIN_TIME:Float = 0.16;
	// Bullets/Identifiers before writing job or task progress
	public static var PREFIX_HED = '~green~ +~!fg~ ';
	public static var PREFIX_ONE = '~cyan~==~!fg~ ';
	public static var PREFIX_TWO = '~cyan~ >~!fg~ ';
	public static var PROGRESS_BAR_LEN = 32;
	public static var PROGRESS_BAR_COL = "darkgreen";
	
	// Pointer to the job
	var job:CJob;
	
	// Pointer to a terminal
	var T:Terminal;
	
	// Print individual task progress
	var flag_multiple_progress:Bool;
	
	// Print predefined Headers and Footers
	var flag_pre_post_infos:Bool;
	
	// Time the main progress was last updated
	var timeLastProgUpdate:Float;
	
	// Store individual task X screen coordinates
	var slotCursorJump:Array<Int>;
	
	// How much to the right since progress printed
	var jobCursorJump:Int;
	
	/**
	   
	   @param	j the job to report progress from
	   @param	MULTIPLE_PROGRESS True to display individual task progress
	   @param	PRINT_PRE_POST	  True to display JobName/Desc at the top and Completion Messages
	**/
	public function new(j:CJob, MULTIPLE_PROGRESS:Bool = false, PRINT_PRE_POST:Bool = false)
	{
		T = BaseApp.TERMINAL;
		job = j;
		j.events.on("jobStatus", onJobStatus);
		flag_multiple_progress = MULTIPLE_PROGRESS;
		flag_pre_post_infos = PRINT_PRE_POST;
		
		if (j.MAX_CONCURRENT == 1 && flag_multiple_progress)
		{
			// No need if the job can only do 1 job at a time
			flag_multiple_progress = false;
		}
		
		slotCursorJump = [];
		
		// In case the job is running, call the initializer now.
		if (j.status != CJobStatus.waiting)
		{
			onJobStatus(CJobStatus.start, j);
		}
	}//---------------------------------------------------;
	
	// User code for before starting
	// Useful to printing more specific details
	dynamic public function onStart(j:CJob) {}
	
	// User code for after ending
	// Useful to printing more specific details
	dynamic public function onComplete(j:CJob, success:Bool) {}
	
	// -
	function onJobStatus(status:CJobStatus, j:CJob)
	{
		switch(status)
		{
			default:
				
			case CJobStatus.start:
				
				if (flag_pre_post_infos)
				{
					T.reset();
					T.printf(PREFIX_HED + j.name).endl();
				}
				onStart(j); // User code or nothing
				timeLastProgUpdate = 0;
				T.cursorHide();
				T.savePos();
				printSynopticInit();
								

			case CJobStatus.complete:
				doCompleteJob(true);

			case CJobStatus.fail:
				doCompleteJob(false);
				
			case CJobStatus.forceKill:
				doCompleteJob(false, true);	// User Exit ?
				
				
			case CJobStatus.progress:
				
				// Task Detailed --
				if (flag_multiple_progress) 
				{
					gotoTaskLine(j.TASK_LAST);	
					T.forward(slotCursorJump[j.TASK_LAST.SLOT]); // <-- SKIP ALREADY PRINTED TEXT
					printPercent(j.TASK_LAST.PROGRESS);
				}
				
				// Job Synoptic Progress --
				// Limit updates to a min time :
				var tim:Float = Node.process.uptime();
				if (tim - timeLastProgUpdate < UPDATE_MIN_TIME) return; 
				timeLastProgUpdate = tim;
				printSynopticProgress();
				
			case CJobStatus.taskStart:
				
				var t = j.TASK_LAST;
				if (t.FLAG_PROGRESS_DISABLE) return;
				var strname:String = (t.desc == null) ? t.name : t.desc;
					
				if (flag_multiple_progress)
				{
					gotoTaskLine(t);
					// First permanent line of a TASK DETAILED
					T.printf(PREFIX_TWO + strname + ' ~darkgray~..~!fg~'); // <-- TASK PROGRESS FORMATTING
					slotCursorJump[t.SLOT] = 7 + strname.length;
					return;
				}
		
				// Just print the Task Name/Desc on the THIRD line
				// First two are JOB Progress
				T.restorePos().down(2).clearLine();
				T.printf(PREFIX_TWO + strname).resetFg();
				
			case CJobStatus.taskEnd:

					timeLastProgUpdate = 0;
					printSynopticProgress(); // update tasks completed
					
					if (flag_multiple_progress) {
						gotoTaskLine(j.TASK_LAST);
						T.clearLine();
					}

		}// end switch
		
	}//---------------------------------------------------;
	
	
	// JOB Progress Formatting
	function printSynopticInit()
	{
		T.endl().endl(); // Reserve two lines just in case
		T.up(2);
		T.printf(PREFIX_ONE + 'Tasks Completed :\n');
		T.printf(PREFIX_ONE + 'Total Progress  :\n');
		jobCursorJump = 21; // manual number
		
		/* example:
						    .< this is 20, cursor will resume from here
		== Tasks Completed : 4 / 10
		== Total Progress  : [################------------] [80.7%]
		
		*/
		
	}//---------------------------------------------------;
	
	/**
	   Print Job Total Progress
	**/
	function printSynopticProgress()
	{
		// Tasks Completed ::
		T.restorePos().forward(jobCursorJump);
		T.printf('~yellow~${job.TASKS_P_COMPLETE}/${job.TASKS_P_TOTAL}'); 
		
		// Progress Bar and Percent ::
		T.restorePos().down().forward(jobCursorJump);
		T.fg(PROGRESS_BAR_COL);
		ProgressBar.print(PROGRESS_BAR_LEN, Std.int(job.PROGRESS_TOTAL));
		T.resetFg();
		printPercent(job.PROGRESS_TOTAL,true);
	}//---------------------------------------------------;
	
	// Place cursor at the proper task progress line
	function gotoTaskLine(t:CTask)
	{
		T.restorePos().down().down();
		for (i in 0...t.SLOT) T.down();
	}//---------------------------------------------------;
	
	
	// Helper, prints progress percent
	function printPercent(p:Float,float:Bool = false)
	{
		T.print('[').fg('yellow');
		if (float){
			T.print(Std.string(Math.round(p * 10) / 10));
		}else{
			T.print(Std.string(p));
		}
		T.print('%').resetFg().print(']   '); // extra spaces to ensure it overwrites 
	}//---------------------------------------------------;
		
	
	// Print ending info and reset cursors etc
	function doCompleteJob(success:Bool,aborted:Bool = false)
	{
		T.cursorShow();
		T.restorePos();
		T.clearScreen(0);
		
		if (flag_pre_post_infos)
		{
			if(success)
				T.fg('green').println(" Complete");
			else
				T.fg('red').println(aborted?" Aborted":" Failed");
		}
		
		T.resetFg();
		onComplete(job, success);
	}//---------------------------------------------------;
	
}// --