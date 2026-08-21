package substates;

using Lambda;
using backend.IteratorTools;

/**
 * Taken from the P-Slice Repo.
 * Credits go to @milkolka9144!
 * @see https://github.com/Psych-Slice/P-Slice/blob/master/source/mikolka/vslice/StickerSubState.hx
 */
class StickerSubState extends MusicBeatSubstate
{
	public static var STICKER_SET = "stickers-set-1";
	public static var STICKER_PACK = "all";

	public var grpStickers:FlxTypedGroup<StickerSprite>;

	public var dipshit:Sprite;

	/**
	 * The state to switch to after the stickers are done.
	 * This is a FUNCTION so we can pass it directly to `FlxG.switchState()`,
	 * and we can add constructor parameters in the caller.
	 */
	var targetState:StickerSubState->FlxState;

	var soundSelections:Array<String> = [];
	var soundSelection:String = "";
	var sounds:Array<String> = [];

	public function new(?oldStickers:Array<StickerSprite>, ?targetState:StickerSubState->FlxState):Void
	{
		super();

		this.targetState = (targetState == null) ? ((sticker) -> new ScriptedState('MainMenuState', [])) : targetState;

		var assetsInList = openfl.utils.Assets.list();

		var soundFilterFunc = function(a:String)
		{
			return a.startsWith('assets/sounds/stickersounds/');
		};

		soundSelections = assetsInList.filter(soundFilterFunc);
		soundSelections = soundSelections.map(function(a:String)
		{
			return a.replace('assets/sounds/stickersounds/', '').split('/')[0];
		});

		for (i in soundSelections)
		{
			while (soundSelections.contains(i))
			{
				soundSelections.remove(i);
			}
			soundSelections.push(i);
		}

		trace(soundSelections);

		soundSelection = FlxG.random.getObject(soundSelections);

		var filterFunc = function(a:String)
		{
			return a.startsWith('assets/sounds/stickersounds/' + soundSelection + '/');
		};
		var assetsInList3 = openfl.utils.Assets.list();
		sounds = assetsInList3.filter(filterFunc);
		for (i in 0...sounds.length)
		{
			sounds[i] = sounds[i].replace('assets/sounds/', '');
			sounds[i] = sounds[i].substring(0, sounds[i].lastIndexOf('.'));
		}

		trace(sounds);

		grpStickers = new FlxTypedGroup<StickerSprite>();
		add(grpStickers);

		grpStickers.cameras = FlxG.cameras.list;

		if (oldStickers != null)
		{
			for (sticker in oldStickers)
			{
				grpStickers.add(sticker);
			}

			degenStickers();
		}
		else
			regenStickers();
	}

	public function degenStickers():Void
	{
		grpStickers.cameras = FlxG.cameras.list;

		if (grpStickers.members == null || grpStickers.members.length == 0)
		{
			switchingState = false;
			close();
			return;
		}

		for (ind => sticker in grpStickers.members)
		{
			new FlxTimer().start(sticker.timing, _ ->
			{
				sticker.visible = false;
				var daSound:String = FlxG.random.getObject(sounds);
				new FlxSound().loadEmbedded(Paths.sound(daSound)).play();

				if (grpStickers == null || ind == grpStickers.members.length - 1)
				{
					switchingState = false;
					FlxTransitionableState.skipNextTransIn = false;
					close();
				}
			});
		}
	}

	function regenStickers():Void
	{
		if (grpStickers.members.length > 0)
		{
			grpStickers.clear();
		}

		trace("Collecting stickers...");
		var stickers:StickerInfo = null;

		#if sys
		var modStickerDir = Paths.getPath('images/transitionSwag/$STICKER_SET');
		if (!FileSystem.exists(modStickerDir))
		{
			Lib.application.window.alert('Missing sticker set "$STICKER_SET"\n\nCouldn\'t find sticker set "$STICKER_SET" in $modStickerDir',
				"Missing sticker set");
		}
		else if (!FileSystem.exists('$modStickerDir/stickers.json'))
		{
			Lib.application.window.alert('Sticker set "$STICKER_SET" is missing its stickers.json file in $modStickerDir', "Missing stickers.json");
		}
		else
		{
			try
			{
				var infoObj = new StickerInfo(STICKER_SET);
				stickers = infoObj;
				if (infoObj.getPack(STICKER_PACK) == null)
					Lib.application.window.alert('Sticker set ${infoObj.name} doesn\'t contain "$STICKER_PACK" pack.\n\nAll available stickers will be loaded instead.',
						"Missing pack");
			}
			catch (x)
			{
				Lib.application.window.alert('In "$modStickerDir":\n\n${x.message}', "Error making sticker pack");
			}
		}
		#else
		var infoObj = new StickerInfo(STICKER_SET);
		stickers = infoObj;
		#end

		var xPos:Float = -100;
		var yPos:Float = -100;
		while (xPos <= FlxG.width)
		{
			var sticky:StickerSprite = null;
			if (stickers != null)
			{
				var stickerPack:Array<String> = stickers.getPack(STICKER_PACK);
				if (stickerPack == null)
				{
					stickerPack = stickers.stickers.keys().array();
				}
				var stickerSetCollection:Array<String> = [];
				for (x in stickerPack)
				{
					stickerSetCollection = stickerSetCollection.concat(stickers.getStickers(x));
				}

				var sticker:String = FlxG.random.getObject(stickerSetCollection);
				sticky = new StickerSprite(0, 0, STICKER_SET, sticker);
			}
			else
			{
				sticky = new StickerSprite(0, 0, null, "justBf");
			}
			sticky.visible = false;

			sticky.x = xPos;
			sticky.y = yPos;
			xPos += sticky.frameWidth * 0.5;

			if (xPos >= FlxG.width)
			{
				if (yPos <= FlxG.height)
				{
					xPos = -100;
					yPos += FlxG.random.float(70, 120);
				}
			}

			sticky.angle = FlxG.random.int(-60, 70);
			grpStickers.add(sticky);
		}

		FlxG.random.shuffle(grpStickers.members);

		for (ind => sticker in grpStickers.members)
		{
			sticker.timing = FlxMath.remapToRange(ind, 0, grpStickers.members.length, 0, 0.9);

			new FlxTimer().start(sticker.timing, _ ->
			{
				if (grpStickers == null)
					return;

				sticker.visible = true;
				var daSound:String = FlxG.random.getObject(sounds);
				new FlxSound().loadEmbedded(Paths.sound(daSound)).play();

				var frameTimer:Int = FlxG.random.int(0, 2);

				if (ind == grpStickers.members.length - 1)
					frameTimer = 2;

				new FlxTimer().start((1 / 24) * frameTimer, _ ->
				{
					if (sticker == null)
						return;

					sticker.scale.x = sticker.scale.y = FlxG.random.float(0.97, 1.02);

					if (ind == grpStickers.members.length - 1)
					{
						switchingState = true;

						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = FlxG.state is ScriptedState || FlxG.state is StickerTest; // lmao idk

						if (subState != null)
						{
							subStateClosed.addOnce(s ->
							{
								FlxG.switchState(targetState(this));
							});
						}
						else
							FlxG.switchState(targetState(this));
					}
				});
			});
		}

		grpStickers.sort((ord, a, b) ->
		{
			return FlxSort.byValues(ord, a.timing, b.timing);
		});

		var lastOne:StickerSprite = grpStickers.members[grpStickers.members.length - 1];
		lastOne.updateHitbox();
		lastOne.angle = 0;
		lastOne.screenCenter();

		STICKER_SET = "stickers-set-1";
		STICKER_PACK = "all";
		Mods.loadTheFirstEnabledMod();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	var switchingState:Bool = false;

	override public function close():Void
	{
		if (switchingState)
			return;
		super.close();
	}

	override public function destroy():Void
	{
		if (switchingState)
			return;
		super.destroy();
	}
}

class StickerSprite extends FlxSprite
{
	public var timing:Float = 0;

	var stickerPath:String;

	public function loadSticker()
	{
		loadGraphic(Paths.image(stickerPath));
		updateHitbox();
		scrollFactor.set();
	}

	public function new(x:Float, y:Float, stickerSet:String, stickerName:String):Void
	{
		super(x, y);
		stickerPath = stickerSet == null ? stickerName : 'transitionSwag/$stickerSet/$stickerName';
		antialiasing = ClientPrefs.data.globalAntialiasing;
		loadSticker();
	}
}

class StickerInfo
{
	public var name:String;
	public var artist:String;
	public var modDir:String;
	public var stickers:Map<String, Array<String>>;
	public var stickerPacks:Map<String, Array<String>>;

	public function new(stickerSet:String):Void
	{
		var json = Json.parse(Paths.getTextFromFile('images/transitionSwag/${StickerSubState.STICKER_SET}/stickers.json'));

		var jsonInfo:StickerShit = cast json;

		this.name = jsonInfo.name;
		this.artist = jsonInfo.artist;

		stickerPacks = new Map<String, Array<String>>();

		for (field in Reflect.fields(json.stickerPacks))
		{
			var stickerFunny = json.stickerPacks;
			var stickerStuff = Reflect.field(stickerFunny, field);

			stickerPacks.set(field, cast stickerStuff);
		}

		stickers = new Map<String, Array<String>>();

		for (field in Reflect.fields(json.stickers))
		{
			var stickerFunny = json.stickers;
			var stickerStuff = Reflect.field(stickerFunny, field);

			stickers.set(field, cast stickerStuff);
		}
	}

	public function getStickers(stickerName:String):Array<String>
	{
		return this.stickers[stickerName];
	}

	public function getPack(packName:String):Array<String>
	{
		return this.stickerPacks[packName];
	}
}

typedef StickerShit =
{
	name:String,
	artist:String,
	stickers:Map<String, Array<String>>,
	stickerPacks:Map<String, Array<String>>
}
