## Creating the Folder
First, create a folder in the `mods/` folder and rename it whatever you want.\
Doing this manually isn't a problem, but it would be better and faster if you copy-and-pasted the template mod folder from `modTemplate.zip`.

## Mod Metadata
The mod metadata comes in two files, which are `pack.json` and `pack.png`.

### `pack.json` (Required)
In pack.json, you can define the mod name, the mod's description, etc.

Here's an example of a valid mod metadata file:
```json
{
	"name": "Name",
	"description": "Description",
	"restart": false,
	"runsGlobally": false,
	"color": [170, 0, 255]
}
```

### `pack.png` (Optional)
As for pack.png, it's just a simple .png icon for the mod. Any square image is recommended, preferably `150 x 150`. Just keep in mind that **whatever image it is, it will always be squished into a `150 x 150` resolution.**

If you've done everything correctly, your mod should appear in the Mods Menu.
Then, you're basically good to go!

## Mod Structure (Unfinished)
Each folder in your mod should be used as follows:
* `characters` - To store your character `.json` files.
* `custom_notetypes` - Script files related to notetypes. Should include `.lua`/`.hxs` and `.txt` files.