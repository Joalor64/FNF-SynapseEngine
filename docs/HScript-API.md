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
* `game` - The current PlayState (only in songs).
* `controls` - The player's controls (`controls.ACCEPT`, `controls.BACK`, ...).
* `Defines` - Reads [custom defines](https://github.com/Joalor64/FNF-SynapseEngine/wiki/Building-the-Game#custom-defines): `Defines.getBool('myFlag')`, `Defines.get('name')`, `getInt`, `getFloat`.

## Errors
Script errors show up in a small overlay at the bottom of the screen, and repeated errors are merged with a counter instead of spamming.
Errors while *loading* a script (syntax errors, missing files) also show a popup, but only once.

## Default Functions
* `trace(value:Dynamic)` - The equivalent of `trace` in normal Haxe.
* `importScript(source:String)` - Gives access to another script's local functions and variables.
* `addScript(path:String)` - Adds a new script during gameplay (PlayState).
* `stopScript()` - Stops the current script.

## Where Scripts Go
HScript files can end in `.hx`, `.hxs`, `.hxc` or `.hscript`. Every folder below works in a mod folder or in the game's assets.

| Location | Runs |
|---|---|
| `scripts/` | In every song |
| `songs/<song>/` | In that song |
| `stages/<stage>.hx` | As that stage (see [Scripted Stages](#scripted-stages)) |
| `characters/<character>.hx` | When that character is in the song |
| `notetypes/<note type>.hx` | When the chart uses that note type |
| `events/<event>.hx` | When the chart uses that event |
| `states/<name>.hx` / `substates/<name>.hx` | As a custom state/substate (see [Custom States/Substates](#custom-statessubstates)) |
| `LoadingScreen.hx` (mod root) | As the loading screen (see [Custom Loading Screen](https://github.com/Joalor64/FNF-SynapseEngine/wiki/Custom-Loading-Screen)) |

### Replacing the Built-In Menus
All the menus are scripts too: `TitleState`, `MainMenuState`, `StoryMenuState`, `FreeplayState`, `CreditsState`, `OptionsState` and `AchievementsState` in `states/`, and `PauseSubState` and `GameOverSubState` in `substates/`.

To change one, copy it from `assets/shared/states/` (or `substates/`) into the same folder in your mod and edit it. Mods are checked before the game's own files, so yours is used instead.

## Callbacks
### In Songs
Lua scripts get these too, with the same arguments. The ones marked **Stop** can be cancelled by returning `Function_Stop`.

| Callback | When |
|---|---|
| `create()` | Right after the script loads |
| `onCreate()` / `onCreatePost()` | Before / after the song is set up |
| `onUpdate(elapsed)` / `onUpdatePost(elapsed)` | Every frame |
| `onBeatHit(curBeat)` / `onStepHit(curStep)` / `onSectionHit()` | On every beat / step / section |
| `onStartCountdown()` **Stop** | Before the countdown starts |
| `onCountdownStarted()` / `onCountdownTick(counter)` | When the countdown starts / on each tick |
| `onSongStart()` | When the song starts playing |
| `onEndSong()` **Stop** | When the song ends |
| `onPause()` **Stop** / `onResume()` | When the game is paused / resumed |
| `onGameOver()` **Stop** | When the player dies |
| `onRecalculateRating()` **Stop** | Before the rating is recalculated |
| `onUpdateScore(miss)` | When the score text updates |
| `onEvent(name, value1, value2, strumTime)` | When an event triggers |
| `eventEarlyTrigger(name)` | Return how many milliseconds early the event should trigger |
| `onMoveCamera(character)` | When the camera moves to `'dad'`, `'boyfriend'` or `'gf'` |
| `onSpawnNote(index, noteData, noteType, isSustain)` | When a note spawns |
| `goodNoteHit(index, noteData, noteType, isSustain)` | When the player hits a note |
| `opponentNoteHit(index, noteData, noteType, isSustain)` | When the opponent hits a note |
| `noteMiss(index, noteData, noteType, isSustain)` | When the player misses a note |
| `onGhostTap(key)` | When the player presses a key with no note to hit |
| `noteMissPress(direction)` | Same, but it counted as a miss (ghost tapping off) |
| `onKeyPress(key)` / `onKeyRelease(key)` | When a note key is pressed / released |
| `onNextDialogue(count)` / `onSkipDialogue(count)` | When dialogue advances / is skipped |
| `destroy()` | When the song closes |

HScript-only, these give you the actual objects:

| Callback | When |
|---|---|
| `onNoteHit(note)` | The player hit a note |
| `onOpponentNoteHit(note)` | The opponent hit a note |
| `onNoteMiss(note)` | The player missed a note |
| `onOpenSubState(substate)` / `onCloseSubState()` | A substate (like the pause menu) opens / closes. Check `game.paused` to know if it's the pause menu |

### In Custom States/Substates
| Callback | When |
|---|---|
| `new(args...)` | When the state is made, with the arguments passed to `ScriptedState`/`ScriptedSubState` |
| `create()` | When the state starts |
| `update(elapsed)` | Every frame |
| `beatHit(curBeat)` / `stepHit(curStep)` | On every beat / step of the music |
| `onFocus()` / `onFocusLost()` | When the game window gains / loses focus |
| `destroy()` | When the state closes |

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

All the base game stages are scripts too (`assets/base_game/stages/`), so they're also good examples:
`philly.hx` for events, `limo.hx` for pausing timers, `tank.hx` and `phillyStreets.hx` for cutscenes.

Some tips for porting a hardcoded stage:
* Use `game.` for PlayState things (`game.boyfriend`, `game.camHUD`, `game.defaultCamZoom`, `game.startCountdown()`, ...).
* Optional arguments can't be skipped by type like in Haxe, so pass them all: `new BGSprite('image', x, y, 1, 1, ['anim'])`, not `new BGSprite('image', x, y, ['anim'])`.
* Enums from your stage class become strings or numbers, and `final` becomes `var`.
* `FlxColor` properties (`saturation`, `brightness`, `alphaFloat`) don't work in scripts, so use `backend.utils.ColorUtil` instead.
* Classes that are only used from scripts need to be compiled in. The engine includes the `states.stages`, `objects`, `shaders`, `cutscenes` and `backend.utils` packages (see `Project.xml`).

## PlayState Callbacks With Objects
Besides the Lua-style callbacks (like `goodNoteHit(index, noteData, noteType, isSustain)`), HScripts in PlayState also get:
* `onNoteHit(note:Note)` - the player hit a note.
* `onOpponentNoteHit(note:Note)` - the opponent hit a note.
* `onNoteMiss(note:Note)` - the player missed a note.
* `onOpenSubState(substate)` / `onCloseSubState()` - e.g. to pause your own timers while the pause menu is open (check `game.paused`).

`stage` gives access to the stage helpers: `stage.addBehindGF(obj)`, `stage.addBehindBF(obj)`, `stage.addBehindDad(obj)`, `stage.setDefaultGF(name)`, `stage.setStartCallback(fn)`, `stage.setEndCallback(fn)`.

> [!NOTE]
> The Week 1 stage is also used as the Note Offset menu background. There, only `create()` runs and `game` is `null`.

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
import flixel.FlxG;
import backend.Paths;

var shader:FlxRuntimeShader;
var filter:ShaderFilter;

function onCreate() 
{
	shader = new FlxRuntimeShader(Paths.getTextFromFile('shaders/rain.frag'), null);
	shader.setFloat('uTime', 0);
	shader.setFloatArray('uScreenResolution', [FlxG.width, FlxG.height]);
	shader.setFloat('uScale', FlxG.height / 200);
	shader.setFloat("uIntensity", 0.5);
	filter = new ShaderFilter(shader);
	FlxG.camera.filters = [filter];
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