## Lua API
Lua scripts work the same as in Psych Engine 0.6.3, so the [Psych Engine Lua documentation](https://github.com/ShadowMario/FNF-PsychEngine/wiki/Lua-Script-API) applies.

Lua scripts go in the same folders as HScripts (see [Where Scripts Go](https://github.com/Joalor64/FNF-SynapseEngine/wiki/HScript-API#where-scripts-go)) and get the same [callbacks](https://github.com/Joalor64/FNF-SynapseEngine/wiki/HScript-API#callbacks), except for `create()` and the HScript-only ones.

## Differences From Psych Engine 0.6.3
* `Function_Stop` from any script (Lua or HScript) cancels the action.
* Many newer functions from Psych Engine 1.0 are included, such as:
    * Texture atlases: `makeFlxAnimateSprite`, `loadAnimateAtlas`, `addAnimationBySymbol`, `addAnimationBySymbolIndices`
    * Reflection: `callMethod`, `callMethodFromClass`, `createInstance`, `addInstance`, `instanceArg`, `addToGroup`
    * Translations: `getTranslationPhrase`, `getFileTranslation`
    * Discord: `changeDiscordPresence`, `changeDiscordClientID`
    * Others: `loadMultipleFrames`, `insertToCustomSubstate`, `setTextAutoSize`, `setTextHeight`, `eraseSaveData`
* Sprites can use several spritesheets at once: `makeAnimatedLuaSprite('tag', 'image1,image2', x, y)`.
* Achievement functions: see [Custom Achievements](https://github.com/Joalor64/FNF-SynapseEngine/wiki/Custom-Achievements#lua).
* Mod settings: `getModSetting('saveTag')`, see [Custom Settings](https://github.com/Joalor64/FNF-SynapseEngine/wiki/Custom-Settings).

### Deprecated
These still work but show a warning:
* `changePresence` - use `changeDiscordPresence`.
* `addAnimationByIndicesLoop`, `objectPlayAnimation` and the other Psych Engine deprecated functions.