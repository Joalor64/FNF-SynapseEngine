## Character JSON
Characters go in `characters/<name>.json`. The easiest way to make one is the Character Editor (press 8 in a song),
but here's what the special properties do if you're editing the file by hand.

All of these are optional.

### Spritesheets
* `image` - The spritesheet to use, like `"characters/BOYFRIEND"`.
    * **Multiple spritesheets:** separate them with commas, like `"characters/bf-1,characters/bf-2"`. Their frames get merged, so animations can come from any of them. Useful when a character doesn't fit in one image.
    * **Texture atlases** (Adobe Animate exports with an `Animation.json`): use the folder, like `"characters/picoBlazin"`. Atlases split into several spritemaps (`spritemap1.json`, `spritemap2.json`, ...) are loaded automatically.

### Floating and Orbit
```jsonc
{
    "floating": true,
    "floating_magnitude": 0.6, // how far it bobs (1.0 = 50 pixels)
    "floating_speed": 1,       // 1 = one bob about every 6 seconds, 2 = twice as fast

    "orbit": true,
    "orbit_radius": 40,        // size of the circle, in pixels
    "orbit_speed": 1           // 1 = one lap about every 6 seconds, negative = other direction
}
```
Both can be used at the same time. The movement starts from the character's normal position and doesn't depend on the framerate.
From a script, `character.resetMotion()` puts the character back on its normal position.

### Other Properties
* `health_drain` - The opponent drains your health when they hit a note.
    * `drain_amount` - How much health each note takes.
    * `drain_floor` - The drain stops when your health gets this low.
* `shake_screen` - Shakes the screen when this character sings.
    * `shake_intensity` (default `0.0075`) and `shake_duration` (default `0.1`).
* `scare_bf` / `scare_gf` - Makes BF / GF play their `scared` animation when this character sings.
* `noteskin` - The note skin to use for this character's notes.
* `flixel_trail` - Adds a trail behind the character, set up with `trail_length`, `trail_delay`, `trail_alpha` and `trail_diff`.