/********************************************************************
  
  Download things from HTTP/HTTPS
  
  - Handles errors
  - Reports progress
  - Custom timeouts
  - Callbacks the entire object when (success/fail) for versatility
  
  - Is an object so that you can use it to probe for progress.
  - Has a quick static function in `HttpTool`
  
  EXAMPLE:
  
	// Download a link to a folder
  	var dl = new HttpDownload("https://www.files.com/file123.zip, "c:\\temp");
	dl.start( (o)->{
		if (o.ERROR == null) {
			trace('Downloaded [OK]');
		}else{
			trace('[ERROR]' + o.ERROR);
		}
	});
				
				

 *******************************************************************/

package djNode.net;

import djA.DataT;
import djNode.net.HttpTool;
import djNode.tools.FileTool;
import djNode.tools.HTool;
import js.lib.Date;
import js.lib.Error;
import js.node.Buffer;
import js.node.Fs;
import js.node.Path;
import js.node.fs.WriteStream;
import js.node.http.ClientRequest;
import js.node.http.IncomingMessage;


class HttpDownload
{
	static public var PROGRESS_FREQUENCY = 500;		// Limit how ofter onProgress should trigger. In milliseconds
	
	public var callback:HttpDownload->Void;	// Check .ERROR var, if null then success
	public var onProgress:Int->Void;		// 0-100 Callbacks
	
	public var bytes_total(default, null):Int = 0;
	public var bytes_got(default, null):Int = 0;
	public var progress(default, null):Int = 0;	// 0 - 100%
	
	public var url(default, null):String;		// URL to download
	public var filepath(default, null):String; 	// Full file destination path
	public var filename(default, null):String;	// Just the filename of the file on disk
	
	public var ERROR:String;	// Read this on the callback Success
	
	var timeProgLast:Float;		// Epoch time the last progress update was pushed
	
	var req:ClientRequest;
	var file:WriteStream;
	
	var options = {
		target_rename:false,	// Autorename the new filename to something unique if path already exists
		target_skip:false,		// Callback success true if target filename already exists
		timeout:8000			// 8 Seconds with no response to callback fail
	}
	
	/**
	   @param	_url URL to download HTTP or HTTPS
	   @param	_dest Destination Folder
	   @param	_saveas New filename instead of original if null it will be guessed from the URL
	   @param	_opt can override fields of {options}. Check inside.
	**/
	public function new(_url:String, _dest:String, ?_saveas:String, ?_opt:Dynamic) 
	{
		url = _url;
		if (url == null) throw new Error("URL null");
		
		if (_saveas != null) {
			filename = _saveas;
		}else{
			filename = url.split('/').pop();
		}
		
		if (_opt != null) options = DataT.copyFields(_opt, options);
		
		filepath = Path.normalize(Path.join(_dest, filename));
	}//--------------------------------------------------;
	
	
	/**
	   Start the Download
	   @param	_cb Callback for Success/Error
	   @param	_onP onProgress Optional
	**/
	public function start(?_cb:HttpDownload->Void, ?_onP:Int->Void):HttpDownload
	{
		if (_cb != null) callback = _cb;
		if (_onP != null) onProgress = _onP;
		
		if (options.target_skip) {
			if (Fs.existsSync(filepath)) end("Target already exists");
			return this;
		}
		
		// First check if target file exists, and if it does rename the new file
		if (options.target_rename) {
			filepath = FileTool.getUniquePath(filepath);
		}
		
		var req = @:privateAccess HttpTool.getRequestObj(url, {timeout:options.timeout});
		
		timeProgLast = 0;
		
		trace("DL Start " + this);
		
		req.once('response', (r:IncomingMessage)->{
			
			if (r.statusCode != 200) {
				return end("Status Code : " + r.statusCode + ' : ' + r.statusMessage);
			}
			
			trace('DL Connected ' + this);
			
			try{
				file = Fs.createWriteStream(filepath);
			}catch (e:Error){
				return end('Cannot write to file "$filepath"');
			}
			
			bytes_total = Std.parseInt(r.headers['content-length']);
			
			r.on('data', (d:Buffer)->{
				bytes_got += d.length;
				file.write(d);
				// --
				progress = Math.ceil((bytes_got / bytes_total) * 100);
				if (progress > 100) progress = 100;
				
				// Try to buffer the progress 
				var t = Date.now();
				if (t >= timeProgLast + PROGRESS_FREQUENCY) {
					timeProgLast = t;
					HTool.sCall(onProgress, progress);
				}
				
			});
			
			r.once('end', end);
			r.once('error', (e:Error)->end(e.message));
		});
		
		req.on('timeout', ()->req.destroy(new Error('Timeout')));
		req.on('error', (e:Error)->end(e.message) );
		req.end();
		
		return this;
	}//---------------------------------------------------;

	
	function end(?f:String)
	{
		trace('Download End | $this');
		if (file != null) file.end();
		if (req != null) {
			req.abort();
			req.removeAllListeners();
		}
		
		ERROR = f;
		if (ERROR != null){
			trace('  > ERROR ' + ERROR);
		}
		HTool.tCall(callback, this);
	}//---------------------------------------------------;
	
	
	public function toString()
	{
		return '$url >> $filepath';
	}//---------------------------------------------------;
		
}// --