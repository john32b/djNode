/**--------------------------------------------------------
 * JSONFetcher.hx
 * @author: johndimi, <johndimi@outlook.com> , @jondmt
 * --------------------------------------------------------
 * @Description
 * -------
 * @supports: nodejs, system
 * 
 * @Notes
 * ------
 * 
 ========================================================*/
package dj.net;

import dj.tools.LOG;
import haxe.Http;
import haxe.Json;

#if !flash
	import sys.FileSystem;
	import sys.io.File;
#end

#if js
	import js.Node;
#end

/**
 * Simple JSON fetcher
 * 
 * ...
 * @author johndimi
 * 
 * @platforms: Nodejs, ??
 */
class JSONFetcher
{
	// The parsed json data
	public var data(default,null):Dynamic = null;	
	// User call when the data is loaded, pushes the data receieved?
	public var onLoad:Dynamic->Void = null; 
	public var onError:Dynamic->Void = null;
	
	// the http object
	private var http:Http;
	// stores the url from the last request
	private var url:String;
	
	//-- FUNCTIONS ---------------------------------------;
	
	public function new(?onLoad_:Dynamic->Void, ?onError_:Dynamic->Void)
	{
		onLoad = onLoad_;
		onError = onError_;
	}//---------------------------------------------------;
	
	public function loadURL(url_:String)
	{
		url = url_;
		LOG.log('Requesting url:"$url"');		
		http = new Http(url);
		//	http.onData = _onData; // not yet,
		http.onError = _onError;
		http.onStatus = _onStatus;
		
		http.request(false);
	}//---------------------------------------------------;
	
	
	private function _onStatus(status:Int)
	{
		LOG.log('HTTP STATUS : $status', 1 );
		
		if (status == 200) {
			http.onData = _onData;
		}
		
	}//---------------------------------------------------;
	
	private function _onError(e:String)
	{
		LOG.log('HTTP ERROR : $e', 3 );
		if (onError != null) onError(e);
	}//---------------------------------------------------;

	private function _onData(data_:String)
	{
		LOG.log("HTTP REQUEST : got data ", 1);
		try{
		data = Json.parse(data_);
		}catch (e:Dynamic) {
			// Data is not Json Format.
			if (onError != null) onError("Data is not JSON");
			return;
		}
		if (onLoad != null) onLoad(data);  
	}//---------------------------------------------------;
	
	
	#if !flash
	public function loadFile(file:String)
	{
		if (!FileSystem.exists(file))
		{
			LOG.log('File $file Does not exist', 3);
			onError("File does not exist");
			return;
		}
		
		_onData(File.getContent(file));
		
	}//---------------------------------------------------;
	#end
	
}//-- end class --//