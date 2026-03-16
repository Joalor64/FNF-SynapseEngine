import backend.AutoUpdater;

class InitState extends FlxState
{
	override function create():Void
	{
		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = Main.muteKeys;
		FlxG.sound.volumeDownKeys = Main.volumeDownKeys;
		FlxG.sound.volumeUpKeys = Main.volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		Controls.instance = new Controls();

		ClientPrefs.loadDefaultKeys();
		ClientPrefs.loadPrefs();
		Colorblind.updateFilter();

		#if ACHIEVEMNTS_ALLOWED
		Achievements.init();
		#end

		Highscore.load();

		if (FlxG.save.data != null && FlxG.save.data.fullscreen)
			FlxG.fullscreen = FlxG.save.data.fullscreen;

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end

		Mods.loadTheFirstEnabledMod();

		#if CHECK_FOR_UPDATES
		if (ClientPrefs.data.checkForUpdates && !WarningState.leftState)
			AutoUpdater.checkForUpdates();
		#end

		FlxG.mouse.visible = false;

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		if (FlxG.save.data.flashing == null && !WarningState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.switchState(new WarningState('flashing'));
		}
		else
		{
			if (AutoUpdater.mustUpdate && !WarningState.leftState)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				FlxG.switchState(new WarningState('outdated'));
			}
			else
				FlxG.switchState(new ScriptedState('TitleState', []));
		}
	}
}
