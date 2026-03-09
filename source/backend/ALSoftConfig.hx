package backend;

#if desktop
import sys.FileSystem;
import haxe.io.Path;

@:keep
@:nullSafety
class ALSoftConfig
{
	private static function __init__():Void
	{
		var configPath:String = Path.directory(Path.withoutExtension(#if hl Sys.getCwd() #else Sys.programPath() #end));
		#if windows
		configPath += "/alsoft.ini";
		#elseif mac
		configPath = '${Path.directory(configPath)}/Resources/alsoft.conf';
		#else
		configPath += "/alsoft.conf";
		#end

		Sys.putEnv("ALSOFT_CONF", FileSystem.fullPath(configPath));
		#if debug
		Sys.println("Successfully loaded alsoft config.");
		#end
	}
}
#end
