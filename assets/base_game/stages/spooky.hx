// Week 2 - Spookeez, South, Monster
import objects.BGSprite;

var halloweenBG:BGSprite;
var halloweenWhite:BGSprite;

var lightningStrikeBeat:Int = 0;
var lightningOffset:Int = 8;

function create()
{
	if (!ClientPrefs.data.lowQuality)
		halloweenBG = new BGSprite('stages/spooky/halloween_bg', -200, -100, 1, 1, ['halloweem bg0', 'halloweem bg lightning strike']);
	else
		halloweenBG = new BGSprite('stages/spooky/halloween_bg_low', -200, -100);
	add(halloweenBG);

	Paths.sound('thunder_1');
	Paths.sound('thunder_2');

	if (PlayState.isStoryMode && !PlayState.seenCutscene && game.songName == 'monster')
		stage.setStartCallback(monsterCutscene);
}

function onCreatePost()
{
	halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
	halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
	halloweenWhite.alpha = 0;
	halloweenWhite.blend = BlendMode.ADD;
	add(halloweenWhite);
}

function onBeatHit(curBeat:Int)
{
	if (FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		lightningStrike(curBeat);
}

function lightningStrike(curBeat:Int)
{
	FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
	if (!ClientPrefs.data.lowQuality)
		halloweenBG.animation.play('halloweem bg lightning strike');

	FlxG.camera.shake(0.003, 2.3, null, true, FlxAxes.Y);

	lightningStrikeBeat = curBeat;
	lightningOffset = FlxG.random.int(8, 24);

	for (char in [game.boyfriend, game.dad, game.gf])
		if (char != null && char.animOffsets.exists('scared'))
			char.playAnim('scared');

	if (ClientPrefs.data.camZooms)
	{
		FlxG.camera.zoom += 0.015;
		game.camHUD.zoom += 0.03;

		if (!game.camZooming)
		{
			FlxTween.tween(FlxG.camera, {zoom: game.defaultCamZoom}, 0.5);
			FlxTween.tween(game.camHUD, {zoom: 1}, 0.5);
		}
	}

	if (ClientPrefs.data.flashing)
	{
		halloweenWhite.alpha = 0.4;
		FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
		FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
	}
}

function monsterCutscene()
{
	game.inCutscene = true;
	game.camHUD.visible = false;

	var focus = game.dad.getMidpoint();
	focus.x += 150;
	focus.y -= 100;
	FlxG.camera.focusOn(focus);

	FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
	if (game.gf != null)
		game.gf.playAnim('scared', true);
	game.boyfriend.playAnim('scared', true);

	var whiteScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
	whiteScreen.scrollFactor.set();
	whiteScreen.blend = BlendMode.ADD;
	add(whiteScreen);
	FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
		startDelay: 0.1,
		ease: FlxEase.linear,
		onComplete: function(twn:FlxTween)
		{
			remove(whiteScreen);
			whiteScreen.destroy();

			game.camHUD.visible = true;
			game.startCountdown();
		}
	});
}
