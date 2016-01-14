package djNode.task;

import djNode.app.Arc;
import djNode.app.IArchiver;
import djNode.task.Task;
import djNode.tools.FileTool;
import djNode.tools.LOG;
import js.Node;
import js.node.Path;


/**
 * Task that extracts a file using the appropriate archiver.
 * Sends Progress events.
 */

class Task_ExtractFile extends Task
{
	
	// can be path + file
	var fileToExtract:String;
	// lowercase extension of file being extracted
	var fileExt:String;
	// 
	var destinationFolder:String;
	// Hold the appropriate archiver
	var archiver:IArchiver;
	
	//====================================================;
	/**
	 * 
	 * @param	file Should be normalized
	 * @param	destinationFolder Should be normalized and it should exist
	 * 
	 * TODO: IF THE FILES ARE NOT SET HERE, THEN TRY TO GET THEM LATER
	 *       WITH THE TASK_SHARED_VARIABLE
	 */
	public function new(?file:String, ?destinationFolder:String)
	{
		name = "Extracting"; // Custom Name
		super();
		this.progress_type = "percent";
		this.fileToExtract = file;
		this.destinationFolder = destinationFolder;
	}//---------------------------------------------------;
	
	// --
	override public function run() 
	{
		super.run();
		
		// If parameters were not set, get them now
		if (fileToExtract == null) {
			fileToExtract = dataGet.input;
			destinationFolder = dataGet.output;
			LOG.log("Extractor, got data from previous Task");
			LOG.log('Input:$fileToExtract, Output:$destinationFolder');
		}
		
		this.fileExt = FileTool.getFileExt(fileToExtract);
		
		// Safeguard
		if (!FileTool.pathExists(fileToExtract))
		{
			fail('File ($fileToExtract) does not exist', 'user');
			return;
		}
		
		// Only allow these formats
		if (["7z", "rar", "arc"].indexOf(fileExt) == -1)
		{
			fail('File extension [$fileExt] is not supported by the extractor', 'user');
			return;
		}
		
		// Same destination folder if not specified
		if (destinationFolder == null) 
		{
			destinationFolder = Path.dirname(fileToExtract);
		}
			
		LOG.log('Extracting file "$fileToExtract" to folder "$destinationFolder"');
		var arc = new Arc();
		arc.events.on("progress", function(e:Int) {
			progress_percent = e;
			onStatus("progress", this);
		});
		arc.events.once("close", function(d:Bool) {
			if (d == false) {
				fail('Could not extract $fileToExtract');
				return;
			}else {
				complete();
			}
		});
		
		arc.uncompress(fileToExtract, destinationFolder);
	}//---------------------------------------------------;
	
}// -- end --