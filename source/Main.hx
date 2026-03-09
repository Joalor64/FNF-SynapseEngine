package;

#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
#end
import debug.FPS;
#if linux
import hxgamemode.GamemodeClient;
#end

class Main extends Sprite
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public final config:Dynamic = {
		gameDimensions: [1280, 720],
		initialState: InitState,
		defaultFPS: 60,
		skipSplash: true,
		startFullscreen: false
	};

	public static var fpsVar:FPS;

	public static function main():Void
		Lib.current.addChild(new Main());

	private static function __init__():Void
	{
		#if linux
		if (GamemodeClient.request_start() != 0)
		{
			Sys.println('Failed to request gamemode start: ${GamemodeClient.error_string()}...');
			System.exit(1);
		}
		else
		{
			Sys.println('Succesfully requested gamemode to start...');
		}
		#end
	}

	public function new()
	{
		untyped __cpp__('', backend.ALSoft);

		super();

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onFatalCrash);
		#end
		#end

		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0") ['--no-lua'] #end);
		#end

		FlxG.signals.preStateSwitch.add(() ->
		{
			#if cpp
			cpp.NativeGc.run(true);
			cpp.NativeGc.enable(true);
			#end
			#if (flixel < "6.0.0")
			FlxG.bitmap.dumpCache();
			#end
			FlxG.bitmap.clearUnused();

			System.gc();
		});

		FlxG.signals.postStateSwitch.add(() ->
		{
			#if cpp
			cpp.NativeGc.run(false);
			cpp.NativeGc.enable(false);
			#end
			System.gc();
		});

		addChild(new FlxGame(config.gameDimensions[0], config.gameDimensions[1], config.initialState, config.defaultFPS, config.defaultFPS, config.skipSplash,
			config.startFullscreen));

		fpsVar = new FPS(10, 10, 0xFFFFFF);
		addChild(fpsVar);
		if (fpsVar != null)
			fpsVar.visible = ClientPrefs.data.showFPS;

		#if (linux || mac)
		Lib.current.stage.window.setIcon(lime.graphics.Image.fromFile("icon.png"));
		#end

		#if html5
		FlxG.autoPause = FlxG.mouse.visible = false;
		#end

		Lib.current.stage.application.window.onClose.add(function()
		{
			#if linux
			if (GamemodeClient.request_end() != 0)
			{
				trace('Failed to request gamemode end: ${GamemodeClient.error_string()}...');
				System.exit(1);
			}
			else
			{
				trace('Succesfully requested gamemode to end...');
			}
			#end
		});
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
		DiscordClient.shutdown();
		#end

		Lib.application.window.alert('Uncaught Error: \n'
			+ msg
			+
			'\n\nPlease report this error to the GitHub page: https://github.com/Joalor64GH/FNF-SynapseEngine/issues\n\n> Crash Handler written by: sqirra-rng',
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

		path = "./crash/" + "SynapseEngine_" + dateNow + ".txt";

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
		DiscordClient.shutdown();
		#end
		Sys.exit(1);
	}
	#end
}
