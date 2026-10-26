// Weekend 1 - Blazin
import objects.BGSprite;
import objects.Note;
import shaders.RainShader;
import flixel.addons.display.FlxTiledSprite;
import states.stages.objects.ABotSpeaker;
import states.stages.objects.PicoBlazinHandler;
import states.stages.objects.DarnellBlazinHandler;

var rainShader:RainShader;
var rainTimeScale:Float = 1;

var scrollingSky:FlxTiledSprite;
var skyAdditive:BGSprite;
var lightning:BGSprite;
var foregroundMultiply:BGSprite;
var additionalLighten:FlxSprite;

var lightningTimer:Float = 3.0;
var LIGHTNING_FULL_DURATION:Float = 1.5;
var LIGHTNING_FADE_DURATION:Float = 0.3;

var abot:ABotSpeaker;

var picoFight:PicoBlazinHandler = new PicoBlazinHandler();
var darnellFight:DarnellBlazinHandler = new DarnellBlazinHandler();

function isBlank(value:String):Bool
	return value == null || StringTools.trim(value).length < 1;

function setupScale(spr:BGSprite)
{
	spr.scale.set(1.75, 1.75);
	spr.updateHitbox();
}

function create()
{
	StickerSubState.STICKER_SET = 'sticker-set-2';
	StickerSubState.STICKER_PACK = 'weekend';

	FlxTransitionableState.skipNextTransOut = true;

	var path:String = 'stages/phillyStreets/phillyBlazin/';

	if (!ClientPrefs.data.lowQuality)
	{
		var skyImage = Paths.image(path + 'skyBlur');
		scrollingSky = new FlxTiledSprite(skyImage, Std.int(skyImage.width * 1.1) + 475, Std.int(skyImage.height / 1.1), true, false);
		scrollingSky.antialiasing = ClientPrefs.data.globalAntialiasing;
		scrollingSky.setPosition(-500, -120);
		scrollingSky.scrollFactor.set();
		add(scrollingSky);

		skyAdditive = new BGSprite(path + 'skyBlur', -600, -175, 0.0, 0.0);
		setupScale(skyAdditive);
		skyAdditive.visible = false;
		add(skyAdditive);

		lightning = new BGSprite(path + 'lightning', -50, -300, 0.0, 0.0, ['lightning0'], false);
		setupScale(lightning);
		lightning.visible = false;
		add(lightning);
	}

	var phillyForegroundCity:BGSprite = new BGSprite(path + 'streetBlur', -600, -175, 0.0, 0.0);
	setupScale(phillyForegroundCity);
	add(phillyForegroundCity);

	if (!ClientPrefs.data.lowQuality)
	{
		foregroundMultiply = new BGSprite(path + 'streetBlur', -600, -175, 0.0, 0.0);
		setupScale(foregroundMultiply);
		foregroundMultiply.blend = BlendMode.MULTIPLY;
		foregroundMultiply.visible = false;
		add(foregroundMultiply);

		additionalLighten = new FlxSprite(-600, -175).makeGraphic(1, 1, FlxColor.WHITE);
		additionalLighten.scrollFactor.set();
		additionalLighten.scale.set(2500, 2500);
		additionalLighten.updateHitbox();
		additionalLighten.blend = BlendMode.ADD;
		additionalLighten.visible = false;
		add(additionalLighten);
	}

	abot = new ABotSpeaker(game.gfGroup.x, game.gfGroup.y + 550);
	add(abot);

	if (ClientPrefs.data.shaders)
		setupRainShader();

	var song = PlayState.SONG;
	if (isBlank(song.gameOverSound))
		game.deathSoundName = 'fnf_loss_sfx-pico-gutpunch';
	if (isBlank(song.gameOverLoop))
		game.loopSoundName = 'gameOver-pico';
	if (isBlank(song.gameOverEnd))
		game.endSoundName = 'gameOverEnd-pico';
	if (isBlank(song.gameOverChar))
		game.characterName = 'pico-blazin';
	game.deathDelay = 0.15;

	stage.setDefaultGF('nene');

	for (i in 1...4)
		Paths.sound('lightning/Lightning' + i);

	if (PlayState.isStoryMode && game.songName == 'blazin')
	{
		stage.setEndCallback(function()
		{
			game.endingSong = true;
			game.inCutscene = true;
			game.canPause = false;
			FlxTransitionableState.skipNextTransIn = true;
			FlxG.camera.visible = false;
			game.camHUD.visible = false;
			game.startVideo('blazinCutscene');
		});
	}
}

function onCreatePost()
{
	FlxG.camera.focusOn(game.camFollow);
	FlxG.camera.fade(FlxColor.BLACK, 1.5, true, null, true);

	for (character in game.boyfriendGroup.members)
		if (character != null)
			character.color = 0xFFDEDEDE;
	for (character in game.dadGroup.members)
		if (character != null)
			character.color = 0xFFDEDEDE;
	for (character in game.gfGroup.members)
		if (character != null)
			character.color = 0xFF888888;
	abot.color = 0xFF888888;

	for (note in game.unspawnNotes)
	{
		if (note == null)
			continue;
		note.noAnimation = true;
		note.noMissAnimation = true;
	}

	remove(game.dadGroup, true);
	stage.addBehindBF(game.dadGroup);
}

function onSongStart()
{
	abot.snd = FlxG.sound.music;
}

function setupRainShader()
{
	rainShader = new RainShader();
	rainShader.scale = FlxG.height / 200;
	rainShader.intensity = 0.5;
	FlxG.camera.filters = [new ShaderFilter(rainShader)];
}

function onUpdate(elapsed:Float)
{
	if (scrollingSky != null)
		scrollingSky.scrollX -= elapsed * 35;

	if (rainShader != null)
	{
		rainShader.updateViewInfo(FlxG.width, FlxG.height, FlxG.camera);
		rainShader.update(elapsed * rainTimeScale);
		rainTimeScale = FlxMath.lerp(0.02, Math.min(1, rainTimeScale), Math.exp(-elapsed / (1 / 3)));
	}

	lightningTimer -= elapsed;
	if (lightningTimer <= 0)
	{
		applyLightning();
		lightningTimer = FlxG.random.float(7, 15);
	}
}

function applyLightning()
{
	if (ClientPrefs.data.lowQuality || game.endingSong)
		return;

	skyAdditive.visible = true;
	skyAdditive.alpha = 0.7;
	FlxTween.tween(skyAdditive, {alpha: 0.0}, LIGHTNING_FULL_DURATION, {
		onComplete: function(twn:FlxTween)
		{
			skyAdditive.visible = false;
			lightning.visible = false;
			foregroundMultiply.visible = false;
			additionalLighten.visible = false;
		}
	});

	foregroundMultiply.visible = true;
	foregroundMultiply.alpha = 0.64;
	FlxTween.tween(foregroundMultiply, {alpha: 0.0}, LIGHTNING_FULL_DURATION);

	additionalLighten.visible = true;
	additionalLighten.alpha = 0.3;
	FlxTween.tween(additionalLighten, {alpha: 0.0}, LIGHTNING_FADE_DURATION);

	lightning.visible = true;
	lightning.animation.play('lightning0', true);

	if (FlxG.random.bool(65))
		lightning.x = FlxG.random.int(-250, 280);
	else
		lightning.x = FlxG.random.int(780, 900);

	FlxTween.color(game.boyfriend, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFFDEDEDE);
	FlxTween.color(game.dad, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFFDEDEDE);
	if (game.gf != null)
		FlxTween.color(game.gf, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFF888888);
	FlxTween.color(abot, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFF888888);

	FlxG.sound.play(Paths.soundRandom('lightning/Lightning', 1, 3));
}

function onNoteHit(note:Note)
{
	rainTimeScale += 0.7;
	picoFight.noteHit(note);
	darnellFight.noteHit(note);
}

function onNoteMiss(note:Note)
{
	picoFight.noteMiss(note);
	darnellFight.noteMiss(note);
}

function noteMissPress(direction:Int)
{
	picoFight.noteMissPress(direction);
	darnellFight.noteMissPress(direction);
}

function onOpponentNoteHit(note:Note)
{
	picoFight.noteMiss(note);
	darnellFight.noteMiss(note);
}
