package djNode.net;

/**
 * Downloadable Interface
 * -----------------
 * Simple and efficient way of interfacing
 * and controlling downloads.
 * --
 * This can be attached to a download manager for 
 * queueing and prioritizing purposes.
 */

interface IDownloadable 
{
	// A unique ID among the downloadable set.
	public var UID:Int;
	public var bytes_total(default, null):Int;
	public var bytes_got(default, null):Int;
	
	public var onProgress:Int->Array<Int>->Void;// onProgress(UID,Array<Int>);
	public var onComplete:Int->Void;			// onComplete(UID);
	public var onError:Int->String->Void;		// onError(UID,ErrorCode);
	
	public var url(default, null):String;		// The url that is being downloaded

	//-- functions --
	public function start():Void;
	public function stop():Void;
	
	// TODO: future expansions ?
	// function pause();
	// function resume();
	
	// INDEV: should I add a progress var?
	// remember: percent = Math.ceil( ((bytes_got / bytes_total) * 100) );
	

}//--