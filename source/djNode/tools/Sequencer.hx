/****
 * Sequencer
 * -------
 * johnimi, johndimi@outlook.com
 * -------
 * @supportedplatforms: nodeJS
 * 
 * A simple sequencer for actions.
 * Can call the next action with a delay or right away
 * 
 * ---------------------------------------*/

package djNode.tools;

import js.Node;

/*
 * Basic Integer Sequencer
 * Calls the callback with an incremented int, with custom time delay
 * Useful for animations or misc actions
 */
class Sequencer {
	
	var callback:Int->Void = null;
	var timer:TimeoutObject = null;
	var timerInt:IntervalObject = null;
	var currentStep:Int = 0;
	//--------------------------------------------------
	
	public function new(_callback:Int->Void) {
		callback = _callback;
	}//---------------------------
	public function stop():Void {
		currentStep = 0;
		Node.clearTimeout(timer);
		timer = null;
	}//---------------------------
	// Time in SECONDS
	public function next(?seconds:Float):Void 
	{
		nextMS(Std.int(seconds * 1000));
	}//---------------------------------------------------;
	// Time in MILLISECONDS
	public function nextMS(?msDelay:Int):Void {
		if (msDelay > 0) {
			/* In case next is called during a previous
			 * step is active */
			if (timer != null) {
				Node.clearTimeout(timer);
				timer = null;
			}
			timer = Node.setTimeout(onTimer, msDelay);
		} else {
			onTimer();
		}
	}//---------------------------
	private function onTimer():Void {
		Node.clearTimeout(timer);
		timer = null;
		currentStep++;
		callback(currentStep);
	}//---------------------------
	public function doXTimes(times:Int, delay:Int, ?callbackEnd:Void->Void):Void {
		var currentStep = 0;
		timerInt = Node.setInterval(function() {
			currentStep++;
			if (currentStep > times) { 
				Node.clearInterval(timerInt); timerInt = null; 
				if (callbackEnd != null) callbackEnd();
				return; 
			}
			callback(currentStep);
		},delay);
	}//------------------------------
	
}//--end class--//