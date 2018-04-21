/****
 * FileCopyPart
 * ----------------
 * 
 * Appends a part of a file to another file.
 * - You can specify the start and end bytes of the source file
 * - The data will be appended to the destination file.
 * - If the destination doesn't exist, it will be created
 * 
 * Example:
 * 
 * 	var fc = new FileCopyPart();
 * 
 *  fc.events.once("complete",function(error:String){
 * 		if(error!=null){
 * 			// Something bad happened
 * 		}
 *  });
 *  // ^ The operation is async so be sure to listen to the events
 * 
 * 	fc.start("inpuFile.bin", "newFile.bin", 0,500000);
 *  // ^ This will copy/append the first 500000 bytes of inputfile into file2
 * 
 * @target: nodejs
 * ---------------------------------------*/


package djNode.file;

import djNode.tools.LOG;
import js.Error;
import js.Node;
import js.node.Buffer;
import js.node.events.EventEmitter;
import js.node.Fs;
import js.node.fs.WriteStream;


class FileCopyPart 
{
	//
	private static inline var BUFFERSIZE:Int = 65536;
	
	// Sends
	// 'complete' : error<String> 	// If error==null, then operation [OK]
	public var events:IEventEmitter;
	
	var dest_stream:WriteStream;
	
	// --
	public function new() 
	{
		events = new EventEmitter();
	}//---------------------------------------------------;
	
	/**
	   Make sure to listen to .events("complete")
	   @ASYNC
	   @param	inputFile	Source file, bytes copied from
	   @param	outputFile	Appends to this file, or creates it
	   @param	readStart	Start Byte Position of source file
	   @param	readLen		End Byte Position of source file ( 0 for entire file )
	   @param	forceNewFile If true, output file will be cleared out if already exists. Else Appended
	**/
	public function start(inputFile:String, outputFile:String, readStart:Int = 0, readLen:Int = 0, forceNewFile:Bool = false )
	{
		var inputSize:Int = 0;
		
		try{
			inputSize = Std.int(Fs.statSync(inputFile).size);
		}catch (e:Error)
		{
			events.emit("complete", e);
		}
		
		// - Autogen read len to the rest of the file
		if (readLen == 0) {
			readLen = inputSize - readStart;
		}
		else if (readLen + readStart > inputSize)
		{
			events.emit("complete", 'Trying to copy more bytes than the input file has.');
			return;
		}
		
		LOG.log('Copying `$inputFile` Bytes [$readStart [len]-> $readLen] to `$outputFile`');
		
		// --
		dest_stream = Fs.createWriteStream(outputFile, {
			flags:forceNewFile?FsOpenFlag.WriteCreate:FsOpenFlag.AppendCreate
		});
		dest_stream.once("error", function(err:Error){
			events.emit("complete", 'Cannot create/write to `$outputFile`');
			return;
		});
		
		// -
		Fs.open(inputFile, FsOpenFlag.Read, function(err:Error, data:Int){
			
			if (err != null)
			{
				events.emit("complete", 'Could not open file `$inputFile`');
				return;
			}
			
			var buffer:Buffer;
			var bytesCopied:Int = 0;
			var bytesLeft:Int = readLen;
			
			while (bytesLeft > 0)
			{
				if (bytesLeft >= BUFFERSIZE)
				{
					buffer = new Buffer(BUFFERSIZE);
				}else
				{
					buffer = new Buffer(bytesLeft);
				}
				
				bytesCopied += Fs.readSync(data, buffer, 0, buffer.byteLength, readStart + bytesCopied);
				bytesLeft -= buffer.byteLength;
				dest_stream.write(buffer);
			}
			
			Fs.closeSync(data);
			dest_stream.once("close", function() { events.emit("complete"); } );
			dest_stream.end();
			
		});
		
	}//---------------------------------------------------;
	
	// Force stop any operations
	public function kill()
	{
		events.removeAllListeners();
		if (dest_stream != null)
		{
			dest_stream.removeAllListeners();
			dest_stream.end();
			dest_stream = null;
		}
	}//---------------------------------------------------;
	
}// --