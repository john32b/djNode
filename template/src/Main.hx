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
			version:"0.1"
		};
		
		// Initialize Program Arguments here.
		// ARGS.requireAction = "false";
		// ARGS.inputRule = "no";
		// ARGS.requireAction = true;
		// ARGS.Actions = [
			//['c', 'Compress a file'],
			//['d', 'Decompress a file\nFile will be decompressed in the same folder'],
		//];
		//ARGS.Options = [
			//['t', 'Set Temp Folder', '1']
		//];
		
		super.init();
	}//---------------------------------------------------;
	
	// This is the user code entry point :
	// --
	override function onStart() 
	{
		printBanner();
		
		//switch (argsAction)
		//{
			//case 'c':
				//T.print(" > About to Compress file : " + this.argsInput[0]).endl();
			//case 'd':
				//T.print(" > About to Decompress file : " + this.argsInput[0]).endl();
		//}
	}//---------------------------------------------------;
	
	// --
	static function main()  {
		new Main();
	}//---------------------------------------------------;
	
}// --