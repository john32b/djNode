/**
   Custom Job
   -----------
   - Manager for a series of custom tasks, handles the execution of tasks
   - Reports progress back to the user
   
   @example
   
	var job = new CJob("Restore");
		job.addAsync(new CTask((t) => {
			....
			t.complete();
		}));
		job.start();
		
		
	@note 
	
	 - Code copied over from C#, CDCRUSH project
		
**/
		
package djNode.task;

import djNode.task.CTask;
import djNode.tools.LOG;
import js.Error;


// CJOB statuses
enum CJobStatus
{
	waiting;	// Job hasn't started yet
	complete;	// Job is complete
	start;		// Job has just started
	fail;		// Job has failed
	progress;	// Job progress has been updated
	taskStart;	// A New task has started
	taskEnd;	// A task has ended
}



class CJob 
{
	// General Use Job name
	public var name(default, null):String;

	// General Use String ID	
	public var sid(default, null):String;
	
	// #USERSET
	// How many parallel tasks to run at a time
	// Set this right after creating the object
	public var MAX_CONCURRENT:Int = 2;
	
	// #USER SET
	// Custom user set data. Can be shared between tasks
	// Useful for storing custom job parameters and such.
	public var jobData:Dynamic;
	
	// Internal pointer to keep track of the data in and out of tasks
	var taskData:Dynamic;

	// Total number of tasks in this job
	public var TASKS_TOTAL(default, null):Int; 		// # USER READ
	// Number of completed tasks
	public var TASKS_COMPLETE(default, null):Int;	// # USER READ
	// Number of tasks currently running
	public var TASKS_RUNNING(default, null):Int; 	// # USER READ

	// The last task, pointer, usen on callbacks
	public var TASK_LAST:CTask;						// # USER READ
	
	// Currently active slots for ASYNC tasks.
	var slots_active:Array<Bool>;
	
	// Holds all the tasks that are waiting to be executed
	var taskQueue:Array<CTask>;

	// Pointers to the current working tasks
	public var currentTasks(default, null):Array<CTask>;

	// Current Job Status
	public var status(default, null):CJobStatus;

	// #USERSET #OPTIONAL
	// Same call as onJobStatus(complete)
	// Called whenever the Job Completes or Fails
	// True : success, False : Error (read the ERROR field)
	// NOTE: Be careful if you set BOTH this and onJobStatus they will both get called
	public var onComplete:Bool->Void = null;

	// #USERSET
	// Sends JOB Related status updates
	// A: Job Status
	//	waiting		:	Job hasn't started yet
	//	complete	:	Job is complete
	//	start		:	Job has just started
	//  progress	:	Job progress % updates  (Read job.PROGRESS)
	//  taskStart	:	A new task just started (Read job.TASK_LAST)
	//  taskEnd		:	A task just ended		(Read job.TASK_LAST)
	//	fail		:	Job has failed
	// B: The CJob itself
	public var onJobStatus:CJobStatus->CJob->Void = function(a, b) {};

	// #USERSET  
	// Called whenever the status changes
	// A, status message :
	//		start	:	The task has just started
	//		progress:	The task progress has changed
	//		complete:	The task has been completed
	//		fail	:	The task has failed, see the ERROR field
	// B, the Task itself
	public var onTaskStatus:CTaskStatus->CTask->Void = function(a, b) {};

	// If the job has failed, this holds the ERROR code, copied from task ERROR code
	public var ERROR(default, null):Error;

	// Keep track of whether the job is done and properly shutdown
	public var IS_KILLED:Bool = false;

	// : NEW :
	
	// How much a task will contribute to the job progress %
	// Can be #USERSET, if you want to hack it. Else it is autocalculated
	var TASK_PROGRESS_RATIO:Float;

	// Store the progress of the currently ongoing tasks, (using slot index)
	// -1 to indicate no progress, 0-100 for standard progress
	var slots_progress:Array<Int>;

	// Progress % of past completed tasks. ! NOT TOTAL PROGRESS !
	var TASKS_COMPLETED_PROGRESS:Float;

	// This is the REAL progress %
	// Percentage of tasks completed
	public var PROGRESS_TOTAL(default, null):Float;
	
	//====================================================;
	
	public function new(?Name:String,?TaskData:Dynamic) 
	{
		taskQueue = [];
		currentTasks = [];
		taskData = TaskData;
		name = Name == null?"Unnamed Job, " + Date.now().toString():Name;
		status = CJobStatus.waiting;
		TASKS_RUNNING = 0; TASKS_COMPLETE = 0; TASKS_TOTAL = 0;
		TASKS_COMPLETED_PROGRESS = 0; PROGRESS_TOTAL = 0;
		TASK_PROGRESS_RATIO = 0;
	}//---------------------------------------------------;

	
	// --
	// Incase a job adds tasks while running. Set this to get proper progress output
	public function hack_setExpectedProgTracks(num:Int)
	{
		TASK_PROGRESS_RATIO = 1.0/num;
	}// -----------------------------------------
	
	// Add a task
	public function add(t:CTask):CJob
	{
		taskQueue.push(t); TASKS_TOTAL++; return this;
	}//---------------------------------------------------;
	// Add a task to the top of the queue
	public function addNext(t:CTask):CJob
	{
		taskQueue.unshift(t); TASKS_TOTAL++; return this;
	}//---------------------------------------------------;
	// Adds a task in the queue that will be executed ASYNC
	public function addAsync(t:CTask):CJob
	{
		t.async = true; return add(t);
	}//---------------------------------------------------;
	// Add a task to the top of the queue
	public function addNextAsync(t:CTask):CJob
	{
		t.async = true; return addNext(t);
	}//---------------------------------------------------;	
	
	// Starts the JOB
	// THIS IS ASYNC and will return execution to the caller right away'
	// Use the onStatus and onComplete callbacks to get updates
	public function start()
	{
		if (status != CJobStatus.waiting) {
			throw "A CJob object can only run once";
		}
		
		if (TASK_PROGRESS_RATIO == 0)
		{
			// num of tasks that report progress
			var tp:Int = 
				taskQueue.filter(function(t:CTask){
					return (t.FLAG_PROGRESS_DISABLE == false);
				}).length;
				
			TASK_PROGRESS_RATIO = 1.0 / tp;
		}
		
		// Fill in the slot array 
		slots_active = [for (i in 0...MAX_CONCURRENT) false];
		slots_progress = [for (i in 0...MAX_CONCURRENT) -1];
		
		LOG.log('Starting Job `$name`');
		status = CJobStatus.start;
		onJobStatus(status, this);
		feedQueue();
		
	}//---------------------------------------------------;
	
	// Scans the task queue and executes them in order
	// also executes multiple at once if they are async.
	function feedQueue()
	{
		// Normally I would want to LOCK here.
		if (taskQueue.length > 0)
		{
			var t = taskQueue[0];
			if (currentTasks.length < MAX_CONCURRENT)
			{
				// if previous was SYNC, and there are 0 running tasks, so ok to run
				// if previous was ASYNC, then this can run in parallel
				if (t.async){
					startNextTask();
					feedQueue();
				}else{
					if (currentTasks.length == 0){
						startNextTask();
					}// else there is a task still running and it will call this again when it ends
				}
			}// else the buffer is full
			
			
		}else{
			// Make sure there are no async tasks waiting to be completed
			if (TASKS_COMPLETE == TASKS_TOTAL)
			{
				// Job Complete
				LOG.log('Job Complete : `$name`');
				kill();
				status = CJobStatus.complete;
				onJobStatus(status, this);
				if (onComplete != null) onComplete(true);
			}

		}
		
	}//---------------------------------------------------;
	
	// Force - Starts the next task on the queue
	// PRE : taskQueue.Count > 0 ; Checked earlier
	function startNextTask()
	{
		var t:CTask;
		
		t = taskQueue.pop();
			t.parent = this;
			t.dataGet = taskData;
			t.onStatus = _onTaskStatus;
			
		currentTasks.push(t);
		
		// Find the next available slot[] index	
		var fr = 0;
		while (fr < slots_active.length) {
			if (slots_active[fr] == false) break;
			fr++;
		}
		slots_active[fr] = true;
		t.SLOT = fr;
		LOG.log('Task Start | ${t} | Remaining:${taskQueue.length} | Running:${currentTasks.length}');

		t.start();
		
	}//---------------------------------------------------;
	
	// End a task properly
	// Task has either Completed or Failed
	function killTask(t:CTask)
	{
		TASKS_RUNNING --;
		slots_active[t.SLOT] = false;
		slots_progress[t.SLOT] = -1;
		if(!t.FLAG_PROGRESS_DISABLE) TASKS_COMPLETED_PROGRESS += TASK_PROGRESS_RATIO * 100;
		currentTasks.remove(t);
		t.kill();
	}//---------------------------------------------------;
	
	// --
	// Calculate the Total Progress
	function calculateProgress()
	{
		// Completed Progress + Current Progress
		PROGRESS_TOTAL = TASKS_COMPLETED_PROGRESS;
		for (i in 0...MAX_CONCURRENT)
		{
			if (slots_active[i]) PROGRESS_TOTAL += slots_progress[i] * TASK_PROGRESS_RATIO;
		}
	}//---------------------------------------------------;
	
	//-- Internal task status handler
	function _onTaskStatus(s:CTaskStatus,t:CTask)
	{
		// Pass this through
		onTaskStatus(s, t);

		switch(s)
		{
			case CTaskStatus.complete:
				LOG.log('Task Completed ' + t.toString());
				taskData = t.dataSend;
				TASKS_COMPLETE++;
				TASK_LAST = t;
				onJobStatus(CJobStatus.taskEnd, this);
				killTask(t);
				feedQueue();

			// TODO: I could report the progress on a timer
			//		 This is not ideal if there are many tasks running at once (CPU wise)
			// NOTE: Will not get called from FLAG_NO_PROGRESS tasks				
			case CTaskStatus.progress:
				slots_progress[t.SLOT] = t.PROGRESS;
				calculateProgress();
				onJobStatus(CJobStatus.progress, this);
				
			// --
			case CTaskStatus.fail:
				LOG.log('ERROR: Task Failed ' + t.toString());
				killTask(t);
				fail(t.ERROR.message);
				
			// --
			case CTaskStatus.start:
				TASK_LAST = t;
				onJobStatus(CJobStatus.taskStart, this);
				
			default:
		}// --
		
	}//---------------------------------------------------;
	
	// Force fail the JOB and cancel all remaining tasks, or this is called when a Task Fails
	function fail(?msg:String)
	{
		ERROR = new Error(msg);
		LOG.log('Job Failed :' + name);
		LOG.log('           :' + ERROR.message);
		
		kill();
		status = CJobStatus.fail;
		onJobStatus(status, this);
		if (onComplete != null) onComplete(false);
		
	}//---------------------------------------------------;
	
	// Cleanup code, called on FAIL and COMPLETE
	function kill()
	{
		if (IS_KILLED) return; IS_KILLED = true;
		
		// Clear any running task
		for (i in currentTasks) i.kill();
		
		// Clear any waiting task (just in case)
		for (i in taskQueue) i.kill();
	}//---------------------------------------------------;
	
}// --