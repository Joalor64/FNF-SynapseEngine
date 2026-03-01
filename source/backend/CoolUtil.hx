package backend;

@:keep
class CoolUtil
{
	public static final defaultDifficulties:Array<String> = ['Easy', 'Normal', 'Hard'];
	public static final defaultDifficulty:String = 'Normal';

	public static var difficulties:Array<String> = [];

	inline public static function quantize(f:Float, snap:Float)
	{
		var m:Float = Math.fround(f * snap);
		trace(snap);
		return (m / snap);
	}

	public static function getDifficultyFilePath(num:Null<Int> = null)
	{
		if (num == null)
			num = PlayState.storyDifficulty;

		var fileSuffix:String = difficulties[num];
		if (fileSuffix != defaultDifficulty)
		{
			fileSuffix = '-' + fileSuffix;
		}
		else
		{
			fileSuffix = '';
		}
		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString():String
	{
		return difficulties[PlayState.storyDifficulty].toUpperCase();
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	inline public static function coolTextFile(path:String):Array<String>
		return Assets.exists(path) ? [for (i in Assets.getText(path).trim().split('\n')) i.trim()] : [];

	inline public static function colorFromArray(colors:Array<Int>, ?defColors:Array<Int>):FlxColor
	{
		colors = fixRGBColorArray(colors, defColors);
		return FlxColor.fromRGB(colors[0], colors[1], colors[2], colors[3]);
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if (color.startsWith('0x'))
			color = color.substr(4);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if (colorNum == null)
			colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	public static function getColor(value:Dynamic, ?defValue:Array<Int>):FlxColor
	{
		if (value == null)
			return FlxColor.WHITE;
		if (value is Int)
			return value;
		if (value is String)
			return colorFromString(value);
		if (value is Array)
			return colorFromArray(value, defValue);
		return FlxColor.WHITE;
	}

	inline public static function fixRGBColorArray(colors:Array<Int>, ?defColors:Array<Int>):Array<Int>
	{
		final endResult:Array<Int> = (defColors != null && defColors.length > 2) ? defColors : [255, 255, 255, 255];
		for (i in 0...endResult.length)
			if (colors[i] > -1)
				endResult[i] = colors[i];
		return endResult;
	}

	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel != 0)
				{
					if (countByColor.exists(colorOfThisPixel))
					{
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					}
					else if (countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687))
					{
						countByColor[colorOfThisPixel] = 1;
					}
				}
			}
		}
		var maxCount = 0;
		var maxKey:Int = 0;
		countByColor[flixel.util.FlxColor.BLACK] = 0;
		for (key in countByColor.keys())
		{
			if (countByColor[key] >= maxCount)
			{
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
		return [for (i in min...max) i];

	public static function precacheSound(sound:String):Void
	{
		Paths.sound(sound);
	}

	public static function precacheMusic(sound:String):Void
	{
		Paths.music(sound);
	}

	public static function browserLoad(site:String)
	{
		#if linux
		var cmd = Sys.command("xdg-open", [url]);
		if (cmd != 0)
			cmd = Sys.command("/usr/bin/xdg-open", [url]);
		Sys.command('/usr/bin/xdg-open', [url]);
		#else
		FlxG.openURL(site);
		#end
	}
}
