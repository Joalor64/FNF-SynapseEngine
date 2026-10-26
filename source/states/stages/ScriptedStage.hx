package states.stages;

import objects.Note.EventNote;
#if HSCRIPT_ALLOWED
import scripts.FunkinHScript;
#end

class ScriptedStage extends BaseStage
{
	#if HSCRIPT_ALLOWED
	public var script:FunkinHScript = null;
	#end

	public var scriptPath(default, null):String = null;

	var ownsScript:Bool = false;

	public static function tryLoad(stageName:String):ScriptedStage
	{
		#if HSCRIPT_ALLOWED
		var path:String = PlayState.findScriptFile('stages/' + stageName, Paths.HSCRIPT_EXT);
		if (path == null)
			return null;

		var stage:ScriptedStage = new ScriptedStage();
		if (!stage.load(path))
		{
			var state:MusicBeatState = MusicBeatState.getState();
			if (state != null)
				state.stages.remove(stage);
			stage.destroy();
			return null;
		}
		return stage;
		#else
		return null;
		#end
	}

	// idk this will be called in the script??
	override function create() {}

	#if HSCRIPT_ALLOWED
	function load(path:String):Bool
	{
		scriptPath = path;

		if (onPlayState && PlayState.instance != null)
		{
			script = PlayState.instance.addHScript(path, setupScript);
			return script != null;
		}

		script = new FunkinHScript(path, false);
		setupScript(script);
		script.execute(path);
		if (script.failedToLoad)
		{
			script.destroy();
			script = null;
			return false;
		}
		ownsScript = true;
		return true;
	}

	function setupScript(newScript:FunkinHScript):Void
	{
		newScript.setVariable('stage', this);
		if (onPlayState)
		{
			newScript.setVariable('addBehindGF', addBehindGF);
			newScript.setVariable('addBehindBF', addBehindBF);
			newScript.setVariable('addBehindDad', addBehindDad);
		}
		else
			newScript.setVariable('game', null);
	}

	override function destroy()
	{
		if (ownsScript && script != null)
		{
			script.executeFunc('destroy', []);
			script.destroy();
		}
		script = null;
		super.destroy();
	}

	override function eventPushed(event:EventNote)
		callStageScript('onEventPushed', event);

	override function eventPushedUnique(event:EventNote)
		callStageScript('onEventPushedUnique', event);

	function callStageScript(func:String, event:EventNote)
	{
		if (script != null && !script.closed)
			script.executeFunc(func, [event.event, event.value1, event.value2, event.strumTime]);
	}
	#end
}
