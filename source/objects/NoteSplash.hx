package objects;

import shaders.RGBPalette;
import flixel.system.FlxAssets.FlxShader;
import backend.animation.PsychAnimationController;
import flixel.graphics.frames.FlxFrame;
import haxe.Json;

typedef NoteSplashJsonAnim =
{
	name:String,
	noteData:Int,
	prefix:String,
	indices:Array<Int>,
	offsets:Array<Float>,
	fps:Array<Int>
}

typedef NoteSplashConfig =
{
	anim:String,
	minFps:Int,
	maxFps:Int,
	offsets:Array<Array<Float>>
}

class NoteSplash extends FlxSprite
{
	public var rgbShader:PixelSplashShaderRef;

	private var idleAnim:String;

	private var _textureLoaded:String = null;
	private var _configLoaded:String = null;
	private var _jsonAnims:Array<NoteSplashJsonAnim> = null;

	public static var defaultNoteSplash(default, never):String = 'noteSplashes/noteSplashes';
	public static var configs:Map<String, NoteSplashConfig> = new Map<String, NoteSplashConfig>();

	public var babyArrow:StrumNote;

	public var inEditor:Bool = false;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0, redColor:FlxColor = 0, greenColor:FlxColor = 0, blueColor:FlxColor = 0)
	{
		super(x, y);

		animation = new PsychAnimationController(this);

		var skin:String = null;
		if (PlayState.SONG != null && PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
			skin = PlayState.SONG.splashSkin;
		else
			skin = defaultNoteSplash + getSplashSkinPostfix();

		rgbShader = new PixelSplashShaderRef();
		rgbShader.enabled = true;

		precacheConfig(skin);
		_configLoaded = skin;
		scrollFactor.set();
	}

	override function destroy()
	{
		configs.clear();
		super.destroy();
	}

	var maxAnims:Int = 2;

	public function loadSplash(skin:String)
	{
		loadAnims(skin);
		_textureLoaded = skin;
	}

	public function setupNoteSplash(x:Float, y:Float, direction:Int = 0, ?note:Note = null, redColor:FlxColor = 0, greenColor:FlxColor = 0,
			blueColor:FlxColor = 0)
	{
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);

		aliveTime = 0;

		var texture:String = null;
		if (note != null && note.noteSplashData.texture != null)
			texture = note.noteSplashData.texture;
		else if (inEditor && _textureLoaded != null)
			texture = _textureLoaded;
		else if (PlayState.SONG != null && PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
			texture = PlayState.SONG.splashSkin;
		else
			texture = defaultNoteSplash + getSplashSkinPostfix();

		var config:NoteSplashConfig = null;
		if (_textureLoaded != texture)
			config = loadAnims(texture);
		else
			config = precacheConfig(_configLoaded);

		var tempShader:RGBPalette = null;
		if ((note == null || note.noteSplashData.useRGBShader) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB))
		{
			if (note != null && !note.noteSplashData.useGlobalShader)
			{
				rgbShader.r = (note.noteSplashData.r != -1) ? note.noteSplashData.r : redColor;
				rgbShader.g = (note.noteSplashData.g != -1) ? note.noteSplashData.g : greenColor;
				rgbShader.b = (note.noteSplashData.b != -1) ? note.noteSplashData.b : blueColor;
				shader = rgbShader.shader;
			}
			else
				tempShader = Note.globalRgbShaders[direction];
		}
		if (tempShader != null)
		{
			rgbShader.copyValues(tempShader);
			rgbShader.enabled = true;
			shader = rgbShader.shader;
		}

		alpha = ClientPrefs.data.splashAlpha;
		if (note != null)
			alpha = note.noteSplashData.a;

		antialiasing = ClientPrefs.data.globalAntialiasing;
		if (note != null)
			antialiasing = note.noteSplashData.antialiasing;
		if (PlayState.isPixelStage)
			antialiasing = false;

		_textureLoaded = texture;
		offset.set(10, 10);

		var animNum:Int = FlxG.random.int(1, maxAnims);
		animation.play('note' + direction + '-' + animNum, true);

		var minFps:Int = 22;
		var maxFps:Int = 26;
		if (_jsonAnims != null)
		{
			var jsonAnim:NoteSplashJsonAnim = _jsonAnims[(animNum - 1) * Note.colArray.length + direction];
			if (jsonAnim != null)
			{
				offset.x += jsonAnim.offsets[0];
				offset.y += jsonAnim.offsets[1];
				minFps = jsonAnim.fps[0];
				maxFps = jsonAnim.fps[1];
			}
		}
		else if (config != null)
		{
			var animID:Int = direction + ((animNum - 1) * Note.colArray.length);
			if (config.offsets.length > 0)
			{
				var offs:Array<Float> = config.offsets[FlxMath.wrap(animID, 0, config.offsets.length - 1)];
				offset.x += offs[0];
				offset.y += offs[1];
			}
			minFps = config.minFps;
			maxFps = config.maxFps;
		}
		else
		{
			offset.x += -58;
			offset.y += -55;
		}

		if (animation.curAnim != null)
			animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
	}

	public static function getSplashSkinPostfix()
	{
		var skin:String = '';
		if (ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin)
			skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadAnims(skin:String, ?animName:String = null):NoteSplashConfig
	{
		maxAnims = 0;
		_jsonAnims = null;
		frames = Paths.getSparrowAtlas(skin);
		var config:NoteSplashConfig = null;
		if (frames == null)
		{
			skin = defaultNoteSplash + getSplashSkinPostfix();
			frames = Paths.getSparrowAtlas(skin);
			if (frames == null) // if you really need this, you really fucked something up
			{
				skin = defaultNoteSplash;
				frames = Paths.getSparrowAtlas(skin);
			}
		}

		config = loadJsonAnims(skin);
		if (_jsonAnims != null)
		{
			_configLoaded = skin;
			return config;
		}

		config = precacheConfig(skin);
		_configLoaded = skin;

		if (animName == null)
			animName = config != null ? config.anim : 'note splash';

		while (true)
		{
			var animID:Int = maxAnims + 1;
			for (i in 0...Note.colArray.length)
			{
				if (!addAnimAndCheck('note$i-$animID', '$animName ${Note.colArray[i]} $animID', 24, false))
				{
					return config;
				}
			}
			maxAnims++;
		}
	}

	function loadJsonAnims(skin:String):NoteSplashConfig
	{
		var path:String = 'images/$skin.json';
		var jsonText:String = Paths.getTextFromFile(path);
		if (jsonText == null)
			return null;

		var raw:Dynamic = Json.parse(jsonText);
		if (raw == null || raw.animations == null)
			return null;

		var animations:Array<NoteSplashJsonAnim> = [];
		for (field in Reflect.fields(raw.animations))
		{
			var value:Dynamic = Reflect.field(raw.animations, field);
			if (value == null || value.prefix == null || value.noteData == null)
				continue;

			var noteData:Int = Std.int(value.noteData);
			if (noteData < 0)
				continue;

			var fps:Array<Int> = [22, 26];
			if (value.fps != null)
			{
				if (value.fps[0] != null) fps[0] = Std.int(value.fps[0]);
				if (value.fps[1] != null) fps[1] = Std.int(value.fps[1]);
			}

			var offsets:Array<Float> = [0, 0];
			if (value.offsets != null)
			{
				if (value.offsets[0] != null) offsets[0] = value.offsets[0];
				if (value.offsets[1] != null) offsets[1] = value.offsets[1];
			}

			var indices:Array<Int> = [];
			if (value.indices != null)
			{
				var rawIndices:Array<Dynamic> = cast value.indices;
				for (index in rawIndices)
					indices.push(Std.int(index));
			}

			var jsonAnim:NoteSplashJsonAnim = {
				name: value.name != null ? value.name : field,
				noteData: noteData,
				prefix: value.prefix,
				indices: indices,
				offsets: offsets,
				fps: fps
			};
			animations[noteData] = jsonAnim;
		}

		if (animations.length < 1)
			return null;

		_jsonAnims = [];
		for (noteData in 0...animations.length)
		{
			var jsonAnim:NoteSplashJsonAnim = animations[noteData];
			if (jsonAnim == null)
				continue;

			var direction:Int = noteData % Note.colArray.length;
			var animNum:Int = Std.int(noteData / Note.colArray.length) + 1;
			if (!addJsonAnimAndCheck('note$direction-$animNum', jsonAnim))
			{
				_jsonAnims = null;
				maxAnims = 0;
				return null;
			}
			_jsonAnims[noteData] = jsonAnim;
			if (direction == 0 && animNum > maxAnims)
				maxAnims = animNum;
		}

		return null;
	}

	function addJsonAnimAndCheck(name:String, anim:NoteSplashJsonAnim):Bool
	{
		var animFrames:Array<FlxFrame> = [];
		@:privateAccess
		animation.findByPrefix(animFrames, anim.prefix);
		if (animFrames.length < 1)
			return false;

		if (anim.indices != null && anim.indices.length > 0)
			animation.addByIndices(name, anim.prefix, anim.indices, '', anim.fps[1], false);
		else
			animation.addByPrefix(name, anim.prefix, anim.fps[1], false);
		return true;
	}

	public static function precacheConfig(skin:String)
	{
		if (configs.exists(skin))
			return configs.get(skin);

		var path:String = Paths.getPath('images/$skin.txt', true);
		var configFile:Array<String> = CoolUtil.coolTextFile(path);
		if (configFile.length < 1)
			return null;

		var framerates:Array<String> = configFile[1].split(' ');
		var offs:Array<Array<Float>> = [];
		for (i in 2...configFile.length)
		{
			var animOffs:Array<String> = configFile[i].split(' ');
			offs.push([Std.parseFloat(animOffs[0]), Std.parseFloat(animOffs[1])]);
		}

		var config:NoteSplashConfig = {
			anim: configFile[0],
			minFps: Std.parseInt(framerates[0]),
			maxFps: Std.parseInt(framerates[1]),
			offsets: offs
		};
		configs.set(skin, config);
		return config;
	}

	function addAnimAndCheck(name:String, anim:String, ?framerate:Int = 24, ?loop:Bool = false)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, anim); // adds valid frames to animFrames

		if (animFrames.length < 1)
			return false;

		animation.addByPrefix(name, anim, framerate, loop);
		return true;
	}

	static var aliveTime:Float = 0;
	static var buggedKillTime:Float = 0.5; // automatically kills note splashes if they break to prevent it from flooding your HUD

	override function update(elapsed:Float)
	{
		aliveTime += elapsed;
		if ((animation.curAnim != null && animation.curAnim.finished) || (animation.curAnim == null && aliveTime >= buggedKillTime))
			kill();

		super.update(elapsed);
	}
}

class PixelSplashShaderRef
{
	public var shader:PixelSplashShader = new PixelSplashShader();
	public var enabled(default, set):Bool = true;
	public var pixelAmount(default, set):Float = 1;
	public var r(default, set):FlxColor;
	public var g(default, set):FlxColor;
	public var b(default, set):FlxColor;

	private function set_r(color:FlxColor)
	{
		r = color;
		shader.r.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}

	private function set_g(color:FlxColor)
	{
		g = color;
		shader.g.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}

	private function set_b(color:FlxColor)
	{
		b = color;
		shader.b.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}

	public function copyValues(tempShader:RGBPalette)
	{
		if (tempShader != null)
		{
			for (i in 0...3)
			{
				shader.r.value[i] = tempShader.shader.r.value[i];
				shader.g.value[i] = tempShader.shader.g.value[i];
				shader.b.value[i] = tempShader.shader.b.value[i];
			}
			shader.mult.value[0] = tempShader.shader.mult.value[0];
		}
		else
			enabled = false;
	}

	public function set_enabled(value:Bool)
	{
		enabled = value;
		shader.mult.value = [value ? 1 : 0];
		return value;
	}

	public function set_pixelAmount(value:Float)
	{
		pixelAmount = value;
		shader.uBlocksize.value = [value, value];
		return value;
	}

	public function reset()
	{
		shader.r.value = [0, 0, 0];
		shader.g.value = [0, 0, 0];
		shader.b.value = [0, 0, 0];
	}

	public function new()
	{
		reset();
		enabled = true;

		if (!PlayState.isPixelStage)
			pixelAmount = 1;
		else
			pixelAmount = PlayState.daPixelZoom;
	}
}

class PixelSplashShader extends FlxShader
{
	@:glFragmentHeader('
		#pragma header

		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;
		uniform vec2 uBlocksize;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec2 blocks = openfl_TextureSize / uBlocksize;
			vec4 color = flixel_texture2D(bitmap, floor(coord * blocks) / blocks);
			if (!hasTransform) {
				return color;
			}

			if (color.a == 0.0 || mult == 0.0) {
				return color * openfl_Alphav;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
			newColor.a = color.a;

			color = mix(color, newColor, mult);

			if (color.a > 0.0) {
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')
	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')
	public function new()
	{
		super();
	}
}
