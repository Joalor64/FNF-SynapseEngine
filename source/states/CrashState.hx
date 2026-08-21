package states;

import flixel.util.FlxGradient;

// this code is from doido engine, credits to them!
class CrashState extends MusicBeatState
{
	var errorMsg:String = "";

	public function new(errorMsg:String)
	{
		super();
		this.errorMsg = errorMsg;
	}

	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuInvert'));
		bg.screenCenter();
		add(bg);

		var gradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFF3F1717, 0xFFB24D4D]);
		gradient.blend = ADD;
		add(gradient);

		var titleTxt:FlxText = new FlxText(0, 40, 0, "GAME CRASH");
		titleTxt.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.RED, CENTER);
		titleTxt.screenCenter(X);
		add(titleTxt);

		var errorTxt:FlxText = new FlxText(24, titleTxt.y + titleTxt.height + 16, FlxG.width - 24, errorMsg);
		errorTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		add(errorTxt);

		var infoTxt:FlxText = new FlxText(24, 0, 'Press ESCAPE to quit\nPress ENTER to report this issue');
		infoTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, RIGHT);
		infoTxt.x = FlxG.width - infoTxt.width - 16;
		infoTxt.y = FlxG.height - infoTxt.height - 16;
		add(infoTxt);

		FlxG.sound.play(Paths.sound('crash'));
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
			Sys.exit(0);

		if (FlxG.keys.justPressed.ENTER)
			FlxG.openURL('https://github.com/Joalor64/FNF-SynapseEngine/issues');
	}
}
