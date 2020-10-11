/********************************************************************
 * Interface for `PISMO MOUNT` application
 *
 * - Mounts (zip/pfo/cfs)
 * - Expects the application to be installed and be at the system PATH
 *
 *******************************************************************/

package djNode.app;

import djNode.utils.CLIApp;

class PismoMount
{
	static var EXE = "pfm.exe";

	/**
	   Mount an archive (zip,pfo,cfs)
	   @param	p Path to archive to mount
	   @param	drive Optional, If you set this, will mount as drive (e.g. X to mount as X:\)
	   @return The mounted folder path.
	**/
	public static function mount(p:String, drive:String = null):String
	{
		trace('Mounting "$p"');
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
			trace('[OK] Mounted in ${reg.matched(1)}');
			return reg.matched(1);
		}else {
			trace('[FAIL]');
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

}// --