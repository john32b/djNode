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
		
				
		a("One task at a time", function(){
			
			T.println("Testing a couple of tasks");
			expect("Tasks should report progress and COMPLETE");
			
			var j = new CJob("Test Job");
				j.onComplete = function(a){doNext(); };
				j.add(new CTestTask(300, 'Initializing'));
				// Starting with - will not report progress
				j.add(new CTestTask(500, '-No Progress Report'));
				j.addAsync(new CTestTask(4200,'Fake Compressing File 1'));
				j.addAsync(new CTestTask(4200,'Fake Compressing File 2'));
				j.addAsync(new CTestTask(3200, 'Fake Compressing File 3'));
				j.add(new CTestTask(500,'Finalizing'));
				
			var report = new CJobReport(j);
			j.start();
		
		}, "halt");
	
		a("Failing Task", function(){
			
			expect("Tasks should report progress and FAIL");
	
			var j = new CJob("Test Job");
				j.onComplete = function(a){doNext(); };
				j.add(new CTestTask(300, 'Initializing'));
				j.addAsync(new CTestTask(2200, 'Doing something').FAIL());
			var report = new CJobReport(j);
			j.start();
		
		}, "halt");
		
		
		doNext();
		
	}//---------------------------------------------------;
	
	
	
}// --