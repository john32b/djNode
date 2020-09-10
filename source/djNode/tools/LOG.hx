/**----------------------------------------------
 * LOG.hx
 * ----------------------------------------------
 * - General purpose logging tools
 * --------------------------
 * @author: johndimi, <johndimi@outlook.com>
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
import js.lib.Error;
import js.Node;
import js.node.Fs;
import js.node.Path;

typedef LogMessage = {
	?pos:PosInfos,
	level:Int,
	log:String
}//--

@:dce
class LOG 
{
	// Holds prerendered text for each type of log level
	static final messageTypes:Array<String> = [ "DEBUG", "INFO", "WARN", "ERROR", "FATAL" ];
	
	static var _isInited:Bool = false;	
	
	// Store logMessages here.
	static var messages:Array<LogMessage>;
	
	// Helper var, stores time
	static var _t:Float;
	
	// The socket.io object.
	static var io:Dynamic = null;

	// User can set a custom message receiver for log messages
	// like push all messages to a text window.
	public static var onLog:LogMessage-> Void = null; 
	
	// There are 5 Available logging levels, anything below this will be skipped
	public static var logLevel:Int = 0;
	
	// If this is set, then program logs will write to that file
	public static var logFile(default, null):String = null;
	
	// UNSUPPORTED
	static var flag_socket_log:Bool = false;
	
	/** If true will show a the message type at the start of the string on file logs
	 *  Default = false */
	public static var FLAG_SHOW_MESSAGE_TYPE = false;
	
	/** If true will show (file:line) at the beginning of each line ( on debug builds ) 
	 * Default = true */
	public static var FLAG_SHOW_POS = true;
	
	// If true will output the log in stdout
	public static var FLAG_STDOUT = false;
	
	/** If > 0. Will limit the number of log messages in memory. File logging is not affected */
	public static var BUFFER_SIZE:Int = 8000;
	
	// --
	public static function init()
	{
		if (_isInited) return;
			_isInited = true;
		messages = [];
	}//---------------------------------------------------;
	
	// --
	public static inline function getLog():Array<LogMessage> 
	{
		return messages;
	}//--------------------------------------------;
	
	// --
	public static function end():Void 
	{
		// Stop the socket if it's listening
		if (flag_socket_log) untyped( io.close() ); // untyped because nodejsLib is complaining
	}//--------------------------------------------;
	
	/**
	   Pipe all traces to Log.log()
	   @param produceStdout Also write to stdout
	**/
	public static function pipeTrace(produceStdout:Bool = false)
	{
		FLAG_STDOUT = produceStdout;
		
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
		
		if (BUFFER_SIZE > 0 && messages.length >= BUFFER_SIZE)
		{
			messages.shift();
		}
		
		messages.push(logmsg);
		
		if (flag_socket_log) 
			push_SocketText(logmsg);
			
		if (logFile != null) 
			push_File(logmsg);
			
		if (onLog != null) onLog(logmsg);
		
		if (FLAG_STDOUT)
		{
			BaseApp.TERMINAL.println(logmsg.log);
		}
	}//---------------------------------------------------;
		
	/**
	 * Set Logging through an http Slot,
	 * Connect to http://localhost:80
	 */
	@:deprecated("Broken")
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
			for (i in messages) push_SocketText(i);
		});
		
	}//---------------------------------------------------;
	
	static inline function push_SocketText(l:LogMessage)
	{
		io.sockets.emit("logText", { data:l.log, pos:l.pos, level:l.level } );
	}//---------------------------------------------------;	
	
	static inline function push_SocketObj(data:Dynamic, level:Int = 0, ?pos:PosInfos)
	{
		io.sockets.emit("logObj", { data:data, pos:pos, level:level } );
	}//---------------------------------------------------;

	
	/**
	 * Logs a logMessage to the Log File
	 */
	static function push_File(log:LogMessage)
	{
		var m = "";
		if (FLAG_SHOW_MESSAGE_TYPE) m += messageTypes[log.level] + " ";
		#if debug
		if (FLAG_SHOW_POS)
		m += "(" +  log.pos.fileName.split('/').pop() + ":" + log.pos.lineNumber + ") ";
		#end
		m += log.log + "\n";
		
		try{
			Fs.appendFileSync(logFile, m, 'utf8');
		}catch (e:Error)
		{
			// ?? Should it exit from the app 
			BaseApp.TERMINAL.ptag('<red> - NO SPACE LEFT FOR THE LOG FILE - <!>\n');
			Sys.exit(1);
		}
	}//---------------------------------------------------;
		
	/**
	 * Set a log file to be updates automatically on LOG.log() calls
	 * If there were any log calls before setting , then those entries will be written as well.
	 * @param	filename Path to a log file, will be overwritten
	 */
	public static function setLogFile(filename:String)
	{	
		// - get params
		logFile = filename;
		
		var header = 
			" - LOG -\n" +
			" -------\n" +
			" - " + logFile + "\n" +
			" - Created: " + Date.now().toString() + "\n" +
			" - App: " + Path.basename(Node.process.argv[1]) + "\n" +
			" ---------------------------------------------------\n\n";
		try
			Fs.writeFileSync(logFile, header, {encoding:'utf8'})
		catch (e:Error)
			throw 'Cannot Create Log File "$logFile"';
		
		// There is a case where the log array has data,
		// write that data to the file.
		for (i in messages) push_File(i);
	}//---------------------------------------------------;

	
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
