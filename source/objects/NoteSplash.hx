package objects;

import shaders.RGBPalette;
import flixel.system.FlxAssets.FlxShader;
import backend.animation.PsychAnimationController;

class NoteSplash extends FlxSprite
{
	public var rgbShader:PixelSplashShaderRef;

	private var idleAnim:String;
	private var textureLoaded:String = null;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0, redColor:FlxColor = 0, greenColor:FlxColor = 0, blueColor:FlxColor = 0)
	{
		super(x, y);

		animation = new PsychAnimationController(this);

		var skin:String = 'noteSplashes';
		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
			skin = PlayState.SONG.splashSkin;

		loadAnims(skin);

		rgbShader = new PixelSplashShaderRef();
		rgbShader.enabled = true;

		setupNoteSplash(x, y, note, redColor, greenColor, blueColor);
		antialiasing = ClientPrefs.data.globalAntialiasing;
	}

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = null, redColor:FlxColor = 0, greenColor:FlxColor = 0,
			blueColor:FlxColor = 0)
	{
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		rgbShader.r = redColor;
		rgbShader.g = greenColor;
		rgbShader.b = blueColor;
		shader = rgbShader.shader;
		alpha = 0.6;

		if (texture == null)
		{
			texture = 'noteSplashes';
			if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
				texture = PlayState.SONG.splashSkin;
		}

		if (textureLoaded != texture)
		{
			loadAnims(texture);
		}
		
		offset.set(-25, -10);

		var animNum:Int = FlxG.random.int(1, 2);
		animation.play('note' + note + '-' + animNum, true);
		if (animation.curAnim != null)
			animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
	}

	function loadAnims(skin:String)
	{
		frames = Paths.getSparrowAtlas(skin);
		for (i in 1...3)
		{
			animation.addByPrefix("note1-" + i, "note splash blue " + i, 24, false);
			animation.addByPrefix("note2-" + i, "note splash green " + i, 24, false);
			animation.addByPrefix("note0-" + i, "note splash purple " + i, 24, false);
			animation.addByPrefix("note3-" + i, "note splash red " + i, 24, false);
		}
	}

	override function update(elapsed:Float)
	{
		if (animation.curAnim != null)
			if (animation.curAnim.finished)
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
        shader.g.value = [color.greenFloat, color.greenFloat, color.blueFloat];
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
		else enabled = false;
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

		if (!PlayState.isPixelStage) pixelAmount = 1;
		else pixelAmount = PlayState.daPixelZoom;
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
