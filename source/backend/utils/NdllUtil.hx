package backend.utils;

import psychlua.LuaUtils;

@:keep
class NdllUtil
{
	public static var os(get, never):String;

	inline public static function get_os():String
	{
		return LuaUtils.getBuildTarget();
	}

	public static function getFunction(ndllPath:String, name:String, args:Int):Dynamic
	{
		#if NDLL_ALLOWED
		var resolvedPath:String = Paths.ndll(ndllPath);
		var func:Dynamic = _getNdllFunc(resolvedPath, name, args);
		trace('Loading ndll function "${name}" from "${resolvedPath}".');

		return Reflect.makeVarArgs(function(a:Array<Dynamic>)
		{
			return macros.Macros.generateReflectionLike(25, "func", "a");
		});
		#else
		trace("Ndlls are not supported on this platform!");
		return noop;
		#end
	}

	#if NDLL_ALLOWED
	public static function _getNdllFunc(ndll:String, name:String, args:Int):Dynamic
	{
		if (!FileSystem.exists(ndll))
		{
			trace('getFunction: ndll "${ndll}" doesn\'t exist!');
			return noop;
		}
		var func = lime.system.CFFI.load(Assets.getPath(ndll), name, args);
		if (func != null)
			return func;

		trace('getFunction: There was an error getting the ndll\'s functions! {ndll: ${ndll}, function: ${name}, argument count: ${args}}');
		return noop;
	}
	#end

	@:dox(hide) @:noCompletion static function noop()
	{
	}
}
