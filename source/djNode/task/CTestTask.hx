/**
	Test Task
	----------
	Simulated task for debugging/development purposes
**/
package djNode.task;
import js.Node;


class CTestTask extends CTask
{
	public function new(time:Int = 2000, steps:Int = 10, Name:String = null) 
	{
		super(null, name, "Fake Task");

		var every:Int = Std.int(time / steps);
		var progressInc = Math.ceil(100.0 / steps);
		var triggers = 0;
		var timer:IntervalObject;
		
		quickRun = function(t){
			
			timer = Node.setInterval(function(){
				
				if (++triggers == steps){
					complete();
					Node.clearInterval(timer);
					timer = null;
				}
				else
					PROGRESS += progressInc;
			},every);
			
		};
	}//---------------------------------------------------;
	
}//--