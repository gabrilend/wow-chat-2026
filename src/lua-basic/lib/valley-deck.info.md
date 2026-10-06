# lib/valley-deck.lua

Each character's own fixed order of its faction's four starting valleys,
worked out from its id every time, never stored (issue 155d1). Pure Lua,
no server calls. Tested by `scripts/test-valley-deal`.

| Function | Takes | Gives |
|---|---|---|
| `Deck.order(guid)` | guid: integer, the character's low guid | list of the four valley indices (integers 0-3), the character's order; the same every call |
| `Deck.standing_in(valleys, map, x, y)` | valleys: one faction's `[0..3]` from `data/starting-valleys.lua`; map: integer; x, y: numbers | the index (0-3) of the nearest of those valleys on that map within 400 yards, or nil |
| `Deck.next(guid, here)` | guid: integer; here: valley index or nil | the index after `here` in the character's order (wrapping), or the order's first when `here` is nil |

A valley record (from `data/starting-valleys.lua`, generated from B028):
`name` text, `map` integer, `zone` integer (the hearthstone's area), `x`
`y` `z` numbers, `o` number (facing, radians).
