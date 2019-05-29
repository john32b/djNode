package;

import djNode.BaseApp;
import djNode.tools.LOG;

class Main extends BaseApp
{	
	override function init():Void 
	{
		// All traces will redirect to LOG object
		LOG.pipeTrace();
		LOG.setLogFile("log.txt");
		
		//FLAG_USE_SLASH_FOR_OPTION = true;
		
		// Initialize Program Information here.
		PROGRAM_INFO = {
			name:"Template",
			version:"0.1",
			info:""
		};
		
		// Initialize Program Arguments here.
		// ARGS.requireAction = "false";
		// ARGS.inputRule = "no";
		// ...
		
		super.init();
	}//---------------------------------------------------;
	
	// This is the user code entry point :
	// --
	override function onStart() 
	{
		printBanner();
	}//---------------------------------------------------;
	
	// --
	static function main()  {
		new Main();
	}//---------------------------------------------------;
	
}// --