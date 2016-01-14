/****
 * IArchiver
 * -------
 * johndimi, johndimi@outlook.com
 * -------
 * 
 * Basic interface for archivers,
 *
 * @events: 
 *			complete(suceess:bool,?msg:String)
 * 			progress(percentage:int)
 *			init_status(success:bool)
 * 
 * ---------------------------------------*/
 
package djNode.app;

import js.node.events.EventEmitter;

// -- Basic Interface for archivers like 7zip.
interface IArchiver 
{
	public var events:IEventEmitter;
	public function compress(ar:Array<String>, ?destinationFile:String):Void;
	public function uncompress(input:String, ?destinationFolder:String):Void;
}