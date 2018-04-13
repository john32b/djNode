/**
   Custom Task
   -----------
   A simple custom Task that runs and reports progress.
   Usually lives inside a "CJob" object, which manages a series of CTasks
**/
   
package djNode.task;

import djNode.utils.CLIApp;
import js.Error;


// Task Statuses
enum CTaskStatus
{
	waiting; complete; start; fail; progress;
}


// --
class CTask 
{
	// UID generator
	static var UID:Int = 0;
	
	// Task Unique ID
	public var uid(default, null):Int;
	
	public var name(default, null):String;
	
	public var desc(default, null):String;
	
	// Current Progress 0-100
	public var PROGRESS(default, set):Int;	
		function set_PROGRESS(value){
			PROGRESS = value; 
			if (PROGRESS < 0) PROGRESS = 0; else if(PROGRESS>100) PROGRESS = 100;
			if (!FLAG_PROGRESS_DISABLE) onStatus(CTaskStatus.progress, this);
			return value;
		}// -
	
	// If true will not report progress or count towards job progress
	// Useful for small tasks that start and end instantaneously
	public var FLAG_PROGRESS_DISABLE:Bool = false;
	
	// Current lifecycle step
	public var status(default, set):CTaskStatus;
		function set_status(val){
			status = val;
			onStatus(val, this);
			return val;
		}
	
	// JOB parallel execution Slot Index for this task
	@:allow(djNode.task.CJob)
	public var SLOT(default, null):Int;
	
	// #USERSET Called when this task is completed
	public var onComplete:Void->Void;
	
	// #USERSET  Called whenever the status changes
	// Available statuses ==
	//		start	:	The task has just started
	//		progress:	The task progress has changed
	//		complete:	The task has been completed
	//		fail	:	The task has failed, read the ERROR field
	public var onStatus:CTaskStatus->CTask->Void = function(a, b){};
	
	// # USER SET
	// if you want to declare a kill function on quick tasks, here is where you do it
	public var killExtra:Void->Void = null;
	
	// Pointer to the Job holding this task
	@:allow(djNode.task.CJob)
	var parent:CJob;
	
	// CJob sets this
	// SYNC tasks run by themselves while no other task is running on the Job
	// ASYNC tasks can run in parallel with other ASYNC tasks on the Job
	@:allow(djNode.task.CJob)
	var async:Bool = false;

	// -- Data
	// Pointer to JOB's shared data object
	@:isVar
	public var jobData(get, set):Dynamic;
		function get_jobData(){
			return parent.jobData;
		}
		function set_jobData(val){
			return jobData = val;
		}
		
	// Data read from the previous task
	@:allow(djNode.task.CJob)
	var dataGet:Dynamic;

	// Data to send to the next task
	@:allow(djNode.task.CJob)
	var dataSend:Dynamic;

	// Data that is unique to the task, perhaps you might need this sometimes
	public var custom:Dynamic;

	// If set, then this code will run at task start
	var quickRun:CTask->Void;
	// --
	
	// In case of error, READ THIS 
	public var ERROR(default, null):Error;
	
	
	//====================================================;
	
	// -
	public function new(?qRun:CTask->Void, ?Name:String, ?Desc:String) 
	{
		uid = ++UID;
		name = Name == null?'task_$uid':Name;
		desc = Desc;
		quickRun = qRun;
		status = CTaskStatus.waiting;
		
		if (name.charAt(0) == "-")
		{
			FLAG_PROGRESS_DISABLE = true;
			name = name.substr(1);
		}
		
	}//---------------------------------------------------;
	
	// # USER EXTEND
	// Or you can just use a quick_run
	public function start()
	{
		status = CTaskStatus.start;
		PROGRESS = 0;
		if (quickRun != null) quickRun(this);
	}//---------------------------------------------------;
		
	// Can also be called from quickTasks
	// -
	public function complete()
	{
		PROGRESS = 100;
		status = CTaskStatus.complete;
		if (onComplete != null) onComplete();
	}//---------------------------------------------------;

	// Can also be called from quickTasks
	// --
	public function fail(?message:String)
	{
		ERROR = new Error(message);
		status = CTaskStatus.fail;
	}//---------------------------------------------------;
	
	
	// Automatically called whenever completed or failed
	// -
	@:allow(djNode.task.CJob)
	function kill()
	{
		if (killExtra != null) killExtra();
	}//---------------------------------------------------;
	
	// Quick information
	// --
	public function toString():String
	{
		return 'UID:$uid "$name"' + (desc == null?'':'($desc)') + ' SLOT:$SLOT , ASYNC:$async';
	}//---------------------------------------------------;
	
	
	// -- Quickly handle an APP success report
	public function handleCliReport(app:CLIApp)
	{
		app.events.once("close", function(a, b){
			if (a){
				complete();
			}else{
				fail(b);
			}
		});
	}//---------------------------------------------------;
	
}// -