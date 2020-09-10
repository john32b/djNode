package;
import djNode.Keyboard;


class TestKeyboard extends TestTemplate 
{
	public function new(?C:Void->Void) 
	{
		super("KEYBOARD.hx");
		
		onComplete = C;
		
		a("RealTime Capture", function(){
			
			T.println("Try to press keys on the keyboard");
			expect("It should be updating on every keystroke");
			T.println("--> PRESS [Q] To stop");
			T.savePos();
			
			Keyboard.onData = function(data) {
				T.restorePos();
				T.clearLine(0);
				T.print("PRESSED : " + data);
				if (data == "Q" || data == "q") {
					T.endl();
					Keyboard.stop();
					doNext();
				}
			}
			Keyboard.startCapture(true);
			
		},"halt");
		
		
		
		a("Capture on Enter Key", function(){
			T.println("Enter a string and press enter");
			expect("The input will be pushed once you push [ENTER]");
			T.print("--: INPUT: ");
			Keyboard.onData = function(data) {
				T.endl();
				T.ptag("You entered : <yellow> " + data);
				Keyboard.stop();
				T.endl().reset();
				doNext();
			}
			Keyboard.startCapture(false);
		}, "halt");
		
		
		doNext();
	
		
	}//---------------------------------------------------;
	
}