package;
import djNode.BaseApp;
import djNode.Keyboard;
import djNode.Terminal;

/**
 * Terminal Test and Example
 * ...
 * @author John Dimi
 */
class TestTerminal extends TestTemplate
{

	public function new(?compl:Void->Void) 
	{
		super("TERMINAL.hx");
		
		onComplete = compl;
		
		// --
		
		a("Information", function(){
			T.println('Terminal Width : ${T.getWidth()}');
			T.println('Terminal Height : ${T.getHeight()}');
		});
		
		a("Colors", function(){
			T.demoPrintColors();
		});
		
		a("print()", function(){
			T.print("Printing text ::");
			expect(" (this part should be in the same line)");
		},"key");
		
		a("println()", function(){
			T.print("This Should be a new line").endl();
			T.println("Also new line ");
		});
		
		a("savePos() and restorePos()", function(){
			T.println("The Cursor Position of the start of this line is saved:");
			T.savePos();
			T.print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
			T.restorePos();
			T.println("------------");
			expect("There should be some dashes (-) overwriting the (X) characters");
		}, "key");

		a("Moving Cursor", function(){
			T.print("\n\n\n\n\n\n");
			T.print("-Start:");
			T.up(4).print("up(4)");
			T.forward(10).print("forward(10)");
			T.down(2).print("down(2)");
			T.back(20).print("back(20)").endl().endl();
			expect("Printed in various positions");
		}, "key");
		
		a("clearLine()", function(){
			T.println("Going to print a line and then going to clear it");
			T.savePos();
			T.drawLine(); // prints a string of --------------
			T.restorePos();
			T.clearLine().endl();
			expect("You shouldn't be able to see a line above ");
		},"key");
		
		a("pageDown()", function(){
			T.pageDown();
			T.println("A pagedown() makes space into the terminal, it does not erase anything.");
			expect("The terminal should be scrolled down");
			expect("Try to scroll the terminal view UP to see if there is content");
		},"key");
		
		a("printf()", function(){
			T.println("Inline TAGS with sprintf()");
			T.printf("~green~This ~bg_cyan~~black~line is supposed ~yellow~ ~!bg~ to have ~red~multiple ~white~ colors. ~!~ (Reseted and now normal text)");
			T.endl();
		});
		
		a("Styles", function()
		{
			T.println("Testing some predefined header styles");
			T.H1("This is an H1 header.");
			T.H2("This is an H2 header.");
			T.H3("This is an H3 header.");
			T.list("List item 1");
			T.list("List item 2");
			T.list("List item 3");
			T.endl();
			T.bold();
			T.println("This should be BOLD text").resetBold();
		});
			
		doNext();
	}//---------------------------------------------------;
	

}// --