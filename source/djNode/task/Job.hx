/**--------------------------------------------------------
 * JOB.hx
 * @author: johndimi, <johndimi@outlook.com> , @jondmt
 * --------------------------------------------------------
 * @Description
 * -------
 * Runs Tasks in sequence.
 * 
 * @Notes
 * ------
 * 
 ========================================================*/
package djNode.task;

import djNode.tools.LOG;
import djNode.task.Task.Qtask;


class Job
{	
	// Job name
	public var name(default, null):String;
	
	// Custom user set data. Can be shared between tasks
	// Useful for storing custom job parameters and such.
	public var sharedData:Dynamic;
	
	// Internal pointer to get and set the task data
	var taskData:Dynamic = null;
	
	// Holds all the subtask creators
	var taskQueue:Array<Task>;
	
	// Current task that is being processed.
	var currentTask:Task;
	
	//====================================================;
	// User callbacks 
	//====================================================;
	
	// Simple callback for complete
	public var onComplete:Void->Void = null; // can be null
	// Simple callback for fail
	public var onFail:Void->Void = null; // can be null
	
	// Detailed task status
	// pass-through of a task onStatus
	// * check Task Class onStatus for details *
	public var onTaskStatus:String->Task->Void = null; // can be null
	
	// More Detailed status updates
	// param 1: Status name
	// 			[start, complete, fail]
	// param 2: The job issuing the status
	public var onJobStatus:String->Job->Void;
	
	// -- If A JOB fails and callbacks to the user,
	// These two will be occupied with some data
	
	// Usually this is a direct copy of a task's fail log.
	public var fail_log(default, null):String;
	
	// Also a direct copy of a task's fail code
	public var fail_code(default, null):String;
	
	//====================================================;
	
	/**
	 * A JOB is a sequence of tasks.
	 * @param	name Optional name identifier
	 * @param	taskData This data is going to be passed to the first task
	 */
	public function new(?name:String, ?taskData:Dynamic)
	{
		if (name == null) name = "GenericJob";
		this.taskData = taskData;
		this.name = name;
		currentTask = null;
		sharedData = { };
		taskQueue = new Array();
	}//---------------------------------------------------;
	
	
	/**
	 * Pushes a task at the end of the queue
	 * @param fn A function that returns a task
	 * ----------------------------------------- */
	public function add(t:Task):Job
	{
		taskQueue.push(t);
		return this;
	}//---------------------------------------------------;

	/**
	 * Adds a task at the bottom of the queue, so
	 * it gets executed right after the current one*
	 * Is called mostly by tasks.
	 * -------------------------------------- */
	public function addNext(t:Task):Job
	{	
		taskQueue.unshift(t);
		return this;
	}//---------------------------------------------------;
	
	/**
	 * Starts running the job
	 */
	public function start():Void
	{
		if (onJobStatus != null) onJobStatus("start", this);
		runNext();
	}//---------------------------------------------------;
	
	/*
	 * Executes the next job in the queue
	 * ----------------------------------- */
	function runNext():Job
	{
		if (taskQueue.length > 0)
		{
			currentTask = taskQueue.shift();
			currentTask.shared = sharedData;
			currentTask.dataGet = taskData; // This has null, or a previous task's data, or user data from job.new(data)
			currentTask.onStatus = _onTaskStatus;
			LOG.log('Starting new Task [${currentTask.name}], remaining (${taskQueue.length})');
			currentTask.run();
		}
		else // Job complete, no more tasks.
		{
			_onJobComplete();
		}
		
		return this;
	}//---------------------------------------------------;
	
	
	/* Free up resources,
	 * eventhough V8 is good enough
	 * --------------------------- */ 
	public function kill():Void 
	{
		if (currentTask != null) currentTask.kill();
		currentTask = null;
		taskQueue = null;
	}//---------------------------------------------------;
	
	//====================================================;
	// SubFunctions
	//====================================================;
	
	
	// --
	// Gets fired whenever a task sends an update
	// It process the status and sends to user the same status.
	function _onTaskStatus(status:String, t:Task)
	{
		// Pass this through to the user first.
		if (onTaskStatus != null) onTaskStatus(status, t);
		
		// Manage status update
		switch(status) 
		{
			case "complete":
				LOG.log('Task complete [${t.name}]');
				taskData = t.dataSend;
				t.kill();
				runNext();
				
			case "fail":
				if (t.important) {
					fail_log = t.fail_log;
					fail_code = t.fail_code;
					LOG.log('Task [${t.name}] failed.',3);
					LOG.log('Reason : ${fail_log} , [$fail_code]', 3);
					if (onJobStatus != null) onJobStatus("fail", this);
					if (onFail != null) onFail();
					t.kill();
					t = null;
				}else {
					LOG.log("Task Failed, but it was not important", 2);
					taskData = null; // Be sure to null this, because the task failed
					t.kill();
					t = null;
					runNext();
				}
		}

	}//---------------------------------------------------;
	
	// -- 
	// Called when ALL the tasks are complete
	inline function _onJobComplete()
	{
		LOG.log('Job [${name}] Complete');
		if (onJobStatus != null) onJobStatus("complete", this);
		if (onComplete != null) onComplete();
	}//---------------------------------------------------;

}// -- end -- //