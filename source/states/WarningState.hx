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

        switch (warnType)
        {
            case 'flashing':
                warning = "WARNING!\n" +
			        "This mod contains some flashing lights!\n" +
			        "Would you like to keep them on anyways?\n" +
			        "ENTER - Yes | ESCAPE - No\n" +
			        "(You can change this later in the options menu!)";
            case 'outdated':
                warning = "HEY YOU!\n" +
                    "You're running an outdated version of Synapse Engine!\n" +
                    "The current version is v" + Constants.SYNAPSE_ENGINE_VERSION + ",\n" +
                    "while the most recent version is" + AutoUpdater.latestVersion + "!\n" +
                    "It's highly recommended you update the game, but that's your choice!\n" +
                    "ENTER - Download Update | ESCAPE - Continue";
        }

        warnText = new FlxText(0, 0, 0, warning, 32);
		warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter();
		add(warnText);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

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
			    if (FlxG.keys.justPressed.ESCAPE || accept)
                {
				    FlxG.sound.play(Paths.sound('cancelMenu'));
				    FlxTween.tween(warnText, {alpha: 0}, 1, 
                    {
					    onComplete: function(twn:FlxTween)
                        {
						    continueToGame();
					    }
				    });

				    if (!accept)
                    {
					    ClientPrefs.data.flashing = false;
					    ClientPrefs.saveSettings();
				    }
			    }
            case 'outdated':
			    if (FlxG.keys.justPressed.ESCAPE)
                {
				    leftState = true;
				    FlxG.sound.play(Paths.sound('cancelMenu'));
				    FlxTween.tween(warnText, {alpha: 0}, 1, 
                    {
					    onComplete: function(twn:FlxTween)
                        {
						    continueToGame();
					    }
				    });
			    }
                else if (FlxG.keys.justPressed.ENTER)
                {
				    leftState = true;
				    FlxG.sound.play(Paths.sound('confirmMenu'));
				    AutoUpdater.downloadUpdate();
			    }
        }
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