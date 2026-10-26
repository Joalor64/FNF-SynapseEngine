package backend.utils;

class ColorUtil
{
	public static function withAlpha(color:Int, alpha:Float):Int
	{
		var c:FlxColor = color;
		c.alphaFloat = alpha;
		return c;
	}

	public static function multiplySaturation(color:Int, mult:Float):Int
	{
		var c:FlxColor = color;
		c.saturation *= mult;
		return c;
	}

	public static function multiplyBrightness(color:Int, mult:Float):Int
	{
		var c:FlxColor = color;
		c.brightness *= mult;
		return c;
	}

	public static function getHue(color:Int):Float
		return (color : FlxColor).hue;

	public static function getSaturation(color:Int):Float
		return (color : FlxColor).saturation;

	public static function getBrightness(color:Int):Float
		return (color : FlxColor).brightness;
}
