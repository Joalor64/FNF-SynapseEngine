#if !macro
// Default Imports
import flixel.*;
import flixel.util.*;
import flixel.math.*;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxRuntimeShader;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.*;
import flixel.input.keyboard.*;
import flixel.input.keyboard.FlxKey;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.ui.FlxBar;

import openfl.Lib;
import openfl.geom.*;
import openfl.Assets;
import openfl.media.Sound;
import openfl.system.System;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.filters.ShaderFilter;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import lime.app.Application;

import haxe.*;
import haxe.io.Path;
import tjson.TJSON;

#if (sys || desktop || MODS_ALLOWED)
import sys.*;
import sys.io.*;
#end

// Engine Imports
import animateatlas.AtlasFrameMaker;

#if DISCORD_ALLOWED
import backend.Discord;
#end

#if MODS_ALLOWED
import backend.Mods;
#end

import backend.*;
import backend.CoolUtil;
import backend.Conductor;
import backend.Conductor.BPMChangeEvent;
import backend.Controls;
import backend.Section;
import backend.Song;
import backend.Paths;
import backend.Highscore;
import backend.PlayerSettings;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import objects.*;
import objects.Alphabet;
import options.*;
import scripts.FunkinLua;
import scripts.FunkinHScript;
import shaders.*;
import states.*;
import states.editors.*;
import states.PlayState;
import substates.*;

#if LUA_ALLOWED
import llua.*;
import llua.Lua;
#end

#if (hscript || HSCRIPT_ALLOWED)
import hscript.*;
#end

#if flxanimate
import flxanimate.*;
import flxanimate.PsychFlxAnimate as FlxAnimate;
#end

using StringTools;
using backend.CoolUtil;

#if !debug
@:noDebug
#end
#end