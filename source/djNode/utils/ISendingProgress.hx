package djNode.utils;

/**
 * Simple interface for things pushing progress/complete callbacks
 * - ffmpeg, archivers, downloaders, etc
 */
interface ISendingProgress 
{
  	public var onComplete:Void->Void;
	public var onFail:String->Void;
	public var onProgress:Int->Void;
	public var ERROR(default, null):String;
}