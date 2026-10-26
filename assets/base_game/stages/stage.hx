// Week 1 - Stage
import objects.BGSprite;
import objects.Character;
import states.stages.objects.DadBattleFog;

var dadbattleBlack:BGSprite;
var dadbattleLight:BGSprite;
var dadbattleFog:DadBattleFog;

function create()
{
	if (PlayState.SONG != null && Paths.formatToSongPath(PlayState.SONG.song) == 'tutorial')
		StickerSubState.STICKER_PACK = 'tutorial';

	var bg:BGSprite = new BGSprite('stages/stage/stageback', -600, -200, 0.9, 0.9);
	add(bg);

	var stageFront:BGSprite = new BGSprite('stages/stage/stagefront', -650, 600, 0.9, 0.9);
	stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
	stageFront.updateHitbox();
	add(stageFront);

	if (!ClientPrefs.data.lowQuality)
	{
		var stageLight:BGSprite = new BGSprite('stages/stage/stage_light', -125, -100, 0.9, 0.9);
		stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
		stageLight.updateHitbox();
		add(stageLight);

		var stageLight2:BGSprite = new BGSprite('stages/stage/stage_light', 1225, -100, 0.9, 0.9);
		stageLight2.setGraphicSize(Std.int(stageLight2.width * 1.1));
		stageLight2.updateHitbox();
		stageLight2.flipX = true;
		add(stageLight2);

		var stageCurtains:BGSprite = new BGSprite('stages/stage/stagecurtains', -500, -300, 1.3, 1.3);
		stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
		stageCurtains.updateHitbox();
		add(stageCurtains);
	}
}

function onEventPushed(name:String, value1:String, value2:String, strumTime:Float)
{
	switch (name)
	{
		case 'Dadbattle Spotlight':
			dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
			dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
			dadbattleBlack.alpha = 0.25;
			dadbattleBlack.visible = false;
			add(dadbattleBlack);

			dadbattleLight = new BGSprite('stages/stage/spotlight', 400, -400);
			dadbattleLight.alpha = 0.375;
			dadbattleLight.blend = BlendMode.ADD;
			dadbattleLight.visible = false;
			add(dadbattleLight);

			dadbattleFog = new DadBattleFog();
			dadbattleFog.visible = false;
			add(dadbattleFog);
	}
}

function onEvent(name:String, value1:String, value2:String, strumTime:Float)
{
	switch (name)
	{
		case 'Dadbattle Spotlight':
			var parsed:Float = Std.parseFloat(value1);
			var val:Int = Math.isNaN(parsed) ? 0 : Math.round(parsed);

			switch (val)
			{
				case 1, 2, 3: // enable and target dad
					if (val == 1) // enable
					{
						dadbattleBlack.visible = true;
						dadbattleLight.visible = true;
						dadbattleFog.visible = true;
						game.defaultCamZoom += 0.12;
					}

					var who:Character = game.dad;
					if (val > 2)
						who = game.boyfriend;
					// 2 only targets dad
					dadbattleLight.alpha = 0;
					new FlxTimer().start(0.12, function(tmr:FlxTimer)
					{
						dadbattleLight.alpha = 0.375;
					});
					dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);
					FlxTween.tween(dadbattleFog, {alpha: 0.7}, 1.5, {ease: FlxEase.quadInOut});

				default:
					dadbattleBlack.visible = false;
					dadbattleLight.visible = false;
					game.defaultCamZoom -= 0.12;
					FlxTween.tween(dadbattleFog, {alpha: 0}, 0.7, {
						onComplete: function(twn:FlxTween)
						{
							dadbattleFog.visible = false;
						}
					});
			}
	}
}
