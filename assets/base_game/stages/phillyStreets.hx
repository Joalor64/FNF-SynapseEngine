// Weekend 1 - Darnell, Lit Up, 2Hot
import objects.BGSprite;
import objects.Note;
import shaders.RainShader;
import flixel.addons.display.FlxTiledSprite;
import states.stages.objects.ABotSpeaker;
import states.stages.objects.SpraycanAtlasSprite;

var MIN_BLINK_DELAY:Int = 3;
var MAX_BLINK_DELAY:Int = 7;
var VULTURE_THRESHOLD:Float = 0.5;
var blinkCountdown:Int = 3;

var rainShader:RainShader;
var rainShaderStartIntensity:Float = 0;
var rainShaderEndIntensity:Float = 0;

var scrollingSky:FlxTiledSprite;
var phillyTraffic:BGSprite;

var phillyCars:BGSprite;
var phillyCars2:BGSprite;

var picoFade:FlxSprite;
var spraycan:SpraycanAtlasSprite;
var spraycanPile:BGSprite;

var darkenable:Array<FlxSprite> = [];
var abot:ABotSpeaker;

var casingGroup:FlxSpriteGroup;
var casingFrames:FlxAtlasFrames;
var gunPrepSnd:FlxSound;
var bonkSnd:FlxSound;
var lightCanSnd:FlxSound;
var kickCanSnd:FlxSound;
var kneeCanSnd:FlxSound;

var cutsceneHandler:CutsceneHandler;
var videoEnded:Bool = false;
var picoFlicker:FlxTimer = null;

var currentNeneState:String = 'default';
var animationFinished:Bool = false;

var lightsStop:Bool = false;
var lastChange:Int = 0;
var changeInterval:Int = 8;
var carWaiting:Bool = false;
var carInterruptable:Bool = true;
var car2Interruptable:Bool = true;

function isBlank(value:String):Bool
	return value == null || StringTools.trim(value).length < 1;

function addDarkenable(spr:FlxSprite)
{
	add(spr);
	darkenable.push(spr);
}

function create()
{
	StickerSubState.STICKER_SET = 'sticker-set-2';
	StickerSubState.STICKER_PACK = 'weekend';

	var path:String = 'stages/phillyStreets/phillyStreets/';

	if (!ClientPrefs.data.lowQuality)
	{
		var skyImage = Paths.image(path + 'phillySkybox');
		scrollingSky = new FlxTiledSprite(skyImage, skyImage.width + 400, skyImage.height, true, false);
		scrollingSky.antialiasing = ClientPrefs.data.globalAntialiasing;
		scrollingSky.setPosition(-650, -375);
		scrollingSky.scrollFactor.set(0.1, 0.1);
		scrollingSky.scale.set(0.65, 0.65);
		addDarkenable(scrollingSky);

		addDarkenable(new BGSprite(path + 'phillySkyline', -545, -273, 0.2, 0.2));
		addDarkenable(new BGSprite(path + 'phillyForegroundCity', 625, 94, 0.3, 0.3));
	}

	addDarkenable(new BGSprite(path + 'phillyConstruction', 1800, 364, 0.7, 1));
	addDarkenable(new BGSprite(path + 'phillyHighwayLights', 284, 305, 1, 1));

	if (!ClientPrefs.data.lowQuality)
	{
		var phillyHighwayLightsLightmap:BGSprite = new BGSprite(path + 'phillyHighwayLights_lightmap', 284, 305, 1, 1);
		phillyHighwayLightsLightmap.blend = BlendMode.ADD;
		phillyHighwayLightsLightmap.alpha = 0.6;
		addDarkenable(phillyHighwayLightsLightmap);
	}

	addDarkenable(new BGSprite(path + 'phillyHighway', 139, 209, 1, 1));

	if (!ClientPrefs.data.lowQuality)
	{
		addDarkenable(new BGSprite(path + 'phillySmog', -6, 245, 0.8, 1));

		phillyCars = new BGSprite(path + 'phillyCars', 1200, 818, 0.9, 1, ['car1', 'car2', 'car3', 'car4'], false);
		addDarkenable(phillyCars);

		phillyCars2 = new BGSprite(path + 'phillyCars', 1200, 818, 0.9, 1, ['car1', 'car2', 'car3', 'car4'], false);
		phillyCars2.flipX = true;
		addDarkenable(phillyCars2);

		phillyTraffic = new BGSprite(path + 'phillyTraffic', 1840, 608, 0.9, 1, ['redtogreen', 'greentored'], false);
		addDarkenable(phillyTraffic);

		var phillyTrafficLightmap:BGSprite = new BGSprite(path + 'phillyTraffic_lightmap', 1840, 608, 0.9, 1);
		phillyTrafficLightmap.blend = BlendMode.ADD;
		phillyTrafficLightmap.alpha = 0.6;
		addDarkenable(phillyTrafficLightmap);
	}

	addDarkenable(new BGSprite(path + 'phillyForeground', 88, 317, 1, 1));

	if (!ClientPrefs.data.lowQuality)
	{
		picoFade = new FlxSprite();
		picoFade.antialiasing = ClientPrefs.data.globalAntialiasing;
		picoFade.alpha = 0;
		addDarkenable(picoFade);
	}

	abot = new ABotSpeaker(game.gfGroup.x, game.gfGroup.y + 550);
	updateABotEye(true);
	add(abot);

	if (ClientPrefs.data.shaders)
		setupRainShader();

	var song = PlayState.SONG;
	if (isBlank(song.gameOverSound))
		game.deathSoundName = 'fnf_loss_sfx-pico';
	if (isBlank(song.gameOverLoop))
		game.loopSoundName = 'gameOver-pico';
	if (isBlank(song.gameOverEnd))
		game.endSoundName = 'gameOverEnd-pico';
	if (isBlank(song.gameOverChar))
		game.characterName = 'pico-dead';
	stage.setDefaultGF('nene');

	if (PlayState.isStoryMode)
	{
		switch (game.songName)
		{
			case 'darnell':
				if (!PlayState.seenCutscene)
					stage.setStartCallback(function() playVideoCutscene('darnellCutscene'));
			case '2hot':
				stage.setEndCallback(function()
				{
					game.endingSong = true;
					game.inCutscene = true;
					game.canPause = false;
					FlxTransitionableState.skipNextTransIn = true;
					FlxG.camera.visible = false;
					game.camHUD.visible = false;
					game.startVideo('2hotCutscene');
				});
		}
	}
}

function onCreatePost()
{
	for (note in game.unspawnNotes)
	{
		if (note != null && note.noteType == 'weekend-1-firegun')
			note.blockHit = true;
	}

	spraycanPile = new BGSprite('stages/phillyStreets/SpraycanPile', 920, 1045, 1, 1);
	precache();
	addDarkenable(spraycanPile);

	if (game.gf != null)
	{
		game.gf.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int)
		{
			if (currentNeneState == 'preRaise' && name == 'danceLeft' && frameNumber >= 14)
			{
				animationFinished = true;
				transitionState();
			}
		};
	}
}

function playVideoCutscene(videoName:String)
{
	game.inCutscene = true;
	if (!videoEnded && videoName != null)
	{
		#if VIDEOS_ALLOWED
		game.startVideo(videoName);
		var onVideoEnd = function()
		{
			videoEnded = true;
			game.videoCutscene = null;
			game.canPause = true;
			playVideoCutscene(null);
		};
		game.videoCutscene.finishCallback = onVideoEnd;
		game.videoCutscene.onSkip = onVideoEnd;
		#else
		// timer so the sprites have time to be ready
		new FlxTimer().start(0.0, function(tmr:FlxTimer)
		{
			videoEnded = true;
			playVideoCutscene(null);
		});
		#end
		return;
	}

	if (PlayState.isStoryMode && game.songName == 'darnell')
		darnellCutscene();
}

function darnellCutscene()
{
	var camFollow = game.camFollow;
	var boyfriend = game.boyfriend;
	var dad = game.dad;
	var gf = game.gf;

	game.moveCamera(false);
	camFollow.x += 250;
	FlxG.camera.snapToTarget();
	FlxG.camera.zoom = 1.3;
	spraycan.cutscene = true;

	cutsceneHandler = new CutsceneHandler();
	cutsceneHandler.endTime = 10;

	var cutsceneMusic:FlxSound = new FlxSound().loadEmbedded(Paths.music('darnellCanCutscene'));
	cutsceneMusic.looped = true;
	FlxG.sound.list.add(cutsceneMusic);

	var darnellLaugh:FlxSound = new FlxSound().loadEmbedded(Paths.sound('cutscene/darnell_laugh'));
	darnellLaugh.volume = 0.6;
	FlxG.sound.list.add(darnellLaugh);

	var neneLaugh:FlxSound = new FlxSound().loadEmbedded(Paths.sound('cutscene/nene_laugh'));
	neneLaugh.volume = 0.6;
	FlxG.sound.list.add(neneLaugh);

	game.camHUD.alpha = 0;
	gf.animation.finishCallback = function(name:String)
	{
		if (name == 'danceLeft' || name == 'danceRight')
			gf.dance();
	};
	gf.dance();

	dad.animation.finishCallback = function(name:String)
	{
		if (name == 'idle')
			dad.dance();
	};
	dad.dance();

	var cutsceneDelay:Float = 2.0;
	boyfriend.playAnim('intro1', true);
	cutsceneHandler.timer(0.7, function() // play music
	{
		cutsceneMusic.play();
	});
	cutsceneHandler.timer(cutsceneDelay, function() // zoom out to show off everything
	{
		game.moveCamera(true);
		camFollow.x += 100;
		FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x + 100 - FlxG.width / 2, y: camFollow.y - FlxG.height / 2}, 2.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(FlxG.camera, {zoom: 0.66}, 2.5, {ease: FlxEase.quadInOut});
	});
	cutsceneHandler.timer(cutsceneDelay + 3, function() // darnell lights can
	{
		dad.playAnim('lightCan', true);
		lightCanSnd.play(true);
	});
	cutsceneHandler.timer(cutsceneDelay + 4, function() // pico reloads
	{
		boyfriend.playAnim('cock', true);
		FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x + 180 - FlxG.width / 2}, 0.4, {ease: FlxEase.backOut});
		gunPrepSnd.play(true);
	});
	cutsceneHandler.timer(cutsceneDelay + 4.166, function() createCasing());
	cutsceneHandler.timer(cutsceneDelay + 4.4, function() // darnell kicks can
	{
		dad.playAnim('kickCan', true);
		spraycan.playCanStart();
		kickCanSnd.play(true);
	});
	cutsceneHandler.timer(cutsceneDelay + 4.8, function() // darnell knees can
	{
		dad.playAnim('kneeCan', true);
		kneeCanSnd.play(true);
	});
	cutsceneHandler.timer(cutsceneDelay + 5.1, function() // pico fires at can
	{
		boyfriend.playAnim('intro2', true);
		boyfriend.specialAnim = true;

		FlxG.sound.play(Paths.soundRandom('shots/shot', 1, 4));

		FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x + 100 - FlxG.width / 2}, 2.5, {ease: FlxEase.quadInOut});

		spraycan.playCanShot();
		new FlxTimer().start(1 / 24, function(tmr:FlxTimer)
		{
			darkenStageProps();
		});
	});
	// darnell laughs
	cutsceneHandler.timer(cutsceneDelay + 5.9, function()
	{
		dad.animation.finishCallback = null;
		dad.playAnim('laughCutscene', true);
		darnellLaugh.play(true);
	});

	// nene spits and laughs
	cutsceneHandler.timer(cutsceneDelay + 6.2, function()
	{
		gf.animation.finishCallback = null;
		gf.playAnim('laughCutscene', true);
		neneLaugh.play(true);
	});

	// cutscene ended, camera returns to normal, cutscene flags set and countdown starts.
	var onFinish = function()
	{
		cutsceneMusic.stop(); // stop the music!!!!!!

		game.cameraSpeed = 0;
		FlxTween.tween(FlxG.camera, {zoom: 0.77}, 2, {ease: FlxEase.sineInOut});
		FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x + 180 - FlxG.width / 2}, 2, {
			ease: FlxEase.sineInOut,
			onComplete: function(twn:FlxTween)
			{
				game.cameraSpeed = 1;
			}
		});
		game.inCutscene = false;

		spraycan.visible = false;
		spraycan.active = false;
		spraycan.cutscene = false;
		game.camHUD.alpha = 1;
		game.startCountdown();
	};
	cutsceneHandler.finishCallback = onFinish;
	cutsceneHandler.skipCallback = function()
	{
		onFinish();

		dad.dance();
		gf.dance();
		boyfriend.dance();
		dad.animation.finishCallback = null;
		gf.animation.finishCallback = null;

		game.moveCameraSection();
		game.cameraSpeed = 1;
		FlxTween.cancelTweensOf(FlxG.camera);
		FlxTween.cancelTweensOf(FlxG.camera.scroll);
		FlxG.camera.scroll.set(camFollow.x - FlxG.width / 2, camFollow.y - FlxG.height / 2);
		FlxG.camera.zoom = game.defaultCamZoom;
	};
	FlxG.camera.fade(FlxColor.BLACK, 2, true, null, true);
}

function updateABotEye(finishInstantly:Bool)
{
	var notes = PlayState.SONG.notes;
	var section = notes[Std.int(FlxMath.bound(game.curSection, 0, notes.length - 1))];
	if (section != null && section.mustHitSection == true)
		abot.lookRight();
	else
		abot.lookLeft();

	if (finishInstantly)
		abot.eyes.anim.curFrame = abot.eyes.anim.length - 1;
}

function onSongStart()
{
	abot.snd = FlxG.sound.music;
	game.gf.animation.finishCallback = onNeneAnimationFinished;
}

function onNeneAnimationFinished(name:String)
{
	if (!game.startedCountdown)
		return;

	if ((currentNeneState == 'raise' || currentNeneState == 'lower') && (name == 'raiseKnife' || name == 'lowerKnife'))
	{
		animationFinished = true;
		transitionState();
	}
}

function precache()
{
	spraycan = new SpraycanAtlasSprite(spraycanPile.x + 530, spraycanPile.y - 240);
	add(spraycan);

	lightCanSnd = loadSound('Darnell_Lighter');
	kickCanSnd = loadSound('Kick_Can_UP');
	kneeCanSnd = loadSound('Kick_Can_FORWARD');

	if (!ClientPrefs.data.lowQuality)
	{
		casingFrames = Paths.getSparrowAtlas('stages/phillyStreets/PicoBullet'); // precache
		casingGroup = new FlxSpriteGroup();
		add(casingGroup);
	}

	gunPrepSnd = loadSound('Gun_Prep');
	bonkSnd = loadSound('Pico_Bonk');

	for (i in 1...5)
		Paths.sound('shots/shot' + i);
}

function loadSound(name:String):FlxSound
{
	var sound:FlxSound = new FlxSound();
	FlxG.sound.list.add(sound);
	sound.loadEmbedded(Paths.sound(name));
	return sound;
}

function setupRainShader()
{
	rainShader = new RainShader();
	rainShader.scale = FlxG.height / 200;
	switch (game.songName)
	{
		case 'darnell':
			rainShaderStartIntensity = 0;
			rainShaderEndIntensity = 0.1;
		case 'lit-up':
			rainShaderStartIntensity = 0.1;
			rainShaderEndIntensity = 0.2;
		case '2hot':
			rainShaderStartIntensity = 0.2;
			rainShaderEndIntensity = 0.4;
	}
	rainShader.intensity = rainShaderStartIntensity;
	FlxG.camera.filters = [new ShaderFilter(rainShader)];
}

function onUpdate(elapsed:Float)
{
	if (scrollingSky != null)
		scrollingSky.scrollX -= elapsed * 22;

	if (rainShader != null)
	{
		var songLength:Float = FlxG.sound.music != null ? FlxG.sound.music.length : 0;
		rainShader.intensity = FlxMath.remapToRange(Conductor.songPosition, 0, songLength, rainShaderStartIntensity, rainShaderEndIntensity);
		rainShader.updateViewInfo(FlxG.width, FlxG.height, FlxG.camera);
		rainShader.update(elapsed);
	}

	if (game.gf == null || !game.startedCountdown)
		return;

	animationFinished = game.gf.isAnimationFinished();
	transitionState();
}

function transitionState()
{
	var gf = game.gf;
	switch (currentNeneState)
	{
		case 'default':
			if (game.health <= VULTURE_THRESHOLD)
			{
				currentNeneState = 'preRaise';
				gf.skipDance = true;
			}

		case 'preRaise':
			if (game.health > VULTURE_THRESHOLD)
			{
				currentNeneState = 'default';
				gf.skipDance = false;
			}
			else if (animationFinished)
			{
				currentNeneState = 'raise';
				gf.playAnim('raiseKnife');
				gf.skipDance = true;
				gf.danced = true;
				animationFinished = false;
			}

		case 'raise':
			if (animationFinished)
			{
				currentNeneState = 'ready';
				animationFinished = false;
			}

		case 'ready':
			if (game.health > VULTURE_THRESHOLD)
			{
				currentNeneState = 'lower';
				gf.playAnim('lowerKnife');
			}

		case 'lower':
			if (animationFinished)
			{
				currentNeneState = 'default';
				animationFinished = false;
				gf.skipDance = false;
			}
	}
}

function onSectionHit()
	updateABotEye(false);

function onBeatHit(curBeat:Int)
{
	if (currentNeneState == 'ready')
	{
		if (blinkCountdown == 0)
		{
			game.gf.playAnim('idleKnife', false);
			blinkCountdown = FlxG.random.int(MIN_BLINK_DELAY, MAX_BLINK_DELAY);
		}
		else
			blinkCountdown--;
	}

	if (ClientPrefs.data.lowQuality)
		return;

	if (FlxG.random.bool(10) && curBeat != (lastChange + changeInterval) && carInterruptable)
	{
		if (!lightsStop)
			driveCar(phillyCars);
		else
			driveCarLights(phillyCars);
	}

	if (FlxG.random.bool(10) && curBeat != (lastChange + changeInterval) && car2Interruptable && !lightsStop)
		driveCarBack(phillyCars2);

	if (curBeat == (lastChange + changeInterval))
		changeLights(curBeat);
}

function changeLights(beat:Int)
{
	lastChange = beat;
	lightsStop = !lightsStop;

	if (lightsStop)
	{
		phillyTraffic.animation.play('greentored');
		changeInterval = 20;
	}
	else
	{
		phillyTraffic.animation.play('redtogreen');
		changeInterval = 30;

		if (carWaiting)
			finishCarLights(phillyCars);
	}
}

var carOffset:Array<Float> = [306.6, 168.3];

function point(x:Float, y:Float)
	return new FlxPoint(x - carOffset[0], y - carOffset[1]);

function pickCarVariant(sprite:FlxSprite, slowVariant2:Bool):Float
{
	var variant:Int = FlxG.random.int(1, 4);
	sprite.animation.play('car' + variant);

	var extraOffset:Array<Float> = [0, 0];
	var duration:Float = 2;
	switch (variant)
	{
		case 1:
			duration = FlxG.random.float(1, 1.7);
		case 2:
			extraOffset = [20, -15];
			duration = slowVariant2 ? FlxG.random.float(0.9, 1.5) : FlxG.random.float(0.6, 1.2);
		case 3:
			extraOffset = [30, 50];
			duration = FlxG.random.float(1.5, 2.5);
		case 4:
			extraOffset = [10, 60];
			duration = FlxG.random.float(1.5, 2.5);
	}
	sprite.offset.set(extraOffset[0], extraOffset[1]);
	return duration;
}

function finishCarLights(sprite:BGSprite)
{
	carWaiting = false;
	var duration:Float = FlxG.random.float(1.8, 3);
	var startdelay:Float = FlxG.random.float(0.2, 1.2);
	var path = [point(1950 - 80, 980 + 15), point(2400, 980 - 50), point(3102, 1127 + 40)];

	FlxTween.angle(sprite, -5, 18, duration, {ease: FlxEase.sineIn, startDelay: startdelay});
	FlxTween.quadPath(sprite, path, duration, true, {
		ease: FlxEase.sineIn,
		startDelay: startdelay,
		onComplete: function(twn:FlxTween)
		{
			carInterruptable = true;
		}
	});
}

function driveCarLights(sprite:BGSprite)
{
	carInterruptable = false;
	FlxTween.cancelTweensOf(sprite);
	var duration:Float = pickCarVariant(sprite, true);
	var path = [point(1500 - 20, 1049 - 20), point(1770 - 80, 994 + 10), point(1950 - 80, 980 + 15)];

	FlxTween.angle(sprite, -7, -5, duration, {ease: FlxEase.cubeOut});
	FlxTween.quadPath(sprite, path, duration, true, {
		ease: FlxEase.cubeOut,
		onComplete: function(twn:FlxTween)
		{
			carWaiting = true;
			if (!lightsStop)
				finishCarLights(phillyCars);
		}
	});
}

function driveCar(sprite:BGSprite)
{
	carInterruptable = false;
	FlxTween.cancelTweensOf(sprite);
	var duration:Float = pickCarVariant(sprite, false);
	var path = [point(1570, 1049 - 30), point(2400, 980 - 50), point(3102, 1127 + 40)];

	FlxTween.angle(sprite, -8, 18, duration);
	FlxTween.quadPath(sprite, path, duration, true, {
		onComplete: function(twn:FlxTween)
		{
			carInterruptable = true;
		}
	});
}

function driveCarBack(sprite:FlxSprite)
{
	car2Interruptable = false;
	FlxTween.cancelTweensOf(sprite);
	var duration:Float = pickCarVariant(sprite, false);
	var path = [point(3102, 1127 + 60), point(2400, 980 - 30), point(1570, 1049 - 10)];

	FlxTween.angle(sprite, 18, -8, duration);
	FlxTween.quadPath(sprite, path, duration, true, {
		onComplete: function(twn:FlxTween)
		{
			car2Interruptable = true;
		}
	});
}

function onNoteHit(note:Note)
{
	var boyfriend = game.boyfriend;
	var gf = game.gf;

	if (gf != null && FlxG.random.bool(10) && (game.combo == 50 || game.combo == 100))
	{
		var animToPlay:String = 'combo' + game.combo;
		if (gf.animation.exists(animToPlay))
		{
			gf.playAnim(animToPlay);
			gf.specialAnim = true;
		}
	}

	switch (note.noteType)
	{
		case 'weekend-1-cockgun': // HE'S PULLING HIS COCK OUT
			boyfriend.holdTimer = 0;
			boyfriend.playAnim('cock', true);
			boyfriend.specialAnim = true;
			gunPrepSnd.play();

			boyfriend.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int)
			{
				if (name == 'cock')
				{
					if (frameNumber == 3)
					{
						boyfriend.animation.callback = null;
						createCasing();
					}
				}
				else
					boyfriend.animation.callback = null;
			};

			game.notes.forEachAlive(function(other:Note)
			{
				if (other.noteType == 'weekend-1-firegun')
					other.blockHit = false;
			});
			showPicoFade();

		case 'weekend-1-firegun':
			boyfriend.holdTimer = 0;
			boyfriend.playAnim('shoot', true);
			boyfriend.specialAnim = true;
			FlxG.sound.play(Paths.soundRandom('shots/shot', 1, 4));
			spraycan.playCanShot();

			new FlxTimer().start(1 / 24, function(tmr:FlxTimer)
			{
				darkenStageProps();
			});
	}
}

function createCasing()
{
	if (ClientPrefs.data.lowQuality)
		return;

	var boyfriend = game.boyfriend;
	var casing:FlxSprite = new FlxSprite(boyfriend.x + 250, boyfriend.y + 100);
	casing.frames = casingFrames;
	casing.animation.addByPrefix('pop', 'Pop0', 24, false);
	casing.animation.addByPrefix('idle', 'Bullet0', 24, true);
	casing.animation.play('pop', true);

	casing.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int)
	{
		if (name == 'pop' && frameNumber == 40)
		{
			// Get the end position of the bullet dynamically.
			casing.x = casing.x + casing.frame.offset.x - 1;
			casing.y = casing.y + casing.frame.offset.y + 1;

			casing.angle = 125.1; // Copied from FLA

			// Okay this is the neat part, we can set the velocity and angular acceleration to make it roll without editing update().
			var randomFactorA:Float = FlxG.random.float(3, 10);
			var randomFactorB:Float = FlxG.random.float(1.0, 2.0);
			casing.velocity.x = 20 * randomFactorB;
			casing.drag.x = randomFactorA * randomFactorB;

			casing.angularVelocity = 100;
			// Calculated to ensure angular acceleration is maintained through the whole roll.
			casing.angularDrag = (casing.drag.x / casing.velocity.x) * 100;

			casing.animation.play('idle');
			casing.animation.callback = null; // Save performance.
		}
	};
	casingGroup.add(casing);
}

function onOpponentNoteHit(note:Note)
{
	var dad = game.dad;
	var sndTime:Float = note.strumTime - Conductor.songPosition;
	switch (note.noteType)
	{
		case 'weekend-1-lightcan':
			dad.holdTimer = 0;
			dad.playAnim('lightCan', true);
			dad.specialAnim = true;
			lightCanSnd.play(true, sndTime - 65);

			game.isCameraOnForcedPos = true;
			game.defaultCamZoom += 0.1;
			game.moveCamera(true);
			game.cameraSpeed = 2;
			game.camFollow.x -= 100;
		case 'weekend-1-kickcan':
			dad.holdTimer = 0;
			dad.playAnim('kickCan', true);
			dad.specialAnim = true;
			kickCanSnd.play(true, sndTime - 50);
			spraycan.playCanStart();
			game.camFollow.x += 250;
			game.cameraSpeed = 1.5;
			game.defaultCamZoom -= 0.1;

			new FlxTimer().start(1.1, function(tmr:FlxTimer)
			{
				game.isCameraOnForcedPos = false;
				game.moveCameraSection();
				game.cameraSpeed = 1;
			});
		case 'weekend-1-kneecan':
			dad.holdTimer = 0;
			dad.playAnim('kneeCan', true);
			dad.specialAnim = true;
			kneeCanSnd.play(true, sndTime - 22);
	}
}

function onNoteMiss(note:Note)
{
	if (note.noteType != 'weekend-1-firegun')
		return;

	var boyfriend = game.boyfriend;
	boyfriend.playAnim('shootMISS', true);
	boyfriend.specialAnim = true;
	bonkSnd.play();

	if (picoFlicker != null)
	{
		picoFlicker.cancel();
		picoFlicker.destroy();
	}
	picoFlicker = null;

	boyfriend.animation.finishCallback = function(name:String)
	{
		if (name == 'shootMISS' && game.health > 0.0 && !game.practiceMode && game.gameOverTimer == null)
		{
			// FlxFlicker was crashing so fuck it, FlxTimer all the way
			picoFlicker = new FlxTimer().start(1 / 30, function(tmr:FlxTimer)
			{
				boyfriend.visible = !boyfriend.visible;
				if (tmr.loopsLeft == 0)
				{
					boyfriend.visible = true;
					picoFlicker = new FlxTimer().start(1 / 60, function(tmr2:FlxTimer)
					{
						boyfriend.visible = !boyfriend.visible;
						if (tmr2.loopsLeft == 0)
							boyfriend.visible = true;
					}, 30);
				}
			}, 30);
		}
		boyfriend.animation.finishCallback = null;
	};

	game.health -= 0.4;
	if (game.health <= 0.0 && !game.practiceMode)
	{
		game.deathSoundName = 'fnf_loss_sfx-pico-explode';
		game.loopSoundName = 'gameOverStart-pico-explode';
		game.characterName = 'pico-explosion-dead';
	}
}

function showPicoFade()
{
	if (picoFade == null)
		return;

	var boyfriend = game.boyfriend;
	picoFade.setPosition(boyfriend.x, boyfriend.y);
	picoFade.frames = boyfriend.frames;
	picoFade.frame = boyfriend.frame;
	picoFade.alpha = 0.3;
	picoFade.scale.set(1, 1);
	picoFade.updateHitbox();
	picoFade.visible = true;

	FlxTween.cancelTweensOf(picoFade.scale);
	FlxTween.cancelTweensOf(picoFade);
	FlxTween.tween(picoFade.scale, {x: 1.3, y: 1.3}, 0.4);
	FlxTween.tween(picoFade, {alpha: 0}, 0.4, {
		onComplete: function(twn:FlxTween)
		{
			picoFade.visible = false;
		}
	});
}

function darkenStageProps()
{
	for (sprite in darkenable)
		darkenSprite(sprite);
}

function darkenSprite(sprite:FlxSprite)
{
	sprite.color = 0xFF111111;
	new FlxTimer().start(1 / 24, function(tmr:FlxTimer)
	{
		sprite.color = 0xFF222222;
		FlxTween.color(sprite, 1.4, 0xFF222222, 0xFFFFFFFF);
	});
}
