/**
	Test Task
	----------
	Simulated task for debugging/development purposes
	
	Example:
	
		job.add(new CTestTask(1000,10,"CompressingFake"));
	
**/
	
package djNode.task;
import js.Node;


class CTestTask extends CTask
{
	
	var flag_fail:Bool = false;
	var nextTasks:Dynamic = null;
	
	/**
	   
	   @param	time Total time of the task
	   @param	tick Report back progress every this many milliseconds
	   @param	Name
	**/
	public function new(time:Int = 2000, Info:String = null, tick:Int = 200 )
	{
		super(Info);

		var timesToTick:Int = Math.ceil(time / tick);
		var progressInc = Math.ceil(100.0 / timesToTick);
		
		var timer:IntervalObject;
		
		quickRun = function(t){
			
			timer = Node.setInterval(function(){
				
				if (--timesToTick == 0){
					Node.clearInterval(timer);
					if (flag_fail) fail(); else complete();
				}
				else
					PROGRESS += progressInc;
			},tick);
		};
	}//---------------------------------------------------;
	
	/**
	 * Fail this task when it ends
	 */
	public function FAIL():CTestTask
	{
		flag_fail = true; return this;
	}//---------------------------------------------------;
	
	/**
	   When this tasks completes, add more tasks on the job
	   right after this one
	   @return
	**/
	public function addMore(num:Int = 3, time:Int = 400):CTestTask
	{
		nextTasks = {num:num, time:time};
		return this;
	}//---------------------------------------------------;
	
	override public function complete() 
	{
		if (nextTasks != null)
		{
			for (i in 0...nextTasks.num)
			{
				parent.addNextAsync(new CTestTask(nextTasks.time, "Injected Task"));
			}
		}
		super.complete();
	}//---------------------------------------------------;
	
}//--