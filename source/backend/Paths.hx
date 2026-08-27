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

	public static function clearStoredWithoutStickers()
	{
		@:privateAccess
		var cache = FlxG.bitmap._cache;
		for (key => val in cache)
		{
			if (key.toLowerCase().contains("transitionswag") || key.contains("bg_graphic_") || key == "images/justBf.png")
				Paths.currentTrackedAssets.set(key, val);
		}
		Paths.clearStoredMemory();
		cacheStickersToContext();
	}

	public static function cacheStickersToContext()
	{
		for (key => val in Paths.currentTrackedAssets)
		{
			if (key.toLowerCase().contains("transitionswag") || key.contains("bg_graphic_") || key == "images/justBf.png")
				Paths.localTrackedAssets.push(key);
		}
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

	public static function freeGraphicsFromMemory()
	{
		var protectedGfx:Array<FlxGraphic> = [];
		function checkForGraphics(spr:Dynamic)
		{
			try
			{
				var grp:Array<Dynamic> = Reflect.getProperty(spr, 'members');
				if (grp != null)
				{
					for (member in grp)
						checkForGraphics(member);
					return;
				}
			}

			try
			{
				var gfx:FlxGraphic = Reflect.getProperty(spr, 'graphic');
				if (gfx != null)
					protectedGfx.push(gfx);
			}
		}

		for (member in FlxG.state.members)
			checkForGraphics(member);

		if (FlxG.state.subState != null)
			for (member in FlxG.state.subState.members)
				checkForGraphics(member);

		for (key in currentTrackedAssets.keys())
		{
			if (!dumpExclusions.contains(key))
			{
				var graphic:FlxGraphic = currentTrackedAssets.get(key);
				if (!protectedGfx.contains(graphic))
				{
					destroyGraphic(graphic);
					currentTrackedAssets.remove(key);
				}
			}
		}
	}

	inline static function destroyGraphic(graphic:FlxGraphic)
	{
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	public static function getPath(file:String, ?parentfolder:String, ?modsAllowed:Bool = false):String
	{
		#if MODS_ALLOWED
		if (modsAllowed)
		{
			var customFile:String = file;
			if (parentfolder != null)
				customFile = '$parentfolder/$file';

			var modded:String = modFolders(customFile);
			if (FileSystem.exists(modded))
				return modded;
		}
		#end

		if (parentfolder != null)
			return getFolderPath(file, parentfolder);

		return getPreloadPath(file);
	}

	inline static public function getFolderPath(file:String, folder:String)
		return 'assets/$folder/$file';

	inline public static function getPreloadPath(file:String = '')
		return 'assets/$file';

	inline static public function txt(key:String, ?folder:String)
		return getPath('$key.txt', folder);

	inline static public function xml(key:String, ?folder:String)
		return getPath('$key.xml', folder);

	inline static public function json(key:String, ?folder:String)
		return getPath('$key.json', folder);

	inline static public function shaderFragment(key:String, ?folder:String)
		return getPath('shaders/$key.frag', folder);

	inline static public function shaderVertex(key:String, ?folder:String)
		return getPath('shaders/$key.vert', folder);

	inline static public function lua(key:String, ?folder:String)
		return getPath('$key.lua', folder);

	inline static public function script(key:String, ?folder:String)
	{
		var extension:String = '.hx';

		for (ext in HSCRIPT_EXT)
			extension = (exists(getPath(key + ext))) ? ext : extension;

		return getPath(key + extension, folder);
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

	inline static public function python(key:String, ?folder:String)
		return getPath('$key.py', folder);

	#if NDLL_ALLOWED
	inline static public function ndll(key:String)
	{
		var ndllName:String = key.trim();
		if (ndllName.endsWith('.ndll'))
			ndllName = ndllName.substring(0, ndllName.length - '.ndll'.length);

		var platformSuffixes:Array<String> = ['windows_x86', 'windows', 'linux', 'mac', 'browser', 'android', 'switch'];
		for (platform in platformSuffixes)
		{
			if (ndllName.endsWith('-' + platform))
			{
				ndllName = ndllName.substring(0, ndllName.length - ('-' + platform).length);
				break;
			}
		}

		ndllName += '-' + backend.utils.NdllUtil.os + '.ndll';

		#if MODS_ALLOWED
		var file:String = modsNdll(ndllName);
		if (FileSystem.exists(file))
		{
			return file;
		}
		#end
		return 'assets/ndlls/$ndllName';
	}
	#end

	inline static public function exists(asset:String)
		return FileAssets.exists(asset);

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

	static public function image(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		key = Language.getFileTranslation('images/$key') + '.png';
		var bitmap:BitmapData = null;
		if (currentTrackedAssets.exists(key))
		{
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		return cacheBitmap(key, parentFolder, bitmap, allowGPU);
	}

	public static function cacheBitmap(key:String, ?parentFolder:String = null, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic
	{
		if (bitmap == null)
		{
			var file:String = getPath(key, parentFolder, true);
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
		var folderKey:String = Language.getFileTranslation('fonts/$key');

		#if MODS_ALLOWED
		if (FileSystem.exists(modsFont(folderKey)))
			return modsFont(folderKey);
		#end

		var path:String = getPath(folderKey);

		if (path.extension() == '')
		{
			if (exists(path.withExtension("ttf")))
				path = path.withExtension("ttf");
			else if (exists(path.withExtension("otf")))
				path = path.withExtension("otf");
		}

		return path;
	}

	public static function fileExists(key:String, ?ignoreMods:Bool = false, ?parentFolder:String = null)
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
		return (Assets.exists(getPath(key, parentFolder, false)));
	}

	static public function getAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var useMod = false;
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);

		var myXml:Dynamic = getPath('images/$key.xml', true);
		if (Assets.exists(myXml) #if MODS_ALLOWED || (FileSystem.exists(myXml) && (useMod = true)) #end)
		{
			#if MODS_ALLOWED
			return FlxAtlasFrames.fromSparrow(imageLoaded, (useMod ? File.getContent(myXml) : myXml));
			#else
			return FlxAtlasFrames.fromSparrow(imageLoaded, myXml);
			#end
		}
		else
		{
			var myJson:Dynamic = getPath('images/$key.json', parentFolder, true);
			if (Assets.exists(myJson) #if MODS_ALLOWED || (FileSystem.exists(myJson) && (useMod = true)) #end)
			{
				#if MODS_ALLOWED
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (useMod ? File.getContent(myJson) : myJson));
				#else
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, myJson);
				#end
			}
		}
		return getPackerAtlas(key);
	}

	static public function getMultiAtlas(keys:Array<String>):FlxAtlasFrames
	{
		var parentFrames:FlxAtlasFrames = Paths.getAtlas(keys[0].trim());
		if (keys.length > 1)
		{
			var original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for (i in 1...keys.length)
			{
				var extraFrames:FlxAtlasFrames = Paths.getAtlas(keys[i].trim());
				if (extraFrames != null)
					parentFrames.addAtlas(extraFrames, true);
			}
		}
		return parentFrames;
	}

	inline static public function getSparrowAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if (FileSystem.exists(xml))
			xmlExists = true;

		return FlxAtlasFrames.fromSparrow(imageLoaded,
			(xmlExists ? File.getContent(xml) : getPath(Language.getFileTranslation('images/$key') + '.xml', parentFolder)));
		#else
		return FlxAtlasFrames.fromSparrow(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.xml', parentFolder));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var txtExists:Bool = false;

		var txt:String = modsTxt(key);
		if (FileSystem.exists(txt))
			txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded,
			(txtExists ? File.getContent(txt) : getPath(Language.getFileTranslation('images/$key') + '.txt', parentFolder)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.txt', parentFolder));
		#end
	}

	inline static public function getAsepriteAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var jsonExists:Bool = false;

		var json:String = modsImagesJson(key);
		if (FileSystem.exists(json))
			jsonExists = true;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded,
			(jsonExists ? File.getContent(json) : getPath(Language.getFileTranslation('images/$key') + '.json', parentFolder)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.json', parentFolder));
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
		final invalidChars = ~/[~&;:<>#\s]/g;
		final hideChars = ~/[.,'"%?!]/g;

		return hideChars.replace(invalidChars.replace(path, '-'), '').trim().toLowerCase();
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true)
	{
		var file:String = getPath(Language.getFileTranslation(key) + '.ogg', path, modsAllowed);

		if (!currentTrackedSounds.exists(file))
		{
			#if sys
			if (FileSystem.exists(file))
				currentTrackedSounds.set(file, Sound.fromFile(file));
			#end
			if (!currentTrackedSounds.exists(file) && Assets.exists(file, SOUND))
				currentTrackedSounds.set(file, Assets.getSound(file));

			if (!currentTrackedSounds.exists(file) && beepOnNull)
			{
				trace('SOUND NOT FOUND: $key | PATH: $path');
				FlxG.log.error('SOUND NOT FOUND: $key | PATH: $path');
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

	inline static public function modsImagesJson(key:String)
		return modFolders('images/$key.json');

	#if NDLL_ALLOWED
	inline static public function modsNdll(key:String)
		return modFolders('ndlls/' + key);
	#end

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
