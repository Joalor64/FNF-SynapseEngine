package states;

class ScriptedState extends MusicBeatState
{
	public var path:String = '';
	public var script:FunkinHScript = null;
	public var scriptArgs:Array<Dynamic> = null;
	
	public var requestedState:FlxState = null;
	public var skipTransition:Bool = false;

	public static var instance:ScriptedState = null;

	public function new(_path:String = null, ?args:Array<Dynamic>):Void
	{
		if (_path != null)
			path = _path;
		scriptArgs = args;
		instance = this;

		super();

		loadScript();
	}

	function loadScript():Void
	{
		try
		{
			var folders:Array<String> = [Paths.getPath('states/')];
			#if MODS_ALLOWED
			folders.insert(0, Paths.mods('states/'));
			if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
				folders.insert(0, Paths.mods(Mods.currentModDirectory + '/states/'));

			for (mod in Mods.getGlobalMods())
				folders.insert(0, Paths.mods(mod + '/states/'));
			#end

			var foundPath:String = null;

			for (folder in folders)
			{
				if (FileSystem.exists(folder))
				{
					for (file in FileSystem.readDirectory(folder))
					{
						if (file.startsWith(path) && Paths.validScriptType(file))
						{
							foundPath = folder + file;
							break;
						}
					}
					if (foundPath != null) break;
				}
			}

			if (foundPath != null) {
				path = foundPath;
				script = new FunkinHScript(path, false);
				script.execute(path, false);
				trace('Script loaded: $path');
			} else {
				trace('Could not find script for: $path');
			}
		}
		catch (e:Dynamic)
		{
			script = null;
			trace('Error loading script: $path\n$e');
		}
	}

	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		super.create();

		if (script != null)
		{
			scriptSet('state', this);
			scriptSet('add', this.add);
			scriptSet('insert', this.insert);
			scriptSet('remove', this.remove);
			scriptSet('members', this.members);
			scriptSet('openSubState', openSubState);
			
			scriptSet('switchState', function(newState:FlxState, ?skipTrans:Bool = false) {
				requestedState = newState;
				skipTransition = skipTrans;
			});
			
			scriptSet('MusicBeatState', {
				switchState: function(s:FlxState) {
					requestedState = s;
					skipTransition = false;
				}
			});

			scriptExecute('new', scriptArgs);
			scriptExecute('create', []);
		}
	}

	override public function update(elapsed:Float):Void
	{
		try
		{
			scriptExecute('update', [elapsed]);
		}
		catch (e:Dynamic)
		{
			trace('Script update error: $e');
		}
	
		if (requestedState != null)
		{
			var target = requestedState;
			var skip = skipTransition;
			requestedState = null;
			skipTransition = false;
			
			if (skip) {
				FlxTransitionableState.skipNextTransIn = true;
				MusicBeatState.switchState(target);
			} else {
				deferStateSwitch(target);
			}
			return;
		
		super.update(elapsed);

		if (FlxG.keys.justPressed.F4) {
			deferStateSwitch(new MainMenuState());
		}
	}
	
	function deferStateSwitch(target:FlxState):Void
	{
		FlxG.signals.postUpdate.addOnce(function() {
			MusicBeatState.switchState(target);
		});
	}

	override public function beatHit():Void
	{
		scriptExecute('beatHit', [curBeat]);
		scriptSet('curBeat', curBeat);
		super.beatHit();
	}

	override public function stepHit():Void
	{
		scriptExecute('stepHit', [curStep]);
		scriptSet('curStep', curStep);
		super.stepHit();
	}

	override public function destroy():Void
	{
		scriptExecute('destroy', []);
		super.destroy();
	}

	override public function onFocus():Void
	{
		scriptExecute('onFocus', []);
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		scriptExecute('onFocusLost', []);
		super.onFocusLost();
	}

	override function openSubState(SubState:FlxSubState):Void
	{
		scriptExecute('openSubState', [SubState]);
		super.openSubState(SubState);
	}

	override function closeSubState():Void
	{
		scriptExecute('closeSubState', []);
		super.closeSubState();
	}

	public function scriptSet(key:String, value:Dynamic):Void
	{
		try
		{
			script?.setVariable(key, value);
		}
		catch (e:Dynamic)
		{
			trace('Error setting script variable $key: $e');
		}
	}

	public function scriptExecute(func:String, args:Array<Dynamic>):Void
	{
		try
		{
			script?.executeFunc(func, args);
		}
		catch (e:Dynamic)
		{
			trace('Error executing $func: $e');
		}
	}
}