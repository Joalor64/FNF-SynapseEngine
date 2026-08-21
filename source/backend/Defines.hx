package backend;

#if CUSTOM_DEFINES
class Defines
{
	static final path:String = 'defines/';
	static final extension:String = '.define';

	static function exists(id:String):Bool
		return FileSystem.exists(path + id + extension);

	static function get(id:String):Null<String>
		return exists(id) ? File.getContent(path + id + extension) : null;

	static function getBool(id:String, defaultValue:Bool = false):Bool
	{
		var val = get(id);
		return val != null ? val.toLowerCase() == "true" : defaultValue;
	}

	static function getInt(id:String, defaultValue:Int = 0):Int
	{
		var val = get(id);
		return val != null ? Std.parseInt(val) : defaultValue;
	}
}
#end
