/**----------------------------------------------
 * LOG.hx
 * ----------------------------------------------
 * - General purpose logging tools
 * --------------------------
 * @author: johndimi, <johndimi@outlook.com> , @jondmt
 * 
 * Features:
 * ---------
 *
 * Notes:
 * ---------
 *  Alpha Version, this is still in development
 *  Features will be coming and going
 *  DEBUG < TRACE < INFO < WARN < ERROR < FATAL
 * 
 * Use Example
 * ----------
 * 
 * 	// Will push logs to a file and will update it at real time
 * 	LOG.setLogFile("log.txt",true);	
 * 
 * 	// Log something, will be pushed to files/sockets/listeners automatically
 * 	LOG.log("something happened");
 * 
 * 
 *********************************************************/
package djNode.tools;

import haxe.Log;
import haxe.PosInfos;
import js.Node;
import js.node.Fs;
import js.node.Path;

// -- Use the logging function on the debug builds only --

typedef LogMessage = {
	?pos:PosInfos,
	level:Int,
	log:String
}//--

@:dce
class LOG 
{
	static var _isInited:Bool = false;	
	
	// Store logMessages here.
	static var messages:Array<LogMessage>;
	
	// Holds prerendered text for each type of log level
	static var messageTypes:Array<String>;
	
	// Helper var, stores time
	static var _t:Float;
	
	// The socket.io object.
	static var io:Dynamic = null;
	
	// == USER SET FLAGS ========================;

	// User can set a custom message receiver for log messages
	// like push all messages to a text window.
	public static var onLog:LogMessage-> Void = null; 
	
	// There are 5 Available logging levels, anything below this will be skipped
	public static var logLevel:Int = 0;
	
	// If this is set, then program logs will write to that file
	static var logFile:String = null;
	
	// If true, the logger will write to the log file in realtime, else at the end of the program
	static var flag_realtime_file:Bool = true;
	
	// Use socket.io logging ?
	static var flag_socket_log:Bool = false;
	
	// Keep messages in memory?
	static var flag_keep_in_memory:Bool = true;
	
	// How many messages to keep in memory, -- Avoid hogging the ram with a huge message log.
	static var param_memory_buffer:Int = 8192;

	// If true will show a the message type at the start of the string on file logs
	public static var FLAG_SHOW_MESSAGE_TYPE = false;
	
	//====================================================;
	// FUNCTIONS
	//====================================================;
	
	/* Make sure to set any parameters BEFORE initializing this class 
	 **/
	public static function init(file:String = null, realtime:Bool = false):Void
	{
		if (_isInited) return;
			_isInited = true;
		
		messages = [];
		messageTypes = [ "DEBUG", "INFO", "WARN", "ERROR", "FATAL" ];
		
		if (file != null) setLogFile(file, realtime);
	}//---------------------------------------------------;
	
	// --
	public static inline function getLog():Array<LogMessage> 
	{
		return messages;
	}//--------------------------------------------;
	
	// --
	public static function end():Void 
	{
		if (logFile != null && flag_realtime_file == false) {
			for (i in messages) push_File(i);
		}
		
		// Stop the socket if it's listening
		if (flag_socket_log) untyped( io.close() ); // untyped because nodejsLib is complaining
	}//--------------------------------------------;
	
	/**
	   Pipe all traces to Log.log()
	**/
	public static function pipeTrace()
	{
		Log.trace = function(msg:Dynamic, ?pos:PosInfos)
		{
			log(msg, 1, pos);
			if ( pos != null && pos.customParams != null ) 
			{
				for ( v in pos.customParams ) log(v, 1, pos);
			}
		}
		
	}//---------------------------------------------------;
	
	/**
	 * Logs a message to the logger
	 * - No posInfos on Release
	 * @param	text The message to log
	 * @param	level 0:Debug, 1:Info, 2:Warn, 3:Error, 4:Fatal
	 * @param	pos Autofilled by the compiler
	 */
	#if debug
	public static function log(obj:Dynamic, level:Int = 1, ?pos:PosInfos)
	#else
	public static function log(obj:Dynamic, level:Int = 1, ?d:Dynamic)
	#end
	{
		if (level < logLevel) return;
		
		var logmsg:LogMessage = {
			#if debug 
				pos:pos, 
			#else
				pos:null,
			#end
			
			log:Std.string(obj), level:level 
		};
		
		if (flag_keep_in_memory) {
			// If the buffer is full, remove the oldest
			if (messages.length == param_memory_buffer) {
				messages.shift();
			}
			messages.push( logmsg );
		}
				
		if (flag_socket_log) 
			push_SocketText(logmsg);
			
		if (flag_realtime_file && logFile != null) 
			push_File(logmsg);
			
		if (onLog != null) onLog(logmsg);
	}//---------------------------------------------------;
		
	/**
	 * Set Logging through an http Slot,
	 * Connect to http://localhost:80
	 */
	public static function setSocketLogging(port:Int = 80)
	{	
		//- setup the socket.io debugging
		if (io != null) return;
		
		flag_socket_log = true;
		
		io = Node.require('socket.io').listen(port);
		log("Socket, Listening to port " + port);
		
		io.sockets.on('connection', function(socket:Dynamic) {
			log("Socket, Connected to client");
			
			socket.on("disconnect", function() {
				log("Socket, Disconnected from client");
			});
			
			untyped(socket.emit("maxLines", param_memory_buffer));
			
			//io.sockets.emit("maxLines", param_memory_buffer );
		
			// In case there are previous logs, push them to the socket
			if (messages.length > 0) {
				for (i in messages) push_SocketText(i);
			}
		});
		
	}//---------------------------------------------------;
	
	/**
	 * @PRE io is inited.
	 * @param	data Data to be logged
	 * @param	level Logging level,
	 */
	static inline function push_SocketText(l:LogMessage)
	{
		io.sockets.emit("logText", { data:l.log, pos:l.pos, level:l.level } );
	}//---------------------------------------------------;	
	
	static inline function push_SocketObj(data:Dynamic, level:Int = 0, ?pos:PosInfos)
	{
		io.sockets.emit("logObj", { data:data, pos:pos, level:level } );
	}//---------------------------------------------------;

	
	/**
	 * Logs a logMessage to the file set for logging.
	 */
	static function push_File(log:LogMessage)
	{
		var m = "";
		if (FLAG_SHOW_MESSAGE_TYPE) m += messageTypes[log.level] + " ";
		m += "(" +  log.pos.fileName.split('/').pop() + ":" + log.pos.lineNumber + ") ";
		m += log.log + "\n";
		Fs.appendFileSync(logFile, m, 'utf8');
	}//---------------------------------------------------;
		
	/**
	 * Set the log file, If there were log call before setting the file
	 * then those entries will be written as well.
	 * @param	filename
	 * @param	realtime_update If TRUE the file will update in real time, if False the log will be written once the program ends
	 */
	public static function setLogFile(filename:String, realtime_update:Bool = false)
	{	
		// - get params
		logFile = filename;
		flag_realtime_file = realtime_update;
		
		// - check log file
		try { 
			
			// TODO: Add time and date and source file info.
			var fileHeader = 
				" - LOG -\n" +
				" -------\n" +
				" - " + logFile + "\n" +
				" - Created: " + Date.now().toString() + "\n" +
				" - App: " + Path.basename(Node.process.argv[1]) + "\n" +
				" ---------------------------------------------------\n\n";
				Fs.writeFileSync(logFile, fileHeader, 'utf8');
		}catch (e:Dynamic) { 
			log('Could not create logfile - $logFile', 3);
			logFile = null;
		}//--
				
		
		// There is a case where the log array has data,
		// write that data to the file.
		if(flag_realtime_file && messages.length > 0 && logFile != null) {
			for (i in messages) push_File(i);
		}
		
	}//---------------------------------------------------;

	//====================================================;
	// Timing Functions
	//====================================================;
	
	/**
	 * Create a time reference,
	 * Call timeGet() later to get the time ellapsed
	 */
	public static function timeStart():Void 
	{
		_t = Date.now().getTime();
	}//--------------------------------------------;
	
	/**
	 * Gets the time passed since timeStart()
	 * @return The time in Milliseconds 
	 */
	public static inline function timeGet():Int
	{
		return Std.int(Date.now().getTime() - _t);
	}//--------------------------------------------;
	
	
}//- end LOG class --
