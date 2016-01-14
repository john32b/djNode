package djNode.task;
import djNode.tools.LOG;
import djNode.tools.Sequencer;

/**
 * FakeTask is a dummy task used for dev purposes
 * Simulates a task run, including progress reports.
 * Can also simulate a failing task,
 * Customizable run time, etc.
 * ...
 */
class FakeTask extends Task
{

	// progress : Simulate a progress run, total runtime $time
	// fail : Fail after $time
	// steps : Simulate a steps run, new step every $time
	var runType:String; // "progress", "fail", "steps"
	//
	var runTime:Float;
	
	var seq:Sequencer;
	
	var r1:Float;
	
	// --
	var progressPercentStep:Int = 9; // Increment progress bar by 9%
	var progressMaxSteps:Int = 10; // If runtype is steps, run upto this.
	
	//====================================================;
	//====================================================;
	
	/**
	 * 
	 * @param	name
	 * @param	runType_ progress, fail, steps
	 * @param	runTime_ time in seconds, affects runType
	 */
	public function new(?name:String, runType_:String = "progress", runTime_:Float = 2)
	{
		this.name = name;
		super();
		
		runType = runType_;
		runTime = runTime_;
	}//---------------------------------------------------;
	
	// --
	override public function run() 
	{		
		switch(runType)
		{
			case "progress":
				seq = new Sequencer(callback_progress);
				progress_type = "percent";
				r1 = runTime / progressPercentStep;
				seq.next(r1);
			case "fail":
				seq = new Sequencer(callback_fail);
				seq.next(runTime);
			case "steps":
				seq = new Sequencer(callback_steps);
				progress_type = "steps";
				r1 = 0; // hold the curent step
				progress_steps_total = progressMaxSteps;
				seq.next(runTime);
		}
		
		super.run();
	}//---------------------------------------------------;
	
	function callback_progress(step:Int)
	{
		progress_percent += progressPercentStep;
		if (progress_percent >= 100) {
			complete(); return; // Remember: Complete also reports progress update
		}
		
		onStatus("progress", this);	
		seq.next(r1);
	}//---------------------------------------------------;
	
	function callback_fail(step:Int)
	{	
		fail("Dummy task has failed");
		// Note: Fail doesn't need a progress update.
	}//---------------------------------------------------;
	function callback_steps(step:Int)
	{
		progress_steps_current ++;
		if (progress_steps_current >= progress_steps_total) {
			complete(); return;
		}
		onStatus("progress", this);
		seq.next(runTime);
	}//---------------------------------------------------;
	
	// 
	override public function kill() 
	{
		LOG.log("killing dummy task...");
		if (seq != null) {
			seq.stop();
			seq = null;
		}
	}//---------------------------------------------------;
	
}// -- end 