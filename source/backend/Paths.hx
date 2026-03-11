package backend;

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

	public static var dumpExclusions:Array<String> = [
		'assets/music/freakyMenu.ogg',
		'assets/music/breakfast.ogg',
		'assets/music/tea-time.ogg',
	];

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
			if (!localTrackedAssets.contains(key))
			{
				destroyGraphic(currentTrackedAssets.get(key));
				currentTrackedAssets.remove(key);
			}
		}
		compress();
		gc(true);
	}

	inline static function destroyGraphic(graphic:FlxGraphic)
	{
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	public static var localTrackedAssets:Array<String> = [];

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory()
	{
		for (key in FlxG.bitmap._cache.keys())
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));

		for (key => asset in currentTrackedSounds)
			if (!localTrackedAssets.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}

		localTrackedAssets = [];
		Assets.cache.clear("songs");
		gc(true);
		compress();
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

	static public function validScriptType(n:String):Bool
		return n.endsWith('.hx') || n.endsWith('.hxs') || n.endsWith('.hxc') || n.endsWith('.hscript');

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

	static public function sound(key:String):Sound
		return returnSound('sounds', key);

	inline static public function soundRandom(key:String, min:Int, max:Int)
		return sound(key + FlxG.random.int(min, max));

	static public function music(key:String):Sound
		return returnSound('music', key);

	inline static public function track(song:String, track:String):Any
		return returnSound('songs', '${formatToSongPath(song)}/$track');

	inline static public function voices(song:String):Any
		return track(song, "Voices");

	inline static public function inst(song:String):Any
		return track(song, "Inst");

	static public function image(key:String):FlxGraphic
		return returnGraphic(key);

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key)))
			return File.getContent(modFolders(key));
		#end

		if (FileSystem.exists(getPreloadPath(key)))
			return File.getContent(getPreloadPath(key));
		#end

		return Assets.getText(getPath(key));
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

			if (FileSystem.exists(mods('$key')))
				return true;
		}
		#end

		return (Assets.exists(getPath(key, false))) ? true : false;
	}

	inline static public function getSparrowAtlas(key:String):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);

		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key)),
			(FileSystem.exists(modsXml(key)) ? File.getContent(modsXml(key)) : getPath('images/$key.xml')));
		#else
		return FlxAtlasFrames.fromSparrow(image(key), getPath('images/$key.xml'));
		#end
	}

	inline static public function getPackerAtlas(key:String)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var txtExists:Bool = FileSystem.exists(modFolders('images/$key.txt'));

		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key)),
			(txtExists ? File.getContent(modFolders('images/$key.txt')) : getPath('images/$key.txt')));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key), getPath('images/$key.txt'));
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

	inline static public function formatToSongPath(path:String)
	{
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	public static function getGraphic(path:String):FlxGraphic
	{
		#if html5
		return FlxG.bitmap.add(path, false, path);
		#elseif sys
		return FlxGraphic.fromBitmapData(BitmapData.fromFile(path), false, path);
		#end
	}

	public static function returnGraphic(key:String)
	{
		#if MODS_ALLOWED
		var modKey:String = modsImages(key);
		if (FileSystem.exists(modKey))
		{
			if (!currentTrackedAssets.exists(modKey))
			{
				var newGraphic:FlxGraphic = getGraphic(modKey);
				newGraphic.persist = true;
				currentTrackedAssets.set(modKey, newGraphic);
			}
			localTrackedAssets.push(modKey);
			return currentTrackedAssets.get(modKey);
		}
		#end

		var path = getPath('images/$key.png');
		if (Assets.exists(path, IMAGE))
		{
			if (!currentTrackedAssets.exists(path))
			{
				var newGraphic:FlxGraphic = getGraphic(path);
				newGraphic.persist = true;
				currentTrackedAssets.set(path, newGraphic);
			}
			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}
		trace('oh no!! $key returned null!');
		return null;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function returnSoundPath(path:String, key:String)
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(modsSounds(path, key)))
			return modsSounds(path, key);
		#end
		return getPath('$path/$key.ogg');
	}

	public static function returnSound(path:String, key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key);
		if (FileSystem.exists(file))
		{
			if (!currentTrackedSounds.exists(file))
				currentTrackedSounds.set(file, Sound.fromFile(file));

			localTrackedAssets.push(key);
			return currentTrackedSounds.get(file);
		}
		#end
		var gottenPath:String = getPath('$path/$key.ogg');
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		if (!currentTrackedSounds.exists(gottenPath))
			#if MODS_ALLOWED
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./$gottenPath'));
			#else
			currentTrackedSounds.set(gottenPath, Assets.getSound((path == 'songs' ? folder = 'songs:' : '') + getPath('$path/$key.ogg')));
			#end
			localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	#if MODS_ALLOWED
	static final modFolderPath:String = "mods/";

	inline static public function mods(key:String = '')
		return modFolderPath + key;

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
