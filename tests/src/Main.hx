/********************************************************************
 * Generic Demo and Tests for djNode
 * ------------------------------------
 * 
 * Note: This was written using an old djNode version and the terminal
 *       printing is a bit awkard. Does not make use of the new <PRINT2> helper
 * 
 * Note: This whole test program is going to be deprecated.
 * 
 *******************************************************************/
package;

import djNode.BaseApp;
import djNode.utils.UserAsk;
import djNode.tools.LOG;
import djNode.utils.ActionInfo;

class Main extends BaseApp

{	
	override function init():Void 
	{
		PROGRAM_INFO = {
			name : "djNode Examples",
			desc : "Use cases and demos",
			version : BaseApp.VERSION
		}
		
		// Arguments example
		ARGS.inputRule = "opt";	// Inputs are optional
		ARGS.outputRule = "no";	// No output is needed
		ARGS.Options.push(['f', 'Test getting an options parameter', 'yes']); // yes=require value
		
		LOG.setLogFile('a:\\djnode_text.txt');
		LOG.pipeTrace();
		
		super.init();
	}//---------------------------------------------------;
	
	// --
	override function onStart() 
	{
		printBanner();
		
		// Read Arguments Test/Example
		if (argsOptions.f != null)
		{
			T.ptag('- Option <cyan>[-f]<!> was set, with a parameter of <cyan>${argsOptions.f}<!>\n');
		}
		
		T.bold().fg(magenta).print('Component examples/tests :\n').reset();
		
		// Read Other Input Arguments
		if (argsInput[0] != null) 
		{
			doTest(Std.parseInt(argsInput[0]));
		}else{
			UserAsk.multipleChoice([
				"Terminal Test",
				"Keyboard Test",
				"Task/Job Test",
				"Job Report Test/Example",
				"ActionInfo.hx Example",
				"Quit"], doTest );
		}
		
	}//---------------------------------------------------;
	
	
	function doTest(s:Int)
	{
		switch(s){
			case 1: new TestTerminal();
			case 2: new TestKeyboard();
			case 3: new TestJobSystem();
			case 4: new TestJobReport();
			case 5: quickTest_ActionInfo();
			case 6: Sys.exit(0);
		}
	}//---------------------------------------------------;
	
	function quickTest_ActionInfo()
	{
		var a = new ActionInfo();
		a.printPair("One", "info");
		a.printPair("Two", "info");
		a.printPair("Three", "info");
		T.rep();
		
		a.quickAction("Doing a thing", true,"it did ok");
		a.quickAction("Doing another thing", false, "it failed");
		
		a.actionStart("Action One");
		a.actionProgress("Doing a thing", "and other");
		a.actionEnd(true, "it did it.");
	}//---------------------------------------------------;
	
	// --
	static function main()  {
		new Main();
	}//---------------------------------------------------;
	
}// --