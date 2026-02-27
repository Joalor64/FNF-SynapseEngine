package states;

class ScriptedState extends MusicBeatState
{
	public var path:String = '';
	public var script:FunkinHScript = null;

	public static var instance:ScriptedState = null;

	public function new(_path:String = null, ?args:Array<Dynamic>):Void
	{
		if (_path != null)
			path = _path;

		instance = this;

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

            	scriptSet('state', this);
            	scriptSet('add', this.add);
            	scriptSet('insert', this.insert);
            	scriptSet('remove', this.remove);
            	scriptSet('members', this.members);
            	scriptSet('openSubState', openSubState);
        	} else {
            	trace('Could not find script for: $path');
        	}
		}
		catch (e:Dynamic)
		{
			script = null;
			trace('Error while getting script: $path!\n$e');
		}

		super();

		if (script != null)
			scriptExecute('new', args);
	}

	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		scriptExecute('create', []);
		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		scriptExecute('update', [elapsed]);
		super.update(elapsed);

		if (FlxG.keys.justPressed.F4) // emergency exit
			FlxG.switchState(new MainMenuState());
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
		script?.setVariable(key, value);
	}

	public function scriptExecute(func:String, args:Array<Dynamic>):Void
	{
		try
		{
			script?.executeFunc(func, args);
		}
		catch (e:Dynamic)
		{
			trace('Error executing $func!\n$e');
		}
	}
}