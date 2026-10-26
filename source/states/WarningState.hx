package states;

import backend.AutoUpdater;

class WarningState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warnText:FlxText;
	var warnType:String = 'flashing';
	var warning:String = 'placeholder string!!!';

	public function new(warnType:String = 'flashing')
	{
		super();
		this.warnType = warnType;
	}

	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.screenCenter();
		bg.color = FlxColor.GRAY;
		bg.alpha = 0.6;
		add(bg);

		switch (warnType)
		{
			case 'flashing':
				warning = "WARNING!\n\n" + "This mod contains some flashing lights!\n" + "Would you like to keep them on anyways?\n\n"
					+ "ENTER - Yes | ESCAPE - No\n" + "(You can change this later in the options menu!)";
			case 'outdated':
				warning = 'HEY YOU!\n\n'
					+ 'You\'re running an outdated version of Synapse Engine!\n'
					+ 'The current version is v${Constants.SYNAPSE_ENGINE_VERSION},\n'
					+ 'while the most recent version is ${AutoUpdater.latestVersion}!\n'
					+ 'It\'s highly recommended you update the game, but that\'s your choice!\n\n'
					+ (AutoUpdater.canAutoInstall() ? 'ENTER - Download Update' : 'ENTER - Go to GitHub')
					+ ' | ESCAPE - Continue';
		}

		warnText = new FlxText(0, 0, 0, warning, 32);
		warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter();
		add(warnText);
	}

	var updating:Bool = false;
	var restarting:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (updating)
		{
			updateDownloadProgress();
			return;
		}

		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			warningCallback(warnType);
		}
	}

	function warningCallback(type:String = 'flashing')
	{
		switch (type)
		{
			case 'flashing':
				var accept:Bool = FlxG.keys.justPressed.ENTER;
				var back:Bool = FlxG.keys.justPressed.ESCAPE;
				if (back || accept)
				{
					var sound:String = accept ? 'confirmMenu' : 'cancelMenu';
					FlxG.sound.play(Paths.sound(sound));

					if (back)
					{
						ClientPrefs.data.flashing = false;
						ClientPrefs.saveSettings();
					}

					FlxTween.tween(warnText, {alpha: 0}, 1, {
						onComplete: function(twn:FlxTween)
						{
							continueToGame();
						}
					});
				}
			case 'outdated':
				leftState = true;
				if (FlxG.keys.justPressed.ESCAPE)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					FlxTween.tween(warnText, {alpha: 0}, 1, {
						onComplete: function(twn:FlxTween)
						{
							continueToGame();
						}
					});
				}
				else if (FlxG.keys.justPressed.ENTER)
				{
					FlxG.sound.play(Paths.sound('confirmMenu'));
					if (AutoUpdater.canAutoInstall())
					{
						updating = true;
						setWarnText('DOWNLOADING UPDATE...\n\nPlease don\'t close the game.');
					}
					AutoUpdater.downloadUpdate();
				}
		}
	}

	function updateDownloadProgress()
	{
		switch (AutoUpdater.status)
		{
			case Downloading:
				setWarnText('DOWNLOADING UPDATE...\n\nPlease don\'t close the game.');
			case Installing:
				setWarnText('INSTALLING UPDATE...\n\nPlease don\'t close the game.');
			case ReadyToRestart:
				if (!restarting)
				{
					restarting = true;
					setWarnText('UPDATE INSTALLED!\n\nRestarting...');
					new FlxTimer().start(1, function(_) AutoUpdater.restart());
				}
			case Failed(reason):
				setWarnText('UPDATE FAILED\n\n$reason\n\nYou can download it manually from GitHub.\n\nENTER - Go to GitHub | ESCAPE - Continue');
				if (FlxG.keys.justPressed.ENTER)
					FlxG.openURL(AutoUpdater.releaseUrl);
				else if (FlxG.keys.justPressed.ESCAPE)
				{
					updating = false;
					FlxG.sound.play(Paths.sound('cancelMenu'));
					continueToGame();
				}
			default:
		}
	}

	function setWarnText(text:String)
	{
		if (warnText.text == text)
			return;
		warnText.text = text;
		warnText.screenCenter();
	}

	function continueToGame()
	{
		if (AutoUpdater.mustUpdate && !WarningState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.switchState(new WarningState('outdated'));
		}
		else
		{
			leftState = true;
			MusicBeatState.switchState(new ScriptedState('TitleState', []));
		}
	}
}
