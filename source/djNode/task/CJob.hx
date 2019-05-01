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
		
	@events
		
		'jobStatus'	 : Sends JOB Related status updates
					<CJobStatus, CJob>
					waiting		:	Job hasn't started yet
					complete	:	Job is complete
					start		:	Job has just started
					progress	:	Job progress % updates  (Read job.PROGRESS)
					taskStart	:	A new task just started (Read job.TASK_LAST)
					taskEnd		:	A task just ended		(Read job.TASK_LAST)
					fail		:	Job has failed
					kill		:	The job has been force killed
	
		'taskStatus' : Called whenever a Task Status changes
					<CJobStatus, CTask>
					start	:	The task has just started
					progress:	The task progress has changed
					complete:	The task has been completed
					fail	:	The task has failed, see the ERROR field
					
	@note 
	
	 - Code copied over from C#, CDCRUSH project
	 
**/
		
package djNode.task;

import djNode.task.CTask;
import djNode.tools.HTool;
import djNode.tools.LOG;
import js.Node;
import js.node.Process;
import js.node.events.EventEmitter;
import js.Error;

enum CJobStatus
{
	waiting;	// Job hasn't started yet
	complete;	// Job is complete
	allcomplete;// Job is complete and there are no more Jobs in the queue
	init;		// Job is about to init()
	start;		// Job is about to start()
	fail;		// Job has failed
	progress;	// Job progress has been updated
	taskStart;	// A New task has started
	taskEnd;	// A task has ended
}



class CJob 
{
	
	// -- GLOBAL HANDLERS
	// If these are set, then every time a JOB starts will automatically
	// attach new event handlers to these
	public static var global_job_status:CJobStatus->CJob->Void;
	public static var global_task_status:CTaskStatus->CTask->Void;
	//---------------------------------------------------;
	
	// General Use Job info
	public var info:String;

	// General Use String ID	
	public var sid:String;
	
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
	public var TASKS_TOTAL(default, null):Int;
	
	// Number of completed tasks
	public var TASKS_COMPLETE(default, null):Int;
	
	// Number of tasks currently running
	public var TASKS_RUNNING(default, null):Int;
	
	// The last task, pointer, usen on callbacks
	public var TASK_LAST:CTask;
	
	// Currently active slots for ASYNC tasks.
	var slots_active:Array<Bool>;
	
	// Holds all the tasks that are waiting to be executed
	var taskQueue:Array<CTask>;

	// Next job to run
	var queueNext:CJob;
	
	// Pointers to the current working tasks
	public var currentTasks(default, null):Array<CTask>;

	// Current Job Status
	public var status(default, null):CJobStatus;
	
	// Job Events Object
	// NOTE: events are called from within the Stack, so be careful
	// "jobStatus"  : -> (CJobStatus,CJob)->{} 
	// "taskStatus" : -> (CTaskStatus,CTask)->{} Notifies for any containing tasks
	public var events:IEventEmitter;
	
	// #USERSET
	// NOTE: OnComplete gets called on a clean STACK
	// Called whenever the Job Completes
	public var onComplete:Void->Void = null;
	
	// #USEREST
	// NOTE: OnComplete gets called on a clean STACK
	// Called whenever the Job FAILS
	public var onFail:Void->Void = null;
	
	// If the job has failed, this holds the ERROR code, copied from task ERROR code
	public var ERROR(default, null):String;

	// Keep track of whether the job is done and properly shutdown
	var IS_KILLED:Bool = false;
	
	// Store the progress of the currently ongoing tasks, (using slot index)
	// -1 to indicate no progress, 0-100 for standard progress
	var slots_progress:Array<Int>;

	// Progress % of past completed tasks. ! NOT TOTAL PROGRESS !
	// Used to save a calculation, same as (COMPLETED_TASKS * (TASKS_P_RATIO * 100))
	var TASKS_P_PRECALC:Float;
	
	// How much a task will contribute to the job progress %
	// Can be #USERSET, if you want to hack it. Else it is autocalculated
	var TASKS_P_RATIO:Float;
	
	// Number of tasks that report progress
	public var TASKS_P_TOTAL(default, null):Int;		// Prefer this over TASKS_TOTAL
	
	// Number of completed tasks that report progress 
	public var TASKS_P_COMPLETE(default, null):Int;		// Prefer this over TASKS_COMPLETE
	
	// This is the REAL progress %
	// Percentage of tasks completed
	public var PROGRESS_TOTAL(default, null):Float;
	
	//====================================================;
	
	public function new(?Sid:String,?TaskData:Dynamic) 
	{
		taskQueue = [];
		currentTasks = [];
		taskData = TaskData;
		sid = Sid == null?"Job:" + Date.now().toString():Sid;
		status = CJobStatus.waiting;
		TASKS_RUNNING = 0; TASKS_COMPLETE = 0; TASKS_TOTAL = 0; PROGRESS_TOTAL = 0;
		TASKS_P_PRECALC = 0; TASKS_P_TOTAL = 0; TASKS_P_COMPLETE = 0; TASKS_P_RATIO = 0;
		events = new EventEmitter();
	}//---------------------------------------------------;
	
	/**
	 * Task initialization after adding in to the queue
	 */
	function addT(t:CTask):CJob
	{
		TASKS_TOTAL++;
		
		if (!t.FLAG_PROGRESS_DISABLE)
		{
			TASKS_P_TOTAL ++;
			
			TASKS_P_RATIO = 1 / TASKS_P_TOTAL; 
			
			if (status == CJobStatus.start) // The Job is currently running
			{
				// recalculate past tasks
				TASKS_P_PRECALC = TASKS_P_RATIO * 100 * TASKS_P_COMPLETE;
				calculateProgress();
			}
			
		}
		
		return this;
	}//---------------------------------------------------;
	
	// Add a task
	public function add(t:CTask):CJob
	{
		taskQueue.push(t); return addT(t);
	}//---------------------------------------------------;
	// Add a task to the top of the queue
	public function addNext(t:CTask):CJob
	{
		taskQueue.unshift(t); return addT(t);
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
	// Add a quicktask. Same as add(new CTask(...));
	public function addQ(?n:String, fn:CTask->Void):CJob
	{
		return add(new CTask(n, fn));
	}//---------------------------------------------------;
	public function addQA(?n:String, fn:CTask->Void):CJob
	{
		return addAsync(new CTask(n, fn));
	}//---------------------------------------------------;
	
	// # USER CODE
	// Override this and put initialization code
	// ~ All Throws will be caught and handled ~
	public function init()
	{		
	}//---------------------------------------------------;
	
	// Starts the JOB
	// THIS IS ASYNC and will return execution to the caller right away'
	// Use the onStatus and onComplete callbacks to get updates
	public function start():CJob
	{
		if (status != CJobStatus.waiting) {
			throw "A CJob object can only run once";
		}
		
		if (global_job_status != null){
			events.on('jobStatus', global_job_status);
		}
		if (global_task_status != null){
			events.on('taskStatus', global_task_status);
		}
		
		// + Send start signal before init();
		LOG.log('JOB INIT : $this');
		status = CJobStatus.init;
		events.emit("jobStatus", status, this);
		
		try{
			init();
		}catch (e:Error){
			return fail(e.message);
		}catch (e:String){
			return fail(e);
		}
		
		if (taskQueue.length == 0){
			return fail("No Tasks to run");
		}
		
		if (TASKS_P_RATIO == 0) // No tracks report progress
		{
			LOG.log("No tracks reporting progress !!!", 2);
			LOG.log("Progress WILL BE BROKEN", 2);
		}
		
		// Fill in the slot array 
		slots_active = [for (i in 0...MAX_CONCURRENT) false];
		slots_progress = [for (i in 0...MAX_CONCURRENT) -1];
		
		// + Send start signal before init();
		LOG.log('JOB START : $this');
		status = CJobStatus.start;
		events.emit("jobStatus", status, this);
		
		feedQueue();
		
		return this;
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
				LOG.log('JOB COMPLETE : $this');
				status = CJobStatus.complete;
				events.emit("jobStatus", status, this);
				if (queueNext == null) {
					events.emit("jobStatus", CJobStatus.allcomplete, this);
				}
				kill();
				Node.process.nextTick(()->{
					HTool.sCall(onComplete);
					if (queueNext != null) {
						queueNext.start();
					}	
				});
			}
		}
		
	}//---------------------------------------------------;
	
	// Force - Starts the next task on the queue
	// PRE : taskQueue.Count > 0 ; Checked earlier
	function startNextTask()
	{
		var t:CTask;
		
		t = taskQueue.shift();	// Gets the first element
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
		TASKS_RUNNING ++;
		
		LOG.log('Task Start : ${t} | $this | Remaining (${taskQueue.length}), Running (${currentTasks.length})');

		try{
			t.start();
		}catch (e:Error){
			t.fail(e.message);
		}catch (e:String){
			t.fail(e);
		}
	}//---------------------------------------------------;
	
	// End a task properly
	// Task has either Completed or Failed
	function killTask(t:CTask)
	{
		TASKS_RUNNING --;
		slots_active[t.SLOT] = false;
		slots_progress[t.SLOT] = -1;
		if(!t.FLAG_PROGRESS_DISABLE) TASKS_P_PRECALC += TASKS_P_RATIO * 100;
		currentTasks.remove(t);
		t.kill();
	}//---------------------------------------------------;
	
	// --
	// Calculate the Total Progress
	function calculateProgress()
	{
		// Completed Progress + Current Progress
		PROGRESS_TOTAL = TASKS_P_PRECALC;
		for (i in 0...MAX_CONCURRENT)
		{
			if (slots_active[i]) PROGRESS_TOTAL += slots_progress[i] * TASKS_P_RATIO;
		}
	}//---------------------------------------------------;
	
	//-- Internal task status handler
	function _onTaskStatus(s:CTaskStatus, t:CTask)
	{
		// Pass this through
		events.emit("taskStatus", s, t);

		switch(s)
		{
			case CTaskStatus.complete:
				LOG.log('Task Complete : ' + t.toString());
				taskData = t.dataSend;
				TASKS_COMPLETE++;
				if (!t.FLAG_PROGRESS_DISABLE) TASKS_P_COMPLETE ++;
				TASK_LAST = t;
				events.emit("jobStatus", CJobStatus.taskEnd, this);
				killTask(t);
				
				// NEW : Avoid filling up the callstack
				Node.process.nextTick(feedQueue);

			// TODO: I could report the progress on a timer
			//		 This is not ideal if there are many tasks running at once (CPU wise)
			// NOTE: Will not get called from FLAG_NO_PROGRESS tasks				
			case CTaskStatus.progress:
				TASK_LAST = t;
				slots_progress[t.SLOT] = t.PROGRESS;
				calculateProgress();
				events.emit("jobStatus", CJobStatus.progress, this);
			// --
			case CTaskStatus.fail:
				LOG.log('Task Fail : $t', 3);
				killTask(t);
				fail(t.ERROR);
				
			// --
			case CTaskStatus.start:
				TASK_LAST = t;
				events.emit("jobStatus", CJobStatus.taskStart, this);
				
			default:
		}// --
		
	}//---------------------------------------------------;
	
	// Force fail the JOB and cancel all remaining tasks, or this is called when a Task Fails
	function fail(msg:String = ""):CJob
	{
		ERROR = msg;
		LOG.log('JOB FAIL : $this');
		LOG.log('         : ' + ERROR + "@" + HTool.getExStackThrownInfo());
		
		status = CJobStatus.fail;
		events.emit("jobStatus", status, this);
		
		kill();
		
		// This could be still on a Task Stack
		Node.process.nextTick(()->{
			HTool.sCall(onFail);
		});
		
		return this;
	}//---------------------------------------------------;
	
	// Cleanup code, called on FAIL and COMPLETE
	// Also Can be called from user on program force exit to do cleanups
	public function kill()
	{
		if (IS_KILLED) return; IS_KILLED = true;
		
		events.removeAllListeners();
		
		// Clear any running task
		for (i in currentTasks) i.kill();
		
		// Clear any waiting task (just in case)
		for (i in taskQueue) i.kill();
		
		LOG.log('JOB KILLED : $this');
	}//---------------------------------------------------;
	
	
	public function toString():String
	{
		return 'JOB [$sid] ' + (info != null?info:'');
	}//---------------------------------------------------;
	
	/**
	   Queue a Job to run when this one completes successfully
	**/
	public function then(j:CJob):CJob
	{
		queueNext = j;
		return j;
	}//---------------------------------------------------;
	
}// --