package substates;

class ScriptedSubState extends MusicBeatSubstate
{
	public var tag:String = null;
	public var path:String = '';
	public var script:FunkinHScript = null;
	public var scriptArgs:Array<Dynamic> = null;

	public static var instance:ScriptedSubState = null;

	public function new(_path:String = null, ?args:Array<Dynamic>, ?_tag:String = null):Void
	{
		if (_path != null)
			path = _path;
		tag = _tag;
		scriptArgs = args;
		instance = this;

		super();

		loadScript();
	}

	function loadScript():Void
	{
		try
		{
			var folders:Array<String> = [Paths.getPath('substates/')];
			#if MODS_ALLOWED
			folders.insert(0, Paths.mods('substates/'));
			if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
				folders.insert(0, Paths.mods(Mods.currentModDirectory + '/substates/'));

			for (mod in Mods.getGlobalMods())
				folders.insert(0, Paths.mods(mod + '/substates/'));
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
					if (foundPath != null)
						break;
				}
			}

			if (foundPath != null)
			{
				path = foundPath;
				script = new FunkinHScript(path, false);
				script.execute(path, false);
				trace('Script loaded: $path');
			}
			else
			{
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
		super.create();

		if (script != null)
		{
			scriptSet('substate', this);
			scriptSet('add', this.add);
			scriptSet('insert', this.insert);
			scriptSet('remove', this.remove);
			scriptSet('members', this.members);

			scriptExecute('new', scriptArgs);
			scriptExecute('create', []);
		}
	}

	override public function update(elapsed:Float):Void
	{
		scriptExecute('update', [elapsed]);
		super.update(elapsed);
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

	public static function getSubStateByTag(tag:String):ScriptedSubState
	{
		if (FlxG.state.subState is ScriptedSubState)
		{
			var sub:ScriptedSubState = cast FlxG.state.subState;
			if (sub.tag == tag)
				return sub;
		}
		return null;
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

	public function scriptGet(key:String):Dynamic
	{
		try
		{
			return script?.getVariable(key);
		}
		catch (e:Dynamic)
		{
			trace('Error getting script variable $key: $e');
			return null;
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
