package states;

import backend.AutoUpdater;

class PreloadState extends FlxState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	override function create()
	{
		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		
		Mods.loadTheFirstEnabledMod();

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		PlayerSettings.init();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		#end

		ClientPrefs.loadPrefs();
		Colorblind.updateFilter();

		#if CHECK_FOR_UPDATES
		if (ClientPrefs.data.checkForUpdates && !WarningState.leftState)
			AutoUpdater.checkForUpdates();
		#end

		if (FlxG.save.data.weekCompleted != null)
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

		FlxG.mouse.visible = false;

		if (FlxG.save.data != null && FlxG.save.data.fullscreen)
			FlxG.fullscreen = FlxG.save.data.fullscreen;

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
