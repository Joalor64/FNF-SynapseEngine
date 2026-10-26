## Limitations
The following are not supported:
* Keywords:
    * `typedef`, `metadata`, `final`
* Wildcard imports (`import flixel.*`)
* Access modifiers (e.g., `private`, `public`)

## Default Variables
* `Function_Stop` - Cancels functions (e.g., `startCountdown`, `endSong`). One script returning it is enough, whether it's Lua or HScript.
* `Function_Continue` - Continues the game like normal.
* `Function_Halt` - Stops the remaining scripts from receiving the current callback.
* `version` - Returns the base game version (from `Project.xml`).
* `engineVersion` - Returns the Synapse Engine version.
* `BlendMode` - Blend mode constants (`BlendMode.ADD`, `BlendMode.MULTIPLY`, ...).

## Errors
Script errors show up in a small overlay at the bottom of the screen, and repeated errors are merged with a counter instead of spamming.
Errors while *loading* a script (syntax errors, missing files) also show a popup, but only once.

## Default Functions
* `trace(value:Dynamic)` - The equivalent of `trace` in normal Haxe.
* `importScript(source:String)` - Gives access to another script's local functions and variables.
* `addScript(path:String)` - Adds a new script during gameplay (PlayState).
* `stopScript()` - Stops the current script.

## Templates
### FlxSprite
```hx
import flixel.FlxSprite;

function onCreate() 
{
	var spr:FlxSprite = new FlxSprite(0, 0).makeGraphic(50, 50, FlxColor.BLACK);
	add(spr);
}
```

#### Animated Sprite
```hx
import flixel.FlxSprite;
import backend.Paths;

function onCreate() 
{
	var spr:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('banana'), true, 102, 103);
	spr.animation.add('rotate', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], 14);
	spr.animation.play('rotate');
	spr.screenCenter();
	add(spr);
}
```

### FlxText
```hx
import flixel.text.FlxText;

function onCreate() 
{
	var text:FlxText = new FlxText(0, 0, 0, "Hello World", 64);
	text.screenCenter();
	add(text);
}
```

### Parsing a JSON
```hx
import sys.FileSystem;
import sys.io.File;
import haxe.Json;

var json:Dynamic;

function onCreate() 
{
	if (FileSystem.exists('assets/data.json'))
		json = Json.parse(File.getContent('assets/data.json'));

	trace(json);
}
```

### Custom States/Substates
```hx
import states.ScriptedState;
import backend.MusicBeatState;
import substates.ScriptedSubState;
import flixel.text.FlxText;
import flixel.FlxSprite;

function create() 
{
	var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(1280, 720, FlxColor.WHITE);
	add(bg);

	var text:FlxText = new FlxText(0, 0, FlxG.width, "I am a custom state!", 48);
	text.color = FlxColor.BLACK;
	add(text);
}

function update(elapsed:Float) 
{
	if (controls.ACCEPT)
		MusicBeatState.switchState(new ScriptedState('name', [/* arguments, if any */])); // load custom state

	if (controls.BACK)
		openSubState(new ScriptedSubState('name', [/* arguments, if any */])); // load custom substate
}
```

### Scripted Stages
Put a script named after your stage in `stages/` (next to its `.json`), e.g. `stages/myStage.hx`.
If it exists, it's used instead of a hardcoded stage. The Week 1 stage (`assets/base_game/stages/stage.hx`) is an example.

```hx
import objects.BGSprite;

// runs before the characters are added
function create()
{
	var bg:BGSprite = new BGSprite('stages/myStage/bg', -600, -200, 0.9, 0.9);
	add(bg);
}

function onBeatHit(curBeat:Int)
{
	if (curBeat % 4 == 0)
		game.camGame.zoom += 0.015;
}

// runs once per event type found in the chart
function onEventPushed(name:String, value1:String, value2:String, strumTime:Float) {}

// runs for every single event in the chart
function onEventPushedUnique(name:String, value1:String, value2:String, strumTime:Float) {}
```

`stage` gives access to the stage helpers: `stage.addBehindGF(obj)`, `stage.addBehindBF(obj)`, `stage.addBehindDad(obj)`, `stage.setDefaultGF(name)`, `stage.setStartCallback(fn)`, `stage.setEndCallback(fn)`.

### Using Imported Scripts
Script 1:
```hx
// assets/helpers/spriteHandler.hxs
package helpers;

import flixel.FlxSprite;
import backend.Paths;

function createSprite(x:Float, y:Float, graphic:String) 
{
	var spr:FlxSprite = new FlxSprite(x, y);
	spr.loadGraphic(Paths.image(graphic));
	add(spr);

	trace("sprite " + graphic + " created");
}
```

Script 2:
```hx
var otherScript = importScript('helpers.spriteHandler');

function onCreate() {
	otherScript.createSprite(0, 0, 'sprite');
}
```

### Using a Custom Shader
```hx
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets;
import flixel.FlxG;
import backend.Paths;

var shader:FlxRuntimeShader;
var shader2:FlxRunTimeShader;

function onCreate() 
{
	shader = new FlxRuntimeShader(Assets.getText(Paths.shaderFragment('rain')), null);
	shader.setFloat('uTime', 0);
	shader.setFloatArray('uScreenResolution', [FlxG.width, FlxG.height]);
	shader.setFloat('uScale', FlxG.height / 200);
	shader.setFloat("uIntensity", 0.5);
	shader2 = new ShaderFilter(shader);
	FlxG.camera.filters = [shader2];
}

function onUpdate(elapsed:Float) 
{
	shader.setFloat("uTime", shader.getFloat("uTime") + elapsed);
	shader.setFloatArray("uCameraBounds", [
		FlxG.camera.scroll.x + FlxG.camera.viewMarginX,
		FlxG.camera.scroll.y + FlxG.camera.viewMarginY,
		FlxG.camera.scroll.x + FlxG.camera.width,
		FlxG.camera.scroll.y + FlxG.camera.height
	]);
}
```