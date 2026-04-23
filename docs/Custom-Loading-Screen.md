> [!NOTE]
> Custom loading screens will only work in the mod folder of the current loaded mod!
> It's also HScript exclusive, due to `.lua` taking too long to initialize!

## Setup
In the root folder of your mod, create a file called `LoadingScreen.hx`.

If you want to check for a specific song, you can use a switch case like this:
```hx
switch (Paths.formatToSongPath(PlayState.SONG.song))
{
    case 'darnell':
        // Will only load this part of the code in Darnell
    case 'lit-up':
        // Will only load this part of the code in Lit Up
    case '2hot':
        // Will only load this part of the code in 2Hot
    case 'blazin':
        // Will only load this part of the code in Blazin
}
```

## Functions, Methods, and Variables
### Functions
* `onCreate()` - Called when the loading screen starts.
* `onUpdate(elapsed:Float)` - Called every frame.
* `onDestroy()` - Called before the script and loading screen are destroyed.

### Methods
* `getLoaded()` - Get the current amount files that have been successfully loaded or failed to load.
* `getLoadMax()` - Get an amount of files it's supposed to load.
* `addBehindBar(obj:FlxBasic)` - Inserts an instance behind the progress bar, recommended over `add()`.

### Variables
* `intendedPercent` - Same as getLoaded() / getLoadMax(), ranges from 0 to 1.
* `curPercent` - Progress bar's visual percentage, it slowly lerps to the intendedPercent value.
* `barGroup` - An [FlxSpriteGroup](https://api.haxeflixel.com/flixel/group/FlxSpriteGroup.html) that contains `barBackground` and `bar`.
* `barBackground` - Contained inside `barGroup`, it's the black background behind the moving progress bar.
* `bar` - Contained inside `barGroup`, it's the white moving progress bar that scales accordingly to `curPercent`'s value.
* `barWidth` - How wide bar should be when `curPercent` equals to 1.
* `stateChangeDelay` - Makes the loading screen take longer to finish, recommended for development purposes or a custom transition.