## Creating the Folder
First, create a folder in the `mods/` folder and rename it whatever you want.\
Doing this manually isn't a problem, but it would be better and faster if you copy-and-pasted the template mod folder from `modTemplate.zip`.

## Mod Metadata
The mod metadata comes in two files, which are `pack.json` and `pack.png`.

### `pack.json` (Required)
In pack.json, you can define the mod name, the mod's description, etc.

Here's an example of a valid mod metadata file:
```jsonc
{
	"name": "Name", // Mod name
	"description": "Description", // Mod description
	"restart": false, // If the mod should restart the game when enabled/disabled
	"runsGlobally": false, // Whether the mod's scripts, if any, run globally or not
	"color": [170, 0, 255], // The background color for the mod (RGB)
	"discordRPC": "863222024192262205", // A custom Discord RPC ID for the mod
	"iconFramerate": 10 // The framerate of the mod's icon, if it's animated
}
```

### `pack.png` (Optional)
As for pack.png, it's just a simple .png icon for the mod. Any square image is recommended, preferably `150 x 150`. Just keep in mind that **whatever image it is, it will always be squished into a `150 x 150` resolution.**

If you've done everything correctly, your mod should appear in the Mods Menu.
Then, you're basically good to go!

## Mod Structure
Each folder in your mod should be used as follows:
* `characters` - To store your character `.json` files.
* `custom_events` - Script files related to events. Should include `.lua`/`.hxs` and `.txt` files.
* `custom_notetypes` - Script files related to notetypes.
* `fonts` - Font files. Kind of self-explanatory.
* `images` - All image files. Can also be used to replace base game images.
* `music` - Non-gameplay related music.
* `scripts` - Script files that run on every song.
* `shaders` - Shader files. Make sure to use the proper format depending on the file (`.frag` for fragment shaders, and `.vert` for vertex shaders.)
* `songs` - Songs for gameplay. Should include charts, audio, etc.
	* `Inst.ogg` - The instrumental for the song.
	* `Voices.ogg` - The voices for the song.
	* `song-name.json` - The chart for the song.
	* `events.json` - Custom event data.
	* You can also add in any custom lua or haxe scripts to run on a specific song.
* `sounds` - All sound effects.
* `stages` - Custom stage files. Should include `.lua`/`.hxs` and `.json` files.
* `states` - HScript files for custom states.
* `substates` - HScript files for custom substates.
* `videos` - Custom videos used for cutscenes or other stuff.
* `weeks` - Week files.

Additionally, you can also add customization files, located in the mod's root folder.

* `achievements.json` - For custom achievements, see more [here](https://github.com/Joalor64GH/FNF-SynapseEngine/wiki).
* `credits.json` - For custom credits, see more [here](https://github.com/Joalor64GH/FNF-SynapseEngine/wiki/Custom-Credits).
* `settings.json` - For custom settings, see more [here](https://github.com/Joalor64GH/FNF-SynapseEngine/wiki).