package;

/**
 * Simple interface for things pushing progress/complete callbacks
 * - ffmpeg, archivers, downloaders, etc
 */
interface ISendingProgress 
{
  	public var onComplete:Bool->Void;
	public var onProgress:Int->Void;
	public var ERROR:String;
}