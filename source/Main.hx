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
import hxwindowmode.WindowColorMode;

class Main extends Sprite
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var fpsVar:FPS;

	// this probably shouldn't be public
	static final config:Dynamic = {
		gameDimensions: [1280, 720],
		initialState: InitState,
		defaultFPS: 60,
		skipSplash: true,
		startFullscreen: false
	};

	public static function main():Void
	{
		WindowColorMode.setDarkMode();
		WindowColorMode.redrawWindowHeader(); // needed for windows 10
		Lib.current.addChild(new Main());
	}

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
		untyped __cpp__('', ALSoft);

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

		var game:FlxGame = new FlxGame(config.gameDimensions[0], config.gameDimensions[1], config.initialState, config.defaultFPS, config.defaultFPS,
			config.skipSplash, config.startFullscreen);

		@:privateAccess
		game._customSoundTray = FunkinSoundTray;

		addChild(game);

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

		#if DISCORD_ALLOWED
		DiscordClient.load();
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

class FunkinSoundTray extends flixel.system.ui.FlxSoundTray
{
	var graphicScale:Float = 0.30;
	var lerpYPos:Float = 0;
	var alphaTarget:Float = 0;

	var volumeMaxSound:String;

	public function new()
	{
		super();
		removeChildren();

		var bg:Bitmap = new Bitmap(Assets.getBitmapData("assets/images/soundtray/volumebox.png"));
		bg.scaleX = graphicScale;
		bg.scaleY = graphicScale;
		bg.smoothing = true;
		addChild(bg);

		y = -height;
		visible = false;

		var backingBar:Bitmap = new Bitmap(Assets.getBitmapData("assets/images/soundtray/bars_10.png"));
		backingBar.x = 9;
		backingBar.y = 5;
		backingBar.scaleX = graphicScale;
		backingBar.scaleY = graphicScale;
		backingBar.smoothing = true;
		addChild(backingBar);
		backingBar.alpha = 0.4;

		_bars = [];

		for (i in 1...11)
		{
			var bar:Bitmap = new Bitmap(Assets.getBitmapData("assets/images/soundtray/bars_" + i + ".png"));
			bar.x = 9;
			bar.y = 5;
			bar.scaleX = graphicScale;
			bar.scaleY = graphicScale;
			bar.smoothing = true;
			addChild(bar);
			_bars.push(bar);
		}

		screenCenter();
		y = -height - 10;

		volumeUpSound = 'assets/sounds/soundtray/Volup.ogg';
		volumeDownSound = 'assets/sounds/soundtray/Voldown.ogg';
		volumeMaxSound = 'assets/sounds/soundtray/VolMAX.ogg';
	}

	override public function update(ms:Float):Void
	{
		var elapsed = ms / 1000.0;

		var hasVolume:Bool = (!FlxG.sound.muted && FlxG.sound.volume > 0);

		if (hasVolume)
		{
			if (_timer > 0)
			{
				_timer -= elapsed;
				if (_timer <= 0)
				{
					lerpYPos = -height - 10;
					alphaTarget = 0;
				}
			}
			else if (y <= -height)
			{
				visible = false;
				active = false;
			}
		}
		else if (!visible)
		{
			showTray();
		}

		y = CoolUtil.smoothLerpPrecision(y, lerpYPos, elapsed, 0.768);
		alpha = CoolUtil.smoothLerpPrecision(alpha, alphaTarget, elapsed, 0.307);
		screenCenter();
	}

	override function showIncrement():Void
	{
		moveTrayMakeVisible(true);
		saveVolumePreferences();
	}

	override function showDecrement():Void
	{
		moveTrayMakeVisible(false);
		saveVolumePreferences();
	}

	function moveTrayMakeVisible(up:Bool = false):Void
	{
		showTray();

		if (!silent)
		{
			var sound:Null<String> = FlxG.sound.volume == 1 ? volumeMaxSound : (up ? volumeUpSound : volumeDownSound);
			if (sound != null)
				FlxG.sound.play(sound);
		}
	}

	function showTray():Void
	{
		_timer = 1;
		lerpYPos = 10;
		visible = true;
		active = true;
		alphaTarget = 1;

		updateBars();
	}

	function updateBars():Void
	{
		var globalVolume:Int = FlxG.sound.muted || FlxG.sound.volume == 0 ? 0 : Math.round(FlxG.sound.volume * 10);

		for (i in 0..._bars.length)
			_bars[i].visible = i < globalVolume;
	}

	function saveVolumePreferences():Void
	{
		#if FLX_SAVE
		if (FlxG.save.isBound)
		{
			FlxG.save.data.mute = FlxG.sound.muted;
			FlxG.save.data.volume = FlxG.sound.volume;
			FlxG.save.flush();
		}
		#end
	}
}
