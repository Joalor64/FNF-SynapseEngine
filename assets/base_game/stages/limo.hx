// Week 4 - Satin Panties, High, M.I.L.F
import objects.BGSprite;
import states.stages.objects.BackgroundDancer;

var grpLimoDancers:FlxTypedGroup;
var fastCar:BGSprite;
var fastCarCanDrive:Bool = true;
var carTimer:FlxTimer;

var limoKillingState:String = 'wait';
var limoMetalPole:BGSprite;
var limoLight:BGSprite;
var limoCorpse:BGSprite;
var limoCorpseTwo:BGSprite;
var bgLimo:BGSprite;
var grpLimoParticles:FlxTypedGroup;
var dancersDiff:Float = 320;
var limoSpeed:Float = 0;

function create()
{
	var skyBG:BGSprite = new BGSprite('stages/limo/limoSunset', -120, -50, 0.1, 0.1);
	add(skyBG);

	if (!ClientPrefs.data.lowQuality)
	{
		limoMetalPole = new BGSprite('stages/limo/gore/metalPole', -500, 220, 0.4, 0.4);
		add(limoMetalPole);

		bgLimo = new BGSprite('stages/limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
		add(bgLimo);

		limoCorpse = new BGSprite('stages/limo/gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
		add(limoCorpse);

		limoCorpseTwo = new BGSprite('stages/limo/gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
		add(limoCorpseTwo);

		grpLimoDancers = new FlxTypedGroup();
		add(grpLimoDancers);

		for (i in 0...5)
		{
			var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + dancersDiff + bgLimo.x, bgLimo.y - 400);
			dancer.scrollFactor.set(0.4, 0.4);
			grpLimoDancers.add(dancer);
		}

		limoLight = new BGSprite('stages/limo/gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
		add(limoLight);

		grpLimoParticles = new FlxTypedGroup();
		add(grpLimoParticles);

		// PRECACHE BLOOD
		var particle:BGSprite = new BGSprite('stages/limo/gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
		particle.alpha = 0.01;
		grpLimoParticles.add(particle);
		resetLimoKill();

		// PRECACHE SOUND
		Paths.sound('dancerdeath');
	}

	stage.setDefaultGF('gf-car');

	fastCar = new BGSprite('stages/limo/fastCarLol', -300, 160);
	fastCar.active = true;
}

function onCreatePost()
{
	resetFastCar();
	stage.addBehindGF(fastCar);

	var limo:BGSprite = new BGSprite('stages/limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);
	stage.addBehindGF(limo); // Shitty layering but whatev it works LOL
}

function onUpdate(elapsed:Float)
{
	if (ClientPrefs.data.lowQuality)
		return;

	grpLimoParticles.forEach(function(spr:BGSprite)
	{
		if (spr.animation != null && spr.animation.curAnim != null && spr.animation.curAnim.finished)
		{
			spr.kill();
			grpLimoParticles.remove(spr, true);
			spr.destroy();
		}
	});

	switch (limoKillingState)
	{
		case 'killing':
			limoMetalPole.x += 5000 * elapsed;
			limoLight.x = limoMetalPole.x - 180;
			limoCorpse.x = limoLight.x - 50;
			limoCorpseTwo.x = limoLight.x + 35;

			var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
			for (i in 0...dancers.length)
			{
				if (dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170)
				{
					switch (i)
					{
						case 0, 3:
							if (i == 0)
								FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

							var diffStr:String = i == 3 ? ' 2 ' : ' ';
							grpLimoParticles.add(new BGSprite('stages/limo/gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4,
								['hench leg spin' + diffStr + 'PINK'], false));
							grpLimoParticles.add(new BGSprite('stages/limo/gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4,
								['hench arm spin' + diffStr + 'PINK'], false));
							grpLimoParticles.add(new BGSprite('stages/limo/gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4,
								['hench head spin' + diffStr + 'PINK'], false));

							var blood:BGSprite = new BGSprite('stages/limo/gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
							blood.flipX = true;
							blood.angle = -57.5;
							grpLimoParticles.add(blood);
						case 1:
							limoCorpse.visible = true;
						case 2:
							limoCorpseTwo.visible = true;
					} // Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
					dancers[i].x += FlxG.width * 2;
				}
			}

			if (limoMetalPole.x > FlxG.width * 2)
			{
				resetLimoKill();
				limoSpeed = 800;
				limoKillingState = 'speedingOffscreen';
			}

		case 'speedingOffscreen':
			limoSpeed -= 4000 * elapsed;
			bgLimo.x -= limoSpeed * elapsed;
			if (bgLimo.x > FlxG.width * 1.5)
			{
				limoSpeed = 3000;
				limoKillingState = 'speeding';
			}

		case 'speeding':
			limoSpeed -= 2000 * elapsed;
			if (limoSpeed < 1000)
				limoSpeed = 1000;

			bgLimo.x -= limoSpeed * elapsed;
			if (bgLimo.x < -275)
			{
				limoKillingState = 'stopping';
				limoSpeed = 800;
			}
			dancersParenting();

		case 'stopping':
			bgLimo.x = FlxMath.lerp(-150, bgLimo.x, Math.exp(-elapsed * 9));
			if (Math.round(bgLimo.x) == -150)
			{
				bgLimo.x = -150;
				limoKillingState = 'wait';
			}
			dancersParenting();
	}
}

function onBeatHit(curBeat:Int)
{
	if (!ClientPrefs.data.lowQuality)
	{
		grpLimoDancers.forEach(function(dancer:BackgroundDancer)
		{
			dancer.dance();
		});
	}

	if (FlxG.random.bool(10) && fastCarCanDrive)
		fastCarDrive();
}

function onOpenSubState(substate)
{
	if (game.paused && carTimer != null)
		carTimer.active = false;
}

function onCloseSubState()
{
	if (game.paused && carTimer != null)
		carTimer.active = true;
}

function onEvent(name:String, value1:String, value2:String, strumTime:Float)
{
	switch (name)
	{
		case 'Kill Henchmen':
			killHenchmen();
	}
}

function dancersParenting()
{
	var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
	for (i in 0...dancers.length)
		dancers[i].x = (370 * i) + dancersDiff + bgLimo.x;
}

function resetLimoKill()
{
	limoMetalPole.x = -500;
	limoMetalPole.visible = false;
	limoLight.x = -500;
	limoLight.visible = false;
	limoCorpse.x = -500;
	limoCorpse.visible = false;
	limoCorpseTwo.x = -500;
	limoCorpseTwo.visible = false;
}

function resetFastCar()
{
	fastCar.x = -12600;
	fastCar.y = FlxG.random.int(140, 250);
	fastCar.velocity.x = 0;
	fastCarCanDrive = true;
}

function fastCarDrive()
{
	FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

	fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
	fastCarCanDrive = false;
	carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
	{
		resetFastCar();
		carTimer = null;
	});
}

function killHenchmen()
{
	if (ClientPrefs.data.lowQuality || limoKillingState != 'wait')
		return;

	limoMetalPole.x = -400;
	limoMetalPole.visible = true;
	limoLight.visible = true;
	limoCorpse.visible = false;
	limoCorpseTwo.visible = false;
	limoKillingState = 'killing';

	#if ACHIEVEMENTS_ALLOWED
	var kills = Achievements.addScore('roadkill_enthusiast');
	trace('Henchmen kills: ' + kills);
	#end
}
