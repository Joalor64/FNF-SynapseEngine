package substates;

import haxe.Exception;

class FreeplayErrorSubState extends MusicBeatSubstate
{
	var missingTextBG:FlxSprite;
	var missingText:FlxText;
	var errorStr:String;

	public var onClose:Void->Void;

	public function new(lowercaseSong:String, error:Exception)
	{
		super();
		errorStr = error.message;
		if (errorStr.contains('There is no TEXT asset with an ID of'))
			errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(lowercaseSong)); // Missing chart
		else
			errorStr += '\n\n' + error.stack;
	}

	override function create()
	{
		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		add(missingText);

		missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
		missingText.screenCenter(Y);
		missingText.visible = true;
		missingTextBG.visible = true;

		super.create();
		FlxG.sound.play(Paths.sound('cancelMenu'));
	}

	override function update(elapsed:Float)
	{
		if (controls.BACK)
		{
			if (onClose != null)
				onClose();
			close();
		}
	}
}
