package scripts;

import debug.ScriptErrorOverlay;

class ScriptErrorHandler
{
	static var seen:Map<String, Int> = new Map();

	static inline var MAX_TRACKED:Int = 256;

	static var initialized:Bool = false;

	public static function init():Void
	{
		if (initialized)
			return;
		initialized = true;

		FlxG.signals.preStateSwitch.add(reset);
	}

	public static function report(title:String, message:String, popup:Bool = false):Void
	{
		init();

		var key:String = '$title|$message';
		var count:Int = seen.exists(key) ? seen.get(key) + 1 : 1;
		if (count == 1 && Lambda.count(seen) >= MAX_TRACKED)
			seen.clear();
		seen.set(key, count);

		ScriptErrorOverlay.push('$title: $message');

		if (count > 1)
			return;

		trace('$title: $message');

		if (popup)
			Lib.application.window.alert(message, title);
	}

	public static function reset():Void
	{
		seen.clear();
	}
}
