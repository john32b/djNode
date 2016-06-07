/****
 * FFmpegAudio
 * -------
 * johndimi, johndimi@outlook.com
 * -------
 * @requires: none
 * @supportedplatforms: nodeJS
 * @architectures: Windows, Linux
 * 
 * Audio Tools, uses ffmpeg to compress 
 * and decompress tracks
 *
 * @events: --overriden-- plus:
 * 			progress(int)
 * 			
 * 
 * Useful Links:
 * 
 * https://trac.ffmpeg.org/wiki/Encode/HighQualityAudio
 * http://ffmpeg.org/ffmpeg-codecs.html#libopus
 * 
 * http://ffmpeg.org/ffmpeg-codecs.html#libvorbis
 * ---------------------------------------*/

package djNode.app;

import djNode.tools.FileTool;
import djNode.app.AppSpawner;
import djNode.tools.LOG;
import js.Node;
import js.node.Fs;
import js.node.Path;

/**
 * FFMPEG should be installed and be on the GLOBAL PATH on windows
 * and be installed as a package on LINUX
 **/
class FFmpegAudio extends AppSpawner
{
	var hh:Int;
	var mm:Int;
	var ss:Int;
	var secondsConverted:Int;
	var targetSeconds:Int;
	var percent:Int;
	
	// Is the current operation complete or not
	// Useful to double checking a convertion result
	public var complete(default,null):Bool = false;
	
	var qualityMap:Array<Int>;
	
	//---------------------------------------------------;
	public function new() 
	{
		super();
		audit.linux = { check:true, type:"onpath", param:"ffmpeg -L"};
		audit.win32 = { check:true, type:"onpath", param:"ffmpeg -L"}; // Running ffmpeg alone will error
		
		qualityMap = [2, 4, 6]; // 0 => 2 , 1 => 4, 2 => 6
	}//---------------------------------------------------;
	
	/**
	 * Converts a PCM audio file to a compressed OGG vorbis file
	 * ---------------------------------------------------
	 * @param	input
	 * @param	output if ommited, it will be [input.ogg]
	 * @param	quality [1,2,3] Ogg Vorbis [4] Flac
	 */
	public function compressPCM(input:String, quality:Int = 2, ?output:String):Void
	{	
		var outputParam:Array<String> = null;
		var outputExt:String = "";
	
		if (quality < 1) quality = 1;
		else if (quality > 4) quality = 4;
		
		// Choose codec based on quality
		// 1-3 = OGG Vorbis codec
		// 4   = Flac codec
		// ----------------------------
		if (quality <= 3) {	
			outputExt = ".ogg";
			outputParam = ["-c:a", "libvorbis"];
			outputParam.push('-q');
			outputParam.push(Std.string( qualityMap[quality - 1] ) );
		}else {
			outputExt = ".flac";
			outputParam = ["-c:a", "flac"];
		}
		
		if (output == null) {
			output = FileTool.getPathNoExt(input) + outputExt;
		}
		
		LOG.log('Converting [$input] to "$output". QUALITY = $quality');

		var st = Fs.statSync(input).size;
		
		// PCM is 176400 bytes per second
		targetSeconds = Math.floor(st / 176400 );
		
		complete = false;
		
		var proc_params:Array<String> = 
			[	
				"-y",				// overwrite destination file
				"-f", "s16le", 		// signed 16-bit little endian	// FORCE FROM PCM
				"-ar", "44.1k", 									// FORCE FROM PCM
				"-ac", "2",			// stereo
				"-i", input
			];
			
			for (i in outputParam) proc_params.push(i);
			proc_params.push(output);
			
		//LOG.log("FFMPEG PARAMS:");
		//LOG.logObj(proc_params);
		spawnProc("ffmpeg", proc_params);
		listen_progress();
	}//---------------------------------------------------;
	
	/**
	 * Call this after the process has been created.
	 */
	private function listen_progress():Void
	{	
		// typical line:
		// size: 99KB time=hh:mm:ss.mm bitrate= 123.4kbits/s
		
		var expr_size = ~/size=\s*(\d*)kb/i; 			  // get kb processed
		var expr_time = ~/time=(\d{2}):(\d{2}):(\d{2})/i; // get hours, minutes and seconds
		
		proc.stderr.setEncoding("utf8");
		proc.stderr.on("data", function(data:String) {
			if (expr_time.match(data)) {
				hh = Std.parseInt(expr_time.matched(1));
				mm = Std.parseInt(expr_time.matched(2));
				ss = Std.parseInt(expr_time.matched(3));
				secondsConverted = ss + (mm * 60) + (hh * 360);
				percent = Math.ceil((secondsConverted / targetSeconds) * 100);
				if (percent > 100) percent = 100;
				events.emit("progress", percent);
			}
		});
	}//---------------------------------------------------;
	
	/*
	 * Returns the audio file duration in seconds
	 * Runs ffmpeg with -i to get info
	 */
	private function getDuration(input:String):Void
	{
		secondsConverted = 0;
		targetSeconds = 0;
		
		// - pre
		// - MAKE SURE FFMPEG EXISTS!
		AppSpawner.quickExec('ffmpeg -i "$input"', function(s:Bool, o:String, e:String) {
			
			// Warning!! ffmpeg will always exit with error for displaying info.
			// Do not check status
			
			var expr_duration = ~/\s*Duration:\s*(\d{2}):(\d{2}):(\d{2})/;
			if (expr_duration.match(e)) 
			{
				hh = Std.parseInt(expr_duration.matched(1));
				mm = Std.parseInt(expr_duration.matched(2));
				ss = Std.parseInt(expr_duration.matched(3));
				targetSeconds = (ss + (mm * 60) + (hh * 360));
			}else
			{
				// ERROR
				// CAN'T EVEN READ THE STDERR
				if (FileTool.pathExists(input)) {
					events.emit("close", false , 'Could not get duration.');
				}else
				{
					events.emit("close", false , '$input, no such file.');
				}
			}
			
			LOG.log('Duration got [$targetSeconds]');
			events.emit("durationGet");
		});

	}//---------------------------------------------------;
	
	
	// --
	public function convertToPCM(input:String,?output:String):Void 
	{ 
		//ffmpeg -i input.flv -f s16le -acodec pcm_s16le output.raw
		LOG.log('Converting [$input] to PCM ..');
		
		complete = false;
		
		// Get everything except the extension
		if (output == null) {
			output = FileTool.getPathNoExt(input) + ".pcm";
		}
		
		// Proceed to convert ater getting duration
		events.once("durationGet", function() {
			spawnProc("ffmpeg",
			[	"-i", input,
				"-y",
				"-f", "s16le",
				"-acodec", "pcm_s16le",
				output
			]);
			listen_progress();
		});
	
		// This is done first, Gets duration, then runs ffmpeg again
		getDuration(input);
	
	}//---------------------------------------------------;
	
}//--end class--