// Week 6 - Thorns
import objects.BGSprite;
import cutscenes.DialogueBox;
import flixel.addons.effects.FlxTrail;

var bgGhouls:BGSprite;
var doof:DialogueBox = null;

function isBlank(value:String):Bool
	return value == null || StringTools.trim(value).length < 1;

function create()
{
	var song = PlayState.SONG;
	if (isBlank(song.gameOverSound))
		game.deathSoundName = 'fnf_loss_sfx-pixel';
	if (isBlank(song.gameOverLoop))
		game.loopSoundName = 'gameOver-pixel';
	if (isBlank(song.gameOverEnd))
		game.endSoundName = 'gameOverEnd-pixel';
	if (isBlank(song.gameOverChar))
		game.characterName = 'bf-pixel-dead';

	var posX = 400;
	var posY = 200;

	var bg:BGSprite;
	if (!ClientPrefs.data.lowQuality)
		bg = new BGSprite('stages/school/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
	else
		bg = new BGSprite('stages/school/animatedEvilSchool_low', posX, posY, 0.8, 0.9);

	bg.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
	bg.antialiasing = false;
	add(bg);
	stage.setDefaultGF('gf-pixel');

	FlxG.sound.playMusic(Paths.music('LunchboxScary'), 0);
	FlxG.sound.music.fadeIn(1, 0, 0.8);

	if (PlayState.isStoryMode && !PlayState.seenCutscene && initDoof())
		stage.setStartCallback(schoolIntro);
}

function onCreatePost()
{
	var trail:FlxTrail = new FlxTrail(game.dad, null, 4, 24, 0.3, 0.069);
	stage.addBehindDad(trail);
}

function onEventPushed(name:String, value1:String, value2:String, strumTime:Float)
{
	switch (name)
	{
		case 'Trigger BG Ghouls':
			if (!ClientPrefs.data.lowQuality)
			{
				bgGhouls = new BGSprite('stages/school/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
				bgGhouls.setGraphicSize(Std.int(bgGhouls.width * PlayState.daPixelZoom));
				bgGhouls.updateHitbox();
				bgGhouls.visible = false;
				bgGhouls.antialiasing = false;
				bgGhouls.animation.finishCallback = function(name:String)
				{
					if (name == 'BG freaks glitch instance')
						bgGhouls.visible = false;
				};
				stage.addBehindGF(bgGhouls);
			}
	}
}

function onEvent(name:String, value1:String, value2:String, strumTime:Float)
{
	switch (name)
	{
		case 'Trigger BG Ghouls':
			if (bgGhouls != null)
			{
				bgGhouls.dance(true);
				bgGhouls.visible = true;
			}
	}
}

function fileExists(path:String):Bool
{
	#if sys
	return FileSystem.exists(path);
	#else
	return Assets.exists(path);
	#end
}

function initDoof():Bool
{
	var songName:String = game.songName;
	var file:String = Paths.txt('songs/' + songName + '/' + songName + 'Dialogue_' + ClientPrefs.data.language); // Checks for vanilla/Senpai dialogue
	if (!fileExists(file))
		file = Paths.txt('songs/' + songName + '/' + songName + 'Dialogue');

	if (!fileExists(file))
		return false;

	doof = new DialogueBox(false, CoolUtil.coolTextFile(file));
	doof.cameras = [game.camHUD];
	doof.scrollFactor.set();
	doof.finishThing = function() game.startCountdown();
	doof.nextDialogueThing = function() game.startNextDialogue();
	doof.skipDialogueThing = function() game.skipDialogue();
	return true;
}

function schoolIntro()
{
	game.inCutscene = true;
	var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
	red.scrollFactor.set();
	add(red);

	var senpaiEvil:FlxSprite = new FlxSprite();
	senpaiEvil.frames = Paths.getSparrowAtlas('stages/school/senpaiCrazy');
	senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
	senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
	senpaiEvil.scrollFactor.set();
	senpaiEvil.updateHitbox();
	senpaiEvil.screenCenter();
	senpaiEvil.x += 300;
	game.camHUD.visible = false;

	new FlxTimer().start(2.1, function(tmr:FlxTimer)
	{
		add(senpaiEvil);
		senpaiEvil.alpha = 0;
		new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
		{
			senpaiEvil.alpha += 0.15;
			if (senpaiEvil.alpha < 1)
			{
				swagTimer.reset(0.3);
			}
			else
			{
				senpaiEvil.animation.play('idle');
				FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
				{
					remove(senpaiEvil);
					senpaiEvil.destroy();
					remove(red);
					red.destroy();
					FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
					{
						add(doof);
						game.camHUD.visible = true;
					}, true);
				});
				new FlxTimer().start(3.2, function(deadTime:FlxTimer)
				{
					FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
				});
			}
		});
	});
}
