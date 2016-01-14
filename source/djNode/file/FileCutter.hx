/****
 * FileCutter
 * -------
 * johndimi, johndimi@outlook.com
 * -------
 * @requires: none
 * @supportedplatforms: nodeJS
 * 
 * Cuts pieces from a binary file into another 
 * file. You can specify the start and end byte 
 * of the piece you want to cut
 * 
 * 	complete -> (),			~ When the whole operation is completed
 * 	error -> (Error)		~ An arror occured, Error.message has info
 * ---------------------------------------*/

package djNode.file;

import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.Error;
import js.Node;
import js.node.Buffer;
import js.node.events.EventEmitter;
import js.node.Fs;
import js.node.fs.WriteStream;

class FileCutter
{
	private static inline var BUFFERSIZE:Int = 65536;
	
	// In case of error, this gets occupied with the error data
	public var error_log(default, null):String;
	
	// In case of error, this gets occupied with an error code (user custom created)
	public var error_code(default, null):String;

	//---------------------------------------------------;
	
	public var events:IEventEmitter;
	
	var inputFile:String;			//File to be cutted
	var dest_stream:WriteStream;	//stream of the destination file
	var outputFile:String;
	var bytes_toRead:Int = 0;
	var file_startPos:Int = 0;

	//====================================================;
	// FUNCTIONS 
	//====================================================;
	// --
	public function new() {
		events = new EventEmitter();
	}//---------------------------------------------------;
	
	/**
	 * @ASYNC
	 * @param	destination Full path for the destination file
	 * @param	byteStart The byte to start reading
	 * @param	bytes How many bytes to read from byteStart
	 */
	public function cut(source:String, destination:String, byteStart:Int, bytes:Int) 
	{
		LOG.log('Cutting $source INTO $destination, bytestart=$byteStart, bytes=$bytes');
		
		inputFile = source;
		outputFile = destination;
		file_startPos = byteStart;
		bytes_toRead = bytes;
		
		/// TODO check for Free space ?
		/// TODO check if request to read more than file contains ?
		
		Fs.writeFileSync(destination, "");
		dest_stream = Fs.createWriteStream(destination);

		Fs.open(inputFile, "r", _readFunction);	// Async
	}//---------------------------------------------------;
	
	// --
	function _readFunction(err:Error, data:Int):Void 
	{	
		if (err != null) 
		{ 
			error_log = err.message;
			events.emit("close", false);
			return;
		}
		
		var buffer:Buffer;
		var lastreadsize:Int = Std.int(bytes_toRead % BUFFERSIZE);
		var bytes_processed = 0;
		var __t = bytes_toRead - lastreadsize;	// Speed up things
				
		while (bytes_processed < __t ) {
			buffer = new Buffer(BUFFERSIZE); // Super important to create a new buffer each time
			bytes_processed += Fs.readSync(data, buffer, 0, BUFFERSIZE, file_startPos + bytes_processed);
			dest_stream.write(buffer);
		}
	
		// If there are leftover bytes to be read, read them now 
		if (lastreadsize > 0) {			
			buffer = new Buffer(lastreadsize);
			bytes_processed += Fs.readSync(data, buffer, 0, lastreadsize, file_startPos + bytes_processed);
			dest_stream.write(buffer);
		}
		// Close the stream
		Fs.closeSync(data);
		
		//Close the stream
		dest_stream.once("close", function() { events.emit("close", true); } );
		dest_stream.end();
	}//---------------------------------------------------;
	
	// --
	public function kill()
	{
		events.removeAllListeners("close");
		events = null;
		if (dest_stream != null) { dest_stream.end(); };
	}//---------------------------------------------------;
	
}//-- FILE CUTTER --//