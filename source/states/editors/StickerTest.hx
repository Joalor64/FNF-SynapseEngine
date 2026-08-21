package states.editors;

import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUI;

class StickerTest extends MusicBeatState
{
	private var stickerSet:String;
	private var stickerPack:String;
	private var stickerSubState:StickerSubState;

	var stickerSetInput:FlxUIInputText;
	var stickerPackInput:FlxUIInputText;

	public function new(?stickers:StickerSubState = null, set:String = "sticker-set-1", pack:String = "all")
	{
		stickerPack = pack;
		stickerSet = set;
		if (stickers != null)
		{
			stickerSubState = stickers;
		}
		super();
	}

	override function create()
	{
		FlxG.sound.music?.pause();
		FlxG.mouse.visible = true;

		if (stickerSubState != null)
		{
			openSubState(stickerSubState);
            Paths.clearStoredWithoutStickers();
			stickerSubState.degenStickers();
		}
		else
			Paths.clearStoredMemory();

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image("menuBG"));
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		add(bg);

		addEditorBox();
		super.create();
	}

	var UI_box:FlxUITabMenu;

	function addEditorBox()
	{
		var tabs = [{name: 'Sticker', label: 'Sticker'}];
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(250, 200);
		UI_box.x = FlxG.width - UI_box.width;
		UI_box.y = FlxG.height - UI_box.height;
		UI_box.scrollFactor.set();

		var tabGroup:FlxUI = new FlxUI(null, UI_box);
		tabGroup.name = "Sticker";
		tabGroup.x = 10;
		tabGroup.y = 30;

		stickerSetInput = new FlxUIInputText(10, 30, 100, stickerSet, 8);
		stickerPackInput = new FlxUIInputText(10, 80, 100, stickerPack, 8);

		var setLabel:FlxText = new FlxText(10, 15, 100, "Sticker set:");
		var packLabel:FlxText = new FlxText(10, 65, 100, "Sticker pack:");

		var playButton:FlxUIButton = new FlxUIButton(10, 120, "Play", function()
		{
			StickerSubState.STICKER_PACK = stickerPackInput.text;
			StickerSubState.STICKER_SET = stickerSetInput.text;
			openSubState(new StickerSubState(null, s -> new StickerTest(s, stickerSetInput.text, stickerPackInput.text)));
		});

		tabGroup.add(setLabel);
		tabGroup.add(stickerSetInput);
		tabGroup.add(packLabel);
		tabGroup.add(stickerPackInput);
		tabGroup.add(playButton);

		UI_box.addGroup(tabGroup);
		add(UI_box);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!stickerSetInput.hasFocus && !stickerPackInput.hasFocus)
		{
			if (controls.BACK)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}
	}
}
