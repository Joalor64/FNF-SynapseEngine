// Week 3 - Pico, Philly Nice, Blammed
import objects.BGSprite;
import objects.Character;
import backend.utils.ColorUtil;
import states.stages.objects.PhillyTrain;
import states.stages.objects.PhillyGlowGradient;
import states.stages.objects.PhillyGlowParticle;

var phillyLightsColors:Array<Int> = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
var phillyWindow:BGSprite;
var phillyStreet:BGSprite;
var phillyTrain:PhillyTrain;
var curLight:Int = -1;

var blammedLightsBlack:FlxSprite;
var phillyGlowGradient:PhillyGlowGradient;
var phillyGlowParticles:FlxTypedGroup;
var curLightEvent:Int = -1;

var blammedLightsBlackTween:FlxTween;
var phillyWindowTween:FlxTween;

function create()
{
	if (!ClientPrefs.data.lowQuality)
	{
		var bg:BGSprite = new BGSprite('stages/philly/sky', -100, 0, 0.1, 0.1);
		add(bg);
	}

	var city:BGSprite = new BGSprite('stages/philly/city', -10, 0, 0.3, 0.3);
	city.setGraphicSize(Std.int(city.width * 0.85));
	city.updateHitbox();
	add(city);

	phillyWindow = new BGSprite('stages/philly/window', city.x, city.y, 0.3, 0.3);
	phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
	phillyWindow.updateHitbox();
	add(phillyWindow);
	phillyWindow.alpha = 0;

	if (!ClientPrefs.data.lowQuality)
	{
		var streetBehind:BGSprite = new BGSprite('stages/philly/behindTrain', -40, 50);
		add(streetBehind);
	}

	phillyTrain = new PhillyTrain(2000, 360);
	add(phillyTrain);

	phillyStreet = new BGSprite('stages/philly/street', -40, 50);
	add(phillyStreet);

	blammedLightsBlack = createBlackScreen();
	blammedLightsBlack.alpha = 0;
	insert(game.members.indexOf(phillyStreet), blammedLightsBlack);
}

function createBlackScreen():FlxSprite
{
	var black:FlxSprite = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5);
	black.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
	black.scrollFactor.set();
	return black;
}

function onEventPushed(name:String, value1:String, value2:String, strumTime:Float)
{
	switch (name)
	{
		case 'Philly Glow':
			phillyGlowGradient = new PhillyGlowGradient(-400, 225);
			phillyGlowGradient.visible = false;
			insert(game.members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
			if (!ClientPrefs.data.flashing)
				phillyGlowGradient.intendedAlpha = 0.7;

			Paths.image('stages/philly/particle');
			phillyGlowParticles = new FlxTypedGroup();
			phillyGlowParticles.visible = false;
			insert(game.members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
	}
}

function onUpdate(elapsed:Float)
{
	if (curLightEvent <= 0)
		phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;

	if (phillyGlowParticles != null)
	{
		var i:Int = phillyGlowParticles.members.length - 1;
		while (i > 0)
		{
			var particle = phillyGlowParticles.members[i];
			if (particle.alpha <= 0)
			{
				particle.kill();
				phillyGlowParticles.remove(particle, true);
				particle.destroy();
			}
			--i;
		}
	}
}

function onBeatHit(curBeat:Int)
{
	phillyTrain.beatHit(curBeat);

	if (curBeat % 4 == 0 && curLightEvent <= 0)
	{
		curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
		phillyWindow.color = phillyLightsColors[curLight];
		phillyWindow.alpha = 1;
	}
}

function onEvent(name:String, value1:String, value2:String, strumTime:Float)
{
	switch (name)
	{
		case 'Philly Glow':
			phillyGlowEvent(value1);
		case 'Blammed Lights':
			blammedLightsEvent(value1);
	}
}

function getChars():Array<Character>
{
	return [game.boyfriend, game.gf, game.dad];
}

function phillyGlowEvent(value1:String)
{
	if (phillyGlowGradient == null)
		return;

	var parsed:Float = Std.parseFloat(value1);
	var lightId:Int = (Math.isNaN(parsed) || parsed <= 0) ? 0 : Math.round(parsed);

	switch (lightId)
	{
		case 0:
			if (phillyGlowGradient.visible)
			{
				doFlash();
				if (ClientPrefs.data.camZooms)
				{
					FlxG.camera.zoom += 0.5;
					game.camHUD.zoom += 0.1;
				}

				blammedLightsBlack.visible = false;
				phillyGlowGradient.visible = false;
				phillyGlowParticles.visible = false;
				curLightEvent = -1;

				for (who in getChars())
					if (who != null)
						who.color = FlxColor.WHITE;
				phillyStreet.color = FlxColor.WHITE;

				resetWindowLayer();
				phillyWindow.visible = true;
				phillyWindow.alpha = 1;
				curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
				phillyWindow.color = phillyLightsColors[curLight];
			}

		case 1:
			curLightEvent = FlxG.random.int(0, phillyLightsColors.length - 1, [curLightEvent]);
			var color:Int = phillyLightsColors[curLightEvent];

			remove(phillyWindow);
			var particleIndex:Int = game.members.indexOf(phillyGlowParticles);
			if (particleIndex > 0)
				insert(particleIndex + 1, phillyWindow);
			else
				add(phillyWindow);

			if (!phillyGlowGradient.visible)
			{
				doFlash();
				if (ClientPrefs.data.camZooms)
				{
					FlxG.camera.zoom += 0.5;
					game.camHUD.zoom += 0.1;
				}

				blammedLightsBlack.visible = true;
				blammedLightsBlack.alpha = 1;
				phillyWindow.visible = true;
				phillyWindow.alpha = 1;
				phillyGlowGradient.visible = true;
				phillyGlowParticles.visible = true;
			}
			else if (ClientPrefs.data.flashing)
			{
				FlxG.camera.flash(ColorUtil.withAlpha(color, 0.25), 0.5, null, true);
			}

			var charColor:Int = ColorUtil.multiplySaturation(color, ClientPrefs.data.flashing ? 0.75 : 0.5);
			for (who in getChars())
				if (who != null)
					who.color = charColor;

			phillyGlowParticles.forEachAlive(function(particle)
			{
				particle.color = color;
			});
			phillyGlowGradient.color = color;
			phillyWindow.color = color;
			phillyStreet.color = ColorUtil.multiplyBrightness(color, 0.5);

		case 2:
			if (!ClientPrefs.data.lowQuality)
			{
				var particlesNum:Int = FlxG.random.int(8, 12);
				var width:Float = (2000 / particlesNum);
				var color:Int = phillyLightsColors[curLightEvent];
				for (j in 0...3)
				{
					for (i in 0...particlesNum)
					{
						var particle:PhillyGlowParticle = new PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5),
							phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
						phillyGlowParticles.add(particle);
					}
				}
			}
			phillyGlowGradient.bop();
	}
}

function blammedLightsEvent(value1:String)
{
	var lightId:Null<Int> = Std.parseInt(value1);
	if (lightId == null)
		lightId = 0;

	if (lightId > 0 && curLightEvent != lightId)
	{
		if (lightId > 5)
			lightId = FlxG.random.int(1, 5, [curLightEvent]);

		var color:Int = 0xffffffff;
		switch (lightId)
		{
			case 1:
				color = 0xff31a2fd;
			case 2:
				color = 0xff31fd8c;
			case 3:
				color = 0xfff794f7;
			case 4:
				color = 0xfff96d63;
			case 5:
				color = 0xfffba633;
		}
		curLightEvent = lightId;

		remove(phillyWindow);
		var blackIndex:Int = game.members.indexOf(blammedLightsBlack);
		if (blackIndex > 0)
			insert(blackIndex + 1, phillyWindow);
		else
			add(phillyWindow);

		phillyWindow.visible = true;
		phillyWindow.color = color;

		if (blammedLightsBlack.alpha == 0)
		{
			if (blammedLightsBlackTween != null)
				blammedLightsBlackTween.cancel();

			blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 1}, 1, {
				ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
				{
					blammedLightsBlackTween = null;
				}
			});

			if (phillyWindowTween != null)
				phillyWindowTween.cancel();

			phillyWindow.alpha = 0;
			phillyWindowTween = FlxTween.tween(phillyWindow, {alpha: 1}, 1, {
				ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
				{
					phillyWindowTween = null;
				}
			});

			for (char in getChars())
				tweenCharColor(char, FlxColor.WHITE, color);
		}
		else
		{
			if (blammedLightsBlackTween != null)
				blammedLightsBlackTween.cancel();

			blammedLightsBlackTween = null;
			blammedLightsBlack.alpha = 1;

			if (phillyWindowTween != null)
				phillyWindowTween.cancel();

			phillyWindowTween = null;
			phillyWindow.alpha = 1;

			for (char in getChars())
			{
				if (char != null)
				{
					if (char.colorTween != null)
						char.colorTween.cancel();

					char.colorTween = null;
					char.color = color;
				}
			}
		}
	}
	else
	{
		if (blammedLightsBlack.alpha != 0)
		{
			if (blammedLightsBlackTween != null)
				blammedLightsBlackTween.cancel();

			blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 0}, 1, {
				ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
				{
					blammedLightsBlackTween = null;
				}
			});
		}

		if (phillyWindow.alpha != 0)
		{
			if (phillyWindowTween != null)
				phillyWindowTween.cancel();

			phillyWindowTween = FlxTween.tween(phillyWindow, {alpha: 0}, 1, {
				ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
				{
					phillyWindowTween = null;
					resetWindowLayer();
					phillyWindow.visible = true;
					phillyWindow.alpha = 1;
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
					phillyWindow.color = phillyLightsColors[curLight];
				}
			});
		}

		for (char in getChars())
			if (char != null)
				tweenCharColor(char, char.color, FlxColor.WHITE);

		curLight = 0;
		curLightEvent = 0;
	}
}

function tweenCharColor(char:Character, from:Int, to:Int)
{
	if (char == null)
		return;

	if (char.colorTween != null)
		char.colorTween.cancel();

	char.colorTween = FlxTween.color(char, 1, from, to, {
		onComplete: function(twn:FlxTween)
		{
			char.colorTween = null;
		},
		ease: FlxEase.quadInOut
	});
}

function resetWindowLayer()
{
	remove(phillyWindow);
	var trainIndex:Int = game.members.indexOf(phillyTrain);
	if (trainIndex > 0)
		insert(trainIndex - 1, phillyWindow);
	else
		add(phillyWindow);
}

function doFlash()
{
	var color:Int = FlxColor.WHITE;
	if (!ClientPrefs.data.flashing)
		color = ColorUtil.withAlpha(color, 0.5);

	FlxG.camera.flash(color, 0.15, null, true);
}
