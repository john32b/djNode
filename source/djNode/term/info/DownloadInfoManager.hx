package dj.term.info;

import dj.net.IDownloadable;
import dj.net.DownloadManager;
import dj.term.Graphics;
import dj.term.Terminal;
import dj.tools.LOG;

/**
 * Attaches a DownloadManager and displays info
 * about the download progress on the terminal
 */
class DownloadInfoManager
{
	// Associated Download Manager
	var manager:DownloadManager;	
	var x:Int;
	var y:Int;
	var width:Int;
	var maxSlots:Int;
	var headerHeight:Int = 3;
	// Current number of active infos shown.
	var activeInfos:Int = 0;
	// Put the Elements being shown here
	var infoArray:Array<DownloadInfo>;
	// Assosiate an iDownloadable's UID with the the Array Index.
	var hash:Map<Int,Int>;
	// Count the number of items processed on the queue
	var itemsProcessed:Int = 0;	
	// Where are the files downloaded to.
	var destination:String = null;
	
	//====================================================;
	// FUNCTIONS
	//====================================================;
	
	/**
	 * This is a fixed position element,
	 * Because this is a terminal implementation,
	 * you need to specify y coordinate that the printing will begin.
	 */
	public function new(x:Int = 2, y:Int = 2)
	{
		this.x = x;
		this.y = y;
		infoArray = new Array();
		hash = new Map();
	}//---------------------------------------------------;
	
	/** 
	 * Print all static data on the header
	 */
	function _drawHeaderStatic()
	{
		// Line 1 of the header
		// Only print the destination if it's global.
		if (manager.unified_destination != null)
		Graphics.t.move(x, y).printf('~!~Destination : ~green~${manager.unified_destination}~!~');		
		// Line 3 of the hearer is a horizontal line
		Graphics.t.move(x, y + 2).printLine();
	}//---------------------------------------------------;
	
	/**
	 * Draw stuff like completed and total downloads.
	 */
	function _updateHeader()
	{
		var remaining = manager.stats_totalItems - manager.stats_downloadedItems;
		// Line 2 of the header
		Graphics.t.move(x, y + 1).printf('~!~Downloaded : ~magenta~${manager.stats_downloadedItems}');
		Graphics.t.printf('~!fg~ , Remaining : ~cyan~$remaining     ');
		Graphics.hideCursor();
	}//---------------------------------------------------;
	
	// Returns the current visual height, useful to have
	public function getHeight()
	{
		return headerHeight + ( activeInfos * DownloadInfo.HEIGHT );
	}//---------------------------------------------------;
	
	public function attachDownloader(d:DownloadManager)
	{
		manager = d;
		maxSlots = manager.MAX_PARALLEL_DOWNLOADS;
		activeInfos = 0;
		
		// First create the infoElements,
		// They will be recycled through all downloads
		for (i in 0...maxSlots){
			infoArray[i] = new DownloadInfo(x, headerHeight + y + (i * DownloadInfo.HEIGHT));
			infoArray[i].slotNo = i + 1;
		}//--
		

		//-- Set the callbacks --
		
		d.onSingleComplete = function(e:IDownloadable) {
			activeInfos--;
			var index = hash.get(e.UID);
			hash.remove(e.UID);
			infoArray[index].stop();
			reorder(index);
			_updateHeader();
		}//--
		
		
		d.onSingleProgress = function(e:IDownloadable) {
			infoArray[hash.get(e.UID)].update();
			//Graphics.hideCursor();
		}//--
		
		d.onSingleStart = function(e:IDownloadable) {
			// Find first available, and
			for (i in 0...maxSlots) {
				if (infoArray[i].isActive == false) {
					hash.set(e.UID, i);
					infoArray[i].queuePos = ++itemsProcessed;
					infoArray[i].start(e);
					activeInfos++;
					break;
				}
			}
		}//--
		
		d.onComplete = function(e:Dynamic) {
			Graphics.t.move(x , y + headerHeight);
			Graphics.t.printf("~cyan~All Downloads Complete.").endl();
		}//--
		
		d.onStart = function(e:Dynamic) {
			_drawHeaderStatic();
			_updateHeader();
		}//--
		
	}//---------------------------------------------------;
	
	/**
	 * Reorders the infos on the screen, so that there are no blanks between them
	 * @when Gets called whenever a single download stops.
	 * @param indexCompleted That index on the array was just completed
	 */
	function reorder(indexCompleted:Int)
	{
		// Last element, no need to shift array
		if (indexCompleted == maxSlots - 1) return;
		
		for (i in indexCompleted...maxSlots - 1)
		{
			// There is no need to shift inactive items
			if (infoArray[i + 1].isActive == false) break;
			// Fix the hash first
			hash.remove(infoArray[i + 1].ref.UID);
			hash.set(infoArray[i + 1].ref.UID, i);
			// Shift the array
			infoArray[i].stop();
			infoArray[i].queuePos = infoArray[i + 1].queuePos;
			infoArray[i].start(infoArray[i + 1].ref);
			infoArray[i + 1].stop();
		}
		
	}//---------------------------------------------------;
	
}//-- end class//