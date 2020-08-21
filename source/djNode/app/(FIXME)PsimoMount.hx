/********************************************************************
 * Interface for `PISMO MOUNT` application
 * 
 * - mount archives
 * - unmount 
 * 
 *******************************************************************/

package djA;

import js.node.ChildProcess;

class PsimoMount
{
	static var EXE = "PFM.exe";
	
	public static function mount_zip(p:String, drive:String = null):String
	{		
		// PFM mount -i : Ignore if already mounted

		if (drive != null)
		{
			ChildProcess.execSync('${EXE} mount -i -m $drive "$p"');
			trace("mounted OK");
			// pfm list on a drive mount will return the default "c:\volumes" so override that
			return '$drive:\\';	
		}
		
		//--> Mount in default folder 
		
		ChildProcess.execSync('${EXE} mount -i "$p"');
		
		// Get the path of the newly mounted archive
		var res = ChildProcess.execSync('${EXE} list "$p"');
		
		// Note:
		// (?:....) is non capturing
		var reg = ~/.*(?:\.zip|\.pfo) (.*)/ig;
		if (reg.match(res))
		{
			return reg.matched(1);
		}else
		{
			return null;
		}
	}//---------------------------------------------------;
	
	/**
	   Unmounts a mounted zip
	   @param	p Either the Mounted path or Source Zip file
	**/
	public static function unmount(p:String = null):Bool
	{
		try{
			var s = (p == null)?'':'"$p"';
			ChildProcess.execSync('${EXE} unmount $s');
			return true;
		}catch (e:Dynamic)
		{
			// Already unmounted or Error?
			return false;
		}
	}//---------------------------------------------------;
	
}// --