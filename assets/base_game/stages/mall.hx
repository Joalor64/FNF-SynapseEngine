// Week 5 - Cocoa, Eggnog
import objects.BGSprite;
import states.stages.objects.MallCrowd;

var upperBoppers:BGSprite;
var bottomBoppers:MallCrowd;
var santa:BGSprite;

function create()
{
	StickerSubState.STICKER_PACK = 'parents';

	var bg:BGSprite = new BGSprite('stages/mall/bgWalls', -1000, -500, 0.2, 0.2);
	bg.setGraphicSize(Std.int(bg.width * 0.8));
	bg.updateHitbox();
	add(bg);

	if (!ClientPrefs.data.lowQuality)
	{
		upperBoppers = new BGSprite('stages/mall/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
		upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
		upperBoppers.updateHitbox();
		add(upperBoppers);

		var bgEscalator:BGSprite = new BGSprite('stages/mall/bgEscalator', -1100, -600, 0.3, 0.3);
		bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
		bgEscalator.updateHitbox();
		add(bgEscalator);
	}

	var tree:BGSprite = new BGSprite('stages/mall/christmasTree', 370, -250, 0.40, 0.40);
	add(tree);

	bottomBoppers = new MallCrowd(-300, 140);
	add(bottomBoppers);

	var fgSnow:BGSprite = new BGSprite('stages/mall/fgSnow', -600, 700);
	add(fgSnow);

	santa = new BGSprite('stages/mall/santa', -840, 150, 1, 1, ['santa idle in fear']);
	add(santa);
	Paths.sound('Lights_Shut_off');
	stage.setDefaultGF('gf-christmas');

	if (PlayState.isStoryMode && !PlayState.seenCutscene)
		stage.setEndCallback(eggnogEndCutscene);
}

function onCountdownTick(counter:Int)
	everyoneDance();

function onBeatHit(curBeat:Int)
	everyoneDance();

function onEvent(name:String, value1:String, value2:String, strumTime:Float)
{
	switch (name)
	{
		case 'Hey!':
			switch (StringTools.trim(value1.toLowerCase()))
			{
				case 'bf', 'boyfriend', '0':
					return;
			}

			// same default as the "Hey!" event itself
			var time:Float = Std.parseFloat(value2);
			if (Math.isNaN(time) || time <= 0)
				time = 0.6;

			bottomBoppers.animation.play('hey', true);
			bottomBoppers.heyTimer = time;
	}
}

function everyoneDance()
{
	if (upperBoppers != null)
		upperBoppers.dance(true);

	bottomBoppers.dance(true);
	santa.dance(true);
}

function eggnogEndCutscene()
{
	if (PlayState.storyPlaylist[1] == null)
	{
		game.endSong();
		return;
	}

	var nextSong:String = Paths.formatToSongPath(PlayState.storyPlaylist[1]);
	if (nextSong == 'winter-horrorland')
	{
		FlxG.sound.play(Paths.sound('Lights_Shut_off'));

		var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom, -FlxG.height * FlxG.camera.zoom);
		blackShit.makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
		blackShit.scrollFactor.set();
		add(blackShit);
		game.camHUD.visible = false;

		game.inCutscene = true;
		game.canPause = false;

		new FlxTimer().start(1.5, function(tmr:FlxTimer)
		{
			game.endSong();
		});
	}
	else
		game.endSong();
}
