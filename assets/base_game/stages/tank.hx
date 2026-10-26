// Week 7 - Ugh, Guns, Stress
import objects.BGSprite;
import objects.Character;
import states.stages.objects.BackgroundTank;
import states.stages.objects.TankmenBG;

var tankWatchtower:BGSprite;
var tankGround:BackgroundTank;
var tankmanRun:FlxTypedGroup;
var foregroundSprites:FlxTypedGroup;

var cutsceneHandler:CutsceneHandler;
var tankman:FlxAnimate;
var pico:FlxAnimate;
var boyfriendCutscene:FlxSprite;
var audioPlaying:FlxSound;
var zoomBackCalls:Int = 0;
var foregroundLowered:Bool = false;

function create()
{
	var sky:BGSprite = new BGSprite('stages/tank/tankSky', -400, -400, 0, 0);
	add(sky);

	if (!ClientPrefs.data.lowQuality)
	{
		var clouds:BGSprite = new BGSprite('stages/tank/tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
		clouds.active = true;
		clouds.velocity.x = FlxG.random.float(5, 15);
		add(clouds);

		var mountains:BGSprite = new BGSprite('stages/tank/tankMountains', -300, -20, 0.2, 0.2);
		mountains.setGraphicSize(Std.int(1.2 * mountains.width));
		mountains.updateHitbox();
		add(mountains);

		var buildings:BGSprite = new BGSprite('stages/tank/tankBuildings', -200, 0, 0.3, 0.3);
		buildings.setGraphicSize(Std.int(1.1 * buildings.width));
		buildings.updateHitbox();
		add(buildings);
	}

	var ruins:BGSprite = new BGSprite('stages/tank/tankRuins', -200, 0, 0.35, 0.35);
	ruins.setGraphicSize(Std.int(1.1 * ruins.width));
	ruins.updateHitbox();
	add(ruins);

	if (!ClientPrefs.data.lowQuality)
	{
		var smokeLeft:BGSprite = new BGSprite('stages/tank/smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
		add(smokeLeft);
		var smokeRight:BGSprite = new BGSprite('stages/tank/smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
		add(smokeRight);

		tankWatchtower = new BGSprite('stages/tank/tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
		add(tankWatchtower);
	}

	tankGround = new BackgroundTank();
	add(tankGround);

	tankmanRun = new FlxTypedGroup();
	add(tankmanRun);

	var ground:BGSprite = new BGSprite('stages/tank/tankGround', -420, -150);
	ground.setGraphicSize(Std.int(1.15 * ground.width));
	ground.updateHitbox();
	add(ground);

	foregroundSprites = new FlxTypedGroup();
	foregroundSprites.add(new BGSprite('stages/tank/tank0', -500, 650, 1.7, 1.5, ['fg']));
	if (!ClientPrefs.data.lowQuality)
		foregroundSprites.add(new BGSprite('stages/tank/tank1', -300, 750, 2, 0.2, ['fg']));
	foregroundSprites.add(new BGSprite('stages/tank/tank2', 450, 940, 1.5, 1.5, ['foreground']));
	if (!ClientPrefs.data.lowQuality)
		foregroundSprites.add(new BGSprite('stages/tank/tank4', 1300, 900, 1.5, 1.5, ['fg']));
	foregroundSprites.add(new BGSprite('stages/tank/tank5', 1620, 700, 1.5, 1.5, ['fg']));
	if (!ClientPrefs.data.lowQuality)
		foregroundSprites.add(new BGSprite('stages/tank/tank3', 1300, 1200, 3.5, 2.5, ['fg']));

	if (game.songName == 'stress')
		stage.setDefaultGF('pico-speaker');
	else
		stage.setDefaultGF('gf-tankmen');

	if (PlayState.isStoryMode && !PlayState.seenCutscene)
	{
		switch (game.songName)
		{
			case 'ugh':
				stage.setStartCallback(ughIntro);
			case 'guns':
				stage.setStartCallback(gunsIntro);
			case 'stress':
				stage.setStartCallback(stressIntro);
		}
	}
}

function onCreatePost()
{
	add(foregroundSprites);

	if (ClientPrefs.data.lowQuality)
		return;

	for (member in game.gfGroup.members)
	{
		var gf:Character = member;
		if (gf != null && gf.curCharacter == 'pico-speaker')
		{
			var firstTank:TankmenBG = new TankmenBG(20, 500, true);
			firstTank.resetShit(20, 1500, true);
			firstTank.strumTime = 10;
			firstTank.visible = false;
			tankmanRun.add(firstTank);

			for (i in 0...TankmenBG.animationNotes.length)
			{
				if (FlxG.random.bool(16))
				{
					var tankBih = tankmanRun.recycle(TankmenBG);
					tankBih.strumTime = TankmenBG.animationNotes[i][0];
					tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
					tankmanRun.add(tankBih);
				}
			}
			break;
		}
	}
}

function onCountdownTick(counter:Int)
{
	if (counter % 2 == 0)
		everyoneDance();
}

function onBeatHit(curBeat:Int)
	everyoneDance();

function everyoneDance()
{
	if (tankWatchtower != null)
		tankWatchtower.dance();
	foregroundSprites.forEach(function(spr:BGSprite)
	{
		spr.dance();
	});
}

function prepareCutscene()
{
	cutsceneHandler = new CutsceneHandler();

	game.dadGroup.alpha = 0.00001;
	game.camHUD.visible = false;

	tankman = new FlxAnimate(game.dad.x + 419, game.dad.y + 225);
	tankman.showPivot = false;
	Paths.loadAnimateAtlas(tankman, 'cutscenes/tankman');
	tankman.antialiasing = ClientPrefs.data.globalAntialiasing;
	stage.addBehindDad(tankman);
	cutsceneHandler.push(tankman);

	cutsceneHandler.finishCallback = function()
	{
		var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
		FlxG.sound.music.fadeOut(timeForStuff);
		FlxTween.tween(FlxG.camera, {zoom: game.defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
		game.startCountdown();

		game.dadGroup.alpha = 1;
		game.camHUD.visible = true;
		game.boyfriend.animation.finishCallback = null;
		game.gf.animation.finishCallback = null;
		game.gf.dance();
	};

	cutsceneHandler.skipCallback = function()
	{
		game.dadGroup.alpha = 1;
		game.gfGroup.alpha = 1;
		game.boyfriendGroup.alpha = 1;
		game.camHUD.visible = true;

		if (audioPlaying != null)
			audioPlaying.stop();

		game.boyfriend.animation.finishCallback = null;
		game.gf.animation.finishCallback = null;
		game.gf.dance();
		game.dad.dance();
		game.boyfriend.dance();

		FlxTween.cancelTweensOf(FlxG.camera);
		FlxTween.cancelTweensOf(game.camFollow);
		game.moveCameraSection();
		FlxG.camera.scroll.set(game.camFollow.x - FlxG.width / 2, game.camFollow.y - FlxG.height / 2);
		FlxG.camera.zoom = game.defaultCamZoom;
		restoreForeground();
		game.startCountdown();
	};
	game.camFollow.set(game.dad.x + 280, game.dad.y + 170);
}

function loadSound(name:String):FlxSound
{
	var sound:FlxSound = new FlxSound().loadEmbedded(Paths.sound(name));
	FlxG.sound.list.add(sound);
	return sound;
}

function ughIntro()
{
	prepareCutscene();
	cutsceneHandler.endTime = 12;
	cutsceneHandler.music = 'DISTORTO';
	Paths.sound('bfBeep');

	var wellWellWell:FlxSound = loadSound('wellWellWell');
	var killYou:FlxSound = loadSound('killYou');

	tankman.anim.addBySymbol('wellWell', 'TANK TALK 1 P1', 24, false);
	tankman.anim.addBySymbol('killYou', 'TANK TALK 1 P2', 24, false);
	tankman.anim.play('wellWell', true);
	FlxG.camera.zoom *= 1.2;

	// Well well well, what do we got here?
	cutsceneHandler.timer(0.1, function()
	{
		wellWellWell.play(true);
		audioPlaying = wellWellWell;
	});

	// Move camera to BF
	cutsceneHandler.timer(3, function()
	{
		game.camFollow.x += 750;
		game.camFollow.y += 100;
	});

	// Beep!
	cutsceneHandler.timer(4.5, function()
	{
		game.boyfriend.playAnim('singUP', true);
		game.boyfriend.specialAnim = true;
		FlxG.sound.play(Paths.sound('bfBeep'));
	});

	// Move camera to Tankman
	cutsceneHandler.timer(6, function()
	{
		game.camFollow.x -= 750;
		game.camFollow.y -= 100;

		// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
		tankman.anim.play('killYou', true);
		killYou.play(true);
		audioPlaying = killYou;
	});
}

function gunsIntro()
{
	prepareCutscene();
	cutsceneHandler.endTime = 11.5;
	cutsceneHandler.music = 'DISTORTO';

	var tightBars:FlxSound = loadSound('tankSong2');

	tankman.anim.addBySymbol('tightBars', 'TANK TALK 2', 24, false);
	tankman.anim.play('tightBars', true);
	game.boyfriend.animation.curAnim.finish();

	cutsceneHandler.onStart = function()
	{
		tightBars.play(true);
		audioPlaying = tightBars;
		var zoom:Float = game.defaultCamZoom;
		FlxTween.tween(FlxG.camera, {zoom: zoom * 1.2}, 4, {ease: FlxEase.quadInOut});
		FlxTween.tween(FlxG.camera, {zoom: zoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
		FlxTween.tween(FlxG.camera, {zoom: zoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
	};

	cutsceneHandler.timer(4, function()
	{
		game.gf.playAnim('sad', true);
		game.gf.animation.finishCallback = function(name:String)
		{
			game.gf.playAnim('sad', true);
		};
	});
}

function stressIntro()
{
	prepareCutscene();

	cutsceneHandler.endTime = 35.5;
	game.gfGroup.alpha = 0.00001;
	game.boyfriendGroup.alpha = 0.00001;
	game.camFollow.set(game.dad.x + 400, game.dad.y + 170);
	FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
	foregroundSprites.forEach(function(spr:BGSprite)
	{
		spr.y += 100;
	});
	foregroundLowered = true;
	Paths.sound('stressCutscene');

	pico = new FlxAnimate(game.gf.x + 150, game.gf.y + 450);
	pico.showPivot = false;
	Paths.loadAnimateAtlas(pico, 'cutscenes/picoAppears');
	pico.antialiasing = ClientPrefs.data.globalAntialiasing;
	pico.anim.addBySymbol('dance', 'GF Dancing at Gunpoint', 24, true);
	pico.anim.addBySymbol('dieBitch', 'GF Time to Die sequence', 24, false);
	pico.anim.addBySymbol('picoAppears', 'Pico Saves them sequence', 24, false);
	pico.anim.addBySymbol('picoEnd', 'Pico Dual Wield on Speaker idle', 24, false);
	pico.anim.play('dance', true);
	stage.addBehindGF(pico);
	cutsceneHandler.push(pico);

	var picoCycleDone:Bool = false;
	pico.anim.onComplete.add(function()
	{
		if (picoCycleDone)
			return;

		switch (pico.anim.curInstance.symbol.name)
		{
			case 'dieBitch', 'GF Time to Die sequence':
				pico.anim.play('picoAppears', true);
				game.boyfriendGroup.alpha = 1;
				boyfriendCutscene.visible = false;
				game.boyfriend.playAnim('bfCatch', true);
				game.boyfriend.animation.finishCallback = function(name:String)
				{
					if (name != 'idle')
					{
						game.boyfriend.playAnim('idle', true);
						game.boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
					}
				};
			case 'picoAppears', 'Pico Saves them sequence':
				pico.anim.play('picoEnd', true);
			case 'picoEnd', 'Pico Dual Wield on Speaker idle':
				game.gfGroup.alpha = 1;
				pico.visible = false;
				picoCycleDone = true;
		}
	});

	boyfriendCutscene = new FlxSprite(game.boyfriend.x + 5, game.boyfriend.y + 20);
	boyfriendCutscene.antialiasing = ClientPrefs.data.globalAntialiasing;
	boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
	boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
	boyfriendCutscene.animation.play('idle', true);
	boyfriendCutscene.animation.curAnim.finish();
	stage.addBehindBF(boyfriendCutscene);
	cutsceneHandler.push(boyfriendCutscene);

	var cutsceneSnd:FlxSound = loadSound('stressCutscene');

	tankman.anim.addBySymbol('godEffingDamnIt', 'TANK TALK 3 P1 UNCUT', 24, false);
	tankman.anim.addBySymbol('lookWhoItIs', 'TANK TALK 3 P2 UNCUT', 24, false);
	tankman.anim.play('godEffingDamnIt', true);

	cutsceneHandler.onStart = function()
	{
		cutsceneSnd.play(true);
		audioPlaying = cutsceneSnd;
	};

	cutsceneHandler.timer(15.2, function()
	{
		FlxTween.tween(game.camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
		FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

		pico.anim.play('dieBitch', true);
	});

	cutsceneHandler.timer(17.5, function()
	{
		zoomBack();
	});

	cutsceneHandler.timer(19.5, function()
	{
		tankman.anim.play('lookWhoItIs', true);
	});

	cutsceneHandler.timer(20, function()
	{
		game.camFollow.set(game.dad.x + 500, game.dad.y + 170);
	});

	cutsceneHandler.timer(31.2, function()
	{
		game.boyfriend.playAnim('singUPmiss', true);
		game.boyfriend.animation.finishCallback = function(name:String)
		{
			if (name == 'singUPmiss')
			{
				game.boyfriend.playAnim('idle', true);
				game.boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
			}
		};

		game.camFollow.set(game.boyfriend.x + 280, game.boyfriend.y + 200);
		FlxG.camera.snapToTarget();
		game.cameraSpeed = 12;
		FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
	});

	cutsceneHandler.timer(32.2, function()
	{
		zoomBack();
	});
}

function zoomBack()
{
	game.camFollow.set(630, 425);
	FlxG.camera.snapToTarget();
	FlxG.camera.zoom = 0.8;
	game.cameraSpeed = 1;

	zoomBackCalls++;
	if (zoomBackCalls > 1)
		restoreForeground();
}

function restoreForeground()
{
	if (!foregroundLowered)
		return;

	foregroundLowered = false;
	foregroundSprites.forEach(function(spr:BGSprite)
	{
		spr.y -= 100;
	});
}
