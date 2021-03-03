/********************************************************************
 * Interface for `PISMO MOUNT` application
 *
 * - Mounts (zip/pfo/cfs)
 * - Expects the application to be installed and be at the system PATH
 *
 *******************************************************************/

package djNode.app;

import djNode.utils.CLIApp;
import js.node.Process;

@:dce
class PismoMount
{
	// This should exist on system path.
	static var EXE = "pfm.exe";
	
	// This program does not exist in default path
	// Is on "C:\Program Files\Pismo File Mount Audit Package"
	static var PTISO = "ptiso.exe";

	/**
	   Mount an archive (zip,pfo,cfs)
	   @param	p Path to archive to mount
	   @param	drive Optional, If you set this, will mount as drive (e.g. X to mount as X:\)
	   @return The mounted folder path.
	**/
	public static function mount(p:String, drive:String = null):String
	{
		trace('> Mounting "$p"');
		// PFM mount -i : Ignore if already mounted
		if (drive != null)
		{
			var res = CLIApp.quickExecS('${EXE} mount -i -m $drive "$p"');
			// pfm list on a drive mount will return the default "c:\volumes" so override that
			return '$drive:\\';
		}

		//--> Mount in default folder

		var res0 = CLIApp.quickExecS('${EXE} mount -i "$p"');
		//ChildProcess.execSync('${EXE} mount -i "$p"');

		// Get the path of the newly mounted archive
		var res1 = CLIApp.quickExecS('${EXE} list "$p"');

		// Note:
		// (?:....) is non capturing
		var reg = ~/.*(?:\.zip|\.pfo|\.cfs) (.*)/ig;
		if (reg.match(res1)) {
			trace('  [OK] Mounted in "${reg.matched(1)}"');
			return reg.matched(1);
		}else {
			trace('  [FAIL]');
			return null;
		}
	}//---------------------------------------------------;

	/**
	   Unmounts a mounted zip.
	   @param	p Null to unmount all | or path to Mounted path or Source Zip file.
	**/
	public static function unmount(p:String = null):Bool
	{
		try{
			var s = (p == null)?'':'"$p"';
			var a = CLIApp.quickExecS('${EXE} unmount $s');
			if (a != null) return true;
		}catch (e:Dynamic) { }

		return false;
	}//---------------------------------------------------;
	
	
	public static function CFS_SetExe(?path:String)
	{
		//ProgramW6432
		if (path == null)
		{
			PTISO = 
				js.node.Path.join(
					js.Node.process.env.get('ProgramW6432'),
					'Pismo File Mount Audit Package',
					'ptiso.exe');
		}else
		{
			PTISO = js.node.Path.join(path, 'ptiso.exe');
		}
	}//---------------------------------------------------;
	
	/**
	   Create a CFS Archive. lzma compression. 
	   SYNC. Will halt until it completes
	   @param	files Files to put in the archive
	   @param	target Must have a ".cfs" extension
	**/
	public static function CFS_CreateSync(files:Array<String>, target:String)
	{
		var filesP = files.map((s)->'"file {$s}" ');
		var output = CLIApp.quickExecS('"$PTISO" create -f -t ciso -z lzma "$target" $filesP');
	}//---------------------------------------------------;
	
	/**
	   Create a CFS LZMA archive from a bunch of files. 
	   This is ASYNC and will push progress and callback complete
	   Replaces target if exists
	   @param	files FullPaths of files
	   @param	target Must be a .cfs file, it will be created
	   @param	callback Success
	   @param	onProgress 0-100
	**/
	public static function CFS_CreateAsync(files:Array<String>, target:String, callback:Bool->Void, ?onProgress:Int->Void)
	{
		/* DEV: Example Output:
			..
			Locating files...
			time 0:00:00.003 byte 0 of 0
			time 0:00:00.003 byte 0 of 0
			Writing file data to file set...
			time 0:00:00.006 byte 0 of 8.727.073
			time 0:00:00.357 byte 1.048.576 of 8.727.073.
			time 0:00:00.975 byte 3.145.728 of 8.727.073.
			time 0:00:01.591 byte 5.242.880 of 8.727.073.
			time 0:00:02.233 byte 7.340.032 of 8.727.073.
			time 0:00:02.647 byte 8.808.448 of 8.808.448
			----
			1) Toggle capture on 'Writing file data to file set' 
			2) Get bytes xxx of yyy and convert those to int numbers and calc the %
		*/
		var app = new CLIApp(PTISO);
		var f0:Bool = false;
		var ex0 = ~/(Writing file data)/;
		var ex1 = ~/\stime.+byte\s(.*)\sof\s(.*\d)/;
		
		if (onProgress != null)	// Define onStdOut only if I want to capture progress
		app.onStdOut = (data:String) -> {
			if (!f0) {
				if (ex0.match(data)) f0 = true; 
				return;
			}
			if (ex1.match(data)){
				var a0 = Std.parseInt(StringTools.replace(ex1.matched(1), ".", ""));
				var a1 = Std.parseInt(StringTools.replace(ex1.matched(2), ".", ""));
				onProgress(Std.int((a0 / a1) * 100));
			}
		};
		
		app.onClose = (s)->{
			trace('PTISO Close Success : [$s]');
			callback(s);
		};
		
		var filesP = files.map((s)->'file {$s}');
		app.start(['create', '-f', '-t', 'ciso', '-z', 'lzma', target].concat(filesP));
	}//---------------------------------------------------;

}// --