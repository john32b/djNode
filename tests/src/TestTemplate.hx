package;
import djNode.BaseApp;
import djNode.Keyboard;
import djNode.Terminal;
import djNode.utils.Print2;


class TestTemplate 
{
	var T:Terminal;
	var P:Print2;
	var onComplete:Void->Void;
	var action_text:Array<String> = [];
	var action_func:Array<Void->Void> = [];
	var action_waits:Array<String> = [];
	var current:Int = -1;
	
	public function new(title:String) 
	{
		P = new Print2();
		T = BaseApp.TERMINAL;
		//T.endl().drawLine().H2(title + "- Tests:");
		P.H('Tests:');
	}//---------------------------------------------------;
	
	/**
	   
	   @param	text
	   @param	func
	   @param	type sync, key, halt
					sync will execute it and immediately start the next
					key  will execute and await keyboard key
					halt will execute and wait forever, until you manually call doNext();
	**/
	function a(text:String, func:Void->Void, type:String = "sync")
	{
		action_text.push(text);
		action_func.push(func);
		action_waits.push(type);
	}//---------------------------------------------------;
	
	
	function expect(txt:String)
	{
		T.fg(cyan).print('>>> ' + txt).resetFg().endl();
	}//---------------------------------------------------;
	
	
	function doNext()
	{
		if (++current >= action_text.length)
		{
			complete();
			return;
		}
		
		T.endl();
		
		T.fg(yellow).print('+ ' + action_text[current]).resetFg().endl();
		action_func[current]();
		
		if (action_waits[current] == "key")
		{
			T.savePos();
			T.fg(magenta).println("[Press Key]").resetFg();
			Keyboard.onData = function(d) {
				T.restorePos();
				T.clearLine();
				Keyboard.stop();
				doNext();
			}
			Keyboard.startCapture();
		}else{
			
			if (action_waits[current] == "sync") doNext();
		}
	}//---------------------------------------------------;
	
	function complete()
	{
		T.ptag("\n<darkcyan> >>> Test end. <!>\n");
		if (onComplete != null) onComplete();
	}//---------------------------------------------------;
	
}