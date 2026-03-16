package options;

import options.Option;

class ModSettingsSubState extends BaseOptionsMenu
{
	var save:Map<String, Dynamic> = new Map<String, Dynamic>();
	var folder:String;
	private var _crashed:Bool = false;

	public function new(options:Array<Dynamic>, folder:String, name:String)
	{
		this.folder = folder;

		title = '';
		rpcTitle = 'Mod Settings ($name)';

		if (FlxG.save.data.modSettings == null)
			FlxG.save.data.modSettings = new Map<String, Dynamic>();

		var saveMap:Map<String, Dynamic> = FlxG.save.data.modSettings;
		if (saveMap.exists(folder))
		{
			save = saveMap.exists(folder) ? saveMap.get(folder) : new Map<String, Dynamic>();
		}

		try
		{
			for (option in options)
			{
				var newOption = new Option(option.name != null ? option.name : option.save,
					option.description != null ? option.description : 'No description provided.', option.save, convertType(option.type), option.options);

				if (newOption.defaultValue == 'null variable value' && option.value != null)
					newOption.defaultValue = option.value;

				@:privateAccess
				{
					newOption.getValue = function()
					{
						if (!save.exists(newOption.variable))
							return newOption.defaultValue;
						return save.get(newOption.variable);
					};
					newOption.setValue = function(value:Dynamic)
					{
						save.set(newOption.variable, value);
					};
				}

				if (option.format != null)
					newOption.displayFormat = option.format;
				if (option.min != null)
					newOption.minValue = option.min;
				if (option.max != null)
					newOption.maxValue = option.max;
				if (option.step != null)
					newOption.changeValue = option.step;
				if (option.scroll != null)
					newOption.scrollSpeed = option.scroll;
				if (option.decimals != null)
					newOption.decimals = option.decimals;

				var curVal = newOption.getValue();
				if (newOption.type == 'string')
				{
					var num:Int = newOption.options.indexOf(curVal);
					if (num > -1)
						newOption.curOption = num;
				}

				addOption(newOption);
			}
		}
		catch (e:Dynamic)
		{
			var errorTitle = 'Mod name: ' + folder;
			var errorMsg = 'An error occurred: $e';
			#if windows
			Application.current.window.alert(errorMsg, errorTitle);
			#end
			trace('$errorTitle - $errorMsg');

			_crashed = true;
			close();
			return;
		}

		super();

		bg.alpha = 0.75;
		bg.color = FlxColor.WHITE;
		reloadCheckboxes();
	}

	private function convertType(str:String):String
	{
		var input:String = str.toLowerCase().trim();
		switch (input)
		{
			case 'bool', 'boolean':
				return 'bool';
			case 'int', 'integer':
				return 'int';
			case 'float', 'fl':
				return 'float';
			case 'percent':
				return 'percent';
			case 'string', 'str':
				return 'string';
		}
		return 'bool';
	}

	override public function update(elapsed:Float)
	{
		if (_crashed)
		{
			close();
			return;
		}
		super.update(elapsed);
	}

	override public function close()
	{
		var saveMap:Map<String, Dynamic> = FlxG.save.data.modSettings;
		saveMap.set(folder, save);
		FlxG.save.data.modSettings = saveMap;
		FlxG.save.flush();
		super.close();
	}
}
