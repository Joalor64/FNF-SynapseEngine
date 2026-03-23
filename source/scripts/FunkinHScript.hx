package scripts;

import rulescript.*;
import rulescript.parsers.*;
import cutscenes.CutsceneHandler;
import options.OptionsSubState;
import options.*;
#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
#end

class FunkinHScript extends FlxBasic
{
	public var locals(get, set):Map<String, {r:Dynamic}>;

	function get_locals():Map<String, {r:Dynamic}>
	{
		@:privateAccess
		return interp.locals;
	}

	function set_locals(local:Map<String, {r:Dynamic}>)
	{
		@:privateAccess
		return interp.locals = local;
	}

	public var parser:HxParser = new HxParser();
	public var interp:RuleScriptInterp = new RuleScriptInterp();

	public var script:RuleScript = null;
	public var scriptPath:String = null;

	public function new(?file:String, ?execute:Bool = true)
	{
		super();

		scriptPath = file;
		script = new RuleScript(interp, parser);

		if (file != null)
			script.scriptName = ~/\.(hx|hxs|hxc|hscript)$/.replace(file.split('/').pop(), '');

		parser.allowAll();
		parser.preprocesorValues = macros.Macros.getDefines();

		setVariable('this', this);
		setVariable('Function_Stop', Globals.Function_Stop);
		setVariable('Function_Continue', Globals.Function_Continue);
		setVariable('Function_Halt', Globals.Function_Halt);
		setVariable('version', Lib.application.meta.get('version'));

		setVariable('trace', function(value:Dynamic)
		{
			trace(value);
		});

		setVariable('importScript', function(source:String)
		{
			var name:String = StringTools.replace(source, '.', '/');
			var hscript:FunkinHScript = new FunkinHScript(Paths.script(name), false);
			hscript.execute(Paths.script(name), false);
			return hscript.getAll();
		});

		setVariable('stopScript', function()
		{
			this.destroy();
		});

		// Haxe
		setVariable('Array', Array);
		setVariable('Bool', Bool);
		setVariable('Date', Date);
		setVariable('DateTools', DateTools);
		setVariable('Dynamic', Dynamic);
		setVariable('EReg', EReg);
		#if sys
		setVariable('File', File);
		setVariable('FileSystem', FileSystem);
		#end
		setVariable('Float', Float);
		setVariable('Int', Int);
		setVariable('Json', Json);
		setVariable('Lambda', Lambda);
		setVariable('Math', Math);
		setVariable('Path', Path);
		setVariable('Reflect', Reflect);
		setVariable('Std', Std);
		setVariable('StringBuf', StringBuf);
		setVariable('String', String);
		setVariable('StringTools', StringTools);
		#if sys
		setVariable('Sys', Sys);
		#end
		setVariable('TJSON', TJSON);
		setVariable('Type', Type);
		setVariable('Xml', Xml);

		setVariable('createThread', function(func:Void->Void)
		{
			#if sys
			sys.thread.Thread.create(() ->
			{
				func();
			});
			#else
			func();
			#end
		});

		// OpenFL
		setVariable('Assets', Assets);
		setVariable('BitmapData', BitmapData);
		setVariable('Lib', Lib);
		setVariable('ShaderFilter', openfl.filters.ShaderFilter);
		setVariable('Sound', openfl.media.Sound);

		// Flixel
		setVariable('FlxAxes', {
			'X': FlxAxes.X,
			'Y': FlxAxes.Y,
			'XY': FlxAxes.XY
		});
		setVariable('FlxBackdrop', FlxBackdrop);
		setVariable('FlxBasic', FlxBasic);
		setVariable('FlxCamera', FlxCamera);
		setVariable('FlxCameraFollowStyle', {
			'LOCKON': FlxCamera.FlxCameraFollowStyle.LOCKON,
			'PLATFORMER': FlxCamera.FlxCameraFollowStyle.PLATFORMER,
			'TOPDOWN': FlxCamera.FlxCameraFollowStyle.TOPDOWN,
			'TOPDOWN_TIGHT': FlxCamera.FlxCameraFollowStyle.TOPDOWN_TIGHT,
			'SCREEN_BY_SCREEN': FlxCamera.FlxCameraFollowStyle.SCREEN_BY_SCREEN,
			'NO_DEAD_ZONE': FlxCamera.FlxCameraFollowStyle.NO_DEAD_ZONE
		});
		setVariable('FlxColor', {
			'BLACK': FlxColor.BLACK,
			'BLUE': FlxColor.BLUE,
			'BROWN': FlxColor.BROWN,
			'CYAN': FlxColor.CYAN,
			'GRAY': FlxColor.GRAY,
			'GREEN': FlxColor.GREEN,
			'LIME': FlxColor.LIME,
			'MAGENTA': FlxColor.MAGENTA,
			'ORANGE': FlxColor.ORANGE,
			'PINK': FlxColor.PINK,
			'PURPLE': FlxColor.PURPLE,
			'RED': FlxColor.RED,
			'TRANSPARENT': FlxColor.TRANSPARENT,
			'WHITE': FlxColor.WHITE,
			'YELLOW': FlxColor.YELLOW,
			'add': FlxColor.add,
			'fromCMYK': FlxColor.fromCMYK,
			'fromHSB': FlxColor.fromHSB,
			'fromHSL': FlxColor.fromHSL,
			'fromInt': FlxColor.fromInt,
			'fromRGB': FlxColor.fromRGB,
			'fromRGBFloat': FlxColor.fromRGBFloat,
			'fromString': FlxColor.fromString,
			'interpolate': FlxColor.interpolate,
			'to24Bit': function(color:Int) return color & 0xffffff
		});
		setVariable('FlxEase', FlxEase);
		setVariable('FlxG', FlxG);
		setVariable('FlxGroup', FlxGroup);
		setVariable('FlxKey', {
			'ANY': -2,
			'NONE': -1,
			'A': 65,
			'B': 66,
			'C': 67,
			'D': 68,
			'E': 69,
			'F': 70,
			'G': 71,
			'H': 72,
			'I': 73,
			'J': 74,
			'K': 75,
			'L': 76,
			'M': 77,
			'N': 78,
			'O': 79,
			'P': 80,
			'Q': 81,
			'R': 82,
			'S': 83,
			'T': 84,
			'U': 85,
			'V': 86,
			'W': 87,
			'X': 88,
			'Y': 89,
			'Z': 90,
			'ZERO': 48,
			'ONE': 49,
			'TWO': 50,
			'THREE': 51,
			'FOUR': 52,
			'FIVE': 53,
			'SIX': 54,
			'SEVEN': 55,
			'EIGHT': 56,
			'NINE': 57,
			'PAGEUP': 33,
			'PAGEDOWN': 34,
			'HOME': 36,
			'END': 35,
			'INSERT': 45,
			'ESCAPE': 27,
			'MINUS': 189,
			'PLUS': 187,
			'DELETE': 46,
			'BACKSPACE': 8,
			'LBRACKET': 219,
			'RBRACKET': 221,
			'BACKSLASH': 220,
			'CAPSLOCK': 20,
			'SEMICOLON': 186,
			'QUOTE': 222,
			'ENTER': 13,
			'SHIFT': 16,
			'COMMA': 188,
			'PERIOD': 190,
			'SLASH': 191,
			'GRAVEACCENT': 192,
			'CONTROL': 17,
			'ALT': 18,
			'SPACE': 32,
			'UP': 38,
			'DOWN': 40,
			'LEFT': 37,
			'RIGHT': 39,
			'TAB': 9,
			'PRINTSCREEN': 301,
			'F1': 112,
			'F2': 113,
			'F3': 114,
			'F4': 115,
			'F5': 116,
			'F6': 117,
			'F7': 118,
			'F8': 119,
			'F9': 120,
			'F10': 121,
			'F11': 122,
			'F12': 123,
			'NUMPADZERO': 96,
			'NUMPADONE': 97,
			'NUMPADTWO': 98,
			'NUMPADTHREE': 99,
			'NUMPADFOUR': 100,
			'NUMPADFIVE': 101,
			'NUMPADSIX': 102,
			'NUMPADSEVEN': 103,
			'NUMPADEIGHT': 104,
			'NUMPADNINE': 105,
			'NUMPADMINUS': 109,
			'NUMPADPLUS': 107,
			'NUMPADPERIOD': 110,
			'NUMPADMULTIPLY': 106,
			'fromStringMap': FlxKey.fromStringMap,
			'toStringMap': FlxKey.toStringMap,
			'fromString': FlxKey.fromString,
			'toString': function(key:Int) return FlxKey.toStringMap.get(key)
		});
		setVariable('FlxMath', FlxMath);
		setVariable('FlxObject', FlxObject);
		setVariable('FlxRuntimeShader', FlxRuntimeShader);
		setVariable('FlxSound', FlxSound);
		setVariable('FlxSprite', FlxSprite);
		setVariable('FlxSpriteGroup', FlxSpriteGroup);
		setVariable('FlxText', FlxText);
		setVariable('FlxTextAlign', {
			'LEFT': FlxTextAlign.LEFT,
			'CENTER': FlxTextAlign.CENTER,
			'RIGHT': FlxTextAlign.RIGHT,
			'JUSTIFY': FlxTextAlign.JUSTIFY
		});
		setVariable('FlxTextBorderStyle', {
			'NONE': FlxTextBorderStyle.NONE,
			'SHADOW': FlxTextBorderStyle.SHADOW,
			'OUTLINE': FlxTextBorderStyle.OUTLINE,
			'OUTLINE_FAST': FlxTextBorderStyle.OUTLINE_FAST
		});
		setVariable('FlxTimer', FlxTimer);
		setVariable('FlxTween', FlxTween);
		setVariable('FlxTypedGroup', FlxTypedGroup);
		setVariable('createTypedGroup', function(?variable)
		{
			return variable = new FlxTypedGroup<Dynamic>();
		});
		setVariable('createSpriteGroup', function(?variable)
		{
			return variable = new FlxSpriteGroup();
		});

		// State Stuff
		setVariable('add', FlxG.state.add);
		setVariable('remove', FlxG.state.remove);
		setVariable('insert', FlxG.state.insert);
		setVariable('members', FlxG.state.members);
		setVariable('state', FlxG.state);

		// Game Stuff
		if (FlxG.state is PlayState && PlayState.instance != null)
			setVariable('game', PlayState.instance);

		#if ACHIEVEMENTS_ALLOWED
		setVariable('Achievements', Achievements);
		#end
		setVariable('Alphabet', Alphabet);
		setVariable('AttachedSprite', AttachedSprite);
		setVariable('AttachedText', AttachedText);
		setVariable('BGSprite', BGSprite);
		setVariable('ClientPrefs', ClientPrefs);
		setVariable('Conductor', Conductor);
		setVariable('Constants', Constants);
		setVariable('CoolUtil', CoolUtil);
		setVariable('CutsceneHandler', CutsceneHandler);
		#if DISCORD_ALLOWED
		setVariable('DiscordClient', DiscordClient);
		#end
		setVariable('Difficulty', Difficulty);
		#if LUA_ALLOWED
		setVariable('FunkinLua', FunkinLua);
		#end
		#if MODS_ALLOWED
		setVariable('Mods', Mods);
		setVariable('ModsMenuState', ModsMenuState);
		#end
		setVariable('Main', Main);
		setVariable('MusicBeatState', MusicBeatState);
		setVariable('MusicBeatSubstate', MusicBeatSubstate);
		setVariable('Note', Note);
		setVariable('Paths', Paths);
		setVariable('PlayState', PlayState);
		setVariable('ScriptedState', ScriptedState);
		setVariable('ScriptedSubState', ScriptedSubState);
		#if VIDEOS_ALLOWED
		setVariable('VideoSprite', VideoSprite);
		setVariable('VideoState', VideoState);
		#end

		// you can't access these unless they're exposed to hscript???
		// i mean, i'm pretty sure that should be obvious, but cmon bruh
		setVariable('GameplayChangersSubstate', GameplayChangersSubstate);
		setVariable('ResetAchievementSubState', ResetAchievementSubState);
		setVariable('ResetScoreSubState', ResetScoreSubState);

		setVariable('NotesSubState', NotesSubState);
		setVariable('ControlsSubState', ControlsSubState);
		setVariable('MiscSubState', MiscSubState);
		setVariable('VisualsSubState', VisualsSubState);
		setVariable('GameplaySubState', GameplaySubState);
		setVariable('NoteOffsetState', NoteOffsetState);

		if (execute && file != null)
			this.execute(file);
	}

	public function execute(file:String, ?executeCreate:Bool = true):Void
	{
		try
		{
			var content = File.getContent(file);
			var result = script.tryExecute(content);

			if (result == null)
			{
				trace('Script returned null: $file');
				return;
			}

			#if (rulescript >= "0.5.0")
			if (result.error != null)
			{
				trace('Script error in $file: ${result.error}');
				return;
			}
			#end

			trace('Script Loaded Successfully: $file');

			if (executeCreate)
				executeFunc('create', []);
		}
		catch (e:Dynamic)
		{
			Lib.application.window.alert(Std.string(e), 'Fatal error executing script $file');
		}
	}

	public function executeStr(code:String):Dynamic
	{
		try
		{
			return script.tryExecute(code);
		}
		catch (e:Dynamic)
		{
			Lib.application.window.alert(Std.string(e), 'Error executing string');
			return null;
		}
	}

	public function setVariable(name:String, val:Dynamic):Void
	{
		try
		{
			if (script != null)
			{
				script.variables.set(name, val);
				locals.set(name, {r: val});
			}
		}
		catch (e:Dynamic)
		{
			Lib.application.window.alert(Std.string(e), 'Error setting variable $name');
		}
	}

	public function getVariable(name:String):Dynamic
	{
		try
		{
			if (locals.exists(name) && locals[name] != null)
				return locals.get(name).r;
			else if (script != null && script.variables.exists(name))
				return script.variables.get(name);
		}
		catch (e:Dynamic)
		{
			Lib.application.window.alert(Std.string(e), 'Error getting variable $name');
		}
		return null;
	}

	public function removeVariable(name:String):Void
	{
		try
		{
			if (script != null)
				script.variables.remove(name);
		}
		catch (e:Dynamic)
		{
			Lib.application.window.alert(Std.string(e), 'Error removing variable $name');
		}
	}

	public function existsVariable(name:String):Bool
	{
		try
		{
			if (script != null)
				return script.variables.exists(name);
		}
		catch (e:Dynamic)
		{
			Lib.application.window.alert(Std.string(e), 'Error checking variable $name');
		}
		return false;
	}

	public function executeFunc(funcName:String, ?args:Array<Dynamic>):Dynamic
	{
		if (!existsVariable(funcName))
			return null;

		try
		{
			var func = getVariable(funcName);
			if (func == null)
				return null;

			return Reflect.callMethod(null, func, args == null ? [] : args);
		}
		catch (e:Dynamic)
		{
			Lib.application.window.alert(Std.string(e), 'Error calling function $funcName');
		}

		return null;
	}

	public function getAll():Dynamic
	{
		var result:Dynamic = {};

		try
		{
			for (key in locals.keys())
				Reflect.setField(result, key, getVariable(key));
			for (key in interp.variables.keys())
				Reflect.setField(result, key, getVariable(key));
		}
		catch (e:Dynamic)
		{
			Lib.application.window.alert(Std.string(e), 'Error getting all variables');
		}

		return result;
	}

	override function destroy()
	{
		super.destroy();
		parser = null;
		interp = null;
		script = null;
	}
}
