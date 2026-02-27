package;

#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
#end

#if DISCORD_ALLOWED
import backend.Discord.DiscordClient;
#end

import openfl.display.FPS;

class Main extends Sprite
{
	public final config:Dynamic = {
		gameDimensions: [1280, 720],
		initialState: PreloadState,
		defaultFPS: 60,
		skipSplash: true,
		startFullscreen: false
	};

	public static var fpsVar:FPS;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	#if desktop
	static function __init__():Void {
		var origin:String = #if hl Sys.getCwd() #else Sys.programPath() #end;

		var configPath:String = Path.directory(Path.withoutExtension(origin));
		#if windows
		configPath += "/alsoft.ini";
		#elseif mac
		configPath = Path.directory(configPath) + "/Resources/alsoft.conf";
		#else
		configPath += "/alsoft.conf";
		#end

		Sys.putEnv("ALSOFT_CONF", configPath);
	}
	#end

	public function new()
	{
		super();

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onFatalCrash);
		#end
		#end
		
		FlxG.save.bind('funkin', 'ninjamuffin99');
		Highscore.load();

		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0") ['--no-lua'] #end);
		#end

		ClientPrefs.loadDefaultKeys();
		addChild(new FlxGame(config.gameDimensions[0], config.gameDimensions[1], config.initialState, config.defaultFPS, config.defaultFPS, config.skipSplash,
			config.startFullscreen));

		fpsVar = new FPS(10, 10, 0xFFFFFF);
		addChild(fpsVar);
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.showFPS;
		}

		#if (linux || mac)
		Lib.current.stage.window.setIcon(lime.graphics.Image.fromFile("icon.png"));
		#end

		#if html5
		FlxG.autoPause = FlxG.mouse.visible = false;
		#end
		
		#if DISCORD_ALLOWED
		if (!DiscordClient.isInitialized)
		{
			DiscordClient.initialize();
		}

		Lib.current.stage.application.window.onClose.add(function()
		{
			if (DiscordClient.isInitialized)
				DiscordClient.shutdown();
		});
		#end
	}

	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var stack:Array<String> = [];
		stack.push(e.error);

		for (stackItem in CallStack.exceptionStack(true))
		{
			switch (stackItem)
			{
				case CFunction:
					stack.push('C Function');
				case Module(m):
					stack.push('Module ($m)');
				case FilePos(s, file, line, column):
					stack.push('$file (line $line)');
				case Method(classname, method):
					stack.push('$classname (method $method)');
				case LocalFunction(name):
					stack.push('Local Function ($name)');
			}
		}

		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		final msg:String = stack.join('\n');

		#if sys
		try
		{
			if (!FileSystem.exists('./crash/'))
				FileSystem.createDirectory('./crash/');

			File.saveContent('./crash/'
				+ Lib.application.meta.get('file')
				+ '-'
				+ Date.now().toString().replace(' ', '-').replace(':', "'")
				+ '.txt',
				msg
				+ '\n');
		}
		catch (e:Dynamic)
		{
			Sys.println("Error!\nCouldn't save the crash dump because:\n" + e);
		}
		#end

		#if (flixel < "6.0.0")
		FlxG.bitmap.dumpCache();
		#end
		FlxG.bitmap.clearCache();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		#if DISCORD_ALLOWED
		Discord.shutdown();
		#end

		Lib.application.window.alert('Uncaught Error: \n'
			+ msg
			+ '\n\nPlease report this error to the GitHub page: https://github.com/Joalor64GH/FNF-SynapseEngine/issues\n\n> Crash Handler written by: sqirra-rng',
			'Error!');
		Sys.println('Uncaught Error: \n'
			+ msg
			+
			'\n\nPlease report this error to the GitHub page: https://github.com/Joalor64GH/FNF-SynapseEngine/issues\n\n> Crash Handler written by: sqirra-rng');
		Sys.exit(1);
	}

	function onFatalCrash(msg:String):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "VSRob_" + dateNow + ".txt";

		errMsg += '${msg}\n';

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += 'in ${file} (line ${line})\n';
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\n\nPlease report this error to the GitHub page: https://github.com/Joalor64GH/FNF-SynapseEngine/issues\n\n> Crash Handler written by: sqirra-rng";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		#if DISCORD_ALLOWED
		Discord.shutdown();
		#end
		Sys.exit(1);
	}
	#end
}
