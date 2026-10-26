package debug;

import openfl.display.Shape;
import openfl.events.Event;

class ScriptErrorOverlay extends Sprite
{
	public static var instance:ScriptErrorOverlay = null;

	public static var maxEntries:Int = 6;

	public static var lifetime:Float = 6;

	static inline var MAX_LINE_LENGTH:Int = 220;

	var entries:Array<OverlayEntry> = [];
	var dirty:Bool = false;

	var background:Shape;
	var label:TextField;

	public function new()
	{
		super();
		instance = this;

		mouseEnabled = false;
		mouseChildren = false;
		visible = false;

		background = new Shape();
		addChild(background);

		label = new TextField();
		label.selectable = false;
		label.mouseEnabled = false;
		label.multiline = true;
		label.wordWrap = true;
		label.defaultTextFormat = new TextFormat('_sans', 12, 0xFFFF6B6B);
		label.x = label.y = 6;
		addChild(label);

		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	public static function push(message:String):Void
	{
		if (instance != null)
			instance.add(message);
	}

	public static function clear():Void
	{
		if (instance != null)
		{
			instance.entries = [];
			instance.dirty = true;
		}
	}

	function add(message:String):Void
	{
		if (message == null)
			return;

		message = message.replace('\r', '').replace('\n', ' ');
		if (message.length > MAX_LINE_LENGTH)
			message = message.substr(0, MAX_LINE_LENGTH) + '...';

		var now:Float = Timer.stamp();
		for (entry in entries)
		{
			if (entry.message == message)
			{
				entry.count++;
				entry.lastSeen = now;
				dirty = true;
				return;
			}
		}

		entries.push({message: message, count: 1, lastSeen: now});
		while (entries.length > maxEntries)
			entries.shift();
		dirty = true;
	}

	function onEnterFrame(_):Void
	{
		var now:Float = Timer.stamp();
		var before:Int = entries.length;
		entries = entries.filter(entry -> now - entry.lastSeen < lifetime);
		if (entries.length != before)
			dirty = true;

		if (!dirty)
			return;
		dirty = false;

		visible = entries.length > 0;
		if (!visible)
			return;

		var lines:Array<String> = [
			for (entry in entries) entry.count > 1 ? '[x${entry.count}] ${entry.message}' : entry.message
		];
		lines.push('(full details in the console / log)');

		var stageWidth:Float = stage != null ? stage.stageWidth : 1280;
		var stageHeight:Float = stage != null ? stage.stageHeight : 720;

		label.width = stageWidth - 12;
		label.text = lines.join('\n');
		label.height = label.textHeight + 6;

		var boxHeight:Float = label.height + 12;
		background.graphics.clear();
		background.graphics.beginFill(0x000000, 0.7);
		background.graphics.drawRect(0, 0, stageWidth, boxHeight);
		background.graphics.endFill();

		y = stageHeight - boxHeight;
	}
}

private typedef OverlayEntry =
{
	var message:String;
	var count:Int;
	var lastSeen:Float;
}
