package;
import djNode.task.CJob;
import djNode.task.CTestTask;
import djNode.utils.CJobReport;

/**
 * ...
 * @author John Dimi
 */
class TestJobReport extends TestTemplate
{

	public function new() 
	{
		super('Testing Generic Job Reporting');
		
		a("Synoptic Progress", function(){
			
			T.println("Testing running a few tasks.");
			expect("There is a single bar displaying progress for all tasks.");
			
			var j = new CJob("Test synoptic progress report");
				j.onComplete = doNext;
				j.add(new CTestTask(300, 'Initializing'));
				// Starting with - will not report progress
				j.add(new CTestTask(500, '-No Progress Report').addMore(3, 400));
				j.add(new CTestTask(500,'Finalizing'));
			var report = new CJobReport(j, false, true);

			j.start();
		
		}, "halt");
		
	
		a("Detailed Progress", function(){
			
			T.println("Testing a few tasks with DETAILED progress view.");
			expect("Tasks should report progress individually");
			expect("Custom user info at beggining and end");
	
			var j = new CJob("Testing multiple progress report");
				j.onComplete = doNext;
				j.MAX_CONCURRENT = 3;
				j.addAsync(new CTestTask(1200,'Compressing File 1'));
				j.addAsync(new CTestTask(2200,'Compressing File 2'));
				j.addAsync(new CTestTask(2800,'Compressing File 3'));
				j.addAsync(new CTestTask(2500,'Compressing File 4'));
				j.addAsync(new CTestTask(1700,'Compressing File 5'));
				j.add(new CTestTask(800, 'Finalizing'));
			var report = new CJobReport(j, true);
			report.onStart = function(j){
				T.println("Custom user code, onStart()");
			}
			report.onComplete = function(j){
				T.println("Custom use code, onComplete()");
			}
			j.start();
		
		}, "halt");
		
		
		doNext();
		
	}//---------------------------------------------------;
	
	
	
}// --