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
	
	/**
	   
	   @param	time Total time of the task
	   @param	tick Report back progress every this many milliseconds
	   @param	Name
	**/
	public function new(time:Int = 2000, Name:String = null, tick:Int = 200) 
	{
		super(null, name, "Fake Task");
		

		var timesToTick:Int = Math.ceil(time / tick);
		var progressInc = Math.ceil(100.0 / timesToTick);
		
		var timer:IntervalObject;
		
		quickRun = function(t){
			
			timer = Node.setInterval(function(){
				
				if (--timesToTick == 0){
					Node.clearInterval(timer);
					complete();
				}
				else
					PROGRESS += progressInc;
			},tick);
		};
	}//---------------------------------------------------;
	
}//--