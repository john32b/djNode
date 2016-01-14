package dj.term.info;

import djNode.net.IDownloadable;
import djNode.tools.StrTool;
import djNode.Graphics;
import djNode.Terminal;


/**
 * Simple Info for a downloadable item
 * -----------------------------------
 * @note This is a fixed position element.
 * 
 * - TODO - 
 * . Check if the url length is bigger than the object width.
 * . Don't update too often, update on a timer?
 */
class DownloadInfo
{
	// The size is standard, unless user changes it
	public static var HEIGHT:Int = 3;
	public static var WIDTH:Int = 55;
	public static var PADDING_X:Int = 2;
	
	// Terminal coordinates
	var x:Int; var y:Int;
	// Hold the percent
	var percent:Int;
	// Helper var, store the total size string, so I don't have to calculate each time
	var _strTotal:String = null;

	public var isActive(default,null):Bool = false;
	public var ref(default,null):IDownloadable = null;
	public var slotNo:Int = null;
	public var queuePos:Int;
	
	//====================================================;
	// FUNCTIONS
	//====================================================;
	// --
	public function new(x:Int,y:Int)
	{
		this.x = x;
		this.y = y;
	}//---------------------------------------------------;

	
	// Draw all changing graphics
	// 
	public function update()
	{
		try{
		if (_strTotal == null) {
			if (ref.bytes_total != 0)
			_strTotal = StrTool.bytesToMBStr(ref.bytes_total) + "MB";
		}	
		percent = Math.ceil( ((ref.bytes_got / ref.bytes_total) * 100));
		// Draw some text info at (y)
		Graphics.t.reset().move(x + PADDING_X, y + 1);
		Graphics.t.print("got: ").color(Color.magenta).print(StrTool.bytesToMBStr(ref.bytes_got)+"MB");
		Graphics.t.reset();
		Graphics.t.print(" of ").color(Color.magenta).print(_strTotal).reset();
		// Draw the progress bar at (y+1)
		Graphics.drawProgressBar(x, y + 2, WIDTH - 10, percent );
		Graphics.t.fg(Color.green).move(x + WIDTH - 10, y + 2).print(' [ $percent% ] ');
		Graphics.hideCursor();
		}catch (e:Dynamic) {
			// Idownloadable doesn't have the ref.bytes_total/got occupied
		}
	}//---------------------------------------------------;
	
	
	// Init and draw all static graphics
	// 
	public function start(i:IDownloadable)
	{
		// reset the variables of the object
		ref = i;
		isActive = true;
		// draw static portions
		Graphics.t.reset().move(x + PADDING_X, y);
		Graphics.t.printf('item[~yellow~$queuePos~!~], url:~yellow~${i.url}~!~');
		Graphics.hideCursor();
		update();
	}//---------------------------------------------------;
	
	/**
	 * @called when the associated job stops
	 */
	public function stop()
	{
		//  Sometimes the last progress wasn't 100, this makes sure
		// that the progress will be updated one last time to 100%
		// if (ref != null) update(); 
		// ^ now that I am erasing everything, I don't need it.
		ref = null;
		_strTotal = null;
		isActive = false;
		// Erase the content from the screen
		Graphics.drawRect(x, y, WIDTH, HEIGHT);
		Graphics.hideCursor();
	}//---------------------------------------------------;
	
}//-- end --//