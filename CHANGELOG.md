# Changelog
All notable changes will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-11-10
> [!WARNING]
> This update has some breaking changes, see **Changed** and **Removed** below.

### Added
* Weekend 1
* Sticker transition (from V-Slice)
* In-game crash handler (from Doido Engine)
* Lil' Buddies in the Chart Editor (from FPS+)
* Translations
* Separate player and opponent vocals
* Alphabet JSON, plus special Alphabet properties: force bold, force plain, colored, rainbow, wavy and shake
* New main menu
* Special character properties: floating, orbit, shake screen, scare BF/GF, health drain and per-character noteskins
* Multi-atlas support: characters, stage sprites, stage JSON objects, Lua sprites and story menu characters can use several spritesheets (`"image1,image2"`), and texture atlases split into several spritemaps are loaded fully
* Re-added the Blammed Lights event (yes)
* Scripted stages: a `stages/<name>.hx` script replaces the hardcoded stage, and every base game stage is now a script
* New HScript callbacks that get the actual objects: `onNoteHit(note)`, `onOpponentNoteHit(note)`, `onNoteMiss(note)`, `onOpenSubState(substate)` and `onCloseSubState()`
* New HScript variables: `engineVersion`, `BlendMode` and `Defines`
* Script errors now show in an on-screen overlay, and repeated errors are merged instead of opening a popup every frame
* Custom defines (`defines/<name>.define` files that can be changed without recompiling)
* NDLL support (`ndlls/` folder, loaded with `NdllUtil.getFunction()`)
* Newer Lua functions from Psych Engine 1.0, including:
  * Texture atlases: `makeFlxAnimateSprite`, `loadAnimateAtlas`, `addAnimationBySymbol`, `addAnimationBySymbolIndices`
  * Reflection: `callMethod`, `callMethodFromClass`, `createInstance`, `addInstance`, `instanceArg`, `addToGroup`
  * Translations: `getTranslationPhrase`, `getFileTranslation`
  * Discord: `changeDiscordPresence`, `changeDiscordClientID`
  * Others: `loadMultipleFrames`, `insertToCustomSubstate`, `setTextAutoSize`, `setTextHeight`, `eraseSaveData`
* An error screen in Freeplay when a song fails to load, instead of crashing
* Shaders that fail to compile now show an error instead of crashing the game
* A Tracy profiler build for engine developers (`-D FEATURE_DEBUG_TRACY`)

### Changed
* Lua and HScript now go through one script dispatcher, so a single script returning `Function_Stop` cancels the action (it used to need every script language to return it)
* HScript stage scripts now run `create()` while the stage is built, before the characters are added
* Assets are reorganized: base game content is in `assets/base_game/` and engine files are in `assets/shared/`, and build-related files moved to `include/`
* The auto-updater now checks GitHub Releases in the background, verifies downloads and keeps your mod list and mod files
* Renamed options: "Health Bar Transparency" is now "Health Bar Opacity", and "Pause Screen Song" is now "Pause Music"
* `animateatlas` was replaced by `flxanimate`
* Deprecated `setOnLuas` (use `setOnScripts`) and the Lua function `changePresence` (use `changeDiscordPresence`); both still work for now

### Fixed
* Linux builds quitting when GameMode isn't installed
* Thorns softlocking in Story Mode when its dialogue file is missing, and Senpai/Roses starting the countdown twice
* The Tank foreground staying 100px too low after the Stress cutscene
* The Limo stage using the wrong GF on low quality
* The Mall crowd's "Hey!" ending instantly when the event has no duration
* Scripted states and substates seeing the previous `curBeat`/`curStep` inside `beatHit`/`stepHit`
* Note types written as `.hx` files losing the last letter of their name in the Chart Editor
* HScript files whose last line returned nothing never having their `create()` called
* A downscroll bug
* `addScript`/`importScript` picking the wrong file when a script exists with more than one extension
* Builds with Discord support turned off failing to compile
* The setup and build scripts not working unless they were run from a specific folder

### Removed
* The HScript `createThread` function (scripts aren't thread-safe, so it could cause random crashes)
* The Lua function `GetFromTypedGroup`

## [0.1.0] - 2026-04-24
Initial release!