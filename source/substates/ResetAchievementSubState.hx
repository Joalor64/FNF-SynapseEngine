package substates;

#if ACHIEVEMENTS_ALLOWED
class ResetAchievementSubState extends MusicBeatSubstate
{
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;

	var option:Dynamic;
	var curSelected:Int;

	public function new(option:Dynamic, curSelected:Int)
	{
		super();

		this.option = option;
		this.curSelected = curSelected;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		var text:Alphabet = new Alphabet(0, 180, 'Reset Achievement:', true);
		text.screenCenter(X);
		text.scrollFactor.set();
		add(text);

		var text:FlxText = new FlxText(50, text.y + 90, FlxG.width - 100, option.displayName, 40);
		text.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.scrollFactor.set();
		text.borderSize = 2;
		add(text);

		yesText = new Alphabet(0, text.y + 120, 'Yes', true);
		yesText.screenCenter(X);
		yesText.x -= 200;
		yesText.scrollFactor.set();
		for (letter in yesText.letters)
			letter.color = FlxColor.RED;
		add(yesText);
		noText = new Alphabet(0, text.y + 120, 'No', true);
		noText.screenCenter(X);
		noText.x += 200;
		noText.scrollFactor.set();
		add(noText);
		updateOptions();
	}

	override function update(elapsed:Float)
	{
		if (controls.BACK)
		{
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}

		super.update(elapsed);

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			onYes = !onYes;
			updateOptions();
		}

		if (controls.ACCEPT)
		{
			if (onYes)
			{
				Achievements.variables.remove(option.name);
				Achievements.achievementsUnlocked.remove(option.name);
				option.unlocked = false;
				option.curProgress = 0;
				option.displayName = '???';

				var scriptedState = cast(FlxG.state, ScriptedState);
				scriptedState.scriptExecute('onAchievementReset', [option, curSelected]);

				Achievements.save();
				FlxG.save.flush();

				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			close();
			return;
		}
	}

	function updateOptions()
	{
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}
#end
