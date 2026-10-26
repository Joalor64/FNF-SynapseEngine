// Week 5 - Winter Horrorland
import objects.BGSprite;

function create()
{
	var bg:BGSprite = new BGSprite('stages/mall/evilBG', -400, -500, 0.2, 0.2);
	bg.setGraphicSize(Std.int(bg.width * 0.8));
	bg.updateHitbox();
	add(bg);

	var evilTree:BGSprite = new BGSprite('stages/mall/evilTree', 300, -300, 0.2, 0.2);
	add(evilTree);

	var evilSnow:BGSprite = new BGSprite('stages/mall/evilSnow', -200, 700);
	add(evilSnow);
	stage.setDefaultGF('gf-christmas');

	if (PlayState.isStoryMode && !PlayState.seenCutscene && game.songName == 'winter-horrorland')
		stage.setStartCallback(winterHorrorlandCutscene);
}

function winterHorrorlandCutscene()
{
	game.camHUD.visible = false;
	game.inCutscene = true;

	FlxG.sound.play(Paths.sound('Lights_Turn_On'));
	FlxG.camera.zoom = 1.5;
	FlxG.camera.follow(new FlxObject(400, -2050));

	// blackout at the start
	var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
	blackScreen.scrollFactor.set();
	add(blackScreen);

	FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
		ease: FlxEase.linear,
		onComplete: function(twn:FlxTween)
		{
			remove(blackScreen);
			blackScreen.destroy();
		}
	});

	// zoom out
	new FlxTimer().start(0.8, function(tmr:FlxTimer)
	{
		game.camHUD.visible = true;
		FlxTween.tween(FlxG.camera, {zoom: game.defaultCamZoom}, 2.5, {
			ease: FlxEase.quadInOut,
			onComplete: function(twn:FlxTween)
			{
				game.startCountdown();
				FlxG.camera.follow(game.camFollowPos);
				FlxG.camera.focusOn(game.camFollow);
			}
		});
	});
}
