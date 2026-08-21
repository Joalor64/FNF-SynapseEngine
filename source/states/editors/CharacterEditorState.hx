package states.editors;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import objects.Character;
import haxe.Json;
import openfl.utils.Assets;

@:bitmap("assets/images/debugger/cursorCross.png")
class PointerGraphic extends BitmapData
{
}

class CharacterEditorState extends MusicBeatState
{
	var char:Character;
	var ghostChar:Character;
	#if flxanimate
	var animateGhost:FlxAnimate;
	var animateGhostImage:String;
	#end
	var textAnim:FlxText;
	var bgLayer:FlxTypedGroup<FlxSprite>;
	var charLayer:FlxTypedGroup<Character>;
	var ghostLayer:FlxTypedGroup<FlxSprite>;
	var dumbTexts:FlxTypedGroup<FlxText>;
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var goToPlayState:Bool = true;
	var camFollow:FlxObject;

	public function new(daAnim:String = 'spooky', goToPlayState:Bool = true)
	{
		super();
		this.daAnim = daAnim;
		this.goToPlayState = goToPlayState;
	}

	var UI_box:FlxUITabMenu;
	var UI_characterbox:FlxUITabMenu;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;

	var changeBGbutton:FlxButton;
	var leHealthIcon:HealthIcon;
	var characterList:Array<String> = [];

	var cameraFollowPointer:FlxSprite;
	var healthBar:Bar;
	var frameAdvanceText:FlxText;
	private var lastPosition:FlxPoint = new FlxPoint();
	private var mouseDiff:FlxPoint = new FlxPoint();

	override function create()
	{
		camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true);

		bgLayer = new FlxTypedGroup<FlxSprite>();
		add(bgLayer);
		charLayer = new FlxTypedGroup<Character>();
		add(charLayer);
		ghostLayer = new FlxTypedGroup<FlxSprite>();
		add(ghostLayer);

		var pointer:FlxGraphic = FlxGraphic.fromClass(PointerGraphic);
		cameraFollowPointer = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		add(cameraFollowPointer);

		changeBGbutton = new FlxButton(FlxG.width - 360, 25, "", function()
		{
			onPixelBG = !onPixelBG;
			reloadBGs();
		});
		changeBGbutton.cameras = [camMenu];

		loadChar(!daAnim.startsWith('bf'), false);

		healthBar = new Bar(30, FlxG.height - 75);
		healthBar.scrollFactor.set();
		add(healthBar);
		healthBar.cameras = [camHUD];

		leHealthIcon = new HealthIcon(char.healthIcon, false);
		leHealthIcon.y = FlxG.height - 150;
		add(leHealthIcon);
		leHealthIcon.cameras = [camHUD];

		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);
		dumbTexts.cameras = [camHUD];

		textAnim = new FlxText(300, 16);
		textAnim.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		textAnim.borderSize = 1;
		textAnim.size = 32;
		textAnim.scrollFactor.set();
		textAnim.cameras = [camHUD];
		add(textAnim);

		genBoyOffsets();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		var tipTextArray:Array<String> = "E/Q or Scroll - Camera Zoom In/Out
		\nR - Reset Camera Zoom
		\nJKLI or Hold and Drag RMB - Move Camera
		\nW/S - Previous/Next Animation
		\nSpace - Play Animation
		\nArrow Keys - Move Character Offset
		\nA/D - Frame Advance (Back/Forward)
		\nT - Reset Current Offset
		\nHold Shift to Move 10x faster\n".split('\n');

		for (i in 0...tipTextArray.length - 1)
		{
			var tipText:FlxText = new FlxText(FlxG.width - 320, FlxG.height - 15 - 16 * (tipTextArray.length - i), 300, tipTextArray[i], 12);
			tipText.cameras = [camHUD];
			tipText.setFormat(null, 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
			tipText.scrollFactor.set();
			tipText.borderSize = 1;
			add(tipText);
		}

		FlxG.camera.follow(camFollow);

		var tabs = [{name: 'Ghost', label: 'Ghost'}, {name: 'Settings', label: 'Settings'}];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camMenu];

		UI_box.resize(250, 120);
		UI_box.x = FlxG.width - 275;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		var tabs = [
			{name: 'Character', label: 'Character'},
			{name: 'Misc', label: 'Misc'},
			{name: 'Animations', label: 'Animations'},
		];
		UI_characterbox = new FlxUITabMenu(null, tabs, true);
		UI_characterbox.cameras = [camMenu];

		UI_characterbox.resize(350, 280);
		UI_characterbox.x = UI_box.x - 100;
		UI_characterbox.y = UI_box.y + UI_box.height;
		UI_characterbox.scrollFactor.set();
		add(UI_characterbox);
		add(UI_box);
		add(changeBGbutton);

		addSettingsUI();
		addGhostUI();
		addCharacterUI();
		addAnimationsUI();
		addMiscUI();

		UI_box.selected_tab_id = 'Settings';
		UI_characterbox.selected_tab_id = 'Character';

		frameAdvanceText = new FlxText(0, 75, 350, '');
		frameAdvanceText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		frameAdvanceText.scrollFactor.set();
		frameAdvanceText.borderSize = 1;
		frameAdvanceText.screenCenter(X);
		frameAdvanceText.cameras = [camHUD];
		add(frameAdvanceText);

		FlxG.mouse.visible = true;
		reloadCharacterOptions();

		super.create();
	}

	var ghostAlpha:Float = 0.6;

	function addGhostUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Ghost";

		var makeGhostButton:FlxButton = new FlxButton(25, 15, "Make Ghost", function()
		{
			if (!char.isAnimationNull())
			{
				var myAnim = char.animationsArray[curAnim];
				if (!char.isAnimateAtlas)
				{
					ghostChar.loadGraphic(char.graphic);
					ghostChar.frames.frames = char.frames.frames;
					ghostChar.animation.copyFrom(char.animation);
					ghostChar.animation.play(char.animation.curAnim.name, true, false, char.animation.curAnim.curFrame);
					ghostChar.animation.pause();
				}
				#if flxanimate
				else if (myAnim != null)
				{
					if (animateGhost == null)
					{
						animateGhost = new FlxAnimate(ghostChar.x, ghostChar.y);
						animateGhost.showPivot = false;
						ghostLayer.add(animateGhost);
						animateGhost.active = false;
					}

					if (animateGhost == null || animateGhostImage != char.imageFile)
						Paths.loadAnimateAtlas(animateGhost, char.imageFile);

					if (myAnim.indices != null && myAnim.indices.length > 0)
						animateGhost.anim.addBySymbolIndices('anim', myAnim.name, myAnim.indices, 0, false);
					else
						animateGhost.anim.addBySymbol('anim', myAnim.name, 0, false);

					animateGhost.anim.play('anim', true, false, char.atlas.anim.curFrame);
					animateGhost.anim.pause();

					animateGhostImage = char.imageFile;
				}
				#end

				var spr:FlxSprite = !char.isAnimateAtlas ? ghostChar : #if flxanimate animateGhost #else ghostChar #end;
				if (spr != null)
				{
					spr.setPosition(char.x, char.y);
					spr.antialiasing = char.antialiasing;
					spr.flipX = char.flipX;
					spr.alpha = ghostAlpha;

					spr.scale.set(char.scale.x, char.scale.y);
					spr.updateHitbox();

					spr.offset.set(char.offset.x, char.offset.y);
					spr.visible = true;

					#if flxanimate
					var otherSpr:FlxSprite = (spr == animateGhost) ? ghostChar : animateGhost;
					if (otherSpr != null)
						otherSpr.visible = false;
					#end
				}
			}
		});

		var highlightGhost:FlxUICheckBox = new FlxUICheckBox(20 + makeGhostButton.x + makeGhostButton.width, makeGhostButton.y, null, null, "Highlight Ghost",
			100);
		highlightGhost.callback = function()
		{
			var value = highlightGhost.checked ? 125 : 0;
			ghostChar.colorTransform.redOffset = value;
			ghostChar.colorTransform.greenOffset = value;
			ghostChar.colorTransform.blueOffset = value;
			#if flxanimate
			if (animateGhost != null)
			{
				animateGhost.colorTransform.redOffset = value;
				animateGhost.colorTransform.greenOffset = value;
				animateGhost.colorTransform.blueOffset = value;
			}
			#end
		};

		var ghostAlphaSlider:FlxUISlider = new FlxUISlider(this, 'ghostAlpha', 10, makeGhostButton.y + 25, 0, 1, 210, null, 5, FlxColor.WHITE, FlxColor.BLACK);
		ghostAlphaSlider.nameLabel.text = 'Opacity:';
		ghostAlphaSlider.decimals = 2;
		ghostAlphaSlider.callback = function(relativePos:Float)
		{
			ghostChar.alpha = ghostAlpha;
			#if flxanimate
			if (animateGhost != null)
				animateGhost.alpha = ghostAlpha;
			#end
		};
		ghostAlphaSlider.value = ghostAlpha;

		tab_group.add(makeGhostButton);
		tab_group.add(highlightGhost);
		tab_group.add(ghostAlphaSlider);

		for (i in tab_group.members)
			i.cameras = [camMenu];

		UI_box.addGroup(tab_group);
	}

	var onPixelBG:Bool = false;
	var OFFSET_X:Float = 300;

	function reloadBGs()
	{
		var i:Int = bgLayer.members.length - 1;
		while (i >= 0)
		{
			var memb:FlxSprite = bgLayer.members[i];
			if (memb != null)
			{
				memb.kill();
				bgLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		bgLayer.clear();
		var playerXDifference = 0;
		if (char.isPlayer)
			playerXDifference = 670;

		if (onPixelBG)
		{
			var playerYDifference:Float = 0;
			if (char.isPlayer)
			{
				playerXDifference += 200;
				playerYDifference = 220;
			}

			var bgSky:BGSprite = new BGSprite('stages/school/weebSky', OFFSET_X - (playerXDifference / 2) - 300, 0 - playerYDifference, 0.1, 0.1);
			bgLayer.add(bgSky);
			bgSky.antialiasing = false;

			var repositionShit = -200 + OFFSET_X - playerXDifference;

			var bgSchool:BGSprite = new BGSprite('stages/school/weebSchool', repositionShit, -playerYDifference + 6, 0.6, 0.90);
			bgLayer.add(bgSchool);
			bgSchool.antialiasing = false;

			var bgStreet:BGSprite = new BGSprite('stages/school/weebStreet', repositionShit, -playerYDifference, 0.95, 0.95);
			bgLayer.add(bgStreet);
			bgStreet.antialiasing = false;

			var widShit = Std.int(bgSky.width * 6);
			var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800 - playerYDifference);
			bgTrees.frames = Paths.getPackerAtlas('stages/school/weebTrees');
			bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
			bgTrees.animation.play('treeLoop');
			bgTrees.scrollFactor.set(0.85, 0.85);
			bgLayer.add(bgTrees);
			bgTrees.antialiasing = false;

			bgSky.setGraphicSize(widShit);
			bgSchool.setGraphicSize(widShit);
			bgStreet.setGraphicSize(widShit);
			bgTrees.setGraphicSize(Std.int(widShit * 1.4));

			bgSky.updateHitbox();
			bgSchool.updateHitbox();
			bgStreet.updateHitbox();
			bgTrees.updateHitbox();
			changeBGbutton.text = "Regular BG";
		}
		else
		{
			var bg:BGSprite = new BGSprite('stages/stage/stageback', -600 + OFFSET_X - playerXDifference, -300, 0.9, 0.9);
			bgLayer.add(bg);

			var stageFront:BGSprite = new BGSprite('stages/stage/stagefront', -650 + OFFSET_X - playerXDifference, 500, 0.9, 0.9);
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			bgLayer.add(stageFront);
			changeBGbutton.text = "Pixel BG";
		}
	}

	var TemplateCharacter:String = '{
			"animations": [
				{
					"loop": false,
					"offsets": [
						0,
						0
					],
					"fps": 24,
					"anim": "idle",
					"indices": [],
					"name": "Dad idle dance"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singLEFT",
					"loop": false,
					"name": "Dad Sing Note LEFT"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singDOWN",
					"loop": false,
					"name": "Dad Sing Note DOWN"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singUP",
					"loop": false,
					"name": "Dad Sing Note UP"
				},
				{
					"offsets": [
						0,
						0
					],
					"indices": [],
					"fps": 24,
					"anim": "singRIGHT",
					"loop": false,
					"name": "Dad Sing Note RIGHT"
				}
			],
			"no_antialiasing": false,
			"image": "characters/DADDY_DEAREST",
			"position": [
				0,
				0
			],
			"healthicon": "face",
			"flip_x": false,
			"healthbar_colors": [
				161,
				161,
				161
			],
			"camera_position": [
				0,
				0
			],
			"sing_duration": 6.1,
			"scale": 1
		}';

	var charDropDown:FlxUIDropDownMenuCustom;

	function loadChar(isDad:Bool = true, reload:Bool = true)
	{
		var pos:Int = -1;
		if (char != null)
		{
			pos = charLayer.members.indexOf(char);
			charLayer.remove(char);
			char.destroy();
		}

		char = new Character(0, 0, daAnim, !isDad);
		char.debugMode = true;

		char.setPosition(char.positionArray[0] + OFFSET_X + 100, char.positionArray[1]);

		if (pos > -1)
			charLayer.insert(pos, char);
		else
			charLayer.add(char);

		if (ghostChar != null)
		{
			ghostLayer.remove(ghostChar, true);
			ghostChar.destroy();
		}
		ghostChar = new Character(0, 0, daAnim, !isDad);
		ghostChar.debugMode = true;
		ghostChar.alpha = ghostAlpha;
		ghostChar.visible = false;
		ghostLayer.add(ghostChar);

		if (reload)
		{
			reloadCharacterOptions();
			genBoyOffsets();
		}
		reloadBGs();
		updatePointerPos();
	}

	function addSettingsUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";

		var check_player = new FlxUICheckBox(10, 60, null, null, "Playable Character", 100);
		check_player.checked = daAnim.startsWith('bf');
		check_player.callback = function()
		{
			char.isPlayer = !char.isPlayer;
			char.flipX = !char.flipX;
			updatePointerPos();
			reloadBGs();
			if (ghostChar != null)
				ghostChar.flipX = char.flipX;
		};

		charDropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(character:String)
		{
			daAnim = characterList[Std.parseInt(character)];
			check_player.checked = daAnim.startsWith('bf');
			loadChar(!check_player.checked);
			updatePresence();
			reloadCharacterDropDown();
		});
		charDropDown.selectedLabel = daAnim;
		reloadCharacterDropDown();

		var reloadCharacter:FlxButton = new FlxButton(140, 20, "Reload Char", function()
		{
			loadChar(!check_player.checked);
			reloadCharacterDropDown();
		});

		var templateCharacter:FlxButton = new FlxButton(140, 50, "Load Template", function()
		{
			var parsedJson:CharacterFile = cast Json.parse(TemplateCharacter);
			var characters:Array<Character> = [char];
			if (ghostChar != null)
				characters.push(ghostChar);

			for (character in characters)
			{
				character.animOffsets.clear();
				character.animationsArray = parsedJson.animations;
				for (anim in character.animationsArray)
				{
					character.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
				if (character.animationsArray[0] != null)
				{
					character.playAnim(character.animationsArray[0].anim, true);
				}

				character.singDuration = parsedJson.sing_duration;
				character.positionArray = parsedJson.position;
				character.cameraPosition = parsedJson.camera_position;

				character.imageFile = parsedJson.image;
				character.jsonScale = parsedJson.scale;
				character.noAntialiasing = parsedJson.no_antialiasing;
				character.originalFlipX = parsedJson.flip_x;
				character.healthIcon = parsedJson.healthicon;
				character.healthColorArray = parsedJson.healthbar_colors;
				character.setPosition(character.positionArray[0] + OFFSET_X + 100, character.positionArray[1]);
			}

			reloadCharacterImage();
			reloadCharacterDropDown();
			reloadCharacterOptions();
			resetHealthBarColor();
			updatePointerPos();
			genBoyOffsets();
		});
		templateCharacter.color = FlxColor.RED;
		templateCharacter.label.color = FlxColor.WHITE;

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 0, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(charDropDown);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		UI_box.addGroup(tab_group);
	}

	var imageInputText:FlxUIInputText;
	var healthIconInputText:FlxUIInputText;

	var singDurationStepper:FlxUINumericStepper;
	var scaleStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;

	var flipXCheckBox:FlxUICheckBox;
	var noAntialiasingCheckBox:FlxUICheckBox;

	var healthColorStepperR:FlxUINumericStepper;
	var healthColorStepperG:FlxUINumericStepper;
	var healthColorStepperB:FlxUINumericStepper;

	function addCharacterUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Character";

		imageInputText = new FlxUIInputText(15, 30, 200, 'characters/BOYFRIEND', 8);
		var reloadImage:FlxButton = new FlxButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			char.imageFile = imageInputText.text;
			reloadCharacterImage();
			if (!char.isAnimationNull())
			{
				char.playAnim(char.getAnimationName(), true);
			}
		});

		var decideIconColor:FlxButton = new FlxButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", function()
		{
			var coolColor = FlxColor.fromInt(CoolUtil.dominantColor(leHealthIcon));
			healthColorStepperR.value = coolColor.red;
			healthColorStepperG.value = coolColor.green;
			healthColorStepperB.value = coolColor.blue;
			getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperR, null);
			getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperG, null);
			getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperB, null);
		});

		healthIconInputText = new FlxUIInputText(15, imageInputText.y + 35, 75, leHealthIcon.getCharacter(), 8);

		singDurationStepper = new FlxUINumericStepper(15, healthIconInputText.y + 45, 0.1, 4, 0, 999, 1);

		scaleStepper = new FlxUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 1);
		Reflect.setProperty(scaleStepper, 'name', 'scaleStepper');

		flipXCheckBox = new FlxUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, null, null, "Flip X", 50);
		flipXCheckBox.checked = char.flipX;
		if (char.isPlayer)
			flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.callback = function()
		{
			char.originalFlipX = !char.originalFlipX;
			char.flipX = char.originalFlipX;
			if (char.isPlayer)
				char.flipX = !char.flipX;

			if (ghostChar != null)
				ghostChar.flipX = char.flipX;
		};

		noAntialiasingCheckBox = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, null, null, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = char.noAntialiasing;
		noAntialiasingCheckBox.callback = function()
		{
			char.antialiasing = false;
			if (!noAntialiasingCheckBox.checked && ClientPrefs.data.globalAntialiasing)
			{
				char.antialiasing = true;
			}
			char.noAntialiasing = noAntialiasingCheckBox.checked;
			if (ghostChar != null)
				ghostChar.antialiasing = char.antialiasing;
		};

		positionXStepper = new FlxUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, char.positionArray[0], -9000, 9000, 0);
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, char.positionArray[1], -9000, 9000, 0);

		positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, char.cameraPosition[0], -9000, 9000, 0);
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, char.cameraPosition[1], -9000, 9000, 0);

		var saveCharacterButton:FlxButton = new FlxButton(reloadImage.x, noAntialiasingCheckBox.y + 40, "Save Character", function()
		{
			saveCharacter();
		});

		healthColorStepperR = new FlxUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, char.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new FlxUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, char.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new FlxUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, char.healthColorArray[2], 0, 255, 0);

		tab_group.add(new FlxText(15, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 0, 'Health icon name:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 0, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Camera X/Y:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 0, 'Health bar R/G/B:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);
		tab_group.add(saveCharacterButton);
		UI_characterbox.addGroup(tab_group);
	}

	var minimumHealthStepper:FlxUINumericStepper;
	var drainAmountStepper:FlxUINumericStepper;
	var healthDrainCheckBox:FlxUICheckBox;

	var shakeIntensityStepper:FlxUINumericStepper;
	var shakeDurationStepper:FlxUINumericStepper;
	var shakeScreenBox:FlxUICheckBox;

	var trailLengthStepper:FlxUINumericStepper;
	var trailDelayStepper:FlxUINumericStepper;
	var trailAlphaStepper:FlxUINumericStepper;
	var trailDiffStepper:FlxUINumericStepper;
	var flixelTrailCheckBox:FlxUICheckBox;

	var scareBFCheckBox:FlxUICheckBox;
	var scareGFCheckBox:FlxUICheckBox;
	var noteskinInputText:FlxUIInputText;
	var floatingCheckBox:FlxUICheckBox;
	var floatingMagnitudeStepper:FlxUINumericStepper;
	var orbitCheckBox:FlxUICheckBox;

	function addMiscUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Misc";

		healthDrainCheckBox = new FlxUICheckBox(15, 30, null, null, "Health Drain", 50);
		healthDrainCheckBox.checked = char.healthDrain;
		healthDrainCheckBox.callback = function()
		{
			char.healthDrain = healthDrainCheckBox.checked;
		};

		minimumHealthStepper = new FlxUINumericStepper(healthDrainCheckBox.x + 80, healthDrainCheckBox.y, 0.01, char.drainFloor, -1, 2, 3);
		drainAmountStepper = new FlxUINumericStepper(minimumHealthStepper.x + 90, healthDrainCheckBox.y, 0.005, char.drainAmount, 0, 2, 3);

		shakeScreenBox = new FlxUICheckBox(healthDrainCheckBox.x, healthDrainCheckBox.y + 40, null, null, "Shake Screen", 50);
		shakeScreenBox.checked = char.shakeScreen;
		shakeScreenBox.callback = function()
		{
			char.shakeScreen = shakeScreenBox.checked;
		};

		shakeIntensityStepper = new FlxUINumericStepper(shakeScreenBox.x + 80, shakeScreenBox.y, 0.0005, char.shakeIntensity, 0, 1, 4);
		shakeDurationStepper = new FlxUINumericStepper(shakeIntensityStepper.x + 90, shakeScreenBox.y, 0.01, char.shakeDuration, 0, 1, 4);

		flixelTrailCheckBox = new FlxUICheckBox(shakeScreenBox.x, shakeScreenBox.y + 40, null, null, "Trail", 50);
		flixelTrailCheckBox.checked = char.flixelTrail;
		flixelTrailCheckBox.callback = function()
		{
			char.flixelTrail = flixelTrailCheckBox.checked;
			if (ghostChar != null)
				ghostChar.flixelTrail = char.flixelTrail;
		};

		trailLengthStepper = new FlxUINumericStepper(flixelTrailCheckBox.x + 60, flixelTrailCheckBox.y, 1, 4, 1, 24, 1);
		Reflect.setProperty(trailLengthStepper, 'name', 'trailLengthStepper');
		trailDelayStepper = new FlxUINumericStepper(trailLengthStepper.x + 70, flixelTrailCheckBox.y, 1, 24, 0, 90, 1);
		Reflect.setProperty(trailDelayStepper, 'name', 'trailDelayStepper');
		trailAlphaStepper = new FlxUINumericStepper(trailDelayStepper.x + 70, flixelTrailCheckBox.y, 0.1, 0.3, 0, 1, 3);
		Reflect.setProperty(trailAlphaStepper, 'name', 'trailAlphaStepper');
		trailDiffStepper = new FlxUINumericStepper(trailAlphaStepper.x + 70, flixelTrailCheckBox.y, 0.05, 0.069, 0, 1, 4);
		Reflect.setProperty(trailDiffStepper, 'name', 'trailDiffStepper');

		scareBFCheckBox = new FlxUICheckBox(15, flixelTrailCheckBox.y + 40, null, null, "Scare BF", 70);
		scareBFCheckBox.checked = char.scareBF;
		scareBFCheckBox.callback = function()
		{
			char.scareBF = scareBFCheckBox.checked;
		};

		scareGFCheckBox = new FlxUICheckBox(105, scareBFCheckBox.y, null, null, "Scare GF", 70);
		scareGFCheckBox.checked = char.scareGF;
		scareGFCheckBox.callback = function()
		{
			char.scareGF = scareGFCheckBox.checked;
		};

		noteskinInputText = new FlxUIInputText(15, scareBFCheckBox.y + 40, 100, char.noteskin != null ? char.noteskin : '', 8);
		floatingCheckBox = new FlxUICheckBox(130, noteskinInputText.y, null, null, "Floating", 60);
		floatingCheckBox.checked = char.floating;
		floatingCheckBox.callback = function()
		{
			char.floating = floatingCheckBox.checked;
		};

		floatingMagnitudeStepper = new FlxUINumericStepper(225, noteskinInputText.y, 0.1, char.floatingMagnitude, 0, 10, 2);
		Reflect.setProperty(floatingMagnitudeStepper, 'name', 'floatingMagnitudeStepper');
		orbitCheckBox = new FlxUICheckBox(15, noteskinInputText.y + 40, null, null, "Orbit", 60);
		orbitCheckBox.checked = char.orbit;
		orbitCheckBox.callback = function()
		{
			char.orbit = orbitCheckBox.checked;
		};

		tab_group.add(healthDrainCheckBox);
		tab_group.add(minimumHealthStepper);
		tab_group.add(drainAmountStepper);

		tab_group.add(shakeScreenBox);
		tab_group.add(shakeIntensityStepper);
		tab_group.add(shakeDurationStepper);

		tab_group.add(flixelTrailCheckBox);
		tab_group.add(trailLengthStepper);
		tab_group.add(trailDelayStepper);
		tab_group.add(trailAlphaStepper);
		tab_group.add(trailDiffStepper);
		tab_group.add(scareBFCheckBox);
		tab_group.add(scareGFCheckBox);
		tab_group.add(noteskinInputText);
		tab_group.add(floatingCheckBox);
		tab_group.add(floatingMagnitudeStepper);
		tab_group.add(orbitCheckBox);

		tab_group.add(new FlxText(minimumHealthStepper.x, minimumHealthStepper.y - 18, 0, 'Minimum Health:'));
		tab_group.add(new FlxText(drainAmountStepper.x, drainAmountStepper.y - 18, 0, 'Drain Amount:'));

		tab_group.add(new FlxText(shakeIntensityStepper.x, shakeIntensityStepper.y - 18, 0, 'Shake Intensity:'));
		tab_group.add(new FlxText(shakeDurationStepper.x, shakeDurationStepper.y - 18, 0, 'Shake Duration:'));

		tab_group.add(new FlxText(trailLengthStepper.x, trailLengthStepper.y - 18, 0, 'Trail Length:'));
		tab_group.add(new FlxText(trailDelayStepper.x, trailDelayStepper.y - 18, 0, 'Trail Delay:'));
		tab_group.add(new FlxText(trailAlphaStepper.x, trailAlphaStepper.y - 18, 0, 'Trail Alpha:'));
		tab_group.add(new FlxText(trailDiffStepper.x, trailDiffStepper.y - 18, 0, 'Trail Diff:'));
		tab_group.add(new FlxText(noteskinInputText.x, noteskinInputText.y - 18, 0, 'Noteskin:'));
		tab_group.add(new FlxText(floatingMagnitudeStepper.x, floatingMagnitudeStepper.y - 18, 0, 'Float Magnitude:'));

		for (i in tab_group.members)
			i.cameras = [camMenu];

		UI_characterbox.addGroup(tab_group);
	}

	var ghostDropDown:FlxUIDropDownMenuCustom;
	var animationDropDown:FlxUIDropDownMenuCustom;
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationNameFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;

	function addAnimationsUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Animations";

		animationInputText = new FlxUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationNameFramerate = new FlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, null, null, "Should it Loop?", 100);

		animationDropDown = new FlxUIDropDownMenuCustom(15, animationInputText.y - 55, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true),
			function(pressed:String)
			{
				var selectedAnimation:Int = Std.parseInt(pressed);
				var anim:AnimArray = char.animationsArray[selectedAnimation];
				animationInputText.text = anim.anim;
				animationNameInputText.text = anim.name;
				animationLoopCheckBox.checked = anim.loop;
				animationNameFramerate.value = anim.fps;

				var indicesStr:String = anim.indices.toString();
				animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
			});

		ghostDropDown = new FlxUIDropDownMenuCustom(animationDropDown.x + 150, animationDropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true),
			function(pressed:String)
			{
				var selectedAnimation:Int = Std.parseInt(pressed);
				if (ghostChar != null)
				{
					ghostChar.visible = false;
					char.alpha = 1;
					if (selectedAnimation > 0)
					{
						ghostChar.visible = true;
						ghostChar.playAnim(ghostChar.animationsArray[selectedAnimation - 1].anim, true);
						char.alpha = 0.85;
					}
				}
			});

		var addUpdateButton:FlxButton = new FlxButton(70, animationIndicesInputText.y + 30, "Add/Update", function()
		{
			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
			if (indicesStr.length > 1)
			{
				for (i in 0...indicesStr.length)
				{
					var index:Int = Std.parseInt(indicesStr[i]);
					if (indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1)
					{
						indices.push(index);
					}
				}
			}

			var lastOffsets:Array<Int> = [0, 0];
			for (anim in char.animationsArray)
			{
				if (animationInputText.text == anim.anim)
				{
					lastOffsets = anim.offsets;
					if (char.animOffsets.exists(animationInputText.text))
					{
						if (!char.isAnimateAtlas)
							char.animation.remove(animationInputText.text);
						#if flxanimate
						else
							@:privateAccess char.atlas.anim.animsMap.remove(animationInputText.text);
						#end
					}
					char.animationsArray.remove(anim);
				}
			}

			var addedAnim:AnimArray = {
				anim: animationInputText.text,
				name: animationNameInputText.text,
				fps: Math.round(animationNameFramerate.value),
				loop: animationLoopCheckBox.checked,
				indices: indices,
				offsets: lastOffsets
			};
			addAnimation(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop, addedAnim.indices);
			char.animationsArray.push(addedAnim);

			reloadAnimList();
			curAnim = Std.int(Math.max(0, char.animationsArray.indexOf(addedAnim)));
			char.playAnim(addedAnim.anim, true);
		});

		var removeButton:FlxButton = new FlxButton(180, animationIndicesInputText.y + 30, "Remove", function()
		{
			for (anim in char.animationsArray)
			{
				if (animationInputText.text == anim.anim)
				{
					var resetAnim:Bool = false;
					if (anim.anim == char.getAnimationName())
						resetAnim = true;
					if (char.hasAnimation(anim.anim))
					{
						if (!char.isAnimateAtlas)
							char.animation.remove(anim.anim);
						#if flxanimate
						else
							@:privateAccess char.atlas.anim.animsMap.remove(anim.anim);
						#end
						char.animOffsets.remove(anim.anim);
						char.animationsArray.remove(anim);
					}

					if (resetAnim && char.animationsArray.length > 0)
					{
						curAnim = FlxMath.wrap(curAnim, 0, char.animationsArray.length - 1);
						char.playAnim(char.animationsArray[curAnim].anim, true);
					}
					reloadAnimList();
					break;
				}
			}
		});

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(ghostDropDown.x, ghostDropDown.y - 18, 0, 'Animation Ghost:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationNameFramerate.x, animationNameFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation on .XML/.TXT file:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationNameFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(ghostDropDown);
		tab_group.add(animationDropDown);

		UI_characterbox.addGroup(tab_group);
	}

	function reloadCharacterImage()
	{
		var lastAnim:String = char.getAnimationName();
		var anims:Array<AnimArray> = char.animationsArray.copy();

		#if flxanimate
		char.atlas = FlxDestroyUtil.destroy(char.atlas);
		#end
		char.isAnimateAtlas = false;
		char.color = FlxColor.WHITE;
		char.alpha = 1;

		#if flxanimate
		if (Paths.fileExists('images/' + char.imageFile + '/Animation.json'))
		{
			char.atlas = new FlxAnimate();
			char.atlas.showPivot = false;
			try
			{
				Paths.loadAnimateAtlas(char.atlas, char.imageFile);
			}
			catch (e:Dynamic)
			{
				FlxG.log.warn('Could not load atlas ${char.imageFile}: $e');
			}
			char.isAnimateAtlas = true;
		}
		else
		#end
		if (Paths.fileExists('images/' + char.imageFile + '.txt'))
			char.frames = Paths.getPackerAtlas(char.imageFile);
		else if (Paths.fileExists('images/' + char.imageFile + '.json'))
			char.frames = Paths.getAsepriteAtlas(char.imageFile);
		else if (Paths.fileExists('images/' + char.imageFile + '.png'))
		{
			var split:Array<String> = char.imageFile.split(',');
			var charFrames:FlxAtlasFrames = Paths.getAtlas(split[0].trim());

			if (split.length > 1)
			{
				var original:FlxAtlasFrames = charFrames;
				charFrames = new FlxAtlasFrames(charFrames.parent);
				charFrames.addAtlas(original, true);
				for (i in 1...split.length)
				{
					var extraFrames:FlxAtlasFrames = Paths.getAtlas(split[i].trim());
					if (extraFrames != null)
						charFrames.addAtlas(extraFrames, true);
				}
			}
			char.frames = charFrames;
		}
		else
			char.frames = Paths.getSparrowAtlas(char.imageFile);

		for (anim in anims)
		{
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop;
			var animIndices:Array<Int> = anim.indices;
			addAnimation(animAnim, animName, animFps, animLoop, animIndices);
		}

		if (anims.length > 0)
		{
			if (lastAnim != null && lastAnim != '')
				char.playAnim(lastAnim, true);
			else
				char.dance();
		}

		if (ghostDropDown != null)
			ghostDropDown.selectedLabel = '';
		reloadGhost();
	}

	function addAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>)
	{
		if (!char.isAnimateAtlas)
		{
			if (indices != null && indices.length > 0)
				char.animation.addByIndices(anim, name, indices, "", fps, loop);
			else
				char.animation.addByPrefix(anim, name, fps, loop);
		}
		#if flxanimate
		else
		{
			if (indices != null && indices.length > 0)
				char.atlas.anim.addBySymbolIndices(anim, name, indices, fps, loop);
			else
				char.atlas.anim.addBySymbol(anim, name, fps, loop);
		}
		#end

		if (!char.animOffsets.exists(anim))
			char.addOffset(anim, 0, 0);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == noteskinInputText)
			{
				char.noteskin = noteskinInputText.text;
			}
			else if (sender == healthIconInputText)
			{
				leHealthIcon.changeIcon(healthIconInputText.text);
				char.healthIcon = healthIconInputText.text;
				updatePresence();
			}
			else if (sender == imageInputText)
			{
				char.imageFile = imageInputText.text;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var stepperName:String = Reflect.getProperty(sender, 'name');
			if (sender == scaleStepper || stepperName == 'scaleStepper')
			{
				reloadCharacterImage();
				char.jsonScale = sender.value;
				char.scale.set(char.jsonScale, char.jsonScale);
				char.updateHitbox();
				if (ghostChar != null)
				{
					ghostChar.scale.set(char.jsonScale, char.jsonScale);
					ghostChar.updateHitbox();
					reloadGhost();
				}
				updatePointerPos();
			}
			else if (sender == positionXStepper)
			{
				char.positionArray[0] = positionXStepper.value;
				char.x = char.positionArray[0] + OFFSET_X + 100;
				updatePointerPos();
			}
			else if (sender == singDurationStepper)
			{
				char.singDuration = singDurationStepper.value;
			}
			else if (sender == positionYStepper)
			{
				char.positionArray[1] = positionYStepper.value;
				char.y = char.positionArray[1];
				updatePointerPos();
			}
			else if (sender == positionCameraXStepper)
			{
				char.cameraPosition[0] = positionCameraXStepper.value;
				updatePointerPos();
			}
			else if (sender == positionCameraYStepper)
			{
				char.cameraPosition[1] = positionCameraYStepper.value;
				updatePointerPos();
			}
			else if (sender == drainAmountStepper)
			{
				char.drainAmount = drainAmountStepper.value;
			}
			else if (sender == minimumHealthStepper)
			{
				char.drainFloor = minimumHealthStepper.value;
			}
			else if (sender == shakeIntensityStepper)
			{
				char.shakeIntensity = shakeIntensityStepper.value;
			}
			else if (sender == shakeDurationStepper)
			{
				char.shakeDuration = shakeDurationStepper.value;
			}
			else if (sender == healthColorStepperR)
			{
				char.healthColorArray[0] = Math.round(healthColorStepperR.value);
				resetHealthBarColor();
			}
			else if (sender == healthColorStepperG)
			{
				char.healthColorArray[1] = Math.round(healthColorStepperG.value);
				resetHealthBarColor();
			}
			else if (sender == healthColorStepperB)
			{
				char.healthColorArray[2] = Math.round(healthColorStepperB.value);
				resetHealthBarColor();
			}
			else if (stepperName == 'trailLengthStepper')
			{
				char.trailLength = Std.int(sender.value);
				if (ghostChar != null)
					ghostChar.trailLength = char.trailLength;
			}
			else if (stepperName == 'trailDelayStepper')
			{
				char.trailDelay = Std.int(sender.value);
				if (ghostChar != null)
					ghostChar.trailDelay = char.trailDelay;
			}
			else if (stepperName == 'trailAlphaStepper')
			{
				char.trailAlpha = sender.value;
				if (ghostChar != null)
					ghostChar.trailAlpha = char.trailAlpha;
			}
			else if (stepperName == 'trailDiffStepper')
			{
				char.trailDiff = sender.value;
				if (ghostChar != null)
					ghostChar.trailDiff = char.trailDiff;
			}
			else if (stepperName == 'floatingMagnitudeStepper')
			{
				char.floatingMagnitude = sender.value;
			}
		}
	}

	function updatePointerPos()
	{
		if (char == null || cameraFollowPointer == null)
			return;

		var offX:Float = 0;
		var offY:Float = 0;
		if (!char.isPlayer)
		{
			offX = char.getMidpoint().x + 150 + char.cameraPosition[0];
			offY = char.getMidpoint().y - 100 + char.cameraPosition[1];
		}
		else
		{
			offX = char.getMidpoint().x - 100 - char.cameraPosition[0];
			offY = char.getMidpoint().y - 100 + char.cameraPosition[1];
		}
		cameraFollowPointer.setPosition(offX, offY);
	}

	function genBoyOffsets():Void
	{
		var daLoop:Int = 0;

		var i:Int = dumbTexts.members.length - 1;
		while (i >= 0)
		{
			var memb:FlxText = dumbTexts.members[i];
			if (memb != null)
			{
				memb.kill();
				dumbTexts.remove(memb);
				memb.destroy();
			}
			--i;
		}
		dumbTexts.clear();

		for (anim => offsets in char.animOffsets)
		{
			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, anim + ": " + offsets, 15);
			text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.borderSize = 1;
			text.scrollFactor.set();
			text.cameras = [camHUD];
			dumbTexts.add(text);

			daLoop++;
		}

		textAnim.text = char.animationsArray.length > 0 ? char.animationsArray[curAnim].anim : '';
		if (dumbTexts.length > 0 && dumbTexts.members[curAnim] != null)
		{
			dumbTexts.members[curAnim].color = FlxColor.YELLOW;
		}
	}

	function reloadAnimList()
	{
		if (char.animationsArray.length > 0)
		{
			curAnim = 0;
			char.playAnim(char.animationsArray[0].anim, true);
		}
		genBoyOffsets();
		if (animationDropDown != null)
			reloadAnimationDropDown();
	}

	function reloadAnimationDropDown()
	{
		var anims:Array<String> = [];
		var ghostAnims:Array<String> = [''];
		for (anim in char.animationsArray)
		{
			anims.push(anim.anim);
			ghostAnims.push(anim.anim);
		}
		if (anims.length < 1)
			anims.push('NO ANIMATIONS');

		if (animationDropDown != null)
			animationDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(anims, true));
		if (ghostDropDown != null)
		{
			ghostDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(ghostAnims, true));
			reloadGhost();
		}
	}

	function reloadGhost()
	{
		if (ghostChar == null)
			return;

		ghostChar.frames = char.frames;
		for (anim in char.animationsArray)
		{
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop;
			var animIndices:Array<Int> = anim.indices;
			if (animIndices != null && animIndices.length > 0)
			{
				ghostChar.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
			}
			else
			{
				ghostChar.animation.addByPrefix(animAnim, animName, animFps, animLoop);
			}

			if (anim.offsets != null && anim.offsets.length > 1)
			{
				ghostChar.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			}
		}

		if (ghostDropDown != null && ghostDropDown.selectedLabel != null && ghostDropDown.selectedLabel != '')
		{
			ghostChar.visible = true;
			char.alpha = 0.85;
		}
		else
		{
			ghostChar.visible = false;
			char.alpha = 1;
		}

		ghostChar.color = 0xFF666688;
		ghostChar.antialiasing = char.antialiasing;
	}

	function reloadCharacterDropDown()
	{
		#if MODS_ALLOWED
		characterList = Mods.mergeAllTextsNamed('characterList.txt', Paths.getPreloadPath());
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getPreloadPath(), 'characters/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if (file.toLowerCase().endsWith('.json'))
				{
					var charToCheck:String = file.substr(0, file.length - 5);
					if (!characterList.contains(charToCheck))
						characterList.push(charToCheck);
				}
		#end

		if (characterList.length < 1)
			characterList.push('');
		charDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(characterList, true));
		charDropDown.selectedLabel = daAnim;
	}

	function reloadCharacterOptions()
	{
		if (UI_characterbox != null)
		{
			imageInputText.text = char.imageFile;
			healthIconInputText.text = char.healthIcon;
			singDurationStepper.value = char.singDuration;
			scaleStepper.value = char.jsonScale;
			flipXCheckBox.checked = char.originalFlipX;
			noAntialiasingCheckBox.checked = char.noAntialiasing;
			resetHealthBarColor();
			leHealthIcon.changeIcon(healthIconInputText.text);
			positionXStepper.value = char.positionArray[0];
			positionYStepper.value = char.positionArray[1];
			positionCameraXStepper.value = char.cameraPosition[0];
			positionCameraYStepper.value = char.cameraPosition[1];

			if (trailLengthStepper != null)
				trailLengthStepper.value = char.trailLength;
			if (trailDelayStepper != null)
				trailDelayStepper.value = char.trailDelay;
			if (trailAlphaStepper != null)
				trailAlphaStepper.value = char.trailAlpha;
			if (trailDiffStepper != null)
				trailDiffStepper.value = char.trailDiff;
			if (flixelTrailCheckBox != null)
				flixelTrailCheckBox.checked = char.flixelTrail;
			if (scareBFCheckBox != null)
				scareBFCheckBox.checked = char.scareBF;
			if (scareGFCheckBox != null)
				scareGFCheckBox.checked = char.scareGF;
			if (noteskinInputText != null)
				noteskinInputText.text = char.noteskin != null ? char.noteskin : '';
			if (floatingCheckBox != null)
				floatingCheckBox.checked = char.floating;
			if (floatingMagnitudeStepper != null)
				floatingMagnitudeStepper.value = char.floatingMagnitude;
			if (orbitCheckBox != null)
				orbitCheckBox.checked = char.orbit;

			reloadAnimationDropDown();
			updatePresence();
			shakeScreenBox.checked = char.shakeScreen;
			shakeIntensityStepper.value = char.shakeIntensity;
			shakeDurationStepper.value = char.shakeDuration;
			healthDrainCheckBox.checked = char.healthDrain;
			drainAmountStepper.value = char.drainAmount;
			minimumHealthStepper.value = char.drainFloor;
		}
	}

	function resetHealthBarColor()
	{
		healthColorStepperR.value = char.healthColorArray[0];
		healthColorStepperG.value = char.healthColorArray[1];
		healthColorStepperB.value = char.healthColorArray[2];
		healthBar.leftBar.color = healthBar.rightBar.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
	}

	function updatePresence()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Character Editor", "Character: " + daAnim, leHealthIcon.getCharacter());
		#end
	}

	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;

	override function update(elapsed:Float)
	{
		MusicBeatState.camBeat = FlxG.camera;

		var inputTexts:Array<FlxUIInputText> = [
			animationInputText,
			imageInputText,
			healthIconInputText,
			noteskinInputText,
			animationNameInputText,
			animationIndicesInputText
		];
		for (i in 0...inputTexts.length)
		{
			if (inputTexts[i].hasFocus)
			{
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				super.update(elapsed);
				return;
			}
		}

		FlxG.sound.muteKeys = Main.muteKeys;
		FlxG.sound.volumeDownKeys = Main.volumeDownKeys;
		FlxG.sound.volumeUpKeys = Main.volumeUpKeys;

		if (FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0) && char.animationsArray.length > 0)
		{
			char.animationsArray[curAnim].offsets[0] -= FlxG.mouse.deltaScreenX;
			char.animationsArray[curAnim].offsets[1] -= FlxG.mouse.deltaScreenY;
			char.offset.x -= FlxG.mouse.deltaScreenX;
			char.offset.y -= FlxG.mouse.deltaScreenY;

			char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
			genBoyOffsets();
		}

		if (!charDropDown.dropPanel.visible)
		{
			if (FlxG.keys.justPressed.ESCAPE)
			{
				if (goToPlayState)
				{
					MusicBeatState.switchState(new PlayState());
				}
				else
				{
					MusicBeatState.switchState(new MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
				FlxG.mouse.visible = false;
				return;
			}

			if (FlxG.keys.justPressed.R)
			{
				FlxG.camera.zoom = 1;
			}

			var shiftMult:Float = 1;
			if (FlxG.keys.pressed.SHIFT)
			{
				shiftMult = 4;
			}

			if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3)
			{
				FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult;
				if (FlxG.camera.zoom > 3)
					FlxG.camera.zoom = 3;
			}
			if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1)
			{
				FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult;
				if (FlxG.camera.zoom < 0.1)
					FlxG.camera.zoom = 0.1;
			}

			if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
			{
				var addToCam:Float = 500 * elapsed * shiftMult;

				if (FlxG.keys.pressed.I)
					camFollow.y -= addToCam;
				else if (FlxG.keys.pressed.K)
					camFollow.y += addToCam;

				if (FlxG.keys.pressed.J)
					camFollow.x -= addToCam;
				else if (FlxG.keys.pressed.L)
					camFollow.x += addToCam;
			}

			var txt = 'ERROR: No Animation Found';
			var clr = FlxColor.RED;

			if (char.animationsArray.length > 0)
			{
				if (FlxG.keys.pressed.A || FlxG.keys.pressed.D)
				{
					holdingFrameTime += elapsed;
					if (holdingFrameTime > 0.5)
						holdingFrameElapsed += elapsed;
				}
				else
					holdingFrameTime = 0;

				if (FlxG.keys.justPressed.W)
					curAnim--;
				else if (FlxG.keys.justPressed.S)
					curAnim++;

				if (curAnim < 0)
					curAnim = char.animationsArray.length - 1;

				if (curAnim >= char.animationsArray.length)
					curAnim = 0;

				if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
				{
					char.playAnim(char.animationsArray[curAnim].anim, true);
					genBoyOffsets();
				}
				if (FlxG.keys.justPressed.T)
				{
					char.animationsArray[curAnim].offsets = [0, 0];

					char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
					genBoyOffsets();
				}

				var controlArray:Array<Bool> = [
					FlxG.keys.justPressed.LEFT,
					FlxG.keys.justPressed.RIGHT,
					FlxG.keys.justPressed.UP,
					FlxG.keys.justPressed.DOWN
				];

				for (i in 0...controlArray.length)
				{
					if (controlArray[i])
					{
						var holdShift = FlxG.keys.pressed.SHIFT;
						var multiplier = holdShift ? 10 : 1;

						var arrayVal = (i > 1) ? 1 : 0;
						var negaMult:Int = (i % 2 == 1) ? -1 : 1;

						char.animationsArray[curAnim].offsets[arrayVal] += negaMult * multiplier;
						char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);

						char.playAnim(char.animationsArray[curAnim].anim, false);
						genBoyOffsets();
					}
				}

				var frames:Int = -1;
				var length:Int = -1;

				if (!char.isAnimateAtlas && char.animation.curAnim != null)
				{
					frames = char.animation.curAnim.curFrame;
					length = char.animation.curAnim.numFrames;
				}
				#if flxanimate
				else if (char.isAnimateAtlas && char.atlas.anim != null)
				{
					frames = char.atlas.anim.curFrame;
					length = char.atlas.anim.length;
				}
				#end

				if (length >= 0)
				{
					if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || holdingFrameTime > 0.5)
					{
						var isLeft = false;
						if ((holdingFrameTime > 0.5 && FlxG.keys.pressed.A) || FlxG.keys.justPressed.A)
							isLeft = true;
						char.animPaused = true;

						if (holdingFrameTime <= 0.5 || holdingFrameElapsed > 0.1)
						{
							frames = FlxMath.wrap(frames + Std.int(isLeft ? -shiftMult : shiftMult), 0, length - 1);
							if (!char.isAnimateAtlas)
								char.animation.curAnim.curFrame = frames;
							#if flxanimate
							else
								char.atlas.anim.curFrame = frames;
							#end
							holdingFrameElapsed -= 0.1;
						}
					}

					txt = 'Frames: ( $frames / ${length - 1} )';
					clr = FlxColor.WHITE;
				}
			}
			if (txt != frameAdvanceText.text)
				frameAdvanceText.text = txt;
			frameAdvanceText.color = clr;
		}

		if (ghostChar != null)
			ghostChar.setPosition(char.x, char.y);

		if (FlxG.mouse.justPressedRight)
		{
			lastPosition.set(CoolUtil.boundTo(FlxG.mouse.getScreenPosition().x, 0, FlxG.width),
				CoolUtil.boundTo(FlxG.mouse.getScreenPosition().y, 0, FlxG.height));
		}

		if (FlxG.mouse.pressedRight)
		{
			FlxG.mouse.visible = false;

			mouseDiff.set(lastPosition.x - FlxG.mouse.getScreenPosition().x, lastPosition.y - FlxG.mouse.getScreenPosition().y);

			if (FlxG.mouse.justMoved)
			{
				var mult:Float = FlxG.keys.pressed.SHIFT ? 4 : 1;

				camFollow.x += mouseDiff.x * mult;
				camFollow.y += mouseDiff.y * mult;

				lastPosition.set(CoolUtil.boundTo(FlxG.mouse.getScreenPosition().x, 0, FlxG.width),
					CoolUtil.boundTo(FlxG.mouse.getScreenPosition().y, 0, FlxG.height));
			}
		}
		else
		{
			FlxG.mouse.visible = true;
		}

		if (FlxG.mouse.wheel != 0)
		{
			FlxG.camera.zoom += FlxG.mouse.wheel / 10;
			FlxG.camera.zoom = CoolUtil.boundTo(FlxG.camera.zoom, 0.1, 3);
		}

		super.update(elapsed);
	}

	var _file:FileReference;

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveCharacter()
	{
		var json = {
			"animations": char.animationsArray,
			"image": char.imageFile,
			"scale": char.jsonScale,
			"sing_duration": char.singDuration,
			"healthicon": char.healthIcon,

			"position": char.positionArray,
			"camera_position": char.cameraPosition,

			"flip_x": char.originalFlipX,
			"no_antialiasing": char.noAntialiasing,
			"healthbar_colors": char.healthColorArray,

			"health_drain": char.healthDrain,
			"drain_amount": char.drainAmount,
			"drain_floor": char.drainFloor,

			"shake_screen": char.shakeScreen,
			"shake_intensity": char.shakeIntensity,
			"shake_duration": char.shakeDuration,

			"flixel_trail": char.flixelTrail,
			"trail_length": char.trailLength,
			"trail_delay": char.trailDelay,
			"trail_alpha": char.trailAlpha,
			"trail_diff": char.trailDiff,

			"scare_bf": char.scareBF,
			"scare_gf": char.scareGF,
			"noteskin": char.noteskin,
			"floating": char.floating,
			"floating_magnitude": char.floatingMagnitude,
			"orbit": char.orbit
		};

		var data:String = Json.stringify(json, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, daAnim + ".json");
		}
	}
}
