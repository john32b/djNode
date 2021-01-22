/********************************************************************
  HTTP Tools
  
 - For getting HTML pages mostly
 
 
  Examples:
  
	  HttpTool.requestPage(URL, (data)->{
				if (data == null) { trace('ERROR : returned error [$gamepage]'); } else
				if (data.substr(0, 1) == "|") { trace('Page Riderected to : ' + res.substr(1)); }
				else { trace("URL Returned data " , data); }
		});

 *******************************************************************/

package djNode.net;

import js.lib.Error;
import js.node.Http;
import js.node.Https;
import js.node.http.ClientRequest;
import js.node.http.IncomingMessage;


class HttpTool 
{
	public static var USER_AGENT = "nodejs script for personal use";
	public static var REQUEST_TIMEOUT = 8000;	// 8 seconds to default timeout a request
	
	/**
	   Requests a URL, returns HTML content with callback
	   If the link is a Redirect, the callback will be "|newlink" so you have to remove the first "|" and follow that link again
	   @param	url HTTPS, or HTTP
	   @param	callback HTML content or null for error or "|newlink"
	**/
	public static function requestPage(url:String, callback:String->Void)
	{
		//trace('Requesting :  $url');
		
		function handle_res(res:IncomingMessage)
		{	
			// - Check if this is a redirect
			if (res.headers['location'] != null)
			{
				return callback("|" + res.headers['location']);
			}
			
			var buffer = "";
			
			//res.setEncoding('ucs2'); //Sometimes the content I get is ucs2, can I do this automatically??
			res.on('data', (d)->buffer += d);
			res.on('end', ()->callback(buffer));
		}
		
		var REQ = getRequestObj(url, {timeout:REQUEST_TIMEOUT});

		REQ.setHeader('User-Agent', USER_AGENT);
		
		REQ.once('timeout', ()->{
			// To test timeout request a blocked port e.g. www.google.com:81 | or unreachable like 10.255.255.1
			REQ.destroy(new Error('Timeout'));
		});

		REQ.once('response', handle_res);
		REQ.on('error', (e)->{ trace('HttpError, "$url"', e); callback(null); });
		REQ.end();
	}//---------------------------------------------------;
	
	
	
	/**
	   Automatically get a HTTP or HTTPS Client Request
	   DEV: Separate function because `HttpDownload` uses it
	   @param	url
	   @param	options
	   @return
	**/
	static function getRequestObj(url:String, ?options:Dynamic):ClientRequest
	{
		if (url.toLowerCase().indexOf('https:') == 0) {
			return Https.request(url, options);
		}else{
			return Http.request(url, options);
		}
	}//---------------------------------------------------;
	
	
	
}