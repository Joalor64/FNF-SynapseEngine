## JSON Structure
Your `achievements.json` should be structured as follows:
```jsonc
[
    {
        "save": "customweek_nomiss", // Will load images/achievements/customweek_nomiss.png
        "name": "Custom Week No Miss",
        "description": "Name it Your week JSON file name + \"_nomiss\"\nif you want it to be handled automatically"
    },
    {
        "save": "test_achievement1", // Will load images/achievements/test_achievement1.png
        "name": "Test Achievement 1",
        "description": "This is a simple achievement with no Progress Bar"
    },
    {
        "save": "test_achievement2", // Will load images/achievements/test_achievement2.png
        "name": "Test Achievement 2",
        "description": "This is a more complex achievement with a Progress Bar and\nall changeable variables being shown.",
        "maxScore": 40,
        "maxDecimals": 0, // This will be how many decimals will be shown on the progress counter
        "hidden": false
    }
]
```

## Functions and Methods
* `getAchievementScore(name:String)` - Gets the score of an achievement.
* `setAchievementScore(name:String, value:Float)` - Sets the score of an achievement.
* `addAchievementScore(name:String, value:Float)` - Adds to the score of an achievement.
* `unlockAchievement(name:String)` - Unlocks an achievement.
* `isAchievementUnlocked(name:String)` - If an achievement is unlocked or not.
* `achievementExists(name:String)` - If an achievement exists or not.

## Examples
### Lua
```lua
function onUpdate(elapsed) 
    if getProperty("songScore") >= 10000000 then
        unlockAchievement("ten_million")
    end
end
```

### HScript
```hx
import backend.Achievements;

function onUpdate(elapsed:Float)
{
    if (game.score >= 10000000)
    {
        Achievements.unlock("ten_million");
    }
}
```