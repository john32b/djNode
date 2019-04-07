/**
   Custom Config (TYPE A)
   ----------------------
   - Compatible with haxe lib
   - @author John Dimi
   
   - Load a config file
   - Save a config file
   - Keeps the comment structure of fields when saving
   
   + Recommended file extention : ".cfg"
   
   + Config File Structure --------------------------------------
   
		# Comments are only valid if [ # ; ] are at the beginning of the line
		; Comment
		# Comment
		# Every field gets associated with all the comments above it
		
		# This Associates a value to a field
		# Accessible with "ConfigFile.data.field"
	
			field value
		
		# You can also declare fields in an object structure
		
		
		# The following will be represented as
		# "configfile.data.obj.field" == {a:"100", b:"200"}
			obj.field.a	100
			obj.field.b 200
			
		# All values are stored as string!
		# 2300 as string in the following example
			fieldB 2300
			
	+ ---------------------------------------------------------
		
	+ Use Example:
	
		var c = new ConfigFileA("settings.ini");
			c.load(); // You can now access "c.data"
			
			
		var c = new ConfigFileA("s.ini");
			c.data = { a:100,b:200,c:"hello"};
			c.save(); // will save the settings to "s.ini";

**/

package djNode.utils;

import sys.FileStat;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
using StringTools;



class ConfigFileA
{	
	// The root for all variables on the config
	public var data:Dynamic;
	
	// FullField -> Comments
	// Useful to keep so I can save it again back
	// e.g. "psx.display.one" -> [ "comment 1", "comment 2"]
	public var comments:Map<String,Array<String>>;
	
	// Rendered config, ready to be typed
	// - WRITTEN BY - scanNode(), used for saving the file again.
	var _renderConfig:Array<String>;
	
	// The file associated with the this object
	var pathFile:String;
	
	// In case of error, read this
	public var ERROR:String;
	
	//====================================================;
	
	public function new(file:String) 
	{
		pathFile = file;
		data = {};
		comments = [];
	}//---------------------------------------------------;
	
	public function load():Bool
	{
		trace("Loading Config File " + pathFile);
		
		if (!FileSystem.exists(pathFile))
		{
			return err('File "$pathFile" does not exist');
		}
		
		// File data
		var lines:Array<String> = File.getContent(pathFile).split('\n');
		var lineNo:Int = 0;
		
		// Current comments
		var com:Array<String> = [];
		
		for (l in lines)
		{
			lineNo++;
			l = l.trim();
			if (l.length < 1) continue;
			var fc = l.charAt(0);
			if (fc == "#" || fc == ";")
			{
				com.push(l);
				continue;
			}
			
			var L = l.split(' ');	// psx.display screen1 screen2 ;
									// psx.display | screen1 | screen2
			if (L.length < 2)
			{
				return err('Parse Error in line $lineNo. No Value set');
			}
			
			// Write the field to data
			var FIELDS = L[0].split('.');	// ["psx","display"]
			L.shift(); 						// remove first, since I got it
			var VAL = L.join(' ');			// combine back ["screen1 screen2"]
			try{
				setField(FIELDS, VAL);
			}catch (e:Dynamic)
			{
				return err('Parse Error, File:$pathFile Line:$lineNo, $e');
			}
			
			// Write the comments
			comments.set(FIELDS.join('.'), com);
			
			com = [];
			
		}// -
		
		return true;
		
	}//---------------------------------------------------;
	
	/**
	   PRE: ar length >= 1
	   Translate Array form fields to actual data 
		["psx","display","one"] -> object.psx.display.one
	   @param	ar Layout of fields
	   @param	v Value
	**/
	   
	function setField(ar:Array<String>, v:String)
	{
		var o:Dynamic = data; 
		var i = 0;
		while (i < ar.length - 1)
		{
			if (Reflect.field(o, ar[i]) == null)
			{
				Reflect.setField(o, ar[i], {});
			}
			o = Reflect.field(o, ar[i]);
			i++;
		}
		
		// DEV: I don't know about this one:
		//if (Reflect.hasField(o, ar[i]))
		//{
			//trace('-WARNING- Field ending with "${ar[i]}" value = "${Reflect.field(o,ar[i])}" already exists');
			//trace('-cont- Duplicate entry to value = "$v"');
			//trace('-cont- SKIPPING and not overwriting');
			//return;
		//}
		
		// This should be the last, so set the actual string value
		Reflect.setField(o, ar[i], v);
	}//---------------------------------------------------;
	
	
	/**
	   Set a field with a format of "field.sub" on the data object
	   Useful sometimes
	   @param	field
	   @param	v
	**/
	public function set(field:String, v:String)
	{
		setField(field.split('.'), v);
	}//---------------------------------------------------;
	
	public function exists(field:String):Bool
	{
		var f = field.split('.');
		var i = 0;
		var o = data;
		while (i < f.length)
		{
			if (!Reflect.hasField(o, f[i])) return false;
			o = Reflect.field(o, f[i]);
			i++;
		}
		return true;
	}//---------------------------------------------------;
	
	/**
	   Fills '_configRender', so make sure to zero it out before calling
	   Translates the data back to full printable config
	   - Along with comments
	**/
	function scanNode(o:Dynamic, path:String = "")
	{
		var f = Reflect.fields(o);
		var i = 0;
		while (i < f.length)
		{
			var v:Dynamic = Reflect.field(o, f[i]);
			var dot = (path.length == 0?"":".");
			if (Std.is(v,String))
			{
				var str = '$path$dot${f[i]}';
				var com = comments.get(str);
				if (com != null) for (c in com) _renderConfig.push(c);
				_renderConfig.push('$str $v');
				// No new line?
			}else{
				scanNode(v, path + dot + f[i]);
			}
			i++;
		}
	}//---------------------------------------------------;
		
	
	/**
	   Save and overwrite the config file
	   @return
	**/
	public function save():Bool
	{
		trace('Saving config to file $pathFile..');
		_renderConfig = [];
		scanNode(data);
		try{
			File.saveContent(pathFile, _renderConfig.join('\n'));
		}catch (e:Any)
		{
			return err('Cannot save "$pathFile" Does the folder exist? Do you have write access?');
		}
		return true;
	}//---------------------------------------------------;
	
	
	public function getList()
	{
		_renderConfig = [];
		scanNode(data);
		return _renderConfig;			
	}//---------------------------------------------------;
	
	#if debug
	public function info()
	{
		_renderConfig = [];
		scanNode(data);
		for (i in _renderConfig) trace(i);
	}
	#end
	
	
	// Error Helper
	function err(e:String):Bool
	{
		ERROR = 'ERROR - ConfigFile.hx - $e';
		trace(ERROR);
		return false;
	}//---------------------------------------------------;
	
	/**
	   Clear memory config, does not affect file.
	   You can use SAVE() to save an empty config
	   @return
	**/
	public function clear()
	{
		data = {};
		comments = [];
	}//---------------------------------------------------;
	
}// --