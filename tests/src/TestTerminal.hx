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

		a("Relative Cursor Movement", function(){
			T.print("\n\n\n\n\n\n");
			T.print("-Start : ");
			T.up(4).print("up(4)");
			T.forward(10).print("forward(10)");
			T.down(2).print("down(2)");
			T.back(20).print("back(20)").endl().endl();
			expect("Printed in various positions");
		}, "key");
		
		
		a("Absolute Cursor Movement", function(){
			T.clearScreen(2);
			
			T.move(10, 3);
			T.print("(10,3)");
			
			T.move(30, 1);
			T.print("(30,1)");
			
			T.move(2, 5);
			T.print("(2, 5)");
			
			T.moveR(10, 1);
			T.print("moveR(10,1) < relative");
			
			T.endl();
			
			
			expect("Printed text on actual coordinates (x,y)");
			
		}, "key");		
		
		
		a("clearLine()", function(){
			var l = StringTools.lpad("", '-', 40);
				T.println(l + " : Original size for reference");
			T.printf('~magenta~clearLine(0);~!~ Clear all Forward\n');
				T.print(l).back(20);
				T.clearLine(0).endl();
				expect("Right part of line cleared");
				
			T.printf('~magenta~clearLine(1);~!~ Clear all back\n');
				T.print(l).back(20);
				T.clearLine(1).endl();
				expect("Left part of line cleared");
				
			T.printf('~magenta~clearLine(2);~!~ Clear Entire Line\n');
				T.print(l).back(20);
				T.clearLine(2).endl();
				expect("Empty Line above ^");
			
		}, "key");
		
	
		a("clearScreen()", function(){
			T.println("Press Key to:");
			T.printf('~magenta~clearScreen(0);~!~ Clear all Forward\n');
			T.println('FROM HERE:'); T.savePos();
			T.drawLine();
			T.drawLine();
			T.drawLine();
			T.drawLine();
		}, "key");
		
		a("clearScreen(0)", function(){
			T.restorePos();
			T.print(" Clearing... ");
			T.clearScreen(0);
		}, "key");
		
		a("clearScreen()", function(){
			T.println("Press Key to:");
			T.printf('~magenta~clearScreen(2);~!~ Clear Entire Screen\n');
			T.println('FROM HERE:'); T.savePos();
			T.drawLine();
			T.drawLine();
			T.drawLine();
			T.drawLine();
		}, "key");
		
		a("clearScreen(2)", function(){
			T.restorePos();
			T.print(" Clearing... ");
			T.clearScreen(2);
			T.printf(" Cleared Entire Screen with ~magenta~clearScreen(2)\n~!~");
		}, "key");
		
		a("printf(), sprintf()", function(){
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