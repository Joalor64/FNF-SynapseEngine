package objects;

import shaders.RGBPalette;
import flixel.math.FlxRect;
import backend.animation.PsychAnimationController;

typedef EventNote =
{
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

class Note extends FlxSprite
{
	public var extraData:Map<String, Dynamic> = [];

	public var strumTime:Float = 0;
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var isSustainEnd:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBPalette;

	public static var globalRgbShaders:Array<RGBPalette> = [];

	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 0.5;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var swagWidth:Float = 160 * 0.7;

	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; // 9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; // plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;

	@:isVar
	public var canBeHit(get, default):Bool = false;

	inline public function get_canBeHit()
	{
		return (mustPress) ? strumTime > Conductor.songPosition - Conductor.safeZoneOffset * lateHitMult
			&& strumTime < Conductor.songPosition
			+ Conductor.safeZoneOffset * earlyHitMult : false;
	}

	// a thing for modders
	public var killNote:Bool = false;

	private function set_multSpeed(value:Float):Float
	{
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		return value;
	}

	public function resizeByRatio(ratio:Float) // haha funny twitter shit
	{
		if (isSustainNote && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			reloadNote(value);
		}
		texture = value;
		return value;
	}

	private function set_noteType(value:String):String
	{
		if (PlayState.SONG != null)
			noteSplashTexture = PlayState.SONG.splashSkin;

		updateColours();

		if (noteData > -1 && noteType != value)
		{
			switch (value)
			{
				case 'Hurt Note':
					ignoreNote = mustPress;
					reloadNote('HURT');
					noteSplashTexture = 'HURTnoteSplashes';
					rgbShader.enabled = false;
					lowPriority = true;
					missHealth = isSustainNote ? 0.25 : 0.1;
					hitCausesMiss = true;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			noteType = value;
		}
		return value;
	}

	var noteColor:Array<Array<FlxColor>> = PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel : ClientPrefs.data.arrowRGB;

	public function updateColours()
	{
		var colorArray:Array<FlxColor> = noteColor[noteData % colArray.length];
    	rgbShader.r = colorArray[0];
    	rgbShader.g = colorArray[1];  
    	rgbShader.b = colorArray[2];
	}

	public static function initializeGlobalRGBShader(idx:Int, aQuant:Bool)
	{
		if (globalRgbShaders[idx] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			globalRgbShaders[idx] = newRGB;

			var arr:Array<FlxColor> = (PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel : ClientPrefs.data.arrowRGB)[idx];
			newRGB.r = arr[0];
			newRGB.g = arr[1];
			newRGB.b = arr[2];
		}
		return globalRgbShaders[idx];
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false)
	{
		super();

		animation = new PsychAnimationController(this);

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if (!inEditor)
			this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		if (noteData > -1)
		{
			texture = '';
			rgbShader = new RGBPalette();
			shader = rgbShader.shader;

			x += swagWidth * (noteData);
			if (!isSustainNote && noteData < colArray.length)
			{ // Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = colArray[noteData % colArray.length];
				animation.play(animToPlay + 'Scroll');
			}
		}

		if (prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if (ClientPrefs.data.downScroll)
				flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % colArray.length] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % colArray.length] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if (PlayState.instance != null)
				{
					prevNote.scale.y *= PlayState.instance.songSpeed;
				}

				if (PlayState.isPixelStage)
				{
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); // Auto adjust note size
				}
				prevNote.updateHitbox();
			}

			isSustainEnd = true;

			if (PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
		}
		else if (!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	var _lastNoteOffX:Float = 0;
	static var _lastValidChecked:String; // optimization
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; // dont mess with this
	public function reloadNote(texture:String = '', postfix:String = '')
	{
		for (e in [texture, postfix])
			if (e == null)
				e = '';

		var skin:String = texture + postfix;
		if (texture.length < 1)
		{
			skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			if (skin == null || skin.length < 1)
				skin = defaultNoteSkin + postfix;
		}

		var animName:String = null;
		if (animation.curAnim != null)
		{
			animName = animation.curAnim.name;
		}

		var skinPixel:String = skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = PlayState.isPixelStage ? 'pixelUI/' : '';
		if (customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png'))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else
			skinPostfix = '';

		if (PlayState.isPixelStage)
		{
			if (isSustainNote)
			{
				var graphic = Paths.image('pixelUI/' + skinPixel + 'ENDS' + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
				originalHeight = graphic.height / 2;
			}
			else
			{
				var graphic = Paths.image('pixelUI/' + skinPixel + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;

			if (isSustainNote)
			{
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= _lastNoteOffX;
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(skin);
			loadNoteAnims();

			if (isSustainNote)
    		{
        		offsetX += width / 2;
        		copyAngle = false;
    		}
			
			if (!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}
		if (isSustainNote)
		{
			scale.y = lastScaleY;

			if (!PlayState.isPixelStage)
    		{
        		offsetX -= width / 2;
    		}
		}
		updateHitbox();

		if (animName != null)
    	{
        	if (isSustainNote)
        	{
            	if (isSustainEnd)
                	animation.play(colArray[noteData % colArray.length] + 'holdend', true);
            	else
                	animation.play(colArray[noteData % colArray.length] + 'hold', true);
        	}
        	else
        	{
            	animation.play(animName, true);
        	}
    	}

		if (inEditor)
		{
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if (ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims()
	{
		if (isSustainNote)
		{
			attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some retarded typo from the original note .FLA
			animation.addByPrefix(colArray[noteData % colArray.length] + 'holdend', colArray[noteData % colArray.length] + ' hold end', 24, true);
			animation.addByPrefix(colArray[noteData % colArray.length] + 'hold', colArray[noteData % colArray.length] + ' hold piece', 24, true);
		}
		else
			animation.addByPrefix(colArray[noteData % colArray.length] + 'Scroll', colArray[noteData % colArray.length] + '0');

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims()
	{
		if (isSustainNote)
		{
			animation.add(colArray[noteData] + 'holdend', [noteData + 4], 24, true);
			animation.add(colArray[noteData] + 'hold', [noteData], 24, true);
		} 
		else
			animation.add(colArray[noteData] + 'Scroll', [noteData + 4], 24, true);
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if (animFrames.length < 1)
			return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (killNote)
			this.kill();

		if (mustPress && strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit && canBeHit)
			tooLate = true;

		if (!mustPress && strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
			if ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
				wasGoodHit = true;

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override public function destroy()
	{
		super.destroy();
		_lastValidChecked = '';
	}

	@:noCompletion override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}
