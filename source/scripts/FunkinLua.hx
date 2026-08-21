package scripts;

#if LUA_ALLOWED
import psychlua.*;
#end
import openfl.display.BlendMode;
import Type.ValueType;
import cutscenes.DialogueBoxPsych;
#if DISCORD_ALLOWED
import backend.DiscordClient;
#end
import scripts.FunkinHScript;

class FunkinLua
{
	#if LUA_ALLOWED
	public var lua:State = null;
	#end
	public var camTarget:FlxCamera;
	public var scriptName:String = '';
	public var modFolder:String = null;
	public var closed:Bool = false;

	#if HSCRIPT_ALLOWED
	public static var hscript:FunkinHScript = null;
	#end

	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();

	public function new(scriptName:String)
	{
		#if LUA_ALLOWED
		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);

		try
		{
			var result:Dynamic = LuaL.dofile(lua, scriptName);
			var resultStr:String = Lua.tostring(lua, result);
			if (resultStr != null && result != 0)
			{
				trace('Error on lua script! ' + resultStr);
				#if windows
				Application.current.window.alert(resultStr, 'Error on lua script!');
				#else
				LuaUtils.luaTrace(lua, 'Error loading lua script: "$scriptName"\n' + resultStr, true, false, FlxColor.RED);
				#end
				lua = null;
				return;
			}
		}
		catch (e:Dynamic)
		{
			trace(e);
			return;
		}
		this.scriptName = scriptName.trim();
		initHaxeModule();

		trace('lua file loaded succesfully:' + scriptName);

		if (lua != null)
		{
			LuaL.dostring(lua, "
				os.execute, os.getenv, os.rename, os.remove, os.tmpname = nil, nil, nil, nil, nil
				io, load, loadfile, loadstring, dofile = nil, nil, nil, nil, nil
				require, module, package = nil, nil, nil
				setfenv, getfenv = nil, nil
				newproxy = nil
				gcinfo = nil
				debug = nil
				jit = nil
			");
		}

		var myFolder:Array<String> = this.scriptName.split('/');
		#if MODS_ALLOWED
		if (myFolder[0] + '/' == Paths.mods()
			&& (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) // is inside mods folder
			this.modFolder = myFolder[1];
		#end

		// Lua shit
		set('Function_StopLua', Globals.Function_Halt);
		set('Function_Stop', Globals.Function_Stop);
		set('Function_Continue', Globals.Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.song);
		set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
		set('loadedSongName', Song.loadedSongName);
		set('loadedSongPath', Paths.formatToSongPath(Song.loadedSongName));
		set('startedCountdown', false);
		set('curStage', PlayState.SONG.stage);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);

		set('difficultyName', Difficulty.getString(false));
		set('difficultyPath', Difficulty.getFilePath());
		set('difficultyNameTranslation', Difficulty.getString(true));
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState cringe ass nae nae bullcrap
		set('curBeat', 0);
		set('curStep', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);

		set('score', 0);
		set('misses', 0);
		set('hits', 0);

		set('rating', 0);
		set('ratingName', '');
		set('ratingFC', '');
		set('version', Constants.SYNAPSE_ENGINE_VERSION.trim());
		set('modFolder', this.modFolder);

		set('inGameOver', false);
		set('mustHitSection', false);
		set('altAnim', false);
		set('gfSection', false);

		// Gameplay settings
		set('healthGainMult', PlayState.instance.healthGain);
		set('healthLossMult', PlayState.instance.healthLoss);
		#if FLX_PITCH set('playbackRate', PlayState.instance.playbackRate); #end
		set('instakillOnMiss', PlayState.instance.instakillOnMiss);
		set('botPlay', PlayState.instance.cpuControlled);
		set('practice', PlayState.instance.practiceMode);

		for (i in 0...4)
		{
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		// Default character positions woooo
		set('defaultBoyfriendX', PlayState.instance.BF_X);
		set('defaultBoyfriendY', PlayState.instance.BF_Y);
		set('defaultOpponentX', PlayState.instance.DAD_X);
		set('defaultOpponentY', PlayState.instance.DAD_Y);
		set('defaultGirlfriendX', PlayState.instance.GF_X);
		set('defaultGirlfriendY', PlayState.instance.GF_Y);

		// Character shit
		set('boyfriendName', PlayState.SONG.player1);
		set('dadName', PlayState.SONG.player2);
		set('gfName', PlayState.SONG.gfVersion);

		// Some settings, no jokes
		set('downscroll', ClientPrefs.data.downScroll);
		set('middlescroll', ClientPrefs.data.middleScroll);
		set('framerate', ClientPrefs.data.framerate);
		set('ghostTapping', ClientPrefs.data.ghostTapping);
		set('hideHud', ClientPrefs.data.hideHud);
		set('timeBarType', ClientPrefs.data.timeBarType);
		set('scoreZoom', ClientPrefs.data.scoreZoom);
		set('cameraZoomOnBeat', ClientPrefs.data.camZooms);
		set('flashingLights', ClientPrefs.data.flashing);
		set('noteOffset', ClientPrefs.data.noteOffset);
		set('healthBarAlpha', ClientPrefs.data.healthBarAlpha);
		set('noResetButton', ClientPrefs.data.noReset);
		set('lowQuality', ClientPrefs.data.lowQuality);
		set('shadersEnabled', ClientPrefs.data.shaders);
		set('scriptName', scriptName);
		set('currentModDirectory', Mods.currentModDirectory);

		set('noteSkin', ClientPrefs.data.noteSkin);
		set('noteSkinPostfix', Note.getNoteSkinPostfix());
		set('splashSkin', ClientPrefs.data.splashSkin);
		set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());
		set('splashAlpha', ClientPrefs.data.splashAlpha);
		set('susSplashAlpha', ClientPrefs.data.susSplashAlpha);

		set('buildTarget', LuaUtils.getBuildTarget());

		//
		Lua_helper.add_callback(lua, "getRunningScripts", function()
		{
			var runningScripts:Array<String> = [];
			for (idx in 0...PlayState.instance.luaArray.length)
				runningScripts.push(PlayState.instance.luaArray[idx].scriptName);

			return runningScripts;
		});

		Lua_helper.add_callback(lua, "callOnLuas",
			function(?funcName:String, ?args:Array<Dynamic>, ignoreStops = false, ignoreSelf = true, ?exclusions:Array<String>)
			{
				if (funcName == null)
				{
					#if (linc_luajit >= "0.0.6")
					LuaL.error(lua, "bad argument #1 to 'callOnLuas' (string expected, got nil)");
					#end
					return;
				}
				if (args == null)
					args = [];

				if (exclusions == null)
					exclusions = [];

				Lua.getglobal(lua, 'scriptName');
				var daScriptName = Lua.tostring(lua, -1);
				Lua.pop(lua, 1);
				if (ignoreSelf && !exclusions.contains(daScriptName))
					exclusions.push(daScriptName);
				PlayState.instance.callOnLuas(funcName, args, ignoreStops, exclusions);
			});

		Lua_helper.add_callback(lua, "callScript", function(?luaFile:String, ?funcName:String, ?args:Array<Dynamic>)
		{
			if (luaFile == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #1 to 'callScript' (string expected, got nil)");
				#end
				return;
			}
			if (funcName == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #2 to 'callScript' (string expected, got nil)");
				#end
				return;
			}
			if (args == null)
			{
				args = [];
			}
			var cervix = luaFile + ".lua";
			if (luaFile.endsWith(".lua"))
				cervix = luaFile;
			var doPush = false;
			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix))
			{
				doPush = true;
			}
			else
			{
				cervix = Paths.getPreloadPath(cervix);
				if (FileSystem.exists(cervix))
				{
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);
			if (Assets.exists(cervix))
			{
				doPush = true;
			}
			#end
			if (doPush)
			{
				for (luaInstance in PlayState.instance.luaArray)
				{
					if (luaInstance.scriptName == cervix)
					{
						luaInstance.call(funcName, args);

						return;
					}
				}
			}
			Lua.pushnil(lua);
		});

		Lua_helper.add_callback(lua, "getGlobalFromScript", function(?luaFile:String, ?global:String)
		{ // returns the global from a script
			if (luaFile == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #1 to 'getGlobalFromScript' (string expected, got nil)");
				#end
				return;
			}
			if (global == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #2 to 'getGlobalFromScript' (string expected, got nil)");
				#end
				return;
			}
			var cervix = luaFile + ".lua";
			if (luaFile.endsWith(".lua"))
				cervix = luaFile;
			var doPush = false;
			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix))
			{
				doPush = true;
			}
			else
			{
				cervix = Paths.getPreloadPath(cervix);
				if (FileSystem.exists(cervix))
				{
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);
			if (Assets.exists(cervix))
			{
				doPush = true;
			}
			#end
			if (doPush)
			{
				for (luaInstance in PlayState.instance.luaArray)
				{
					if (luaInstance.scriptName == cervix)
					{
						Lua.getglobal(luaInstance.lua, global);
						if (Lua.isnumber(luaInstance.lua, -1))
						{
							Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -1));
						}
						else if (Lua.isstring(luaInstance.lua, -1))
						{
							Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -1));
						}
						else if (Lua.isboolean(luaInstance.lua, -1))
						{
							Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -1));
						}
						else
						{
							Lua.pushnil(lua);
						}

						Lua.pop(luaInstance.lua, 1); // remove the global

						return;
					}
				}
			}
			Lua.pushnil(lua);
		});
		Lua_helper.add_callback(lua, "setGlobalFromScript", function(luaFile:String, global:String, val:Dynamic)
		{ // returns the global from a script
			var cervix = luaFile + ".lua";
			if (luaFile.endsWith(".lua"))
				cervix = luaFile;
			var doPush = false;
			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix))
			{
				doPush = true;
			}
			else
			{
				cervix = Paths.getPreloadPath(cervix);
				if (FileSystem.exists(cervix))
				{
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);
			if (Assets.exists(cervix))
			{
				doPush = true;
			}
			#end
			if (doPush)
			{
				for (luaInstance in PlayState.instance.luaArray)
				{
					if (luaInstance.scriptName == cervix)
					{
						luaInstance.set(global, val);
					}
				}
			}
			Lua.pushnil(lua);
		});

		Lua_helper.add_callback(lua, "isRunning", function(luaFile:String)
		{
			var cervix = luaFile + ".lua";
			if (luaFile.endsWith(".lua"))
				cervix = luaFile;
			var doPush = false;
			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix))
			{
				doPush = true;
			}
			else
			{
				cervix = Paths.getPreloadPath(cervix);
				if (FileSystem.exists(cervix))
				{
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);
			if (Assets.exists(cervix))
			{
				doPush = true;
			}
			#end

			if (doPush)
			{
				for (luaInstance in PlayState.instance.luaArray)
				{
					if (luaInstance.scriptName == cervix)
						return true;
				}
			}
			return false;
		});

		Lua_helper.add_callback(lua, "addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{ // would be dope asf.
			var cervix = luaFile + ".lua";
			if (luaFile.endsWith(".lua"))
				cervix = luaFile;
			var doPush = false;
			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix))
			{
				doPush = true;
			}
			else
			{
				cervix = Paths.getPreloadPath(cervix);
				if (FileSystem.exists(cervix))
				{
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);
			if (Assets.exists(cervix))
			{
				doPush = true;
			}
			#end

			if (doPush)
			{
				if (!ignoreAlreadyRunning)
				{
					for (luaInstance in PlayState.instance.luaArray)
					{
						if (luaInstance.scriptName == cervix)
						{
							LuaUtils.luaTrace(lua, 'addLuaScript: The script "' + cervix + '" is already running!');
							return;
						}
					}
				}
				PlayState.instance.luaArray.push(new FunkinLua(cervix));
				return;
			}
			LuaUtils.luaTrace(lua, "addLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "removeLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{ // would be dope asf.
			var cervix = luaFile + ".lua";
			if (luaFile.endsWith(".lua"))
				cervix = luaFile;
			var doPush = false;
			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix))
			{
				doPush = true;
			}
			else
			{
				cervix = Paths.getPreloadPath(cervix);
				if (FileSystem.exists(cervix))
				{
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);
			if (Assets.exists(cervix))
			{
				doPush = true;
			}
			#end

			if (doPush)
			{
				if (!ignoreAlreadyRunning)
				{
					for (luaInstance in PlayState.instance.luaArray)
					{
						if (luaInstance.scriptName == cervix)
						{
							PlayState.instance.luaArray.remove(luaInstance);
							return;
						}
					}
				}
				return;
			}
			LuaUtils.luaTrace(lua, "removeLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "runHaxeCode", function(codeToRun:String)
		{
			var retVal:Dynamic = null;

			#if HSCRIPT_ALLOWED
			initHaxeModule();
			try
			{
				retVal = hscript.executeStr(codeToRun);
			}
			catch (e:Dynamic)
			{
				LuaUtils.luaTrace(lua, scriptName + ":" + lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
			#else
			LuaUtils.luaTrace(lua, "runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end

			if (retVal != null && !isOfTypes(retVal, [Bool, Int, Float, String, Array]))
				retVal = null;
			if (retVal == null)
				Lua.pushnil(lua);
			return retVal;
		});

		Lua_helper.add_callback(lua, "runHaxeFunction", function(codeToRun:String, ?args:Array<Dynamic>)
		{
			var retVal:Dynamic = null;

			#if HSCRIPT_ALLOWED
			initHaxeModule();
			try
			{
				retVal = hscript.executeFunc(codeToRun, args);
			}
			catch (e:Dynamic)
			{
				LuaUtils.luaTrace(lua, scriptName + ":" + lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
			#else
			LuaUtils.luaTrace(lua, "runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end

			if (retVal != null && !isOfTypes(retVal, [Bool, Int, Float, String, Array]))
				retVal = null;
			if (retVal == null)
				Lua.pushnil(lua);
			return retVal;
		});

		Lua_helper.add_callback(lua, "addHaxeLibrary", function(libName:String, ?libPackage:String = '')
		{
			#if HSCRIPT_ALLOWED
			initHaxeModule();
			try
			{
				hscript.setVariable(libName, Type.resolveClass((libPackage != null ? libPackage + '.' : '') + libName));
			}
			catch (e:Dynamic)
			{
				LuaUtils.luaTrace(lua, scriptName + ":" + lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
			#end
		});

		Lua_helper.add_callback(lua, "loadSong", function(?name:String = null, ?difficultyNum:Int = -1)
		{
			if (name == null || name.length < 1)
				name = PlayState.SONG.song;
			if (difficultyNum == -1)
				difficultyNum = PlayState.storyDifficulty;

			var poop = Highscore.formatSong(name, difficultyNum);
			PlayState.SONG = Song.loadFromJson(poop, name);
			PlayState.storyDifficulty = difficultyNum;
			PlayState.instance.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if (PlayState.instance.vocals != null)
			{
				PlayState.instance.vocals.pause();
				PlayState.instance.vocals.volume = 0;
			}
		});

		Lua_helper.add_callback(lua, "loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0)
		{
			var killMe:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
			var animated = gridX != 0 || gridY != 0;

			if (killMe.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}

			if (spr != null && image != null && image.length > 0)
			{
				spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
			}
		});
		Lua_helper.add_callback(lua, "loadFrames", function(variable:String, image:String, spriteType:String = "sparrow")
		{
			var killMe:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}

			if (spr != null && image != null && image.length > 0)
			{
				LuaUtils.loadFrames(spr, image, spriteType);
			}
		});
		Lua_helper.add_callback(lua, "loadMultipleFrames", function(variable:String, images:Array<String>)
		{
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = LuaUtils.LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
			{
				spr = LuaUtils.LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			}

			if (spr != null && images != null && images.length > 0)
			{
				spr.frames = Paths.getMultiAtlas(images);
			}
		});

		// shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		Lua_helper.add_callback(lua, "getObjectOrder", function(obj:String)
		{
			var killMe:Array<String> = obj.split('.');
			var leObj:FlxBasic = LuaUtils.getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
			{
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}

			if (leObj != null)
			{
				return Globals.getInstance().members.indexOf(leObj);
			}
			LuaUtils.luaTrace(lua, "getObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});
		Lua_helper.add_callback(lua, "setObjectOrder", function(obj:String, position:Int)
		{
			var killMe:Array<String> = obj.split('.');
			var leObj:FlxBasic = LuaUtils.getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
			{
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}

			if (leObj != null)
			{
				Globals.getInstance().remove(leObj, true);
				Globals.getInstance().insert(position, leObj);
				return;
			}
			LuaUtils.luaTrace(lua, "setObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});

		// gay ass tweens
		Lua_helper.add_callback(lua, "doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {x: value}, duration, {
					ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else
			{
				LuaUtils.luaTrace(lua, 'doTweenX: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		Lua_helper.add_callback(lua, "doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {y: value}, duration, {
					ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else
			{
				LuaUtils.luaTrace(lua, 'doTweenY: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		Lua_helper.add_callback(lua, "doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {angle: value}, duration, {
					ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else
			{
				LuaUtils.luaTrace(lua, 'doTweenAngle: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		Lua_helper.add_callback(lua, "doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {alpha: value}, duration, {
					ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else
			{
				LuaUtils.luaTrace(lua, 'doTweenAlpha: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		Lua_helper.add_callback(lua, "doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {zoom: value}, duration, {
					ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else
			{
				LuaUtils.luaTrace(lua, 'doTweenZoom: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		Lua_helper.add_callback(lua, "doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				var color:Int = Std.parseInt(targetColor);
				if (!targetColor.startsWith('0x'))
					color = Std.parseInt('0xff' + targetColor);

				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				PlayState.instance.modchartTweens.set(tag, FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {
					ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.modchartTweens.remove(tag);
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
					}
				}));
			}
			else
			{
				LuaUtils.luaTrace(lua, 'doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		// Tween shit, but for strums
		Lua_helper.add_callback(lua, "noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {
					ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {
					ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {
					ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {
					ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "mouseClicked", function(button:String)
		{
			var boobs = FlxG.mouse.justPressed;
			switch (button)
			{
				case 'middle':
					boobs = FlxG.mouse.justPressedMiddle;
				case 'right':
					boobs = FlxG.mouse.justPressedRight;
			}

			return boobs;
		});
		Lua_helper.add_callback(lua, "mousePressed", function(button:String)
		{
			var boobs = FlxG.mouse.pressed;
			switch (button)
			{
				case 'middle':
					boobs = FlxG.mouse.pressedMiddle;
				case 'right':
					boobs = FlxG.mouse.pressedRight;
			}
			return boobs;
		});
		Lua_helper.add_callback(lua, "mouseReleased", function(button:String)
		{
			var boobs = FlxG.mouse.justReleased;
			switch (button)
			{
				case 'middle':
					boobs = FlxG.mouse.justReleasedMiddle;
				case 'right':
					boobs = FlxG.mouse.justReleasedRight;
			}
			return boobs;
		});
		Lua_helper.add_callback(lua, "noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {
					ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration, {
					ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		Lua_helper.add_callback(lua, "cancelTween", function(tag:String)
		{
			cancelTween(tag);
		});

		Lua_helper.add_callback(lua, "runTimer", function(tag:String, time:Float = 1, loops:Int = 1)
		{
			cancelTimer(tag);
			PlayState.instance.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				if (tmr.finished)
				{
					PlayState.instance.modchartTimers.remove(tag);
				}
				PlayState.instance.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});
		Lua_helper.add_callback(lua, "cancelTimer", function(tag:String)
		{
			cancelTimer(tag);
		});

		// stupid bietch ass functions
		Lua_helper.add_callback(lua, "addScore", function(value:Int = 0)
		{
			PlayState.instance.songScore += value;
			PlayState.instance.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "addMisses", function(value:Int = 0)
		{
			PlayState.instance.songMisses += value;
			PlayState.instance.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "addHits", function(value:Int = 0)
		{
			PlayState.instance.songHits += value;
			PlayState.instance.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setScore", function(value:Int = 0)
		{
			PlayState.instance.songScore = value;
			PlayState.instance.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setMisses", function(value:Int = 0)
		{
			PlayState.instance.songMisses = value;
			PlayState.instance.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "setHits", function(value:Int = 0)
		{
			PlayState.instance.songHits = value;
			PlayState.instance.RecalculateRating();
		});
		Lua_helper.add_callback(lua, "getScore", function()
		{
			return PlayState.instance.songScore;
		});
		Lua_helper.add_callback(lua, "getMisses", function()
		{
			return PlayState.instance.songMisses;
		});
		Lua_helper.add_callback(lua, "getHits", function()
		{
			return PlayState.instance.songHits;
		});

		Lua_helper.add_callback(lua, "setHealth", function(value:Float = 0)
		{
			PlayState.instance.health = value;
		});
		Lua_helper.add_callback(lua, "addHealth", function(value:Float = 0)
		{
			PlayState.instance.health += value;
		});
		Lua_helper.add_callback(lua, "getHealth", function()
		{
			return PlayState.instance.health;
		});

		Lua_helper.add_callback(lua, "getColorFromHex", function(color:String)
		{
			if (!color.startsWith('0x'))
				color = '0xff' + color;
			return Std.parseInt(color);
		});

		Lua_helper.add_callback(lua, "addCharacterToList", function(name:String, type:String)
		{
			var charType:Int = 0;
			switch (type.toLowerCase())
			{
				case 'dad':
					charType = 1;
				case 'gf' | 'girlfriend':
					charType = 2;
			}
			PlayState.instance.addCharacterToList(name, charType);
		});
		Lua_helper.add_callback(lua, "precacheImage", function(name:String, ?allowGPU:Bool = true)
		{
			Paths.image(name, allowGPU);
		});
		Lua_helper.add_callback(lua, "precacheSound", function(name:String)
		{
			Paths.sound(name);
		});
		Lua_helper.add_callback(lua, "precacheMusic", function(name:String)
		{
			Paths.music(name);
		});
		Lua_helper.add_callback(lua, "triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic, strumTime:Float)
		{
			var value1:String = arg1;
			var value2:String = arg2;
			PlayState.instance.triggerEventNote(name, value1, value2, strumTime);
			return true;
		});

		Lua_helper.add_callback(lua, "startCountdown", function()
		{
			PlayState.instance.startCountdown();
			return true;
		});
		Lua_helper.add_callback(lua, "endSong", function()
		{
			PlayState.instance.KillNotes();
			PlayState.instance.endSong();
			return true;
		});
		Lua_helper.add_callback(lua, "restartSong", function(?skipTransition:Bool = false)
		{
			PlayState.instance.persistentUpdate = false;
			PlayState.instance.paused = true;
			FlxG.sound.music.volume = 0;
			PlayState.instance.vocals.volume = 0;

			FlxG.resetState();
			return true;
		});
		Lua_helper.add_callback(lua, "exitSong", function(?skipTransition:Bool = false)
		{
			if (skipTransition)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			PlayState.cancelMusicFadeTween();
			CustomFadeTransition.nextCamera = PlayState.instance.camOther;
			if (FlxTransitionableState.skipNextTransIn)
				CustomFadeTransition.nextCamera = null;

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new ScriptedState('StoryMenuState', []));
			else
				MusicBeatState.switchState(new ScriptedState('FreeplayState', []));

			#if DISCORD_ALLOWED
			DiscordClient.resetClientID();
			#end

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			PlayState.instance.transitioning = true;
			Mods.loadTheFirstEnabledMod();
			return true;
		});
		Lua_helper.add_callback(lua, "getSongPosition", function()
		{
			return Conductor.songPosition;
		});

		Lua_helper.add_callback(lua, "getCharacterX", function(type:String)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					return PlayState.instance.dadGroup.x;
				case 'gf' | 'girlfriend':
					return PlayState.instance.gfGroup.x;
				default:
					return PlayState.instance.boyfriendGroup.x;
			}
		});
		Lua_helper.add_callback(lua, "setCharacterX", function(type:String, value:Float)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					PlayState.instance.dadGroup.x = value;
				case 'gf' | 'girlfriend':
					PlayState.instance.gfGroup.x = value;
				default:
					PlayState.instance.boyfriendGroup.x = value;
			}
		});
		Lua_helper.add_callback(lua, "getCharacterY", function(type:String)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					return PlayState.instance.dadGroup.y;
				case 'gf' | 'girlfriend':
					return PlayState.instance.gfGroup.y;
				default:
					return PlayState.instance.boyfriendGroup.y;
			}
		});
		Lua_helper.add_callback(lua, "setCharacterY", function(type:String, value:Float)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					PlayState.instance.dadGroup.y = value;
				case 'gf' | 'girlfriend':
					PlayState.instance.gfGroup.y = value;
				default:
					PlayState.instance.boyfriendGroup.y = value;
			}
		});
		Lua_helper.add_callback(lua, "cameraSetTarget", function(target:String)
		{
			var isDad:Bool = false;
			if (target == 'dad')
			{
				isDad = true;
			}
			PlayState.instance.moveCamera(isDad);
			return isDad;
		});
		Lua_helper.add_callback(lua, "cameraShake", function(camera:String, intensity:Float, duration:Float)
		{
			LuaUtils.cameraFromString(camera).shake(intensity, duration);
		});

		Lua_helper.add_callback(lua, "cameraFlash", function(camera:String, color:String, duration:Float, forced:Bool)
		{
			LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration, null, forced);
		});
		Lua_helper.add_callback(lua, "cameraFade", function(camera:String, color:String, duration:Float, forced:Bool)
		{
			LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration, false, null, forced);
		});
		Lua_helper.add_callback(lua, "setRatingPercent", function(value:Float)
		{
			PlayState.instance.ratingPercent = value;
		});
		Lua_helper.add_callback(lua, "setRatingName", function(value:String)
		{
			PlayState.instance.ratingName = value;
		});
		Lua_helper.add_callback(lua, "setRatingFC", function(value:String)
		{
			PlayState.instance.ratingFC = value;
		});
		Lua_helper.add_callback(lua, "getMouseX", function(camera:String)
		{
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).x;
		});
		Lua_helper.add_callback(lua, "getMouseY", function(camera:String)
		{
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).y;
		});

		Lua_helper.add_callback(lua, "getMidpointX", function(variable:String)
		{
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}
			if (obj != null)
				return obj.getMidpoint().x;

			return 0;
		});
		Lua_helper.add_callback(lua, "getMidpointY", function(variable:String)
		{
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}
			if (obj != null)
				return obj.getMidpoint().y;

			return 0;
		});
		Lua_helper.add_callback(lua, "getGraphicMidpointX", function(variable:String)
		{
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}
			if (obj != null)
				return obj.getGraphicMidpoint().x;

			return 0;
		});
		Lua_helper.add_callback(lua, "getGraphicMidpointY", function(variable:String)
		{
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}
			if (obj != null)
				return obj.getGraphicMidpoint().y;

			return 0;
		});
		Lua_helper.add_callback(lua, "getScreenPositionX", function(variable:String)
		{
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}
			if (obj != null)
				return obj.getScreenPosition().x;

			return 0;
		});
		Lua_helper.add_callback(lua, "getScreenPositionY", function(variable:String)
		{
			var killMe:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
			{
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}
			if (obj != null)
				return obj.getScreenPosition().y;

			return 0;
		});
		Lua_helper.add_callback(lua, "characterDance", function(character:String)
		{
			switch (character.toLowerCase())
			{
				case 'dad':
					PlayState.instance.dad.dance();
				case 'gf' | 'girlfriend':
					if (PlayState.instance.gf != null)
						PlayState.instance.gf.dance();
				default:
					PlayState.instance.boyfriend.dance();
			}
		});

		Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, image:String, x:Float, y:Float)
		{
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if (image != null && image.length > 0)
			{
				leSprite.loadGraphic(Paths.image(image));
			}
			leSprite.antialiasing = ClientPrefs.data.globalAntialiasing;
			PlayState.instance.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});
		Lua_helper.add_callback(lua, "makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?spriteType:String = "sparrow")
		{
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);

			LuaUtils.loadFrames(leSprite, image, spriteType);
			leSprite.antialiasing = ClientPrefs.data.globalAntialiasing;
			PlayState.instance.modchartSprites.set(tag, leSprite);
		});

		Lua_helper.add_callback(lua, "makeGraphic", function(obj:String, width:Int, height:Int, color:String)
		{
			var spr:FlxSprite = PlayState.instance.getLuaObject(obj, false);
			if (spr != null)
			{
				PlayState.instance.getLuaObject(obj, false).makeGraphic(width, height, CoolUtil.colorFromString(color));
				return;
			}

			var object:FlxSprite = Reflect.getProperty(Globals.getInstance(), obj);
			if (object != null)
			{
				object.makeGraphic(width, height, CoolUtil.colorFromString(color));
			}
		});
		Lua_helper.add_callback(lua, "addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true)
		{
			if (PlayState.instance.getLuaObject(obj, false) != null)
			{
				var cock:FlxSprite = PlayState.instance.getLuaObject(obj, false);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null)
				{
					cock.animation.play(name, true);
				}
				return;
			}

			var cock:FlxSprite = Reflect.getProperty(Globals.getInstance(), obj);
			if (cock != null)
			{
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null)
				{
					cock.animation.play(name, true);
				}
			}
		});

		Lua_helper.add_callback(lua, "addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true)
		{
			if (PlayState.instance.getLuaObject(obj, false) != null)
			{
				var cock:FlxSprite = PlayState.instance.getLuaObject(obj, false);
				cock.animation.add(name, frames, framerate, loop);
				if (cock.animation.curAnim == null)
				{
					cock.animation.play(name, true);
				}
				return;
			}

			var cock:FlxSprite = Reflect.getProperty(Globals.getInstance(), obj);
			if (cock != null)
			{
				cock.animation.add(name, frames, framerate, loop);
				if (cock.animation.curAnim == null)
				{
					cock.animation.play(name, true);
				}
			}
		});

		Lua_helper.add_callback(lua, "addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24)
		{
			return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, false);
		});
		Lua_helper.add_callback(lua, "addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24)
		{
			return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});

		Lua_helper.add_callback(lua, "playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
		{
			if (PlayState.instance.getLuaObject(obj, false) != null)
			{
				var luaObj:FlxSprite = PlayState.instance.getLuaObject(obj, false);
				if (luaObj.animation.getByName(name) != null)
				{
					luaObj.animation.play(name, forced, reverse, startFrame);
					if (Std.isOfType(luaObj, ModchartSprite))
					{
						// convert luaObj to ModchartSprite
						var obj:Dynamic = luaObj;
						var luaObj:ModchartSprite = obj;

						var daOffset = luaObj.animOffsets.get(name);
						if (luaObj.animOffsets.exists(name))
						{
							luaObj.offset.set(daOffset[0], daOffset[1]);
						}
					}
				}
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(Globals.getInstance(), obj);
			if (spr != null)
			{
				if (spr.animation.getByName(name) != null)
				{
					if (Std.isOfType(spr, Character))
					{
						// convert spr to Character
						var obj:Dynamic = spr;
						var spr:Character = obj;
						spr.playAnim(name, forced, reverse, startFrame);
					}
					else
						spr.animation.play(name, forced, reverse, startFrame);
				}
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "addOffset", function(obj:String, anim:String, x:Float, y:Float)
		{
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				PlayState.instance.modchartSprites.get(obj).animOffsets.set(anim, [x, y]);
				return true;
			}

			var char:Character = Reflect.getProperty(Globals.getInstance(), obj);
			if (char != null)
			{
				char.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float)
		{
			if (PlayState.instance.getLuaObject(obj, false) != null)
			{
				PlayState.instance.getLuaObject(obj, false).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(Globals.getInstance(), obj);
			if (object != null)
			{
				object.scrollFactor.set(scrollX, scrollY);
			}
		});
		Lua_helper.add_callback(lua, "addLuaSprite", function(tag:String, front:Bool = false)
		{
			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				if (!shit.wasAdded)
				{
					if (front)
					{
						Globals.getInstance().add(shit);
					}
					else
					{
						var gameOverSub = ScriptedSubState.getSubStateByTag('gameover');

						if (PlayState.instance.isDead && gameOverSub != null)
						{
							var bf = gameOverSub.scriptGet('boyfriend');

							if (bf != null)
								gameOverSub.insert(gameOverSub.members.indexOf(bf), shit);
							else
								gameOverSub.add(shit);
						}
						else
						{
							var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
							if (PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position)
							{
								position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
							}
							else if (PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position)
							{
								position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
							}
							PlayState.instance.insert(position, shit);
						}
					}
					shit.wasAdded = true;
				}
			}
		});
		Lua_helper.add_callback(lua, "setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true)
		{
			if (PlayState.instance.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
				shit.setGraphicSize(x, y);
				if (updateHitbox)
					shit.updateHitbox();
				return;
			}

			var killMe:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
			{
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}

			if (poop != null)
			{
				poop.setGraphicSize(x, y);
				if (updateHitbox)
					poop.updateHitbox();
				return;
			}
			LuaUtils.luaTrace(lua, 'setGraphicSize: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true)
		{
			if (PlayState.instance.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
				shit.scale.set(x, y);
				if (updateHitbox)
					shit.updateHitbox();
				return;
			}

			var killMe:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
			{
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}

			if (poop != null)
			{
				poop.scale.set(x, y);
				if (updateHitbox)
					poop.updateHitbox();
				return;
			}
			LuaUtils.luaTrace(lua, 'scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "updateHitbox", function(obj:String)
		{
			if (PlayState.instance.getLuaObject(obj) != null)
			{
				var shit:FlxSprite = PlayState.instance.getLuaObject(obj);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(Globals.getInstance(), obj);
			if (poop != null)
			{
				poop.updateHitbox();
				return;
			}
			LuaUtils.luaTrace(lua, 'updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "updateHitboxFromGroup", function(group:String, index:Int)
		{
			if (Std.isOfType(Reflect.getProperty(Globals.getInstance(), group), FlxTypedGroup))
			{
				Reflect.getProperty(Globals.getInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(Globals.getInstance(), group)[index].updateHitbox();
		});

		Lua_helper.add_callback(lua, "removeLuaSprite", function(tag:String, destroy:Bool = true)
		{
			if (!PlayState.instance.modchartSprites.exists(tag))
			{
				return;
			}

			var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
			if (destroy)
			{
				pee.kill();
			}

			if (pee.wasAdded)
			{
				Globals.getInstance().remove(pee, true);
				pee.wasAdded = false;
			}

			if (destroy)
			{
				pee.destroy();
				PlayState.instance.modchartSprites.remove(tag);
			}
		});

		Lua_helper.add_callback(lua, "luaSpriteExists", function(tag:String)
		{
			return PlayState.instance.modchartSprites.exists(tag);
		});
		Lua_helper.add_callback(lua, "luaTextExists", function(tag:String)
		{
			return PlayState.instance.modchartTexts.exists(tag);
		});
		Lua_helper.add_callback(lua, "luaSoundExists", function(tag:String)
		{
			return PlayState.instance.modchartSounds.exists(tag);
		});

		Lua_helper.add_callback(lua, "setHealthBarColors", function(leftHex:String, rightHex:String)
		{
			var left:FlxColor = CoolUtil.colorFromString(leftHex);
			var right:FlxColor = CoolUtil.colorFromString(rightHex);
			PlayState.instance.healthBar.setColors(left, right);
		});
		Lua_helper.add_callback(lua, "setTimeBarColors", function(leftHex:String, rightHex:String)
		{
			var left:FlxColor = CoolUtil.colorFromString(leftHex);
			var right:FlxColor = CoolUtil.colorFromString(rightHex);
			PlayState.instance.healthBar.setColors(left, right);
		});

		Lua_helper.add_callback(lua, "setObjectCamera", function(obj:String, camera:String = '')
		{
			var real = PlayState.instance.getLuaObject(obj);
			if (real != null)
			{
				real.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}

			var killMe:Array<String> = obj.split('.');
			var object:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
			{
				object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}

			if (object != null)
			{
				object.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			LuaUtils.luaTrace(lua, "setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "setBlendMode", function(obj:String, blend:String = '')
		{
			var real = PlayState.instance.getLuaObject(obj);
			if (real != null)
			{
				real.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}

			var killMe:Array<String> = obj.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}

			if (spr != null)
			{
				spr.blend = LuaUtils.blendModeFromString(blend);
				return true;
			}
			LuaUtils.luaTrace(lua, "setBlendMode: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "screenCenter", function(obj:String, pos:String = 'xy')
		{
			var spr:FlxSprite = PlayState.instance.getLuaObject(obj);

			if (spr == null)
			{
				var killMe:Array<String> = obj.split('.');
				spr = LuaUtils.getObjectDirectly(killMe[0]);
				if (killMe.length > 1)
				{
					spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
				}
			}

			if (spr != null)
			{
				switch (pos.trim().toLowerCase())
				{
					case 'x':
						spr.screenCenter(X);
						return;
					case 'y':
						spr.screenCenter(Y);
						return;
					default:
						spr.screenCenter(XY);
						return;
				}
			}
			LuaUtils.luaTrace(lua, "screenCenter: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "objectsOverlap", function(obj1:String, obj2:String)
		{
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxSprite> = [];
			for (i in 0...namesArray.length)
			{
				var real = PlayState.instance.getLuaObject(namesArray[i]);
				if (real != null)
				{
					objectsArray.push(real);
				}
				else
				{
					objectsArray.push(Reflect.getProperty(Globals.getInstance(), namesArray[i]));
				}
			}

			if (!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]))
			{
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "getPixelColor", function(obj:String, x:Int, y:Int)
		{
			var killMe:Array<String> = obj.split('.');
			var spr:FlxSprite = LuaUtils.getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
			{
				spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length - 1]);
			}

			if (spr != null)
			{
				if (spr.framePixels != null)
					spr.framePixels.getPixel32(x, y);
				return spr.pixels.getPixel32(x, y);
			}
			return 0;
		});
		Lua_helper.add_callback(lua, "getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '')
		{
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length)
			{
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
		Lua_helper.add_callback(lua, "getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '')
		{
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length)
			{
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
		Lua_helper.add_callback(lua, "getRandomBool", function(chance:Float = 50)
		{
			return FlxG.random.bool(chance);
		});
		Lua_helper.add_callback(lua, "startDialogue", function(dialogueFile:String, music:String = null)
		{
			var path:String;
			#if TRANSLATIONS_ALLOWED
			path = Paths.modsJson('songs/' + Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile + '_${ClientPrefs.data.language}');
			#if MODS_ALLOWED
			if (!FileSystem.exists(path))
			#else
			if (!Assets.exists(path))
			#end
			#end
			path = Paths.json('songs/' + Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);

			LuaUtils.luaTrace(lua, 'startDialogue: Trying to load dialogue: ' + path);

			if (#if MODS_ALLOWED FileSystem.exists(path) #else Assets.exists(path) #end)
			{
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if (shit.dialogue.length > 0)
				{
					PlayState.instance.startDialogue(shit, music);
					LuaUtils.luaTrace(lua, 'startDialogue: Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				}
				else
				{
					LuaUtils.luaTrace(lua, 'startDialogue: Your dialogue file is badly formatted!', false, false, FlxColor.RED);
				}
			}
			else
			{
				LuaUtils.luaTrace(lua, 'startDialogue: Dialogue file not found', false, false, FlxColor.RED);
				if (PlayState.instance.endingSong)
				{
					PlayState.instance.endSong();
				}
				else
				{
					PlayState.instance.startCountdown();
				}
			}
			return false;
		});
		Lua_helper.add_callback(lua, "startVideo",
			function(videoFile:String, ?canSkip:Bool = true, ?forMidSong:Bool = false, ?shouldLoop:Bool = false, ?playOnLoad:Bool = true)
			{
				#if VIDEOS_ALLOWED
				if (FileSystem.exists(Paths.video(videoFile)))
				{
					if (PlayState.instance.videoCutscene != null)
					{
						PlayState.instance.remove(PlayState.instance.videoCutscene);
						PlayState.instance.videoCutscene.destroy();
					}
					PlayState.instance.videoCutscene = PlayState.instance.startVideo(videoFile, forMidSong, canSkip, shouldLoop, playOnLoad);
					return true;
				}
				else
				{
					LuaUtils.luaTrace(lua, 'startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
				}
				return false;
				#else
				PlayState.instance.inCutscene = true;
				new FlxTimer().start(0.1, function(tmr:FlxTimer)
				{
					PlayState.instance.inCutscene = false;
					if (PlayState.instance.endingSong)
						PlayState.instance.endSong();
					else
						PlayState.instance.startCountdown();
				});
				return true;
				#end
			});

		Lua_helper.add_callback(lua, "playMusic", function(sound:String, volume:Float = 1, loop:Bool = false)
		{
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});
		Lua_helper.add_callback(lua, "playSound", function(sound:String, volume:Float = 1, ?tag:String = null)
		{
			if (tag != null && tag.length > 0)
			{
				tag = tag.replace('.', '');
				if (PlayState.instance.modchartSounds.exists(tag))
				{
					PlayState.instance.modchartSounds.get(tag).stop();
				}
				PlayState.instance.modchartSounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, function()
				{
					PlayState.instance.modchartSounds.remove(tag);
					PlayState.instance.callOnLuas('onSoundFinished', [tag]);
				}));
				return;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
		});
		Lua_helper.add_callback(lua, "stopSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag))
			{
				PlayState.instance.modchartSounds.get(tag).stop();
				PlayState.instance.modchartSounds.remove(tag);
			}
		});
		Lua_helper.add_callback(lua, "pauseSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag))
			{
				PlayState.instance.modchartSounds.get(tag).pause();
			}
		});
		Lua_helper.add_callback(lua, "resumeSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag))
			{
				PlayState.instance.modchartSounds.get(tag).play();
			}
		});
		Lua_helper.add_callback(lua, "soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1)
		{
			if (tag == null || tag.length < 1)
			{
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			}
			else if (PlayState.instance.modchartSounds.exists(tag))
			{
				PlayState.instance.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
			}
		});
		Lua_helper.add_callback(lua, "soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0)
		{
			if (tag == null || tag.length < 1)
			{
				FlxG.sound.music.fadeOut(duration, toValue);
			}
			else if (PlayState.instance.modchartSounds.exists(tag))
			{
				PlayState.instance.modchartSounds.get(tag).fadeOut(duration, toValue);
			}
		});
		Lua_helper.add_callback(lua, "soundFadeCancel", function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music.fadeTween != null)
				{
					FlxG.sound.music.fadeTween.cancel();
				}
			}
			else if (PlayState.instance.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if (theSound.fadeTween != null)
				{
					theSound.fadeTween.cancel();
					PlayState.instance.modchartSounds.remove(tag);
				}
			}
		});
		Lua_helper.add_callback(lua, "getSoundVolume", function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
				{
					return FlxG.sound.music.volume;
				}
			}
			else if (PlayState.instance.modchartSounds.exists(tag))
			{
				return PlayState.instance.modchartSounds.get(tag).volume;
			}
			return 0;
		});
		Lua_helper.add_callback(lua, "setSoundVolume", function(tag:String, value:Float)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
				{
					FlxG.sound.music.volume = value;
				}
			}
			else if (PlayState.instance.modchartSounds.exists(tag))
			{
				PlayState.instance.modchartSounds.get(tag).volume = value;
			}
		});
		Lua_helper.add_callback(lua, "getSoundTime", function(tag:String)
		{
			if (tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag))
			{
				return PlayState.instance.modchartSounds.get(tag).time;
			}
			return 0;
		});
		Lua_helper.add_callback(lua, "setSoundTime", function(tag:String, value:Float)
		{
			if (tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if (theSound != null)
				{
					var wasResumed:Bool = theSound.playing;
					theSound.pause();
					theSound.time = value;
					if (wasResumed)
						theSound.play();
				}
			}
		});

		#if FLX_PITCH
		Lua_helper.add_callback(lua, "getSoundPitch", function(tag:String)
		{
			if (tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag))
			{
				return PlayState.instance.modchartSounds.get(tag).pitch;
			}
			return 0;
		});
		Lua_helper.add_callback(lua, "setSoundPitch", function(tag:String, value:Float, doPause:Bool = false)
		{
			if (tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if (theSound != null)
				{
					var wasResumed:Bool = theSound.playing;
					if (doPause)
						theSound.pause();
					theSound.pitch = value;
					if (doPause && wasResumed)
						theSound.play();
				}
			}
		});
		#end

		Lua_helper.add_callback(lua, "getModSetting", function(saveTag:String, ?modName:String = null)
		{
			#if MODS_ALLOWED
			if (modName == null)
			{
				if (this.modFolder == null)
				{
					LuaUtils.luaTrace(lua, 'getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', false, false, FlxColor.RED);
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
			#else
			LuaUtils.luaTrace(lua, "getModSetting: Mods are disabled in this build!", false, false, FlxColor.RED);
			#end
		});

		Lua_helper.add_callback(lua, "debugPrint", function(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = '')
		{
			for (i in [text1, text2, text3, text4, text5])
				if (i == null)
					i = '';

			LuaUtils.luaTrace(lua, '' + text1 + text2 + text3 + text4 + text5, true, false);
		});

		Lua_helper.add_callback(lua, "close", function()
		{
			closed = true;
			return closed;
		});

		#if DISCORD_ALLOWED DiscordClient.addLuaCallbacks(lua); #end
		#if ACHIEVEMENTS_ALLOWED Achievements.addLuaCallbacks(lua); #end
		#if TRANSLATIONS_ALLOWED Language.addLuaCallbacks(lua); #end
		#if flxanimate FlxAnimateFunctions.implement(this); #end
		ReflectionFunctions.implement(this);
		TextFunctions.implement(this);
		ExtraFunctions.implement(this);
		CustomSubstate.implement(this);
		ShaderFunctions.implement(this);
		DeprecatedFunctions.implement(this);

		for (name => func in customFunctions)
		{
			if (func != null)
				Lua_helper.add_callback(lua, name, func);
		}

		call('onCreate', []);
		#end
	}

	public static function isOfTypes(value:Any, types:Array<Dynamic>)
	{
		for (type in types)
		{
			if (Std.isOfType(value, type))
				return true;
		}
		return false;
	}

	#if HSCRIPT_ALLOWED
	public function initHaxeModule()
	{
		if (hscript == null)
		{
			trace('initializing haxe interp for: $scriptName');
			hscript = new FunkinHScript();
		}
	}
	#end

	inline static function getTextObject(name:String):FlxText
	{
		return PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : Reflect.getProperty(PlayState.instance, name);
	}

	public function addLocalCallback(name:String, myFunction:Dynamic)
	{
		callbacks.set(name, myFunction);
		Lua_helper.add_callback(lua, name, null); //just so that it gets called
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end

	public function initLuaShader(name:String)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (!flash && sys)
		if(runtimeShaders.exists(name))
		{
			var shaderData:Array<String> = runtimeShaders.get(name);
			if(shaderData != null && (shaderData[0] != null || shaderData[1] != null))
			{
				LuaUtils.luaTrace(lua, 'Shader $name was already initialized!');
				return true;
			}
		}

		var foldersToCheck:Array<String> = [Paths.getPreloadPath('shaders/')];
		#if MODS_ALLOWED
		foldersToCheck.push(Paths.mods('shaders/'));
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for(mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if(FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					//trace('Found shader $name!');
					return true;
				}
			}
		}
		LuaUtils.luaTrace(lua, 'Missing shader $name .frag AND .vert files!', false, false, FlxColor.RED);
		#else
		LuaUtils.luaTrace(lua, 'This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
		#end
		return false;
	}

	function resetTextTag(tag:String)
	{
		if (!PlayState.instance.modchartTexts.exists(tag))
		{
			return;
		}

		var pee:ModchartText = PlayState.instance.modchartTexts.get(tag);
		pee.kill();
		if (pee.wasAdded)
		{
			PlayState.instance.remove(pee, true);
		}
		pee.destroy();
		PlayState.instance.modchartTexts.remove(tag);
	}

	function resetSpriteTag(tag:String)
	{
		if (!PlayState.instance.modchartSprites.exists(tag))
		{
			return;
		}

		var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
		pee.kill();
		if (pee.wasAdded)
		{
			PlayState.instance.remove(pee, true);
		}
		pee.destroy();
		PlayState.instance.modchartSprites.remove(tag);
	}

	function cancelTween(tag:String)
	{
		if (PlayState.instance.modchartTweens.exists(tag))
		{
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
	}

	function tweenShit(tag:String, vars:String)
	{
		cancelTween(tag);
		var variables:Array<String> = vars.split('.');
		var sexyProp:Dynamic = LuaUtils.getObjectDirectly(variables[0]);
		if (variables.length > 1)
		{
			sexyProp = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(variables), variables[variables.length - 1]);
		}
		return sexyProp;
	}

	function cancelTimer(tag:String)
	{
		if (PlayState.instance.modchartTimers.exists(tag))
		{
			var theTimer:FlxTimer = PlayState.instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			PlayState.instance.modchartTimers.remove(tag);
		}
	}

	public var lastCalledFunction:String = '';
	public static var lastCalledScript:FunkinLua = null;

	public function call(func:String, args:Array<Dynamic>):Dynamic
	{
		#if LUA_ALLOWED
		if (closed)
			return Globals.Function_Continue;

		lastCalledFunction = func;
		lastCalledScript = this;
		try
		{
			if (lua == null)
				return Globals.Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION)
			{
				if (type > Lua.LUA_TNIL)
					LuaUtils.luaTrace(lua, "ERROR (" + func + "): attempt to call a " + LuaUtils.typeToString(type) + " value", false, false, FlxColor.RED);

				Lua.pop(lua, 1);
				return Globals.Function_Continue;
			}

			for (arg in args)
				Convert.toLua(lua, arg);
			var status:Int = Lua.pcall(lua, args.length, 1, 0);

			// Checks if it's not successful, then show a error.
			if (status != Lua.LUA_OK)
			{
				var error:String = LuaUtils.getErrorMessage(lua, status);
				LuaUtils.luaTrace(lua, "ERROR (" + func + "): " + error, false, false, FlxColor.RED);
				return Globals.Function_Continue;
			}

			// If successful, pass and then return the result.
			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null)
				result = Globals.Function_Continue;

			Lua.pop(lua, 1);
			return result;
		}
		catch (e:Dynamic)
		{
			trace(e);
		}
		#end
		return Globals.Function_Continue;
	}

	public function set(variable:String, data:Dynamic)
	{
		#if LUA_ALLOWED
		if (lua == null)
		{
			return;
		}

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	public function stop()
	{
		#if LUA_ALLOWED
		if (lua == null)
		{
			return;
		}

		Lua.close(lua);
		lua = null;
		#end
	}
}
