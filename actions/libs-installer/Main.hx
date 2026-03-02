import sys.FileSystem;
import sys.io.File;
import haxe.Json;

typedef HmmConfig =
{
	dependencies:Array<LibraryConfig>
}

typedef LibraryConfig =
{
	name:String,
	type:String,
	?version:String,
	?dir:String,
	?ref:String,
	?url:String
}

class Main
{
	public static function main():Void
	{
		if (!FileSystem.exists('.haxelib'))
			runCommand(['haxelib', 'newrepo', '--quiet', '--never']);

		final config:HmmConfig = Json.parse(File.getContent('./haxelibs.json'));

		final options:Array<String> = ['--quiet', '--never', '--skip-dependencies'];

		for (lib in config.dependencies)
		{
			switch (lib.type)
			{
				case 'haxelib':
					final args:Array<String> = ['haxelib', 'install'];

					args.push(lib.name);

					if (lib.version != null)
						args.push(lib.version);

					runCommand(args.concat(options));
				case 'git':
					final args:Array<String> = ['haxelib', 'git'];

					args.push(lib.name);
					args.push(lib.url);

					if (lib.ref != null)
						args.push(lib.ref);

					runCommand(args.concat(options));
			}
		}

		runCommand(['haxelib', 'list']);
	}

	public static function runCommand(args:Array<String>):Void
	{
		final command:String = args.join(' ');

		if (command != AnsiColors.yellow(command))
			Sys.println(AnsiColors.yellow(command));

		Sys.command(args.shift(), args);
	}
}

class AnsiColors
{
	public static inline function red(input:String):String
	{
		return color(input, Red);
	}

	public static inline function green(input:String):String
	{
		return color(input, Green);
	}

	public static inline function yellow(input:String):String
	{
		return color(input, Yellow);
	}

	public static inline function blue(input:String):String
	{
		return color(input, Blue);
	}

	public static inline function magenta(input:String):String
	{
		return color(input, Magenta);
	}

	public static inline function cyan(input:String):String
	{
		return color(input, Cyan);
	}

	public static inline function gray(input:String):String
	{
		return color(input, Gray);
	}

	public static inline function white(input:String):String
	{
		return color(input, White);
	}

	public static inline function none(input:String):String
	{
		return color(input, None);
	}

	public static inline function color(input:String, ansiColor:AnsiColor):String
	{
		return #if sys '$ansiColor$input${AnsiColor.None}' #else input #end;
	}
}

enum abstract AnsiColor(String) from String to String
{
	var Black = '\033[0;30m';
	var Red = '\033[0;31m';
	var Green = '\033[0;32m';
	var Yellow = '\033[0;33m';
	var Blue = '\033[0;34m';
	var Magenta = '\033[0;35m';
	var Cyan = '\033[0;36m';
	var Gray = '\033[0;37m';
	var White = '\033[1;37m';
	var None = '\033[0;0m';
}