package djNode.net;

import djNode.net.IDownloadable;
import djNode.tools.FileTool;
import djNode.tools.ArrayExecSync;
import djNode.tools.Calc;
import djNode.tools.LOG;
import haxe.Timer;
import js.node.events.EventEmitter;

/**
 * Download Manager
 * -----------
 * Handles IDownloadable objects, 
 * Automatically queues them, so they won't download all at once.
 * 
 */

class DownloadManager // change name to DownloadQueue
{
	var queue:Array<IDownloadable>;
	var activeItems:Map<Int,IDownloadable>;
	
	// Basic UID generator for handing out to downloadables
	var UID_GENERATOR:Int = 0;
	
	// Keep the number of active items
	var totalActiveItems:Int = 0;
	var bytes_total:Int = 0;//unused 
	var bytes_got:Int = 0;//unused
	var timerProgress:Timer;
	
	// If this is set, all elements are to be downloaded here:
	public var unified_destination:String = null;
	
	// If it's currently downloading
	public var isWorking(default, null):Bool = false;
	public var stats_totalItems(default, null):Int = 0;
	public var stats_downloadedItems(default, null):Int = 0;
	public var MAX_PARALLEL_DOWNLOADS(default, null):Int = 4;

	public var events:IEventEmitter;	
	
	// - Callbacks -
	public var onStart:Dynamic->Void = null;		// onStart(this)
	public var onComplete:Dynamic->Void = null;		// onComplete(this)
	public var onProgress:Array<Int>->Void = null;	// onProgress([completed,total]);
	public var onError:Dynamic->Void = null;		// onError( );
	// Pass through callbacks for the downloadables callbacks
	public var onSingleStart:IDownloadable->Void = null;
	public var onSingleProgress:IDownloadable->Void = null;
	public var onSingleComplete:IDownloadable->Void = null;

	// Check for progress every X time.
	static inline var PROGRESS_UPDATE_INTERVAL:Int = 400;	
	
	// If true, the onProgress() will send downloadedBytes and totalBytes
	var flag_report_progress_bytes:Bool = false;
	//----------------------------------------------------;
	//----------------------------------------------------;
	
	
	/**
	 * Construct this with an object of parameters.
	 * @param obj { maxparallel:Int, unified_destination:String }
	 */
	public function new(?obj:Dynamic) 
	{
		if (obj != null) {
			if (obj.maxparallel != null) MAX_PARALLEL_DOWNLOADS = obj.maxparallel;
			if (obj.destination != null) unified_destination = obj.destination;
		}
		
		events = new EventEmitter();
		queue = new Array();
		activeItems = new Map();
	}//---------------------------------------------------;

	// --
	// When the download queue is complete, this resets the stats
	public function reset()
	{
		if (isWorking)
		{
			LOG.log("DownloadManager is still working", 2);
			return;
		}
		
		isWorking = false;
		stats_totalItems = 0;
		stats_downloadedItems = 0;
		
		_progressTimerStop();
	}//---------------------------------------------------;
	
	/**
	 * Adds an @IDownloadable object to the queue
	 */
	public function add(item:IDownloadable)
	{
		LOG.log("Adding Idownloadable");
		stats_totalItems++;
		item.UID = ++UID_GENERATOR;
		item.onComplete = _callback_complete;
		item.onError 	= _callback_error;
		
		//INDEV: Manager will check the progress at a time interval
		item.onProgress = _callback_progress;
		LOG.log('TotalItems = $stats_totalItems');
		queue.push(item);
	}//---------------------------------------------------;
	
	
	/**
	 * Adds a DownloadJob to the queue,
	 * @param url The file to be downloaded
	 * @param destination Where to store the filr.
	 */
	public function addUrl(url:String, ?destination:String)
	{
		if (destination == null) destination = unified_destination;
		add(new DownloadJob( { url:url, destination:destination } ));
	}//---------------------------------------------------;
	
	/**
	 * Download an array filled with filenames to target _destination.
	 * @param arr The array holding the URL's
	 * @param destination If it does not exist, it will be created.
	 */
	public function addUrlArray(arr:Array<String>, ?destination:String)
	{
		if (destination == null) destination = unified_destination;
		// DEVELOP: Does it really need to check for the folder??
		// FileTool.createRecursiveDir(destination);
		// nope, check it elsewhere
		for (i in arr) addUrl(i, destination);
	}//---------------------------------------------------;
	
	
	/**  
	 * @IDownloadable Callbacks ==========================;
	 **/
	private function _callback_complete(uid:Int)
	{
		LOG.log("Item completed, UID = " + uid);
		stats_downloadedItems++;
		if (onSingleComplete != null) onSingleComplete(activeItems.get(uid));
		
		if (!flag_report_progress_bytes && onProgress != null)
			onProgress([stats_downloadedItems, stats_totalItems]);
			
		totalActiveItems--;
		activeItems.remove(uid);
		feed();	// Renew the queue
	}//---------------------------------------------------;
	private function _callback_progress(uid:Int,stats:Array<Int>)
	{
		if (onSingleProgress != null) onSingleProgress(activeItems.get(uid));
	}//---------------------------------------------------;
	private function _callback_error(uid:Int,str:String)
	{
		// TODO: Implement error catching
		// 	Have critical levels on downloads,
		// 	Autoretry a download? Fail the program? Skip it?
		// 	Download from somewhere else?
	}//---------------------------------------------------;


	/** 
	 * Feeds the activepool with items from
	 * the waiting queue, and starts them,
	 */
	public function feed():Void
	{
		LOG.log("Feeding the queue..");
		
		// -- Completion Check
		if (queue.length == 0 && totalActiveItems == 0) 
		{
			LOG.log("All Items Complete");
			// _progressTimerStop();
			if (onComplete != null) onComplete(this);
			return;
		}
		
		//-- Feed the queue with waiting download jobs
		// Note, it is guaranteed that 1 slot will be free,
		// 		 but could be more, so check for multiple empty slots.
		
		var emptySlots:Int = MAX_PARALLEL_DOWNLOADS - totalActiveItems;
		LOG.log('Empty slots = $emptySlots');
		while (emptySlots-- > 0)
		{
			if (queue.length > 0)
			{
				var j:IDownloadable = queue.shift();
				activeItems.set(j.UID, j);
				totalActiveItems++;
				j.start();
				LOG.log("Adding to active queue, item with UID = " + j.UID);
				if (onSingleStart != null) onSingleStart(j);
			} 
			else break; // no need to count through the rest of the empty slots.
		}
	}//---------------------------------------------------;
	
	
	
	//============ TIMER FUNCTIONS =======================;
	//==
	private function _progressTimerStart()
	{
		_progressTimerStop(); // this frees the timer, in case it exists
		timerProgress = new Timer(PROGRESS_UPDATE_INTERVAL);
		timerProgress.run = function() {
			// TODO: INDEV:
			// - I don't think there is a way to properly estimate this,
			// because the size of the items waiting in the queue is unknown.
			// I can only calculate the download speed,
		}//--
	}//---------------------------------------------------;
	
	private function _progressTimerStop()
	{
		if (timerProgress != null) {
			timerProgress.stop();
			timerProgress = null;
		}
	}//---------------------------------------------------;
	/**
	 * Check active downloads for a progress update
	 */
	private function onTimer_checkProgress()
	{
		
	}//---------------------------------------------------;
	
	/** @IDownloadable 
	 */
	public function start():Void
	{
		LOG.log("Starting the queue..");
		isWorking = true;
		feed();
		if (onStart != null) onStart(this);
		// Start the timer to update progress
		// if (flag_report_progress_bytes) _progressTimerStart()
	}//---------------------------------------------------;
	/** @IDownloadable
	 */
	public function stop():Void
	{
		LOG.log("Does not actually work", 2);
		isWorking = false;
		// TODO: actually stop all downloads
		// _progressTimerStop();
		for (i in activeItems) {
			i.stop();
		}
	}//---------------------------------------------------;
	
	#if debug
	public function debug_start_simulation(numberOfItems:Int)
	{
		// Randomize fake filesizes
		var rnd_min_size:Int = 100000; 
		var rnd_max_size:Int = 1500000;
		
		LOG.log('Starting simulation with numberOfItems=$numberOfItems, parallel=$MAX_PARALLEL_DOWNLOADS');
		//Assumes that the queue and active queue is empty.
		do {
			// Set fake download speed to 1.5MB\s +- 500KB\s
			add(new DownloadJob({
				debug:true,
				size:Calc.randomRange(rnd_min_size, rnd_max_size),
				bps:Calc.randomRange(50000, 150000)
				}));
		}while (--numberOfItems > 0);
		start();
	}//---------------------------------------------------;
	#end
   
}//--end class --//