package options;

import flixel.addons.display.shapes.FlxShapeCircle;
import lime.system.Clipboard;
import shaders.RGBPalette;

class ControlsSubState extends MusicBeatSubstate
{
	var curSelected:Int = 0;
	var curAlt:Bool = false;

	// Display name - Save file key - Rebind display name
	var options:Array<Dynamic> = [
		['NOTES'],
		['Left', 'note_left', 'Note Left'],
		['Down', 'note_down', 'Note Down'],
		['Up', 'note_up', 'Note Up'],
		['Right', 'note_right', 'Note Right'],
		[],
		['UI'],
		['Left', 'ui_left', 'UI Left'],
		['Down', 'ui_down', 'UI Down'],
		['Up', 'ui_up', 'UI Up'],
		['Right', 'ui_right', 'UI Right'],
		[],
		['Reset', 'reset', 'Reset'],
		['Accept', 'accept', 'Accept'],
		['Back', 'back', 'Back'],
		['Pause', 'pause', 'Pause'],
		[],
		['VOLUME'],
		['Mute', 'volume_mute', 'Volume Mute'],
		['Up', 'volume_up', 'Volume Up'],
		['Down', 'volume_down', 'Volume Down'],
		[],
		['DEBUG'],
		['Key 1', 'debug_1', 'Debug Key #1'],
		['Key 2', 'debug_2', 'Debug Key #2']
	];

	var curOptions:Array<Int>;
	var curOptionsValid:Array<Int>;

	static var defaultKey:String = 'Reset to Default Keys';

	var bg:FlxSprite;
	var grpDisplay:FlxTypedGroup<Alphabet>;
	var grpBlacks:FlxTypedGroup<AttachedSprite>;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var grpBinds:FlxTypedGroup<Alphabet>;
	var selectSpr:AttachedSprite;

	public function new()
	{
		super();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Controls Menu", null);
		#end

		options.push([]);
		options.push([]);
		options.push([defaultKey]);

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff7192fd;
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		bg.screenCenter();
		add(bg);

		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		grpDisplay = new FlxTypedGroup<Alphabet>();
		add(grpDisplay);
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		grpBlacks = new FlxTypedGroup<AttachedSprite>();
		add(grpBlacks);
		selectSpr = new AttachedSprite();
		selectSpr.makeGraphic(250, 78, FlxColor.WHITE);
		selectSpr.copyAlpha = false;
		selectSpr.alpha = 0.75;
		add(selectSpr);
		grpBinds = new FlxTypedGroup<Alphabet>();
		add(grpBinds);

		createTexts();
	}

	var lastID:Int = 0;

	function createTexts()
	{
		curOptions = [];
		curOptionsValid = [];
		grpDisplay.forEachAlive(function(text:Alphabet) text.destroy());
		grpBlacks.forEachAlive(function(black:AttachedSprite) black.destroy());
		grpOptions.forEachAlive(function(text:Alphabet) text.destroy());
		grpBinds.forEachAlive(function(text:Alphabet) text.destroy());
		grpDisplay.clear();
		grpBlacks.clear();
		grpOptions.clear();
		grpBinds.clear();

		var myID:Int = 0;
		for (i in 0...options.length)
		{
			var option:Array<Dynamic> = options[i];
			if (option.length > 0)
			{
				var isCentered:Bool = (option.length < 3);
				var isDefaultKey:Bool = (option[0] == defaultKey);
				var isDisplayKey:Bool = (isCentered && !isDefaultKey);

				var text:Alphabet = new Alphabet(200, 300, option[0], !isDisplayKey);
				text.isMenuItem = true;
				text.changeX = false;
				text.distancePerItem.y = 60;
				text.targetY = myID;
				if (isDisplayKey)
					grpDisplay.add(text);
				else
				{
					grpOptions.add(text);
					curOptions.push(i);
					curOptionsValid.push(myID);
				}
				text.ID = myID;
				lastID = myID;

				if (isCentered)
					addCenteredText(text, option, myID);
				else
					addKeyText(text, option, myID);

				text.snapToPosition();
				text.y += FlxG.height * 2;
			}
			myID++;
		}
		updateText();
	}

	function addCenteredText(text:Alphabet, option:Array<Dynamic>, id:Int)
	{
		text.screenCenter(X);
		text.y -= 55;
		text.startPosition.y -= 55;
	}

	function addKeyText(text:Alphabet, option:Array<Dynamic>, id:Int)
	{
		for (n in 0...2)
		{
			var textX:Float = 350 + n * 300;

			var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option[1]);
			var key:String = InputFormatter.getKeyName((savKey[n] != null) ? savKey[n] : NONE);

			var attach:Alphabet = new Alphabet(textX + 210, 248, key, false);
			attach.isMenuItem = true;
			attach.changeX = false;
			attach.distancePerItem.y = 60;
			attach.targetY = text.targetY;
			attach.ID = Math.floor(grpBinds.length / 2);
			attach.snapToPosition();
			attach.y += FlxG.height * 2;
			grpBinds.add(attach);

			attach.scaleX = Math.min(1, 230 / attach.width);

			// spawn black bars at the right of the key name
			var black:AttachedSprite = new AttachedSprite();
			black.makeGraphic(250, 78, FlxColor.BLACK);
			black.alphaMult = 0.4;
			black.sprTracker = text;
			black.yAdd = -6;
			black.xAdd = textX;
			grpBlacks.add(black);
		}
	}

	function updateBind(num:Int, text:String)
	{
		var bind:Alphabet = grpBinds.members[num];
		var attach:Alphabet = new Alphabet(350 + (num % 2) * 300, 248, text, false);
		attach.isMenuItem = true;
		attach.changeX = false;
		attach.distancePerItem.y = 60;
		attach.targetY = bind.targetY;
		attach.ID = bind.ID;
		attach.x = bind.x;
		attach.y = bind.y;

		attach.scaleX = Math.min(1, 230 / attach.width);

		bind.kill();
		grpBinds.remove(bind);
		grpBinds.insert(num, attach);
		bind.destroy();
	}

	var binding:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:Alphabet;
	var bindingText2:Alphabet;

	var timeForMoving:Float = 0.1;

	override function update(elapsed:Float)
	{
		if (timeForMoving > 0)
		{
			timeForMoving = Math.max(0, timeForMoving - elapsed);
			super.update(elapsed);
			return;
		}

		if (!binding)
		{
			if (controls.BACK)
			{
				close();
				return;
			}

			if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
				updateAlt(true);

			if (controls.UI_UP_P)
				updateText(-1);
			else if (controls.UI_DOWN_P)
				updateText(1);

			if (controls.ACCEPT)
			{
				if (options[curOptions[curSelected]][0] != defaultKey)
				{
					bindingBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
					bindingBlack.scale.set(FlxG.width, FlxG.height);
					bindingBlack.updateHitbox();
					bindingBlack.alpha = 0;
					FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
					add(bindingBlack);

					bindingText = new Alphabet(FlxG.width / 2, 160, "Rebinding " + options[curOptions[curSelected]][2], false);
					bindingText.alignment = CENTERED;
					add(bindingText);

					bindingText2 = new Alphabet(FlxG.width / 2, 340, "Hold ESC to Cancel\nHold Backspace to Delete", true);
					bindingText2.alignment = CENTERED;
					add(bindingText2);

					binding = true;
					holdingEsc = 0;
					ClientPrefs.toggleVolumeKeys(false);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				else
				{
					ClientPrefs.keyBinds = ClientPrefs.defaultKeys.copy();
					ClientPrefs.reloadVolumeKeys();
					var lastSel:Int = curSelected;
					createTexts();
					curSelected = lastSel;
					updateText();
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			}
		}
		else
		{
			var altNum:Int = curAlt ? 1 : 0;
			var curOption:Array<Dynamic> = options[curOptions[curSelected]];
			var optionKey:String = curOption[1];

			if (FlxG.keys.pressed.ESCAPE)
			{
				holdingEsc += elapsed;
				if (holdingEsc > 0.5)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeBinding();
				}
			}
			else if (FlxG.keys.pressed.BACKSPACE)
			{
				holdingEsc += elapsed;
				if (holdingEsc > 0.5)
				{
					var keysArray:Array<FlxKey> = ClientPrefs.keyBinds.get(optionKey);
					keysArray[altNum] = NONE;
					ClientPrefs.keyBinds.set(optionKey, keysArray);
					ClientPrefs.clearInvalidKeys(optionKey);
					updateBind(Math.floor(curSelected * 2) + altNum, InputFormatter.getKeyName(NONE));
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeBinding();
				}
			}
			else
			{
				holdingEsc = 0;
				var keyPressed:Int = FlxG.keys.firstJustPressed();

				if (keyPressed > -1 && keyPressed != FlxKey.ESCAPE && keyPressed != FlxKey.BACKSPACE)
				{
					var keysArray:Array<FlxKey> = ClientPrefs.keyBinds.get(optionKey);
					keysArray[altNum] = keyPressed;

					var opposite:Int = (curAlt ? 0 : 1);
					if (keysArray[altNum] == keysArray[opposite])
					{
						keysArray[opposite] = NONE;
					}

					ClientPrefs.keyBinds.set(optionKey, keysArray);
					ClientPrefs.clearInvalidKeys(optionKey);

					for (n in 0...2)
					{
						var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(optionKey);
						var key:String = InputFormatter.getKeyName(savKey[n] != null ? savKey[n] : NONE);
						updateBind(Math.floor(curSelected * 2) + n, key);
					}
					FlxG.sound.play(Paths.sound('confirmMenu'));
					closeBinding();
				}
			}
		}
		super.update(elapsed);
	}

	function closeBinding()
	{
		binding = false;
		bindingBlack.destroy();
		remove(bindingBlack);

		bindingText.destroy();
		remove(bindingText);

		bindingText2.destroy();
		remove(bindingText2);
		ClientPrefs.reloadVolumeKeys();
	}

	function updateText(?move:Int = 0)
	{
		if (move != 0)
		{
			curSelected += move;

			if (curSelected < 0)
				curSelected = curOptions.length - 1;
			else if (curSelected >= curOptions.length)
				curSelected = 0;
		}

		var num:Int = curOptionsValid[curSelected];
		var addNum:Int = 0;
		if (num < 3)
			addNum = 3 - num;
		else if (num > lastID - 4)
			addNum = (lastID - 4) - num;

		grpDisplay.forEachAlive(function(item:Alphabet)
		{
			item.targetY = item.ID - num - addNum;
		});

		grpOptions.forEachAlive(function(item:Alphabet)
		{
			item.targetY = item.ID - num - addNum;
			item.alpha = (item.ID - num == 0) ? 1 : 0.6;
		});

		grpBinds.forEachAlive(function(item:Alphabet)
		{
			var parent:Alphabet = grpOptions.members[item.ID];
			item.targetY = parent.targetY;
			item.alpha = parent.alpha;
		});

		updateAlt();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function updateAlt(?doSwap:Bool = false)
	{
		if (doSwap)
		{
			curAlt = !curAlt;
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		selectSpr.sprTracker = grpBlacks.members[Math.floor(curSelected * 2) + (curAlt ? 1 : 0)];
		selectSpr.visible = (selectSpr.sprTracker != null);
	}
}

class GameplaySubState extends BaseOptionsMenu
{
	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var notesTween:Array<FlxTween> = [];
	var noteY:Float = 90;

	var windowBar:FlxSprite;
	var windowOptions:Array<Option> = [];
	final windowDefaultMaxes:Array<Int> = [45, 90, 135, 205];
	final windowDefaultMins:Array<Int> = [16, 46, 91, 136];
	final windowColours = [0xbf00ff00, 0xbfffaa00, 0xbfff0000, 0xbfff00ff];

	public function new()
	{
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu'; // for Discord Rich Presence

		notes = new FlxTypedGroup<StrumNote>();
		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = new StrumNote(370 + (560 / Note.colArray.length) * i, -200, i, 0);
			note.centerOffsets();
			note.centerOrigin();
			note.playAnim('static');
			notes.add(note);
		}

		var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		if (noteSkins.length > 0)
		{
			if (!noteSkins.contains(ClientPrefs.data.noteSkin))
				ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin; // Reset to default if saved noteskin couldnt be found

			noteSkins.insert(0, ClientPrefs.defaultData.noteSkin); // Default skin always comes first
			var option:Option = new Option('Note Skins:', "Select your prefered Note skin.", 'noteSkin', 'string', noteSkins);
			addOption(option);
			option.onChange = onChangeNoteSkin;
			noteOptionID = optionsArray.length - 1;
		}

		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
		if (noteSplashes.length > 0)
		{
			if (!noteSplashes.contains(ClientPrefs.data.splashSkin))
				ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin; // Reset to default if saved splashskin couldnt be found

			noteSplashes.insert(0, ClientPrefs.defaultData.splashSkin); // Default skin always comes first
			var option:Option = new Option('Note Splashes:', "Select your prefered Note Splash variation or turn it off.", 'splashSkin', 'string',
				noteSplashes);
			addOption(option);
		}

		var option:Option = new Option('Note Splash Opacity', 'How much transparent should the Note Splashes be.', 'splashAlpha', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Sustain Splash Opacity', 'How much transparent should the Sustain Splashes be.', 'susSplashAlpha', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		// I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Downscroll', // Name
			'If checked, notes go Down instead of Up, simple enough.', // Description
			'downScroll', // Save data variable name
			'bool'); // Variable type
		addOption(option);

		var option:Option = new Option('Middlescroll', 'If checked, your notes get centered.', 'middleScroll', 'bool');
		addOption(option);

		var option:Option = new Option('Opponent Notes', 'If unchecked, opponent notes get hidden.', 'opponentStrums', 'bool');
		addOption(option);

		var option:Option = new Option('Ghost Tapping', "If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.",
			'ghostTapping', 'bool');
		addOption(option);

		var option:Option = new Option('Ghost Tap Animation', 'If checked, plays player one\'s anim when ghost tapping is active.', 'ghostTapAnim', 'bool');
		addOption(option);

		var option:Option = new Option('Camera Movement', 'If checked, move the camera depending the note that was hit.', 'cameraPanning', 'bool');
		addOption(option);

		var option:Option = new Option('Camera Pan Intensity:', // Name
			'Changes how much the camera pans when Camera Movement is turned on.', 'panIntensity', 'float');
		option.scrollSpeed = 2;
		option.minValue = 0.01;
		option.maxValue = 10;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		addOption(option);

		var option:Option = new Option('Auto Pause', "If checked, the game automatically pauses if the screen isn't on focus.", 'autoPause', 'bool');
		addOption(option);
		option.onChange = onChangeAutoPause;

		var option:Option = new Option('Disable Reset Button', "If checked, pressing Reset won't do anything.", 'noReset', 'bool');
		addOption(option);

		var option:Option = new Option('Hitsound Volume', 'Funny notes does \"Tick!\" when you hit them."', 'hitsoundVolume', 'percent');
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;

		var option:Option = new Option('Note Splashes', "If unchecked, hitting \"Sick!\" notes won't show particles.", 'noteSplashes', 'bool');
		addOption(option);

		var option:Option = new Option('Hide HUD', 'If checked, hides most HUD elements.', 'hideHud', 'bool');
		addOption(option);

		var option:Option = new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', 'string',
			['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms', 'bool');
		addOption(option);

		var option:Option = new Option('Score Text Zoom on Hit', "If unchecked, disables the Score text zooming\neverytime you hit a note.", 'scoreZoom',
			'bool');
		addOption(option);

		var option:Option = new Option('Health Bar Transparency', 'How much transparent should the health bar and icons be.', 'healthBarAlpha', 'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Combo Stacking',
			"If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read", 'comboStacking', 'bool');
		addOption(option);

		var option:Option = new Option('Display Milliseconds', 'If checked, displays your note hit offset in milliseconds.', 'displayMilliseconds', 'bool');
		addOption(option);

		var option:Option = new Option('Rating Offset', 'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.',
			'ratingOffset', 'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var option:Option = new Option('Sick! Hit Window', 'Changes the amount of time you have\nfor hitting a "Sick!" in milliseconds.', 'sickWindow', 'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15;
		option.maxValue = 45;
		windowOptions.push(option);
		addOption(option);
		option.onChange = onChangeHitWindow;

		var option:Option = new Option('Good Hit Window', 'Changes the amount of time you have\nfor hitting a "Good" in milliseconds.', 'goodWindow', 'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15;
		option.maxValue = 90;
		windowOptions.push(option);
		addOption(option);
		option.onChange = onChangeHitWindow;

		var option:Option = new Option('Bad Hit Window', 'Changes the amount of time you have\nfor hitting a "Bad" in milliseconds.', 'badWindow', 'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 135;
		windowOptions.push(option);
		addOption(option);
		option.onChange = onChangeHitWindow;

		var option:Option = new Option('Shit Hit Window', 'Changes the amount of time you have\nfor hitting a "Shit" in milliseconds.', 'shitWindow', 'int');
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		windowOptions.push(option);
		addOption(option);
		option.onChange = onChangeHitWindow;

		var option:Option = new Option('Safe Frames', 'Changes how many frames you have for\nhitting a note earlier or late.', 'safeFrames', 'float');
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		super();

		add(notes);

		windowBar = new FlxSprite((FlxG.width / 4) * 3 + 150, FlxG.height / 4 - 100).makeGraphic(80, 220, 0x00ffffff);
		windowBar.visible = false;
		windowBar.setGraphicSize(80, 440);
		windowBar.updateHitbox();
		windowBar.antialiasing = false;
		insert(members.indexOf(descBox) - 1, windowBar);

		onChangeHitWindow();
	}

	function onChangeHitsoundVolume()
		FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);

	function onChangeAutoPause()
		FlxG.autoPause = ClientPrefs.data.autoPause;

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);

		if (noteOptionID < 0)
			return;

		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = notes.members[i];
			if (notesTween[i] != null)
				notesTween[i].cancel();
			if (curSelected == noteOptionID)
				notesTween[i] = FlxTween.tween(note, {y: noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
			else
				notesTween[i] = FlxTween.tween(note, {y: -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
		}

		if (windowBar != null)
			windowBar.visible = (optionsArray[curSelected].name.contains('Hit Window'));
	}

	function onChangeNoteSkin()
	{
		notes.forEachAlive(function(note:StrumNote)
		{
			changeNoteSkin(note);
			note.centerOffsets();
			note.centerOrigin();
		});
	}

	function changeNoteSkin(note:StrumNote)
	{
		var skin:String = Note.defaultNoteSkin;
		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if (Paths.fileExists('images/$customSkin.png'))
			skin = customSkin;

		note.texture = skin; // Load texture and anims
		note.reloadNote();
		note.playAnim('static');
	}

	function onChangeHitWindow()
	{
		var prevLine:Float = 0;
		for (i => option in windowOptions)
		{
			option.minValue = windowDefaultMins[i];
			option.maxValue = windowDefaultMaxes[i];
			if (windowOptions[i - 1] != null)
			{
				if (windowOptions[i - 1].maxValue > option.minValue)
					option.minValue = windowOptions[i - 1].maxValue;
			}
			if (windowOptions[i + 1] != null)
			{
				if (windowOptions[i + 1].minValue < option.maxValue)
					option.maxValue = windowOptions[i + 1].minValue;
			}
			var pixels = windowBar.pixels;
			for (y in 0...pixels.height)
			{
				if (y / pixels.height <= option.getValue() / pixels.height && y / pixels.height > prevLine)
					for (x in 0...pixels.width)
						pixels.setPixel32(x, y, windowColours[i]);
				else if (y / pixels.height > option.getValue() / pixels.height)
					for (x in 0...pixels.width)
						pixels.setPixel32(x, y, windowColours[windowColours.length - 1]);
			}
			prevLine = option.getValue() / pixels.height;
		}
	}

	override function destroy()
	{
		Note.globalRgbShaders = [];
		super.destroy();
	}
}

class MiscSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Miscellaneous';
		rpcTitle = 'Misc. Settings Menu'; // for Discord Rich Presence

		var option:Option = new Option('Pause Screen Song:', "What song do you prefer for the Pause Screen?", 'pauseMusic', 'string',
			['None', 'Breakfast', 'Tea Time']);
		addOption(option);
		option.onChange = onChangePauseMusic;

		#if CHECK_FOR_UPDATES
		var option:Option = new Option('Check for Updates', 'On release builds, turn this on to check for updates when you start the game.',
			'checkForUpdates', 'bool');
		addOption(option);
		#end

		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord Rich Presence',
			"Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord", 'discordRPC', 'bool');
		addOption(option);
		#end

		super();
	}

	var changedMusic:Bool = false;

	function onChangePauseMusic()
	{
		if (ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));

		changedMusic = true;
	}

	override function destroy()
	{
		if (changedMusic)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		super.destroy();
	}
}

class NotesSubState extends MusicBeatSubstate
{
	var onModeColumn:Bool = true;
	var curSelectedMode:Int = 0;
	var curSelectedNote:Int = 0;
	var onPixel:Bool = false;
	var dataArray:Array<Array<FlxColor>>;

	var hexTypeLine:FlxSprite;
	var hexTypeNum:Int = -1;
	var hexTypeVisibleTimer:Float = 0;

	var copyButton:FlxSprite;
	var pasteButton:FlxSprite;

	var colorGradient:FlxSprite;
	var colorGradientSelector:FlxSprite;
	var colorPalette:FlxSprite;
	var colorWheel:FlxSprite;
	var colorWheelSelector:FlxSprite;

	var alphabetR:Alphabet;
	var alphabetG:Alphabet;
	var alphabetB:Alphabet;
	var alphabetHex:Alphabet;

	var modeBG:FlxSprite;
	var notesBG:FlxSprite;

	var daCam:FlxCamera;
	var tipTxt:FlxText;

	public function new()
	{
		super();

		daCam = new FlxCamera();
		daCam.bgColor.alpha = 0;
		FlxG.cameras.add(daCam, false);

		FlxG.mouse.visible = true;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		add(bg);

		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		modeBG = new FlxSprite(215, 85).makeGraphic(315, 115, FlxColor.BLACK);
		modeBG.visible = false;
		modeBG.alpha = 0.4;
		add(modeBG);

		notesBG = new FlxSprite(140, 190).makeGraphic(480, 125, FlxColor.BLACK);
		notesBG.visible = false;
		notesBG.alpha = 0.4;
		add(notesBG);

		modeNotes = new FlxTypedGroup<FlxSprite>();
		add(modeNotes);

		myNotes = new FlxTypedGroup<StrumNote>();
		add(myNotes);

		var bg:FlxSprite = new FlxSprite(720).makeGraphic(FlxG.width - 720, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.25;
		add(bg);
		var bg:FlxSprite = new FlxSprite(750, 160).makeGraphic(FlxG.width - 780, 540, FlxColor.BLACK);
		bg.alpha = 0.25;
		add(bg);

		var text:Alphabet = new Alphabet(50, 86, 'CTRL', false);
		text.alignment = CENTERED;
		text.setScale(0.4);
		add(text);

		copyButton = new FlxSprite(760, 50).loadGraphic(Paths.image('noteColorMenu/copy'));
		copyButton.alpha = 0.6;
		add(copyButton);

		pasteButton = new FlxSprite(1180, 50).loadGraphic(Paths.image('noteColorMenu/paste'));
		pasteButton.alpha = 0.6;
		add(pasteButton);

		colorGradient = FlxGradient.createGradientFlxSprite(60, 360, [FlxColor.WHITE, FlxColor.BLACK]);
		colorGradient.setPosition(780, 200);
		add(colorGradient);

		colorGradientSelector = new FlxSprite(770, 200).makeGraphic(80, 10, FlxColor.WHITE);
		colorGradientSelector.offset.y = 5;
		add(colorGradientSelector);

		colorPalette = new FlxSprite(820, 580).loadGraphic(Paths.image('noteColorMenu/palette', false));
		colorPalette.scale.set(20, 20);
		colorPalette.updateHitbox();
		colorPalette.antialiasing = false;
		add(colorPalette);

		colorWheel = new FlxSprite(860, 200).loadGraphic(Paths.image('noteColorMenu/colorWheel'));
		colorWheel.setGraphicSize(360, 360);
		colorWheel.updateHitbox();
		add(colorWheel);

		colorWheelSelector = new FlxShapeCircle(0, 0, 8, {thickness: 0}, FlxColor.WHITE);
		colorWheelSelector.offset.set(8, 8);
		colorWheelSelector.alpha = 0.6;
		add(colorWheelSelector);

		var txtX = 980;
		var txtY = 90;
		alphabetR = makeColorAlphabet(txtX - 100, txtY);
		add(alphabetR);
		alphabetG = makeColorAlphabet(txtX, txtY);
		add(alphabetG);
		alphabetB = makeColorAlphabet(txtX + 100, txtY);
		add(alphabetB);
		alphabetHex = makeColorAlphabet(txtX, txtY - 55);
		add(alphabetHex);

		hexTypeLine = new FlxSprite(0, 20).makeGraphic(5, 62, FlxColor.WHITE);
		hexTypeLine.visible = false;
		add(hexTypeLine);

		var tipX = 20;
		var tipY = 660;
		var tip:FlxText = new FlxText(tipX, tipY, 0, "Press RELOAD to Reset the selected Note Part.", 16);
		tip.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tip.borderSize = 2;
		add(tip);

		tipTxt = new FlxText(tipX, tipY + 24, 0, '', 16);
		tipTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipTxt.borderSize = 2;
		add(tipTxt);
		updateTip();

		spawnNotes();
		updateNotes(true);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);

		cameras = [daCam];
	}

	function updateTip()
	{
		tipTxt.text = 'Hold Shift' + ' + Press RELOAD to fully reset the selected Note.';
	}

	var _storedColor:FlxColor;
	var changingNote:Bool = false;
	var holdingOnObj:FlxSprite;

	var allowedTypeKeys:Map<FlxKey, String> = [
		ZERO => '0',
		ONE => '1',
		TWO => '2',
		THREE => '3',
		FOUR => '4',
		FIVE => '5',
		SIX => '6',
		SEVEN => '7',
		EIGHT => '8',
		NINE => '9',
		NUMPADZERO => '0',
		NUMPADONE => '1',
		NUMPADTWO => '2',
		NUMPADTHREE => '3',
		NUMPADFOUR => '4',
		NUMPADFIVE => '5',
		NUMPADSIX => '6',
		NUMPADSEVEN => '7',
		NUMPADEIGHT => '8',
		NUMPADNINE => '9',
		A => 'A',
		B => 'B',
		C => 'C',
		D => 'D',
		E => 'E',
		F => 'F'
	];

	override function update(elapsed:Float)
	{
		if (controls.BACK)
		{
			FlxG.cameras.remove(daCam);
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
			return;
		}

		if (FlxG.keys.justPressed.CONTROL)
		{
			onPixel = !onPixel;
			spawnNotes();
			updateNotes(true);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}

		if (hexTypeNum > -1)
		{
			var keyPressed:FlxKey = cast(FlxG.keys.firstJustPressed(), FlxKey);
			hexTypeVisibleTimer += elapsed;
			var changed:Bool = false;
			if (changed = FlxG.keys.justPressed.LEFT)
				hexTypeNum--;
			else if (changed = FlxG.keys.justPressed.RIGHT)
				hexTypeNum++;
			else if (allowedTypeKeys.exists(keyPressed))
			{
				var curColor:String = alphabetHex.text;
				var newColor:String = curColor.substring(0, hexTypeNum) + allowedTypeKeys.get(keyPressed) + curColor.substring(hexTypeNum + 1);

				var colorHex:FlxColor = FlxColor.fromString('#' + newColor);
				setShaderColor(colorHex);
				_storedColor = getShaderColor();
				updateColors();

				hexTypeNum++;
				changed = true;
			}
			else if (FlxG.keys.justPressed.ENTER)
				hexTypeNum = -1;

			var end:Bool = false;
			if (changed)
			{
				if (hexTypeNum > 5)
				{
					hexTypeNum = -1;
					end = true;
					hexTypeLine.visible = false;
				}
				else
				{
					if (hexTypeNum < 0)
						hexTypeNum = 0;
					else if (hexTypeNum > 5)
						hexTypeNum = 5;
					centerHexTypeLine();
					hexTypeLine.visible = true;
				}
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			if (!end)
				hexTypeLine.visible = Math.floor(hexTypeVisibleTimer * 2) % 2 == 0;
		}
		else
		{
			var add:Int = 0;
			if (controls.UI_LEFT_P)
				add = -1;
			else if (controls.UI_RIGHT_P)
				add = 1;
			if (controls.UI_UP_P || controls.UI_DOWN_P)
			{
				onModeColumn = !onModeColumn;
				modeBG.visible = onModeColumn;
				notesBG.visible = !onModeColumn;
			}

			if (add != 0)
			{
				if (onModeColumn)
					changeSelectionMode(add);
				else
					changeSelectionNote(add);
			}
			hexTypeLine.visible = false;
		}

		if (FlxG.mouse.justMoved)
		{
			copyButton.alpha = 0.6;
			pasteButton.alpha = 0.6;
		}
		if (FlxG.mouse.overlaps(copyButton))
		{
			if (FlxG.mouse.justMoved)
				copyButton.alpha = 1;

			if (FlxG.mouse.justPressed)
			{
				if (FlxG.mouse.justPressed)
					Clipboard.text = getShaderColor().toHexString(false, false);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}

			hexTypeNum = -1;
		}
		else if (FlxG.mouse.overlaps(pasteButton))
		{
			if (FlxG.mouse.justMoved)
				pasteButton.alpha = 1;

			if (FlxG.mouse.justPressed)
			{
				var formattedText = Clipboard.text.trim().toUpperCase().replace('#', '').replace('0x', '');
				var newColor:Null<FlxColor> = FlxColor.fromString('#' + formattedText);
				if (newColor != null && formattedText.length == 6)
				{
					setShaderColor(newColor);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					_storedColor = getShaderColor();
					updateColors();
				}
				else
					FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			}

			hexTypeNum = -1;
		}

		var generalMoved:Bool = (FlxG.mouse.justMoved);
		var generalPressed:Bool = (FlxG.mouse.justPressed);
		if (generalMoved)
		{
			copyButton.alpha = 0.6;
			pasteButton.alpha = 0.6;
		}

		if (FlxG.mouse.justPressed)
		{
			hexTypeNum = -1;
			if (FlxG.mouse.overlaps(modeNotes))
			{
				modeNotes.forEachAlive(function(note:FlxSprite)
				{
					if (curSelectedMode != note.ID && FlxG.mouse.overlaps(note))
					{
						modeBG.visible = notesBG.visible = false;
						curSelectedMode = note.ID;
						onModeColumn = true;
						updateNotes();
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					}
				});
			}
			else if (FlxG.mouse.overlaps(myNotes))
			{
				myNotes.forEachAlive(function(note:StrumNote)
				{
					if (curSelectedNote != note.ID && FlxG.mouse.overlaps(note))
					{
						modeBG.visible = notesBG.visible = false;
						curSelectedNote = note.ID;
						onModeColumn = false;
						bigNote.shader = Note.globalRgbShaders[note.ID].shader;
						updateNotes();
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					}
				});
			}
			else if (FlxG.mouse.overlaps(colorWheel))
			{
				_storedColor = getShaderColor();
				holdingOnObj = colorWheel;
			}
			else if (FlxG.mouse.overlaps(colorGradient))
			{
				_storedColor = getShaderColor();
				holdingOnObj = colorGradient;
			}
			else if (FlxG.mouse.overlaps(colorPalette))
			{
				setShaderColor(colorPalette.pixels.getPixel32(Std.int((FlxG.mouse.x - colorPalette.x) / colorPalette.scale.x),
					Std.int((FlxG.mouse.y - colorPalette.y) / colorPalette.scale.y)));
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				updateColors();
			}
			else if (FlxG.mouse.overlaps(skinNote))
			{
				onPixel = !onPixel;
				spawnNotes();
				updateNotes(true);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			else if (FlxG.mouse.y >= hexTypeLine.y
				&& FlxG.mouse.y < hexTypeLine.y + hexTypeLine.height
				&& Math.abs(FlxG.mouse.x - 1000) <= 84)
			{
				hexTypeNum = 0;
				for (letter in alphabetHex.letters)
				{
					if (letter.x - letter.offset.x + letter.width <= FlxG.mouse.x)
						hexTypeNum++;
					else
						break;
				}
				if (hexTypeNum > 5)
					hexTypeNum = 5;
				hexTypeLine.visible = true;
				centerHexTypeLine();
			}
			else
				holdingOnObj = null;
		}
		if (holdingOnObj != null)
		{
			if (FlxG.mouse.justReleased)
			{
				holdingOnObj = null;
				_storedColor = getShaderColor();
				updateColors();
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			else if (generalMoved || generalPressed)
			{
				if (holdingOnObj == colorGradient)
				{
					var newBrightness = 1 - FlxMath.bound((FlxG.mouse.y - colorGradient.y) / colorGradient.height, 0, 1);
					_storedColor.alpha = 1;
					if (_storedColor.brightness == 0)
						setShaderColor(FlxColor.fromRGBFloat(newBrightness, newBrightness, newBrightness));
					else
						setShaderColor(FlxColor.fromHSB(_storedColor.hue, _storedColor.saturation, newBrightness));
					updateColors(_storedColor);
				}
				else if (holdingOnObj == colorWheel)
				{
					var center:FlxPoint = new FlxPoint(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
					var mouse:FlxPoint = FlxG.mouse.getScreenPosition();
					var hue:Float = FlxMath.wrap(FlxMath.wrap(Std.int(mouse.degreesTo(center)), 0, 360) - 90, 0, 360);
					var sat:Float = FlxMath.bound(mouse.dist(center) / colorWheel.width * 2, 0, 1);
					if (sat != 0)
						setShaderColor(FlxColor.fromHSB(hue, sat, _storedColor.brightness));
					else
						setShaderColor(FlxColor.fromRGBFloat(_storedColor.brightness, _storedColor.brightness, _storedColor.brightness));
					updateColors();
				}
			}
		}
		else if (controls.RESET && hexTypeNum < 0)
		{
			if (FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyJustPressed(LEFT_SHOULDER))
			{
				for (i in 0...3)
				{
					var strumRGB:RGBPalette = myNotes.members[curSelectedNote].rgbShader;
					var color:FlxColor = !onPixel ? ClientPrefs.defaultData.arrowRGB[curSelectedNote][i] : ClientPrefs.defaultData.arrowRGBPixel[curSelectedNote][i];
					switch (i)
					{
						case 0:
							getShader().r = strumRGB.r = color;
						case 1:
							getShader().g = strumRGB.g = color;
						case 2:
							getShader().b = strumRGB.b = color;
					}
					dataArray[curSelectedNote][i] = color;
				}
			}
			setShaderColor(!onPixel ? ClientPrefs.defaultData.arrowRGB[curSelectedNote][curSelectedMode] : ClientPrefs.defaultData.arrowRGBPixel[curSelectedNote][curSelectedMode]);
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			updateColors();
		}
		super.update(elapsed);
	}

	function centerHexTypeLine()
	{
		if (hexTypeNum > 0)
		{
			var letter = alphabetHex.letters[hexTypeNum - 1];
			hexTypeLine.x = letter.x - letter.offset.x + letter.width;
		}
		else
		{
			var letter = alphabetHex.letters[0];
			hexTypeLine.x = letter.x - letter.offset.x;
		}
		hexTypeLine.x += hexTypeLine.width;
		hexTypeVisibleTimer = 0;
	}

	function changeSelectionMode(change:Int = 0)
	{
		curSelectedMode += change;
		if (curSelectedMode < 0)
			curSelectedMode = 2;
		if (curSelectedMode >= 3)
			curSelectedMode = 0;

		modeBG.visible = true;
		notesBG.visible = false;
		updateNotes();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeSelectionNote(change:Int = 0)
	{
		curSelectedNote += change;
		if (curSelectedNote < 0)
			curSelectedNote = dataArray.length - 1;
		if (curSelectedNote >= dataArray.length)
			curSelectedNote = 0;

		modeBG.visible = false;
		notesBG.visible = true;
		bigNote.shader = Note.globalRgbShaders[curSelectedNote].shader;
		updateNotes();
		updateColors();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function makeColorAlphabet(x:Float = 0, y:Float = 0):Alphabet
	{
		var text:Alphabet = new Alphabet(x, y, '', true);
		text.alignment = CENTERED;
		text.setScale(0.6);
		add(text);
		return text;
	}

	var skinNote:FlxSprite;
	var modeNotes:FlxTypedGroup<FlxSprite>;
	var myNotes:FlxTypedGroup<StrumNote>;
	var bigNote:Note;

	public function spawnNotes()
	{
		dataArray = !onPixel ? ClientPrefs.data.arrowRGB : ClientPrefs.data.arrowRGBPixel;
		if (onPixel)
			PlayState.stageUI = "pixel";

		modeNotes.forEachAlive(function(note:FlxSprite)
		{
			note.kill();
			note.destroy();
		});
		myNotes.forEachAlive(function(note:StrumNote)
		{
			note.kill();
			note.destroy();
		});
		modeNotes.clear();
		myNotes.clear();

		if (skinNote != null)
		{
			remove(skinNote);
			skinNote.destroy();
		}
		if (bigNote != null)
		{
			remove(bigNote);
			bigNote.destroy();
		}

		var res:Int = onPixel ? 160 : 17;
		skinNote = new FlxSprite(48, 24).loadGraphic(Paths.image('noteColorMenu/' + (onPixel ? 'note' : 'notePixel')), true, res, res);
		skinNote.setGraphicSize(68);
		skinNote.updateHitbox();
		skinNote.animation.add('anim', [0], 24, true);
		skinNote.animation.play('anim', true);
		if (!onPixel)
			skinNote.antialiasing = false;
		add(skinNote);

		var res:Int = !onPixel ? 160 : 17;
		for (i in 0...3)
		{
			var newNote:FlxSprite = new FlxSprite(230 + (100 * i),
				100).loadGraphic(Paths.image('noteColorMenu/' + (!onPixel ? 'note' : 'notePixel')), true, res, res);
			newNote.setGraphicSize(85);
			newNote.updateHitbox();
			newNote.animation.add('anim', [i], 24, true);
			newNote.animation.play('anim', true);
			newNote.ID = i;
			if (onPixel)
				newNote.antialiasing = false;
			modeNotes.add(newNote);
		}

		Note.globalRgbShaders = [];
		for (i in 0...dataArray.length)
		{
			Note.initializeGlobalRGBShader(i, false);
			var newNote:StrumNote = new StrumNote(150 + (480 / dataArray.length * i), 200, i, 0);
			newNote.setGraphicSize(102);
			newNote.updateHitbox();
			newNote.ID = i;
			myNotes.add(newNote);
		}

		bigNote = new Note(0, 0, false, true);
		bigNote.setPosition(250, 325);
		bigNote.setGraphicSize(250);
		bigNote.updateHitbox();
		for (i in 0...Note.colArray.length)
		{
			if (!onPixel)
				bigNote.animation.addByPrefix('note$i', Note.colArray[i] + '0', 24, true);
			else
				bigNote.animation.add('note$i', [i + 4], 24, true);
		}
		insert(members.indexOf(myNotes) + 1, bigNote);
		bigNote.shader = Note.globalRgbShaders[curSelectedNote].shader;
		_storedColor = getShaderColor();
		PlayState.stageUI = "normal";
	}

	function updateNotes(?instant:Bool = false)
	{
		for (note in modeNotes)
			note.alpha = (curSelectedMode == note.ID) ? 1 : 0.6;

		for (note in myNotes)
		{
			var newAnim:String = curSelectedNote == note.ID ? 'confirm' : 'pressed';
			note.alpha = (curSelectedNote == note.ID) ? 1 : 0.6;
			if (note.animation.curAnim == null || note.animation.curAnim.name != newAnim)
				note.playAnim(newAnim, true);
			if (instant)
				note.animation.curAnim.finish();
		}
		bigNote.animation.play('note$curSelectedNote', true);
		updateColors();
	}

	function updateColors(specific:Null<FlxColor> = null)
	{
		var color:FlxColor = getShaderColor();
		var wheelColor:FlxColor = specific == null ? getShaderColor() : specific;
		alphabetR.text = Std.string(color.red);
		alphabetG.text = Std.string(color.green);
		alphabetB.text = Std.string(color.blue);
		alphabetHex.text = color.toHexString(false, false);
		for (letter in alphabetHex.letters)
			letter.color = color;

		colorWheel.color = FlxColor.fromHSB(0, 0, color.brightness);
		colorWheelSelector.setPosition(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
		if (wheelColor.brightness != 0)
		{
			var hueWrap:Float = wheelColor.hue * Math.PI / 180;
			colorWheelSelector.x += Math.sin(hueWrap) * colorWheel.width / 2 * wheelColor.saturation;
			colorWheelSelector.y -= Math.cos(hueWrap) * colorWheel.height / 2 * wheelColor.saturation;
		}
		colorGradientSelector.y = colorGradient.y + colorGradient.height * (1 - color.brightness);

		var strumRGB:RGBPalette = myNotes.members[curSelectedNote].rgbShader;
		switch (curSelectedMode)
		{
			case 0:
				getShader().r = strumRGB.r = color;
			case 1:
				getShader().g = strumRGB.g = color;
			case 2:
				getShader().b = strumRGB.b = color;
		}
	}

	function setShaderColor(value:FlxColor)
		dataArray[curSelectedNote][curSelectedMode] = value;

	function getShaderColor()
		return dataArray[curSelectedNote][curSelectedMode];

	function getShader()
		return Note.globalRgbShaders[curSelectedNote];
}

class VisualsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Visuals';
		rpcTitle = 'Visuals Settings Menu'; // for Discord Rich Presence

		var option:Option = new Option('Low Quality', // Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', // Description
			'lowQuality', // Save data variable name
			'bool'); // Variable type
		addOption(option);

		var option:Option = new Option('Anti-Aliasing', 'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'globalAntialiasing', 'bool');
		option.showBoyfriend = true;
		option.onChange = onChangeAntiAliasing; // Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		var option:Option = new Option('Shaders', // Name
			'If unchecked, disables shaders.\nIt\'s used for some visual effects, and also CPU intensive for weaker PCs.', // Description
			'shaders', // Save data variable name
			'bool'); // Variable type
		addOption(option);

		var option:Option = new Option('Colorblind Filter:', "Filters for colorblind people.", 'colorBlindFilter', 'string', Colorblind.getFilterNames());
		addOption(option);
		option.onChange = () -> Colorblind.updateFilter();

		// credits to the denpa engine team
		// don't support arcadia though
		var option:Option = new Option('CrossFade Mode:', "What mode should CrossFade be in?", 'crossFadeMode', 'string',
			['Mid-Fight Masses', 'Static', 'Eccentric', 'Off']);
		addOption(option);

		var option:Option = new Option('BF CrossFade Limit', "Determines the maximium amount of frames of CrossFade the player can have.",
			'boyfriendCrossFadeLimit', 'int');
		addOption(option);
		option.minValue = 1;
		option.maxValue = 10;

		var option:Option = new Option('Opponent CrossFade Limit', "Determines the maximium amount of frames of CrossFade the opponent can have.",
			'crossFadeLimit', 'int');
		addOption(option);
		option.minValue = 1;
		option.maxValue = 10;

		var option:Option = new Option('GPU Caching', // Name
			"If checked, allows the GPU to be used for caching textures, decreasing RAM usage.\nDon't turn this on if you have a shitty Graphics Card.", // Description
			'cacheOnGPU', 'bool');
		addOption(option);

		#if !html5 // Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate', "Pretty self explanatory, isn't it?", 'framerate', 'int');
		addOption(option);

		option.minValue = 60;
		option.maxValue = 240;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		#end

		var option:Option = new Option('Flashing Lights', "Uncheck this if you're sensitive to flashing lights!", 'flashing', 'bool');
		addOption(option);

		var option:Option = new Option('FPS Counter', 'If unchecked, hides FPS Counter.', 'showFPS', 'bool');
		addOption(option);
		option.onChange = onChangeFPSCounter;

		super();
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:Dynamic = sprite; // Make it check for FlxSprite instead of FlxBasic
			var sprite:FlxSprite = sprite; // Don't judge me ok
			if (sprite != null && (sprite is FlxSprite) && !(sprite is FlxText))
				sprite.antialiasing = ClientPrefs.data.globalAntialiasing;
		}
	}

	function onChangeFramerate()
	{
		if (ClientPrefs.data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.data.framerate;
			FlxG.drawFramerate = ClientPrefs.data.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.data.framerate;
			FlxG.updateFramerate = ClientPrefs.data.framerate;
		}
	}

	function onChangeFPSCounter()
	{
		if (Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.data.showFPS;
	}
}
