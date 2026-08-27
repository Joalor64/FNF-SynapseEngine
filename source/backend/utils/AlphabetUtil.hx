package backend.utils;

// also code from doido engine

typedef ParsedText =
{
	var chars:Array<String>;
	var tags:Array<TagData>;
}

typedef TagData =
{
	var name:String;
	var startIndex:Int;
	var endIndex:Int;
	var type:TagType;
}

enum TagType
{
	BoldTag;
	PlainTag;
	ColorTag(value:FlxColor);
	RainbowTag(speed:Float, offset:Float, saturation:Float, brightness:Float);
	ShakeTag(speed:Float, intensity:Float);
	WaveTag(speed:Float, intensity:Float, delay:Float);
}

class AlphabetUtil
{
	public static function parse(text:String):ParsedText
	{
		var chars:Array<String> = [];
		var tags:Array<TagData> = [];
		var openTags:Array<{name:String, tag:TagData}> = [];
		var index:Int = 0;
		var position:Int = 0;

		while (position < text.length)
		{
			if (text.charAt(position) == '<')
			{
				var close:Int = text.indexOf('>', position + 1);
				if (close != -1)
				{
					var content:String = StringTools.trim(text.substring(position + 1, close));
					var isClosing:Bool = content.startsWith('/');
					var tagName:String = content.substring(isClosing ? 1 : 0).split(' ')[0].toLowerCase();

					if (isClosing)
					{
						var matched:Bool = false;
						for (i in 0...openTags.length)
						{
							var open = openTags[openTags.length - 1 - i];
							if (open.name == tagName)
							{
								matched = true;
								open.tag.endIndex = index;
								openTags.splice(openTags.length - 1 - i, 1);
								break;
							}
						}
						if (matched)
						{
							position = close + 1;
							continue;
						}
					}

					var tag:TagData = parseTag(content, index);
					if (tag != null)
					{
						tag.name = tagName;
						tags.push(tag);
						openTags.push({name: tagName, tag: tag});
						position = close + 1;
						continue;
					}
				}
			}

			chars.push(text.charAt(position));
			index++;
			position++;
		}

		for (open in openTags)
			open.tag.endIndex = index;

		return {chars: chars, tags: tags};
	}

	static function parseTag(content:String, index:Int):TagData
	{
		if (content == "bold" || content == "plain")
		{
			return {
				name: "",
				startIndex: index,
				endIndex: -1,
				type: content == "bold" ? BoldTag : PlainTag
			};
		}

		if (content == "color" || content.startsWith("color "))
		{
			var color = parseColor(content, "value");
			return {
				name: "",
				startIndex: index,
				endIndex: -1,
				type: ColorTag(color)
			};
		}

		if (content == "rainbow" || content.startsWith("rainbow "))
		{
			var speed = parseFloatTag(content, "speed", 1);
			var offset = parseFloatTag(content, "offset", 30);
			var saturation = parseFloatTag(content, "saturation", 1);
			var brightness = parseFloatTag(content, "brightness", 1);

			return {
				name: "",
				startIndex: index,
				endIndex: -1,
				type: RainbowTag(speed, offset, saturation, brightness)
			};
		}

		if (content == "shake" || content.startsWith("shake "))
		{
			var speed = parseFloatTag(content, "speed", 1);
			var intensity = parseFloatTag(content, "intensity", 5);

			return {
				name: "",
				startIndex: index,
				endIndex: -1,
				type: ShakeTag(speed, intensity)
			};
		}

		if (content == "wave" || content.startsWith("wave "))
		{
			var speed = parseFloatTag(content, "speed", 1);
			var intensity = parseFloatTag(content, "intensity", 5);
			var delay = parseFloatTag(content, "delay", 1);

			return {
				name: "",
				startIndex: index,
				endIndex: -1,
				type: WaveTag(speed, intensity, delay)
			};
		}

		return null;
	}

	static function parseFloatTag(content:String, name:String, defaultValue:Float):Float
	{
		var idx = content.indexOf(name + "=");

		if (idx == -1)
			return defaultValue;

		var start = idx + name.length + 1;
		var end = content.indexOf(" ", start);

		if (end == -1)
			end = content.length;

		var value = content.substring(start, end);
		var parsed = Std.parseFloat(value);

		return Math.isNaN(parsed) ? defaultValue : parsed;
	}

	static function parseBoolTag(content:String, name:String, defaultValue:Bool):Bool
	{
		var idx = content.indexOf(name + "=");
		if (idx == -1)
			return defaultValue;

		var start = idx + name.length + 1;
		var end = content.indexOf(" ", start);

		if (end == -1)
			end = content.length;

		var value = content.substring(start, end);

		return (value == "true" ? true : value == "false" ? false : defaultValue);
	}

	static function parseColor(content:String, name:String = "", defaultValue:String = "#000000"):FlxColor
	{
		var idx = content.indexOf(name + "=");
		if (idx == -1)
			return FlxColor.fromString(defaultValue);

		var start = idx + name.length + 1;
		var end = content.indexOf(" ", start);

		if (end == -1)
			end = content.length;

		var value = content.substring(start, end);

		return FlxColor.fromString(value);
	}
}
