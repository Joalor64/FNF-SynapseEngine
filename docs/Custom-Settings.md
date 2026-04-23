## JSON Structure
Your `settings.json` should be structured as follows:
```jsonc
[
    // All types:
    // bool - Has a checkbox only, meaning it can only be 'true' or 'false'.
    // int - Numbers with no decimals (ex. 1, 3, 9, -1)
    // float - Similar to int, but numbers can have decimals (ex. 1.5, 2.75)
    // percent - Similar to float, but the displayed value is multiplied by 100 (ex. 1.1 will be displayed as "110%")
    // string - A text instead of numbers/false and true, you gotta set up "options" variable to it
    {
        "save": "testbool",
        "name": "Test Bool Option", //Name shown on the mod settings menu
        "type": "bool",
        "description": "This is a test bool option", //Description shown on the mod settings menu
        "value": true //This is the default value
    },
    {
        "save": "testnumber",
        "name": "Test Number Option",
        "type": "float", //
        "description": "This is a test number option",
        "value": 5,
        // Int/Float/Percent only variables
        "min": 0, //How low can the value be
        "max": 10, //How high can the value be
        "step": 1, //How much is changed at once when you press left/right
        // Float/Percent only variables
        "decimals": 1, //If your option is type 'float' or 'percent', you should probably make it have atleast 1 decimal places
        "scroll": 5 //How fast you scroll while holding left/right (in this case, it changes 5 per second)
    },
    {
        "save": "teststring",
        "name": "Test String Option",
        "type": "string",
        "description": "This is a test string option",
        "value": "Sun",
        "format": "%vday", //Text formatting, '%v' means 'current value', so if my current value is 'Fri', it wil be shown as 'Friday'. You can also use '%d' to represent the default value
        // String only variables
        "options": [
            "Sun",
            "Mon",
            "Tues",
            "Wednes",
            "Thurs",
            "Fri",
            "Satur"
        ] //Available options to choose
    }
]
```

## Accessing Mod Options
To access your mod option, you can do it through `.lua` or `.hxs`.\
For example:
```lua
if getModSetting("modOption") == true then
    -- code goes here
end
```

Or, in HScript:
```hx
import psychlua.LuaUtils;

function onUpdate(elapsed:Float)
{
    if (LuaUtils.getModSetting('modOption') == true)
    {
        // code goes here
    }
}
```