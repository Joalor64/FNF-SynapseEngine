// Week 6 - Senpai, Roses
import objects.BGSprite;
import cutscenes.DialogueBox;
import states.stages.objects.BackgroundGirls;

var bgGirls:BackgroundGirls;
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

	var bgSky:BGSprite = new BGSprite('stages/school/weebSky', 0, 0, 0.1, 0.1);
	add(bgSky);
	bgSky.antialiasing = false;

	var repositionShit = -200;

	var bgSchool:BGSprite = new BGSprite('stages/school/weebSchool', repositionShit, 0, 0.6, 0.90);
	add(bgSchool);
	bgSchool.antialiasing = false;

	var bgStreet:BGSprite = new BGSprite('stages/school/weebStreet', repositionShit, 0, 0.95, 0.95);
	add(bgStreet);
	bgStreet.antialiasing = false;

	var widShit = Std.int(bgSky.width * PlayState.daPixelZoom);
	if (!ClientPrefs.data.lowQuality)
	{
		var fgTrees:BGSprite = new BGSprite('stages/school/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
		fgTrees.setGraphicSize(Std.int(widShit * 0.8));
		fgTrees.updateHitbox();
		add(fgTrees);
		fgTrees.antialiasing = false;
	}

	var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
	bgTrees.frames = Paths.getPackerAtlas('stages/school/weebTrees');
	bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
	bgTrees.animation.play('treeLoop');
	bgTrees.scrollFactor.set(0.85, 0.85);
	add(bgTrees);
	bgTrees.antialiasing = false;

	if (!ClientPrefs.data.lowQuality)
	{
		var treeLeaves:BGSprite = new BGSprite('stages/school/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
		treeLeaves.setGraphicSize(widShit);
		treeLeaves.updateHitbox();
		add(treeLeaves);
		treeLeaves.antialiasing = false;
	}

	bgSky.setGraphicSize(widShit);
	bgSchool.setGraphicSize(widShit);
	bgStreet.setGraphicSize(widShit);
	bgTrees.setGraphicSize(Std.int(widShit * 1.4));

	bgSky.updateHitbox();
	bgSchool.updateHitbox();
	bgStreet.updateHitbox();
	bgTrees.updateHitbox();

	if (!ClientPrefs.data.lowQuality)
	{
		bgGirls = new BackgroundGirls(-100, 190);
		bgGirls.scrollFactor.set(0.9, 0.9);
		add(bgGirls);
	}
	stage.setDefaultGF('gf-pixel');

	switch (game.songName)
	{
		case 'senpai':
			FlxG.sound.playMusic(Paths.music('Lunchbox'), 0);
			FlxG.sound.music.fadeIn(1, 0, 0.8);
		case 'roses':
			FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
	}

	if (PlayState.isStoryMode && !PlayState.seenCutscene)
	{
		if (game.songName == 'roses')
			FlxG.sound.play(Paths.sound('ANGRY'));
		initDoof();
		stage.setStartCallback(schoolIntro);
	}
}

function onBeatHit(curBeat:Int)
{
	if (bgGirls != null)
		bgGirls.dance();
}

function onEvent(name:String, value1:String, value2:String, strumTime:Float)
{
	switch (name)
	{
		case 'BG Freaks Expression':
			if (bgGirls != null)
				bgGirls.swapDanceType();
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

function initDoof()
{
	var songName:String = game.songName;
	var file:String = Paths.txt('songs/' + songName + '/' + songName + 'Dialogue_' + ClientPrefs.data.language); // Checks for vanilla/Senpai dialogue
	if (!fileExists(file))
		file = Paths.txt('songs/' + songName + '/' + songName + 'Dialogue');

	if (!fileExists(file))
		return;

	doof = new DialogueBox(false, CoolUtil.coolTextFile(file));
	doof.cameras = [game.camHUD];
	doof.scrollFactor.set();
	doof.finishThing = function() game.startCountdown();
	doof.nextDialogueThing = function() game.startNextDialogue();
	doof.skipDialogueThing = function() game.skipDialogue();
}

function schoolIntro()
{
	game.inCutscene = true;
	var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
	black.scrollFactor.set();
	if (game.songName == 'senpai')
		add(black);

	new FlxTimer().start(0.3, function(tmr:FlxTimer)
	{
		black.alpha -= 0.15;

		if (black.alpha > 0)
			tmr.reset(0.3);
		else
		{
			if (doof != null)
				add(doof);
			else
				game.startCountdown();

			remove(black);
			black.destroy();
		}
	});
}
