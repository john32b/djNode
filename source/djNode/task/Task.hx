/**--------------------------------------------------------
 * Task.hx
 * @author: johndimi, <johndimi@outlook.com> , @jondmt
 * --------------------------------------------------------
 * @Description
 * -------
 * A Task is a process that is being managed by a job
 * Tasks emit events
 * 
 * @Notes
 * ------
 * TODOS
 * - Every task should return a dynamic value
 * - Every task should start with the previously parameters on the function caller
 ========================================================*/
 
package djNode.task;

import djNode.task.Job;
import djNode.task.Task.Qtask;
import djNode.tools.LOG;


class Task
{
	// -- Global UID generator counter.
	static var UID_:Int = 0;
	//---------------------------------------------------;
	
	// Pointer to job's custom DATA variable.
	// For quick access
	public var shared:Dynamic;
	
	// Every task has a unique ID
	public var UID(default, null):Int;
	// Code name of the task
	public var name(default, null):String;
	// Progress percent
	public var progress_percent:Int;
	// Optional progress steps, like [1/10]
	public var progress_steps_current:Int;
	public var progress_steps_total:Int;
	// Specify what kind of progress report this task will emit.
	// == [ "percent", "steps", "none" ]
	// default : none
	public var progress_type:String;
	
	// Current status of this task
	// == [ "waiting", "complete", "running", "failed" ] , "prestart??" 
	public var status(default, null):String;
	
	// In case this task has failed, write the reason here.
	public var fail_log(default, null):String;
	
	// Custom set. e.g. you can put here "readerror" or "connecterror"
	public var fail_code(default, null):String;
	
	// If false. This task will not push any task reports to the user
	public var flag_reports_status:Bool = true; // # EXPERIMENTAL
	
	
	// If a task is important and fails the whole job fails
	// else the job continues execution
	public var important:Bool = true;
	
	// Dynamic variable, store custom data
	// Useful to getting extra info from the progress updates, etc.
	public var custom(default, null):Dynamic = null;
	
	// If this is occupied it will be sent to the next task at the receive end
	@:allow(djNode.task.Job)
	var dataSend(default, null):Dynamic = null;
	// Any data gotten from the previous task
	@:allow(djNode.task.Job)
	var dataGet:Dynamic = null;
	
	//====================================================;
	// Status control 
	//====================================================;
	
	// Quick way to add simple onComplete();
	// you could check for completion using onStatus();
	public var onComplete:Void->Void = null; // can be null
	
	// # More detailed status update for a task 
	//  
	//  Status messages:
	//  ----------------
	//   start    : The task is just starting
	//   progress : The task changed progress ( use task.progress to get progress )
	//   complete : The task has completed successfuly
	//   fail     : The task has failed
	public var onStatus:String->Task->Void = null; // MUST BE SET, JOB SETS THIS
	
	//====================================================;
	
	// --
	public function new()
	{
		UID = ++Task.UID_;
		
		// There are cases where the task name is set at a derived object.
		if (name == null) 
		{
			// Get the class name for the default task name
			var reg = ~/\.*(\w+)$/;
			if (reg.match(Type.getClassName(Type.getClass(this)))) {
				name = reg.matched(1);
			} else {
				name = "GenericTask";
			}
		}
		
		LOG.log('Task created, name = $name, UID = $UID');
		
		status = "waiting";
		progress_percent = 0;
		progress_steps_current = 0;
		progress_steps_total = 0;
		progress_type = "none";
	}//---------------------------------------------------;
	
	// -- Override this
	// -- Starts the Task
	// + perhaps you should call this at THE END of the overriden run() and before anything new happens
	public function run() 
	{ 
		status = "running";
		onStatus("start", this); // Gets pushed to job AND user
		onStatus("progress", this); // If there is any progress handler, make it init to 0
	}//---------------------------------------------------;
	
	// --
	function fail(?why:String, ?code:String)
	{
		status = "failed";
		fail_log = why;
		fail_code = code;
		onStatus("fail", this); // Gets pushed to job AND user
	}//---------------------------------------------------;
	
	// --
	function complete()
	{
		progress_percent = 100;	// Just in case the task uses percent progress
		progress_steps_current = progress_steps_total; // Just in case the task uses steps
		status = "complete";
		onStatus("progress", this); // One last progress report for the progress handlers
		onStatus("complete", this); // Gets pushed to job AND user
		if (onComplete != null) onComplete();
	}//---------------------------------------------------;
	
	// --
	// -- override this
	public function kill() 
	{
		// Force kill the operation
		// Stop everything and clear memory
		// Usually called from a job
	}//---------------------------------------------------;
	
}// -- end class --//



/**
 * Create a task without having to declare a new task class
 * Useful to quickly creating simple tasks to add in Jobs.
 * 
 * e.g.
 * 
 *	job.add(new Qtask("quickTask", function(t:Qtask) {
 *      var dataFromPrevious = t._dataGet();
 * 		-- do things --
 *		t._complete();
 *		});
 *	}));
 *	
 **/
class Qtask extends Task
{
	// Hold the quick run set by the constructor
	var _qrun:Qtask->Void;
	
	// If you skip setting a construction function, you can set this manually later
	public var _run:Void->Void;
	
	//====================================================;
	
	/**
	 * If you set a quick function here, it will run this.
	 * @param name
	 * @param fn 
	 */
	public function new(?name:String, ?fn:Qtask->Void)
	{
		_qrun = fn;
		if (name != null) this.name = name;
		super();
	}//---------------------------------------------------;
	
	/* Just run the user function
	 * User has to call job._taskComplete()
	 * ------------------------------------ */
	override public function run() 
	{
		super.run();
		
		if (_qrun != null){
			_qrun(this);
		}else{
			_run();
		}

	}//---------------------------------------------------;
	
	//====================================================;
	// These are helper functions that the user 
	// can call to control the task flow outside of the class
	// e.g.
	//   t1 = new QTask();
	//   t1._run = function(){ dothis(); t1._complete(); };
	//   ...
	//====================================================;

	public function _complete() { complete(); }	
	public function _fail(?why:String, ?code:String) { fail(why, code); }
	// taskData set,get.
	public function _dataSend(data:Dynamic) { dataSend = data; }
	public function _dataGet():Dynamic { return dataGet; }	
	
}//-- end -- //