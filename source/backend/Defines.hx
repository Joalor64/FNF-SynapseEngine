package backend;

#if CUSTOM_DEFINES
class Defines
{
	static final path:String = 'defines/';
	static final extension:String = '.define';

	public static function exists(id:String):Bool
		return FileSystem.exists(path + id + extension);

	public static function get(id:String):Null<String>
		return exists(id) ? File.getContent(path + id + extension).trim() : null;

	public static function getBool(id:String, defaultValue:Bool = false):Bool
	{
		var val = get(id);
		return val != null ? val.toLowerCase() == "true" : defaultValue;
	}

	public static function getInt(id:String, defaultValue:Int = 0):Int
	{
		var str = get(id);
		var val:Null<Int> = str != null ? Std.parseInt(str) : null;
		return val != null ? val : defaultValue;
	}

	public static function getFloat(id:String, defaultValue:Float = 0):Float
	{
		var str = get(id);
		if (str == null)
			return defaultValue;
		var val:Float = Std.parseFloat(str);
		return Math.isNaN(val) ? defaultValue : val;
	}
}
#end
