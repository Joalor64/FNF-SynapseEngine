package backend;

@:keep
class CoolUtil
{
	inline public static function quantize(f:Float, snap:Float)
	{
		var m:Float = Math.fround(f * snap);
		return (m / snap);
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

	public static inline function listFromString(string:String):Array<String>
	{
		return string.trim().split('\n').map(str -> str.trim());
	}

	public static inline function dominantColor(sprite:flixel.FlxSprite):Int
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
		countByColor[FlxColor.BLACK] = 0;
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

	public static function lerp(base:Float, target:Float, alpha:Float):Float
	{
		if (alpha == 0)
			return base;
		if (alpha == 1)
			return target;
		return base + alpha * (target - base);
	}

	public static function smoothLerpPrecision(base:Float, target:Float, deltaTime:Float, duration:Float, precision:Float = 1 / 100):Float
	{
		if (deltaTime == 0)
			return base;
		if (base == target)
			return target;
		return lerp(target, base, Math.pow(precision, deltaTime / duration));
	}

	inline public static function browserLoad(site:String)
	{
		#if linux
		var cmd = Sys.command("xdg-open", [site]);
		if (cmd != 0)
			cmd = Sys.command("/usr/bin/xdg-open", [site]);
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1)
			return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;

		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String
	{
		final company:String = FlxG.stage.application.meta.get('company');
		return '${company}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
	}
}
