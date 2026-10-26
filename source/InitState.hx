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

		#if LUA_ALLOWED
		Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call));
		#end

		Controls.instance = new Controls();

		ClientPrefs.loadDefaultKeys();
		ClientPrefs.loadPrefs();
		Language.reloadPhrases();
		Colorblind.updateFilter();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.init();
		#end

		Highscore.load();

		if (FlxG.save.data != null && FlxG.save.data.fullscreen)
			FlxG.fullscreen = FlxG.save.data.fullscreen;

		#if MODS_ALLOWED
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

		#if !CHECK_FOR_UPDATES
		goToNextState();
		#end
	}

	#if CHECK_FOR_UPDATES
	static inline var UPDATE_CHECK_WAIT:Float = 3;

	var waitedForUpdate:Float = 0;
	var leaving:Bool = false;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (leaving)
			return;

		waitedForUpdate += elapsed;
		if (!AutoUpdater.isChecking || waitedForUpdate >= UPDATE_CHECK_WAIT)
		{
			leaving = true;
			goToNextState();
		}
	}
	#end

	function goToNextState():Void
	{
		if (FlxG.save.data.flashing == null && !WarningState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.switchState(new WarningState('flashing'));
		}
		else if (AutoUpdater.mustUpdate && !WarningState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.switchState(new WarningState('outdated'));
		}
		else
			FlxG.switchState(new ScriptedState('TitleState', []));
	}
}
