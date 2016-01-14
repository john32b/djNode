package djNode.net;

import djNode.net.IDownloadable;
import djNode.tools.FileTool;
import djNode.tools.StrTool;
import djNode.tools.LOG;
import haxe.Timer;
import js.Node;
import js.node.Buffer;
import js.node.events.EventEmitter;
import js.node.Fs;
import js.node.fs.WriteStream;
import js.node.Http;
import js.node.http.IncomingMessage;
import js.node.Path;
import js.node.Url;


/**
 * DownloadJob, is responsible for downloading a single file
 * Emmits events AND callbacks.
 * 
 * @platforms nodejs
 * @Callbacks:
 * ----------------------
 * onProgress => (UID,[got,total])
 * onComplete => (UID)
 * onError    => (UID,ERRORCODE) [ Errorcodes: "FILE_EXISTS", "DISK_ERROR", "HTTP_ERROR", "URL_BAD", "TIMEOUT" ]
 * 
 * events => 
 *				"ERROR", {type:String, message:String, source:DownloadJob}
 * 				"COMPLETE
 * 
 * ---------------------
 */

class DownloadJob implements IDownloadable
{
	// Unique UID, incase this belongs to a DownloadManager
	public var UID:Int;
	// Total file length
	public var bytes_total(default, null):Int = 0;
	// Current downloaded file length
	public var bytes_got(default, null):Int = 0;
	// URL to download
	public var url(default, null):String;
	// Local file path to download the file
	public var destinationFile(default, null):String;
	
	public var onProgress:Int->Array<Int>->Void;// onProgress(UID,Array<Int>);
	public var onComplete:Int->Void;			// onComplete(UID);
	public var onError:Int->String->Void;		// onError(UID,ErrorCode);
	
	// -- object vars
	public var events:IEventEmitter;
	var file:WriteStream;

	// -- Flags --
	// Overwrite the file without asking if already exists.
	public var flag_force_overwrite:Bool = true;
	// If an event with an error, this describes the error
	public var errorMessage:String = null;
	
	// - Development Purposes, simulation variables
	#if debug
	public var flag_simulate_download:Bool = false;
	public var param_fake_size:Int = 16777216; 		// Fake size in bytes
	public var param_fake_bps:Int = 150000;		    // Fake bytes / sec
	public var param_fake_updateSpeed:Int = 400;	// Report progress every X millisecs
	var fakeTimer:Timer;							// A timer object
	#end
	
	//----------------------------------------------------;
	
	/**
	 * Construct this with an object of parameters.
	 * @param obj { url:String, destination:String, UID:int, || debug: bps,size}
	 */
	public function new(obj:Dynamic)
	{
		//-- Params:
		// obj.url; 		#required
		// obj.destination; #required
		// obj.UID;
		#if debug
			flag_simulate_download = obj.debug;
			if (flag_simulate_download) 
			{
				if (obj.bps != null) param_fake_bps = obj.bps;
				if (obj.size != null) param_fake_size = obj.size;
				obj.url = "http://server.simulation.001";
				obj.destination = "c:\\app\\downloads";
			}
		#end
		
		// Init
		events = new EventEmitter();
		file = null;
		
		UID = obj.UID;
		url = obj.url;
		
		if (url != null) 
		{
			var filename = url.split('/').pop();
			destinationFile = Path.join(obj.destination, filename);
		}

	}//---------------------------------------------------;

	
	#if debug
	private function start_simulate()
	{
		LOG.log("Starting SIMULATED Download --", 1);
		bytes_total = param_fake_size;
		bytes_got = 0;
		
		fakeTimer = new Timer(param_fake_updateSpeed);
		fakeTimer.run = function() {
			bytes_got += param_fake_bps;
			if (bytes_got >= bytes_total) {
				bytes_got = bytes_total;
				fakeTimer.stop();
				fakeTimer = null;
				if (onComplete != null) onComplete(UID);
			}else {
				if (onProgress != null) onProgress(UID, [bytes_got, bytes_total]);
			}
		}
		
	}//---------------------------------------------------;
	#end

	/**
	 * @IDownloadable
	 */
	public function stop()
	{
	
	}//---------------------------------------------------;

	/**
	 * @IDownloadable
	 */
	public function start():Void
	{
		LOG.log('Downloadjob, start, ($url)');
		
		// -- Testing purposes , simulate download
		#if debug 
		if (flag_simulate_download) {
			start_simulate();
			return;
		} 
		#end
		//-------------------
		
		
		// Pre Check: file already exists
		if (FileTool.pathExists(destinationFile) && flag_force_overwrite == false)
		{	
			LOG.log('File already exists: $destinationFile', 3);
			events.emit("error", { type:"FILE_EXISTS" } );
			if (onError != null) onError(UID, "FILE_EXISTS");
			return;
		}
		
		// Pre Check: Can't write, or disk error.
		try {
			file = Fs.createWriteStream(destinationFile);			
		}catch (e:Dynamic)
		{
			LOG.log("DISK_ERROR" + e, 3);
			events.emit("error", { type:"DISK", message:"Can't write to disk" } );
			if (onError != null) onError(UID, "DISK_ERROR");
			return;
		}
		
		//var url_obj:UrlData = Url.parse(url);
		//Http.get(cast url_obj, onHttpResponse);
		Http.get(url, onHttpResponse);
	}//---------------------------------------------------;
	
	private function onHttpResponse(res:IncomingMessage):Void
	{
		// res object example on [code-notes]
		bytes_total = Std.parseInt(Reflect.getProperty(res.headers, "content-length"));
		
		res.pipe(file);
		
		res.on('data', function(chunk:Buffer) {
			bytes_got += chunk.length;
			if (onProgress != null) onProgress(UID, [bytes_got, bytes_total]);
		});
		
		res.on('error', function(e:Dynamic) {
			LOG.log('HTTP ERROR, ' + e.message, 3);
			events.emit("error", { type:"HTTP", message:e.message } );
			if (onError != null) onError(UID, e.message);
		});
	
		file.on('finish', function() {
			file.end();
			bytes_got = bytes_total;
			events.emit("complete", this);
			events.removeAllListeners("complete");
			events.removeAllListeners("error");
			if (onComplete != null) onComplete(UID);
		});
	}//---------------------------------------------------;
	
}//-- end class --//