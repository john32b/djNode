package;
import djNode.task.CJob;
import djNode.task.CTask;
import djNode.task.CTestTask;

/**
 * Test Tasks and Jobs
 * ...
 * @author John Dimi
 */
class TestJobSystem extends TestTemplate
{

	var flag_report_progress:Bool = true;
	
	public function new() 
	{
		super("Testing Job System");
		
		// Create a Job 
		// Tasks go inside a Job, which acts like a manager
		
		a("One task at a time", function(){
			
			T.println("Setting MAX_CONCURRENT to 1");
			T.println("Adding ASYNC and SYNC tasks on the queue");
			expect("Tasks should start and end one after the other");
			
			var job = new CJob();
				job.events.on("taskStatus", onTaskStatus);
				job.MAX_CONCURRENT = 1;
				
				job.onComplete = function(a){doNext();};
			
				job.add(new CTestTask(300));
				job.add(new CTestTask(300));
				job.addAsync(new CTestTask(800));
				job.addAsync(new CTestTask(700));
				job.add(new CTestTask(300));		
				job.start();
				
		}, "halt");
		
		a("", function() {},"key"); // Await for key
		
		a("Test", function(){
			T.println("Setting MAX_CONCURRENT to 3");
			T.println("Adding ASYNC and SYNC tasks on the queue");
			expect("Sync Tasks should run on their own and always have SLOT=0");
			expect("ASync tasks should run along with other Async tasks only");
			
				var job = new CJob();
				job.events.on("taskStatus", onTaskStatus);
				job.MAX_CONCURRENT = 3;
				job.onComplete = function(a){doNext();};
				flag_report_progress = false;
				job.add(new CTestTask(300));
				job.add(new CTestTask(300).addMore(2, 400));
				job.addAsync(new CTestTask(800));
				job.addAsync(new CTestTask(1000, 700));
				job.addAsync(new CTestTask(2000,700));
				job.add(new CTestTask(400));
				job.addAsync(new CTestTask(300));
				job.start();
		}, "halt");
		
		doNext();
	}//---------------------------------------------------;
	
	
	function onTaskStatus (a:CTaskStatus, b:CTask)
	{
		if (a == CTaskStatus.start)
		{
			T.fg("green").print("[START] = ").resetFg().println(b.toString());
		}else
		
		if (a == CTaskStatus.complete)
		{
			T.fg("magenta").print("[END]   = ").resetFg().println(b.toString());
			
		}else
		
		if (a == CTaskStatus.progress && flag_report_progress) 
		{
			T.print('Progress Task UID(${b.uid}) ').fg("yellow").println('[${b.PROGRESS}%]').resetFg();
		}
	}//---------------------------------------------------;
	
}// --