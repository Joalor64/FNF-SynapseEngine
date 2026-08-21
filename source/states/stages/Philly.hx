package states.stages;

import states.stages.objects.*;
import objects.Character;

class Philly extends BaseStage
{
	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:PhillyTrain;
	var curLight:Int = -1;

	var blammedLightsBlack:FlxSprite;
	var phillyGlowGradient:PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlowParticle>;
	var curLightEvent:Int = -1;

	var blammedLightsBlackTween:FlxTween;
	var phillyWindowTween:FlxTween;

	override function create()
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

		phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];

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

		blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5);
		blammedLightsBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		blammedLightsBlack.alpha = 0;
		blammedLightsBlack.scrollFactor.set();
		insert(members.indexOf(phillyStreet), blammedLightsBlack);
	}

	override function eventPushed(event:Note.EventNote)
	{
		switch (event.event)
		{
			case "Philly Glow":
				if (blammedLightsBlack == null)
				{
					blammedLightsBlack = new FlxSprite(FlxG.width * -0.5,
						FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					blammedLightsBlack.visible = false;
					insert(members.indexOf(phillyStreet), blammedLightsBlack);
				}

				phillyGlowGradient = new PhillyGlowGradient(-400, 225);
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				if (!ClientPrefs.data.flashing)
					phillyGlowGradient.intendedAlpha = 0.7;

				Paths.image('stages/philly/particle');
				phillyGlowParticles = new FlxTypedGroup<PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);

			case "Blammed Lights":
				if (blammedLightsBlack == null)
				{
					blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5);
					blammedLightsBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					blammedLightsBlack.alpha = 0;
					blammedLightsBlack.scrollFactor.set();
					insert(members.indexOf(phillyStreet), blammedLightsBlack);
				}
		}
	}

	override function update(elapsed:Float)
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

	override function beatHit()
	{
		phillyTrain.beatHit(curBeat);

		if (curBeat % 4 == 0 && curLightEvent <= 0)
		{
			curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
			phillyWindow.color = phillyLightsColors[curLight];
			phillyWindow.alpha = 1;
		}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch (eventName)
		{
			case "Philly Glow":
				if (flValue1 == null || flValue1 <= 0)
					flValue1 = 0;

				var lightId:Int = Math.round(flValue1);

				var chars:Array<Character> = [boyfriend, gf, dad];
				switch (lightId)
				{
					case 0:
						if (phillyGlowGradient.visible)
						{
							doFlash();
							if (ClientPrefs.data.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
							curLightEvent = -1;

							for (who in chars)
							{
								who.color = FlxColor.WHITE;
							}
							phillyStreet.color = FlxColor.WHITE;

							resetWindowLayer();
							phillyWindow.visible = true;
							phillyWindow.alpha = 1;
							curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
							phillyWindow.color = phillyLightsColors[curLight];
						}

					case 1:
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length - 1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						remove(phillyWindow);
						var particleIndex:Int = members.indexOf(phillyGlowParticles);
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
								camHUD.zoom += 0.1;
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
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;
						if (!ClientPrefs.data.flashing)
							charColor.saturation *= 0.5;
						else
							charColor.saturation *= 0.75;

						for (who in chars)
						{
							who.color = charColor;
						}
						phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle)
						{
							particle.color = color;
						});
						phillyGlowGradient.color = color;
						phillyWindow.color = color;

						color.brightness *= 0.5;
						phillyStreet.color = color;

					case 2:
						if (!ClientPrefs.data.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];
							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlowParticle = new PhillyGlowParticle(-400
										+ width * i
										+ FlxG.random.float(-width / 5, width / 5),
										phillyGlowGradient.originalY
										+ 200
										+ (FlxG.random.float(0, 125) + j * 40), color);
									phillyGlowParticles.add(particle);
								}
							}
						}
						phillyGlowGradient.bop();
				}

			case "Blammed Lights":
				var lightId:Int = Std.parseInt(value1);
				if (Math.isNaN(lightId))
					lightId = 0;

				var chars:Array<Character> = [boyfriend, gf, dad];
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
					var blackIndex:Int = members.indexOf(blammedLightsBlack);
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

						for (char in chars)
						{
							if (char != null)
							{
								if (char.colorTween != null)
									char.colorTween.cancel();

								char.colorTween = FlxTween.color(char, 1, FlxColor.WHITE, color, {
									onComplete: function(twn:FlxTween)
									{
										char.colorTween = null;
									},
									ease: FlxEase.quadInOut
								});
							}
						}
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

						for (char in chars)
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

					for (char in chars)
					{
						if (char != null)
						{
							if (char.colorTween != null)
								char.colorTween.cancel();

							char.colorTween = FlxTween.color(char, 1, char.color, FlxColor.WHITE, {
								onComplete: function(twn:FlxTween)
								{
									char.colorTween = null;
								},
								ease: FlxEase.quadInOut
							});
						}
					}

					curLight = 0;
					curLightEvent = 0;
				}
		}
	}

	function resetWindowLayer()
	{
		remove(phillyWindow);
		var trainIndex:Int = members.indexOf(phillyTrain);
		if (trainIndex > 0)
			insert(trainIndex - 1, phillyWindow);
		else
			add(phillyWindow);
	}

	function doFlash()
	{
		var color:FlxColor = FlxColor.WHITE;
		if (!ClientPrefs.data.flashing)
			color.alphaFloat = 0.5;

		FlxG.camera.flash(color, 0.15, null, true);
	}
}
