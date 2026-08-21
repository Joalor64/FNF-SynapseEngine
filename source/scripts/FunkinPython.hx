package scripts;

#if PYTHON_ALLOWED
import paopao.hython.*;
import paopao.hython.Interp as PyInterp;
import paopao.hython.Parser as PyParser;
#end
#if LUA_ALLOWED
import psychlua.LuaUtils;
#end
import cutscenes.DialogueBoxPsych;

class FunkinPython extends FlxBasic
{
	public var parser:PyParser;
	public var interp:PyInterp;

	public var origin:Null<String>;

	public var scriptName:String = null;
	public var script:Dynamic = null;

	public var modFolder:String = null;

	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();

	public function new(?file:String, ?execute:Bool = true, ?varsToBring:Any = null)
	{
		super();

		parser = new PyParser();
		interp = new PyInterp();

		#if MODS_ALLOWED
		var myFolder:Array<String> = file.split('/');
		if (myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1])))
			this.modFolder = myFolder[1];
		#end

		preset(varsToBring);

		this.scriptName = origin = file;

		if (execute && file != null)
			this.execute(file);
	}

	private function noteTweenFunction(tag:String, note:Int, data:Dynamic, duration:Float, ease:String)
	{
		if (PlayState.instance == null)
			return null;

		var strumNote:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];
		if (strumNote == null)
			return null;

		if (tag != null)
		{
			var originalTag:String = tag;
			tag = LuaUtils.formatVariable('tween_$tag');
			LuaUtils.cancelTween(tag);

			var variables = MusicBeatState.getVariables();
			variables.set(tag, FlxTween.tween(strumNote, data, duration, {
				ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					variables.remove(tag);
					if (PlayState.instance != null)
						PlayState.instance.callOnLuas('onTweenCompleted', [originalTag]);
				}
			}));
			return tag;
		}
		else
			FlxTween.tween(strumNote, data, duration, {ease: LuaUtils.getTweenEaseByString(ease)});
		return null;
	}

	function preset(varsToBring:Any)
	{
		var game:PlayState = PlayState.instance;

		if (varsToBring != null)
		{
			for (k in Reflect.fields(varsToBring))
				set(k, Reflect.field(varsToBring, k));
		}

		set('Function_Stop', Globals.Function_Stop);
		set('Function_Halt', Globals.Function_Halt);
		set('Function_Continue', Globals.Function_Continue);

		set('Type', Type);
		set('Math', Math);
		set('Std', Std);
		set('StringTools', StringTools);
		#if sys
		set('File', File);
		set('FileSystem', FileSystem);
		#end

		set('FlxG', FlxG);
		set('FlxMath', flixel.math.FlxMath);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxText', flixel.text.FlxText);
		set('FlxCamera', flixel.FlxCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('FlxSound', flixel.sound.FlxSound);

		set('Countdown', BaseStage.Countdown);
		set('PlayState', PlayState);
		set('Paths', Paths);
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);
		set('Difficulty', Difficulty);
		set('CoolUtil', CoolUtil);
		set('Character', Character);
		set('Alphabet', Alphabet);
		set('Note', objects.Note);
		set('StrumNote', StrumNote);
		set('NoteSplash', NoteSplash);
		set('CustomSubstate', CustomSubstate);
		set('ModchartSprite', ModchartSprite);

		#if ACHIEVEMENTS_ALLOWED
		set('Achievements', Achievements);
		#end
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		#if flxanimate
		set('FlxAnimate', FlxAnimate);
		#end

		set('version', Constants.SYNAPSE_ENGINE_VERSION.trim());
		set('modFolder', this.modFolder);
		set('scriptName', this.scriptName);
		set('currentModDirectory', Mods.currentModDirectory);
		set('buildTarget', LuaUtils.getBuildTarget());

		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music != null ? FlxG.sound.music.length : 0);
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
		set('hasVocals', PlayState.SONG.needsVoices);

		set('FlxColor', function(color:String) return FlxColor.fromString(color));
		set('getColorFromName', function(color:String) return FlxColor.fromString(color));
		set('getColorFromString', function(color:String) return FlxColor.fromString(color));
		set('getColorFromHex', function(color:String) return FlxColor.fromString('#$color'));

		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		if (game != null)
			@:privateAccess
		{
			var curSection:SwagSection = PlayState.SONG.notes[game.curSection];
			set('curSection', game.curSection);
			set('curBeat', game.curBeat);
			set('curStep', game.curStep);
			set('curDecBeat', game.curDecBeat);
			set('curDecStep', game.curDecStep);

			set('score', game.songScore);
			set('misses', game.songMisses);
			set('hits', game.songHits);
			set('combo', game.combo);
			set('deaths', PlayState.deathCounter);

			set('rating', game.ratingPercent);
			set('ratingName', game.ratingName);
			set('ratingFC', game.ratingFC);
			set('totalPlayed', game.totalPlayed);
			set('totalNotesHit', game.totalNotesHit);

			set('inGameOver', Globals.getInstance());
			set('mustHitSection', curSection != null ? (curSection.mustHitSection == true) : false);
			set('altAnim', curSection != null ? (curSection.altAnim == true) : false);
			set('gfSection', curSection != null ? (curSection.gfSection == true) : false);

			set('healthGainMult', game.healthGain);
			set('healthLossMult', game.healthLoss);

			#if FLX_PITCH
			set('playbackRate', game.playbackRate);
			#else
			set('playbackRate', 1);
			#end

			set('instakillOnMiss', game.instakillOnMiss);
			set('botPlay', game.cpuControlled);
			set('practice', game.practiceMode);

			for (i in 0...4)
			{
				set('defaultPlayerStrumX$i', 0);
				set('defaultPlayerStrumY$i', 0);
				set('defaultOpponentStrumX$i', 0);
				set('defaultOpponentStrumY$i', 0);
			}

			set('defaultBoyfriendX', game.BF_X);
			set('defaultBoyfriendY', game.BF_Y);
			set('defaultOpponentX', game.DAD_X);
			set('defaultOpponentY', game.DAD_Y);
			set('defaultGirlfriendX', game.GF_X);
			set('defaultGirlfriendY', game.GF_Y);

			set('boyfriendName', game.boyfriend != null ? game.boyfriend.curCharacter : PlayState.SONG.player1);
			set('dadName', game.dad != null ? game.dad.curCharacter : PlayState.SONG.player2);
			set('gfName', game.gf != null ? game.gf.curCharacter : PlayState.SONG.gfVersion);
		}

		// Client preferences
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
		set('noteSkin', ClientPrefs.data.noteSkin);
		set('noteSkinPostfix', Note.getNoteSkinPostfix());
		set('splashSkin', ClientPrefs.data.splashSkin);
		set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());
		set('splashAlpha', ClientPrefs.data.splashAlpha);

		set('setVar', function(name:String, value:Dynamic)
		{
			MusicBeatState.getVariables().set(name, value);
			return value;
		});
		set('getVar', function(name:String)
		{
			return MusicBeatState.getVariables().get(name);
		});
		set('removeVar', function(name:String)
		{
			if (MusicBeatState.getVariables().exists(name))
			{
				MusicBeatState.getVariables().remove(name);
				return true;
			}
			return false;
		});

		set("noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {x: value}, duration, ease);
		});
		set("noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {y: value}, duration, ease);
		});
		set("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {angle: value}, duration, ease);
		});
		set("noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {alpha: value}, duration, ease);
		});
		set("noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear')
		{
			return noteTweenFunction(tag, note, {direction: value}, duration, ease);
		});

		// Script management
		set('getRunningScripts', function()
		{
			var runningScripts:Array<String> = [];
			#if PYTHON_ALLOWED
			for (script in game.pythonArray)
			{
				if (Std.isOfType(script, FunkinPython))
				{
					var pythonScript:FunkinPython = cast script;
					runningScripts.push(pythonScript.origin);
				}
			}
			#end
			return runningScripts;
		});

		set('setOnScripts', function(varName:String, args:Dynamic)
		{
			game.setOnLuas(varName, args);
		});

		set('callOnScripts', function(funcName:String, ?args:Array<Dynamic> = null)
		{
			return game.callOnScripts(funcName, args);
		});

		// Tweens
		set('startTween', function(tag:String, vars:String, values:Any = null, duration:Float, ?options:Any = null)
		{
			var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
			if (penisExam != null && values != null)
			{
				var myOptions:LuaTweenOptions = LuaUtils.getLuaTween(options);
				if (tag != null)
				{
					var variables = MusicBeatState.getVariables();
					var originalTag:String = 'tween_' + LuaUtils.formatVariable(tag);
					variables.set(tag, FlxTween.tween(penisExam, values, duration, myOptions != null ? {
						type: myOptions.type,
						ease: myOptions.ease,
						startDelay: myOptions.startDelay,
						loopDelay: myOptions.loopDelay,
						onUpdate: function(twn:FlxTween)
						{
							if (myOptions.onUpdate != null)
								game.callOnScripts(myOptions.onUpdate, [originalTag, vars]);
						},
						onStart: function(twn:FlxTween)
						{
							if (myOptions.onStart != null)
								game.callOnScripts(myOptions.onStart, [originalTag, vars]);
						},
						onComplete: function(twn:FlxTween)
						{
							if (twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD)
								variables.remove(tag);
							if (myOptions.onComplete != null)
								game.callOnScripts(myOptions.onComplete, [originalTag, vars]);
						}
					} : null));
					return tag;
				}
			}
			return null;
		});

		set('cancelTween', function(tag:String)
		{
			LuaUtils.cancelTween(tag);
		});

		// Timers
		set('runTimer', function(tag:String, time:Float = 1, loops:Int = 1)
		{
			LuaUtils.cancelTimer(tag);
			var variables = MusicBeatState.getVariables();
			var originalTag:String = tag;
			tag = LuaUtils.formatVariable('timer_$tag');
			variables.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				if (tmr.finished)
					variables.remove(tag);
				game.callOnScripts('onTimerCompleted', [originalTag, tmr.loops, tmr.loopsLeft]);
			}, loops));
			return tag;
		});

		set('cancelTimer', function(tag:String)
		{
			LuaUtils.cancelTimer(tag);
		});

		// Game state
		set('addScore', function(value:Int = 0)
		{
			game.songScore += value;
			game.RecalculateRating();
		});
		set('addMisses', function(value:Int = 0)
		{
			game.songMisses += value;
			game.RecalculateRating();
		});
		set('addHits', function(value:Int = 0)
		{
			game.songHits += value;
			game.RecalculateRating();
		});
		set('setScore', function(value:Int = 0)
		{
			game.songScore = value;
			game.RecalculateRating();
		});
		set('setMisses', function(value:Int = 0)
		{
			game.songMisses = value;
			game.RecalculateRating();
		});
		set('setHits', function(value:Int = 0)
		{
			game.songHits = value;
			game.RecalculateRating();
		});
		set('setHealth', function(value:Float = 1)
		{
			game.health = value;
		});
		set('addHealth', function(value:Float = 0)
		{
			game.health += value;
		});
		set('getHealth', function()
		{
			return game.health;
		});

		// Colors
		set('FlxColor', function(color:String)
		{
			return FlxColor.fromString(color);
		});
		set('getColorFromName', function(color:String)
		{
			return FlxColor.fromString(color);
		});
		set('getColorFromString', function(color:String)
		{
			return FlxColor.fromString(color);
		});
		set('getColorFromHex', function(color:String)
		{
			return FlxColor.fromString('#$color');
		});

		// Precaching
		set('addCharacterToList', function(name:String, type:String)
		{
			var charType:Int = 0;
			switch (type.toLowerCase())
			{
				case 'dad':
					charType = 1;
				case 'gf' | 'girlfriend':
					charType = 2;
			}
			game.addCharacterToList(name, charType);
		});
		set('precacheImage', function(name:String, ?allowGPU:Bool = true)
		{
			Paths.image(name, allowGPU);
		});
		set('precacheSound', function(name:String)
		{
			Paths.sound(name);
		});
		set('precacheMusic', function(name:String)
		{
			Paths.music(name);
		});

		// Events
		set('triggerEvent', function(name:String, ?value1:String = '', ?value2:String = '')
		{
			game.triggerEventNote(name, value1, value2, Conductor.songPosition);
			return true;
		});

		// Song control
		set('startCountdown', function()
		{
			game.startCountdown();
			return true;
		});
		set('endSong', function()
		{
			game.KillNotes();
			game.endSong();
			return true;
		});
		set('restartSong', function(?skipTransition:Bool = false)
		{
			game.persistentUpdate = false;
			FlxG.camera.followLerp = 0;
			FlxG.resetState();
			return true;
		});
		set('exitSong', function(?skipTransition:Bool = false)
		{
			if (skipTransition)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}
			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new ScriptedState('StoryMenuState', []));
			else
				MusicBeatState.switchState(new ScriptedState('FreeplayState', []));

			#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			game.transitioning = true;
			FlxG.camera.followLerp = 0;
			Mods.loadTheFirstEnabledMod();
			return true;
		});
		set('getSongPosition', function()
		{
			return Conductor.songPosition;
		});

		// Character control
		set('getCharacterX', function(type:String)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					return game.dadGroup.x;
				case 'gf' | 'girlfriend':
					return game.gfGroup.x;
				default:
					return game.boyfriendGroup.x;
			}
		});
		set('setCharacterX', function(type:String, value:Float)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					game.dadGroup.x = value;
				case 'gf' | 'girlfriend':
					game.gfGroup.x = value;
				default:
					game.boyfriendGroup.x = value;
			}
		});
		set('getCharacterY', function(type:String)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					return game.dadGroup.y;
				case 'gf' | 'girlfriend':
					return game.gfGroup.y;
				default:
					return game.boyfriendGroup.y;
			}
		});
		set('setCharacterY', function(type:String, value:Float)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					game.dadGroup.y = value;
				case 'gf' | 'girlfriend':
					game.gfGroup.y = value;
				default:
					game.boyfriendGroup.y = value;
			}
		});
		set('cameraSetTarget', function(target:String)
		{
			var isDad:Bool = false;
			if (target == 'dad')
			{
				isDad = true;
			}
			PlayState.instance.moveCamera(isDad);
			return isDad;
		});
		set('characterDance', function(character:String)
		{
			switch (character.toLowerCase())
			{
				case 'dad':
					game.dad.dance();
				case 'gf' | 'girlfriend':
					if (game.gf != null)
						game.gf.dance();
				default:
					game.boyfriend.dance();
			}
		});

		// Camera
		set('setCameraScroll', function(x:Float, y:Float)
		{
			FlxG.camera.scroll.set(x - FlxG.width / 2, y - FlxG.height / 2);
		});
		set('addCameraScroll', function(?x:Float = 0, ?y:Float = 0)
		{
			FlxG.camera.scroll.add(x, y);
		});
		set('addCameraFollowPoint', function(?x:Float = 0, ?y:Float = 0)
		{
			game.camFollow.x += x;
			game.camFollow.y += y;
		});
		set('getCameraScrollX', function()
		{
			return FlxG.camera.scroll.x + FlxG.width / 2;
		});
		set('getCameraScrollY', function()
		{
			return FlxG.camera.scroll.y + FlxG.height / 2;
		});
		set('getCameraFollowX', function()
		{
			return game.camFollow.x;
		});
		set('getCameraFollowY', function()
		{
			return game.camFollow.y;
		});
		set('cameraShake', function(camera:String, intensity:Float, duration:Float)
		{
			LuaUtils.cameraFromString(camera).shake(intensity, duration);
		});
		set('cameraFlash', function(camera:String, color:String, duration:Float, forced:Bool)
		{
			LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration, null, forced);
		});
		set('cameraFade', function(camera:String, color:String, duration:Float, forced:Bool, ?fadeOut:Bool = false)
		{
			LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration, fadeOut, null, forced);
		});

		// Mouse
		set('getMouseX', function(?camera:String = 'game')
		{
			return FlxG.mouse.getScreenPosition(LuaUtils.cameraFromString(camera)).x;
		});
		set('getMouseY', function(?camera:String = 'game')
		{
			return FlxG.mouse.getScreenPosition(LuaUtils.cameraFromString(camera)).y;
		});
		set('mouseClicked', function(?button:String = 'left')
		{
			var click:Bool = FlxG.mouse.justPressed;
			switch (button.trim().toLowerCase())
			{
				case 'middle':
					click = FlxG.mouse.justPressedMiddle;
				case 'right':
					click = FlxG.mouse.justPressedRight;
			}
			return click;
		});
		set('mousePressed', function(?button:String = 'left')
		{
			var press:Bool = FlxG.mouse.pressed;
			switch (button.trim().toLowerCase())
			{
				case 'middle':
					press = FlxG.mouse.pressedMiddle;
				case 'right':
					press = FlxG.mouse.pressedRight;
			}
			return press;
		});
		set('mouseReleased', function(?button:String = 'left')
		{
			var released:Bool = FlxG.mouse.justReleased;
			switch (button.trim().toLowerCase())
			{
				case 'middle':
					released = FlxG.mouse.justReleasedMiddle;
				case 'right':
					released = FlxG.mouse.justReleasedRight;
			}
			return released;
		});

		// Sprites
		set('makePythonSprite', function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0)
		{
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if (image != null && image.length > 0)
				leSprite.loadGraphic(Paths.image(image));
			MusicBeatState.getVariables().set(tag, leSprite);
			leSprite.active = true;
		});
		set('makeAnimatedPythonSprite', function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = 'auto')
		{
			tag = tag.replace('.', '');
			LuaUtils.destroyObject(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if (image != null && image.length > 0)
				LuaUtils.loadFrames(leSprite, image, spriteType);
			MusicBeatState.getVariables().set(tag, leSprite);
		});
		set('addPythonSprite', function(tag:String, ?inFront:Bool = false)
		{
			var mySprite:FlxSprite = MusicBeatState.getVariables().get(tag);
			if (mySprite == null)
				return;
			var instance = LuaUtils.getTargetInstance();
			if (inFront)
				instance.add(mySprite);
			else
			{
				var gameOverSub = ScriptedSubState.getSubStateByTag('gameover');
				var bf = gameOverSub.scriptGet('boyfriend');

				if (PlayState.instance == null || !PlayState.instance.isDead)
					instance.insert(instance.members.indexOf(LuaUtils.getLowestCharacterGroup()), mySprite);
				else
					gameOverSub.insert(gameOverSub.members.indexOf(bf), mySprite);
			}
		});
		set('removePythonSprite', function(tag:String, destroy:Bool = true, ?group:String = null)
		{
			var obj:FlxSprite = LuaUtils.getObjectDirectly(tag);
			if (obj == null || obj.destroy == null)
				return;
			var groupObj:Dynamic = null;
			if (group == null)
				groupObj = LuaUtils.getTargetInstance();
			else
				groupObj = LuaUtils.getObjectDirectly(group);
			groupObj.remove(obj, true);
			if (destroy)
			{
				MusicBeatState.getVariables().remove(tag);
				obj.destroy();
			}
		});

		// Sound
		set('playMusic', function(sound:String, ?volume:Float = 1, ?loop:Bool = false)
		{
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});
		set('playSound', function(sound:String, ?volume:Float = 1, ?tag:String = null, ?loop:Bool = false)
		{
			if (tag != null && tag.length > 0)
			{
				var originalTag:String = tag;
				tag = LuaUtils.formatVariable('sound_$tag');
				var variables = MusicBeatState.getVariables();
				var oldSnd = variables.get(tag);
				if (oldSnd != null)
				{
					oldSnd.stop();
					oldSnd.destroy();
				}
				variables.set(tag, FlxG.sound.play(Paths.sound(sound), volume, loop, null, true, function()
				{
					if (!loop)
						variables.remove(tag);
					if (game != null)
						game.callOnScripts('onSoundFinished', [originalTag]);
				}));
				return tag;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
			return null;
		});
		set('stopSound', function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
					FlxG.sound.music.stop();
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var variables = MusicBeatState.getVariables();
				var snd:FlxSound = variables.get(tag);
				if (snd != null)
				{
					snd.stop();
					variables.remove(tag);
				}
			}
		});
		set('pauseSound', function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
					FlxG.sound.music.pause();
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null)
					snd.pause();
			}
		});
		set('resumeSound', function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
					FlxG.sound.music.play();
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null)
					snd.play();
			}
		});
		set('getSoundVolume', function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
					return FlxG.sound.music.volume;
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null)
					return snd.volume;
			}
			return 0;
		});
		set('setSoundVolume', function(tag:String, value:Float)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
					FlxG.sound.music.volume = value;
			}
			else
			{
				tag = LuaUtils.formatVariable('sound_$tag');
				var snd:FlxSound = MusicBeatState.getVariables().get(tag);
				if (snd != null)
					snd.volume = value;
			}
		});

		// Animation
		set('addAnimationByPrefix', function(obj:String, name:String, prefix:String, framerate:Float = 24, loop:Bool = true)
		{
			var obj:FlxSprite = cast LuaUtils.getObjectDirectly(obj);
			if (obj != null && obj.animation != null)
			{
				obj.animation.addByPrefix(name, prefix, framerate, loop);
				if (obj.animation.curAnim == null)
				{
					var dyn:Dynamic = cast obj;
					if (dyn.playAnim != null)
						dyn.playAnim(name, true);
					else
						dyn.animation.play(name, true);
				}
				return true;
			}
			return false;
		});
		set('playAnim', function(obj:String, name:String, ?forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
		{
			var obj:Dynamic = LuaUtils.getObjectDirectly(obj);
			if (obj.playAnim != null)
			{
				obj.playAnim(name, forced, reverse, startFrame);
				return true;
			}
			else
			{
				if (obj.anim != null)
					obj.anim.play(name, forced, reverse, startFrame);
				else
					obj.animation.play(name, forced, reverse, startFrame);
				return true;
			}
			return false;
		});

		// Object utilities
		set('getProperty', function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:Dynamic = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			return obj;
		});
		set('setProperty', function(variable:String, value:Dynamic)
		{
			var split:Array<String> = variable.split('.');
			if (split.length > 1)
				LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1], value);
			else
				LuaUtils.setVarInArray(LuaUtils.getTargetInstance(), variable, value);
			return true;
		});
		set('getPropertyFromClass', function(className:String, variable:String)
		{
			var myClass:Dynamic = Type.resolveClass(className);
			if (myClass == null)
			{
				pythonTrace('getPropertyFromClass: Class $className not found', false, false, FlxColor.RED);
				return null;
			}
			return Reflect.getProperty(myClass, variable);
		});
		set('setPropertyFromClass', function(className:String, variable:String, value:Dynamic)
		{
			var myClass:Dynamic = Type.resolveClass(className);
			if (myClass == null)
			{
				pythonTrace('setPropertyFromClass: Class $className not found', false, false, FlxColor.RED);
				return false;
			}
			Reflect.setProperty(myClass, variable, value);
			return true;
		});

		// Object position utilities
		set('getMidpointX', function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (obj != null)
				return obj.getMidpoint().x;
			return 0;
		});
		set('getMidpointY', function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (obj != null)
				return obj.getMidpoint().y;
			return 0;
		});
		set('getGraphicMidpointX', function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (obj != null)
				return obj.getGraphicMidpoint().x;
			return 0;
		});
		set('getGraphicMidpointY', function(variable:String)
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (obj != null)
				return obj.getGraphicMidpoint().y;
			return 0;
		});
		set('getScreenPositionX', function(variable:String, ?camera:String = 'game')
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (obj != null)
				return obj.getScreenPosition(LuaUtils.cameraFromString(camera)).x;
			return 0;
		});
		set('getScreenPositionY', function(variable:String, ?camera:String = 'game')
		{
			var split:Array<String> = variable.split('.');
			var obj:FlxObject = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (obj != null)
				return obj.getScreenPosition(LuaUtils.cameraFromString(camera)).y;
			return 0;
		});

		// Object transform
		set('setGraphicSize', function(obj:String, x:Float, y:Float = 0, updateHitbox:Bool = true)
		{
			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (poop != null)
			{
				poop.setGraphicSize(x, y);
				if (updateHitbox)
					poop.updateHitbox();
				return;
			}
			pythonTrace('setGraphicSize: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		set('scaleObject', function(obj:String, x:Float, y:Float, updateHitbox:Bool = true)
		{
			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (poop != null)
			{
				poop.scale.set(x, y);
				if (updateHitbox)
					poop.updateHitbox();
				return;
			}
			pythonTrace('scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		set('updateHitbox', function(obj:String)
		{
			var split:Array<String> = obj.split('.');
			var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (poop != null)
			{
				poop.updateHitbox();
				return;
			}
			pythonTrace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		set('screenCenter', function(obj:String, pos:String = 'xy')
		{
			var spr:FlxObject = LuaUtils.getObjectDirectly(obj);
			if (spr == null)
			{
				var split:Array<String> = obj.split('.');
				spr = LuaUtils.getObjectDirectly(split[0]);
				if (split.length > 1)
					spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
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
			pythonTrace("screenCenter: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});
		set('setObjectCamera', function(obj:String, camera:String = 'game')
		{
			var real:FlxBasic = LuaUtils.getObjectDirectly(obj);
			if (real != null)
			{
				real.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			var split:Array<String> = obj.split('.');
			var object:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
			if (split.length > 1)
				object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
			if (object != null)
			{
				object.cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			pythonTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		set('setScrollFactor', function(obj:String, scrollX:Float, scrollY:Float)
		{
			var object:FlxObject = LuaUtils.getObjectDirectly(obj);
			if (object != null)
				object.scrollFactor.set(scrollX, scrollY);
		});

		// Bar colors
		set('setHealthBarColors', function(left:String, right:String)
		{
			var left_color:Null<FlxColor> = null;
			var right_color:Null<FlxColor> = null;
			if (left != null && left != '')
				left_color = CoolUtil.colorFromString(left);
			if (right != null && right != '')
				right_color = CoolUtil.colorFromString(right);
			game.healthBar.setColors(left_color, right_color);
		});
		set('setTimeBarColors', function(left:String, right:String)
		{
			var left_color:Null<FlxColor> = null;
			var right_color:Null<FlxColor> = null;
			if (left != null && left != '')
				left_color = CoolUtil.colorFromString(left);
			if (right != null && right != '')
				right_color = CoolUtil.colorFromString(right);
			game.timeBar.setColors(left_color, right_color);
		});

		// Dialogue & video
		set('startDialogue', function(dialogueFile:String, ?music:String = null)
		{
			var path:String;
			var songPath:String = Paths.formatToSongPath(Song.loadedSongName);
			#if TRANSLATIONS_ALLOWED
			path = Paths.getPath('songs/$songPath/${dialogueFile}_${ClientPrefs.data.language}.json');
			#if MODS_ALLOWED
			if (!FileSystem.exists(path))
			#else
			if (!Assets.exists(path, TEXT))
			#end
			#end
			path = Paths.getPath('songs/$songPath/$dialogueFile.json');

			pythonTrace('startDialogue: Trying to load dialogue: ' + path);

			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			#else
			if (Assets.exists(path, TEXT))
			#end
			{
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if (shit.dialogue.length > 0)
				{
					game.startDialogue(shit, music);
					pythonTrace('startDialogue: Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				}
				else
					pythonTrace('startDialogue: Your dialogue file is badly formatted!', false, false, FlxColor.RED);
			}
		else
		{
			pythonTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
			if (game.endingSong)
				game.endSong();
			else
				game.startCountdown();
		}
			return false;
		});

		set('startVideo', function(videoFile:String, ?canSkip:Bool = true, ?forMidSong:Bool = false, ?shouldLoop:Bool = false, ?playOnLoad:Bool = true)
		{
			#if VIDEOS_ALLOWED
			if (FileSystem.exists(Paths.video(videoFile)))
			{
				if (game.videoCutscene != null)
				{
					game.remove(game.videoCutscene);
					game.videoCutscene.destroy();
				}
				game.videoCutscene = game.startVideo(videoFile, forMidSong, canSkip, shouldLoop, playOnLoad);
				return true;
			}
			else
			{
				pythonTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
			}
			return false;
			#else
			PlayState.instance.inCutscene = true;
			new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				PlayState.instance.inCutscene = false;
				if (game.endingSong)
					game.endSong();
				else
					game.startCountdown();
			});
			return true;
			#end
		});

		set('debugPrint', function(text:Dynamic = '', ?color:FlxColor = null)
		{
			if (color == null)
				color = FlxColor.WHITE;
			if (PlayState.instance != null)
			{
				PlayState.instance.addTextToDebug(text, color);
				return;
			}
			trace('[Python] $text');
		});

		set("getModSetting", function(saveTag:String, ?modName:String = null)
		{
			#if MODS_ALLOWED
			if (modName == null)
			{
				if (this.modFolder == null)
				{
					pythonTrace('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', false, false, FlxColor.RED);
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
			#else
			pythonTrace("getModSetting: Mods are disabled in this build!", false, false, FlxColor.RED);
			return null;
			#end
		});

		set("destroy", function()
		{
			this.destroy();
		});

		for (name => func in customFunctions)
		{
			if (func != null)
				set(name, func);
		}
	}

	public static function pythonTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE)
	{
		if (PlayState.instance != null)
		{
			PlayState.instance.addTextToDebug(text, color);
			return;
		}
		trace('[Python] $text');
	}

	public function execute(script:String, ?executeCreate:Bool = true):Dynamic
	{
		try
		{
			var file = File.getContent(script);
			var expr = parser.parseString(file);

			var result = interp.execute(expr);

			trace('Python script loaded successfully: ' + scriptName);

			if (executeCreate)
				call('onCreate', []);
			return result;
		}
		catch (e:Dynamic)
		{
			Lib.application.window.alert(Std.string(e), 'Error executing python script');
			return null;
		}
	}

	public function executeStr(code:String):Dynamic
	{
		try
		{
			return parser.parseString(code);
		}
		catch (e:Dynamic)
		{
			Lib.application.window.alert(Std.string(e), 'Error executing python string');
			return null;
		}
	}

	public function call(func:String, ?args:Array<Dynamic>):Dynamic
	{
		if (args == null)
			args = [];

		try
		{
			if (existsVar(func))
			{
				var result = interp.callDef(func, args);
				if (result == null)
					result = Globals.Function_Continue;
				return result;
			}
		}
		catch (e:Dynamic)
		{
			Lib.application.window.alert(Std.string(e), 'Error calling python function');
			return null;
		}

		return Globals.Function_Continue;
	}

	public function existsVar(name:String):Bool
	{
		return interp.getVar(name) != null;
	}

	public function set(variable:String, value:Dynamic)
	{
		if (interp != null)
			interp.setVar(variable, value);
	}

	public function get(variable:String):Dynamic
	{
		if (interp != null)
			return interp.getVar(variable);
		return null;
	}

	override public function destroy()
	{
		super.destroy();
		parser = null;
		interp = null;
		script = null;
	}
}
