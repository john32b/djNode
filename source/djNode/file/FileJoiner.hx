/****
 * FileJoiner
 * -------
 * johndimi, johndimi@outlook.com
 * -------
 * 
 * Joins files into a single file
 * You can join an array of files and the
 * files will be pushed to the new file sequentally
 *
 * @events. the public (events) object emits events
 * 
 * 	close 	 -> (bool) 		~ True if completed successfully,
 * 							  False on error.
 * 	progress -> (Int,Int)  	~ When a single operation in the queue is completed, 
 * 							  (currentfile, maxfiles)
 * ---------------------------------------*/

package djNode.file;

import djNode.tools.ArrayExecSync;
import djNode.tools.FileTool;
import djNode.tools.LOG;

import js.Error;
import js.Node;
import js.node.Buffer;
import js.node.events.EventEmitter;
import js.node.Fs;
import js.node.fs.WriteStream;


class FileJoiner
{
	
	static inline var BUFFERSIZE:Int = 65536;
	//---------------------------------------------------;
	
	var dest_filename:String; 		// Will be created.
	var dest_stream:WriteStream;
	
	// -- Emits 
	// progress (int,int) (current,total)
	// close (bool), success, if false, check error_log
	public var events:IEventEmitter;
	
	// In case of error, this gets occupied with the error data
	public var error_log(default, null):String;
	
	// In case of error, this gets occupied with an error code (user custom created)
	public var error_code(default, null):String;
	
	// -- Delete the files that were merged to a destination file
	public var flag_delete_processed:Bool = true;
	
	var arrayExec:ArrayExecSync<String>;
	
	// Pointer to the path of the file being added to the destination
	var fileBeingProcessed:String;
	

	
	//====================================================;
	// FUNCTIONS
	//====================================================;
	
	public function new() {
		events = new EventEmitter();
	}//-----------------------------
	
	/**
	 * Joins multiple files into one.
	 * 
	 * @param	dest	Destination file, or full path
	 * @param	files	Array of files to be joined into dest file (fullpath) ORDERING!!!!!!
	 */
	public function join(dest:String, files:Array<String>):Void 
	{
		if (files.length == 0) return;

		/// TODO check for Free space ??
		
		dest_filename = dest;

		// Create the destination as an empty file 
		Fs.writeFileSync(dest_filename, "");
		dest_stream = Fs.createWriteStream(dest_filename);
		
		LOG.log('Appending ${files.length} files to "$dest_filename"');
		
		// -- NEW WAY --
		arrayExec = new ArrayExecSync(files);
		
		arrayExec.queue_action = function(f:String) {
			LOG.log('Appending "$fileBeingProcessed"');
			fileBeingProcessed = f;
			if (!FileTool.pathExists(f)) {
				error_log = 'File "$f" does not exist';
				dest_stream.end();
				events.emit("close", false);
				return;
			}	
			Fs.open(f, "r", _readFunction);
		}// --
		
		arrayExec.queue_complete = function() {
			// Wait for stream to end then emit OK
			dest_stream.once("close", function() { events.emit("close", true); } );
			dest_stream.end();
		}// --
		
		arrayExec.start();
	}//---------------------------------------------------;
	

	// --
	function _readFunction(er:Error, data:Int):Void 
	{
		if (er != null)  { 
			error_log = er.message;
			events.emit("close", false);
			return;
		}
		
		var stats = Fs.fstatSync(data);
		var buffer:Buffer;
		var lastreadsize:Int = Std.int(stats.size % BUFFERSIZE);	
		var bytes_processed = 0;		
		var __t = stats.size - lastreadsize; // Speed up things a bit by precalculating this.
	
		// logic
		while (bytes_processed < __t) {
			buffer = new Buffer(BUFFERSIZE);	// super important to create a new buffer each time
			bytes_processed += Fs.readSync(data, buffer, 0, BUFFERSIZE, bytes_processed);
			dest_stream.write(buffer);
		}
		
		// Redo this for the rest of the bytes
		// TODO, make this better by reducing redundancy
		if (lastreadsize > 0) {
			buffer = new Buffer(lastreadsize);
			bytes_processed += Fs.readSync(data, buffer, 0, lastreadsize, bytes_processed);
			dest_stream.write(buffer);	
		}
		
		events.emit("progress", arrayExec.counter);
		
		// Close the stream
		Fs.closeSync(data);
		
		// -- Delete the next file??
		if (flag_delete_processed)
		{
			LOG.log('Deleting "$fileBeingProcessed"..');
			Fs.unlinkSync(fileBeingProcessed);
		}
		
		arrayExec.next();
	}//-----------------------------
	
	
	// --
	public function kill()
	{
		events.removeAllListeners("progress");
		events.removeAllListeners("close");
		events = null;
		if (dest_stream != null) { dest_stream.end(); };
	}//---------------------------------------------------;
	
}//--end class--//