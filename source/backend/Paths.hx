package backend;

import flixel.system.FlxAssets;
import flixel.graphics.FlxGraphic;

using haxe.io.Path;

typedef FileAssets = #if sys FileSystem; #else Assets; #end
typedef GarbageCollect = #if cpp cpp.vm.Gc; #elseif hl hl.Gc; #elseif neko neko.vm.Gc; #end

@:keep
@:access(openfl.display.BitmapData)
class Paths
{
	public static var HSCRIPT_EXT:Array<String> = ['.hx', '.hxs', '.hxc', '.hscript'];

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = ['assets/music/freakyMenu.ogg'];

	@:noCompletion private inline static function _gc(major:Bool)
	{
		#if (cpp || neko)
		GarbageCollect.run(major);
		#elseif hl
		GarbageCollect.major();
		#end
	}

	@:noCompletion public inline static function compress()
	{
		#if cpp
		GarbageCollect.compact();
		#elseif hl
		GarbageCollect.major();
		#elseif neko
		GarbageCollect.run(true);
		#end
	}

	public inline static function gc(major:Bool = false, repeat:Int = 1)
	{
		while (repeat-- > 0)
			_gc(major);
	}

	public static function clearUnusedMemory()
	{
		for (key in currentTrackedAssets.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				destroyGraphic(currentTrackedAssets.get(key));
				currentTrackedAssets.remove(key);
			}
		}
		compress();
		gc(true);
	}

	public static var localTrackedAssets:Array<String> = [];

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory()
	{
		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));
		}

		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		localTrackedAssets = [];
		Assets.cache.clear("songs");
		gc(true);
		compress();
	}

	inline static function destroyGraphic(graphic:FlxGraphic)
	{
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	public static function getPath(file:String, ?modsAllowed:Bool = false):String
	{
		#if MODS_ALLOWED
		if (modsAllowed)
			if (FileSystem.exists(modFolders(file)))
				return modFolders(file);
		#end

		return getPreloadPath(file);
	}

	inline public static function getPreloadPath(file:String = '')
		return 'assets/$file';

	inline static public function txt(key:String)
		return getPath('$key.txt');

	inline static public function xml(key:String)
		return getPath('$key.xml');

	inline static public function json(key:String)
		return getPath('$key.json');

	inline static public function shaderFragment(key:String)
		return getPath('shaders/$key.frag');

	inline static public function shaderVertex(key:String)
		return getPath('shaders/$key.vert');

	inline static public function lua(key:String)
		return getPath('$key.lua');

	inline static public function script(key:String)
	{
		var extension:String = '.hx';

		for (ext in HSCRIPT_EXT)
			extension = (exists(getPath(key + ext))) ? ext : extension;

		return getPath(key + extension);
	}

	static public function validScriptType(key:String):Bool
	{
		for (ext in HSCRIPT_EXT)
		{
			if (key.endsWith(ext))
				return true;
		}
		return false;
	}

	inline static public function exists(asset:String)
		return FileAssets.exists(asset);

	inline static public function getContent(asset:String):Null<String>
	{
		#if sys
		if (FileSystem.exists(asset))
			return File.getContent(asset);
		#else
		if (Assets.exists(asset))
			return Assets.getText(asset);
		#end

		return null;
	}

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(modsVideo(key)))
			return modsVideo(key);
		#end
		return getPath('videos/$key.mp4');
	}

	static public function sound(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('sounds/$key', modsAllowed);

	inline static public function soundRandom(key:String, min:Int, max:Int, ?modsAllowed:Bool = true)
		return sound(key + FlxG.random.int(min, max), modsAllowed);

	static public function music(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('music/$key', modsAllowed);

	inline static public function inst(song:String, ?modsAllowed:Bool = true):Sound
		return returnSound('songs/${formatToSongPath(song)}/Inst', modsAllowed);

	inline static public function voices(song:String, postfix:String = null, ?modsAllowed:Bool = true):Sound
	{
		var songKey:String = 'songs/${formatToSongPath(song)}/Voices';
		if (postfix != null)
			songKey += '-' + postfix;
		return returnSound(songKey, modsAllowed, false);
	}

	static public function image(key:String, ?allowGPU:Bool = true):FlxGraphic
	{
		var bitmap:BitmapData = null;
		if (currentTrackedAssets.exists(key))
		{
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		return cacheBitmap(key, bitmap, allowGPU);
	}

	public static function cacheBitmap(key:String, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic
	{
		if (bitmap == null)
		{
			var file:String = getPath(key, true);
			#if MODS_ALLOWED if (FileSystem.exists(file))
				bitmap = BitmapData.fromFile(file);
			else #end if (Assets.exists(file, IMAGE))
				bitmap = Assets.getBitmapData(file);

			if (bitmap == null)
			{
				trace('Bitmap not found: $file | key: $key');
				return null;
			}
		}

		if (allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null)
		{
			bitmap.lock();
			if (bitmap.__texture == null)
			{
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
			bitmap.getSurface();
			bitmap.disposeImage();
			bitmap.image.data = null;
			bitmap.image = null;
			bitmap.readable = true;
		}

		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentTrackedAssets.set(key, graph);
		localTrackedAssets.push(key);
		return graph;
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		var path:String = getPath(key, !ignoreMods);
		#if sys
		return (FileSystem.exists(path)) ? File.getContent(path) : null;
		#else
		return (Assets.exists(path, TEXT)) ? Assets.getText(path) : null;
		#end
	}

	inline static public function font(key:String)
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(modsFont(key)))
			return modsFont(key);
		#end

		var path:String = getPath('fonts/$key');

		if (path.extension() == '')
		{
			if (exists(path.withExtension("ttf")))
				path = path.withExtension("ttf");
			else if (exists(path.withExtension("otf")))
				path = path.withExtension("otf");
		}

		return path;
	}

	public static function fileExists(key:String, ?ignoreMods:Bool = false)
	{
		#if MODS_ALLOWED
		if (!ignoreMods)
		{
			for (mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$key')))
					return true;

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + key)) || FileSystem.exists(mods(key)))
				return true;
		}
		#end
		return (Assets.exists(getPath(key, false)));
	}

	inline static public function getSparrowAtlas(key:String, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, allowGPU);
		#if MODS_ALLOWED
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if (FileSystem.exists(xml))
			xmlExists = true;

		return FlxAtlasFrames.fromSparrow(imageLoaded, (xmlExists ? File.getContent(xml) : getPath('images/$key.xml')));
		#else
		return FlxAtlasFrames.fromSparrow(imageLoaded, getPath('images/$key.xml'));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, allowGPU);
		#if MODS_ALLOWED
		var txtExists:Bool = false;
		
		var txt:String = modsTxt(key);
		if (FileSystem.exists(txt))
			txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, (txtExists ? File.getContent(txt) : getPath('images/$key.txt')));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath('images/$key.txt'));
		#end
	}

	#if flxanimate
	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null)
	{
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;

		if (spriteJson != null)
		{
			changedAtlasJson = true;
			spriteJson = File.getContent(spriteJson);
		}

		if (animationJson != null)
		{
			changedAnimJson = true;
			animationJson = File.getContent(animationJson);
		}

		if (Std.isOfType(folderOrImg, String))
		{
			var originalPath:String = folderOrImg;
			for (i in 0...10)
			{
				var st:String = '$i';
				if (i == 0)
					st = '';

				if (!changedAtlasJson)
				{
					spriteJson = getTextFromFile('images/$originalPath/spritemap$st.json');
					if (spriteJson != null)
					{
						changedImage = true;
						changedAtlasJson = true;
						folderOrImg = Paths.image('$originalPath/spritemap$st');
						break;
					}
				}
				else if (Paths.fileExists('images/$originalPath/spritemap$st.png'))
				{
					changedImage = true;
					folderOrImg = Paths.image('$originalPath/spritemap$st');
					break;
				}
			}

			if (!changedImage)
			{
				changedImage = true;
				folderOrImg = Paths.image(originalPath);
			}

			if (!changedAnimJson)
			{
				changedAnimJson = true;
				animationJson = getTextFromFile('images/$originalPath/Animation.json');
			}
		}
		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}
	#end

	inline static public function formatToSongPath(path:String) {
		final invalidChars = ~/[~&;:<>#\s]/g;
		final hideChars = ~/[.,'"%?!]/g;

		return hideChars.replace(invalidChars.replace(path, '-'), '').trim().toLowerCase();
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function returnSound(key:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true)
	{
		var file:String = getPath('$key.ogg', modsAllowed);

		if (!currentTrackedSounds.exists(file))
		{
			#if sys
			if (FileSystem.exists(file))
				currentTrackedSounds.set(file, Sound.fromFile(file));
			#else
			if (Assets.exists(file, SOUND))
				currentTrackedSounds.set(file, Assets.getSound(file));
			#end
			else if (beepOnNull)
			{
				trace('SOUND NOT FOUND: $key');
				FlxG.log.error('SOUND NOT FOUND: $key');
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		localTrackedAssets.push(file);
		return currentTrackedSounds.get(file);
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
		return 'mods/' + key;

	inline static public function modsFont(key:String)
		return modFolders('fonts/$key');

	inline static public function modsJson(key:String)
		return modFolders('$key.json');

	inline static public function modsVideo(key:String)
		return modFolders('videos/$key.mp4');

	inline static public function modsSounds(path:String, key:String)
		return modFolders('$path/$key.ogg');

	inline static public function modsImages(key:String)
		return modFolders('images/$key.png');

	inline static public function modsXml(key:String)
		return modFolders('images/$key.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/$key.txt');

	static public function modFolders(key:String)
	{
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + key)))
				return mods(Mods.currentModDirectory + '/' + key);

		for (mod in Mods.getGlobalMods())
			if (FileSystem.exists(mods('$mod/$key')))
				return mods('$mod/$key');

		return 'mods/$key';
	}
	#end
}
