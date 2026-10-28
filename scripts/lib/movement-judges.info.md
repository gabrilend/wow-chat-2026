# lib/movement-judges.lua

The movement benchmark's measures (issue 617e14f): plain arithmetic over a
positions record, used by `scripts/movement-benchmark` and its test. Each
measure turns one word of the owner's picture ("whirling, but semi chaotic,
like a maelstrom of swirls but in all directions at once ... circle about
... explore") into a number; the targets are in
`src/lua-basic/data/movement-benchmark-targets.lua`.

| Function | Takes | Gives |
|---|---|---|
| `J.read(path, from, to)` | a record's path (text); from, to: unix seconds or nil | `groups`, the first and last time (numbers); or nil and a message |
| `J.measure(group, area_squares)` | one group; the squares of its sub-zone as a list of `{ x, y }` (world middles, numbers), or nil | `values`, `evidence` |

**groups**: owner guid (number; a bot with no owner: minus its guid) ->
`{ owner = { sample, ... }, buddies = { [guid] = { name = text, samples = { sample, ... } } } }`.
A **sample**: `t` (unix seconds), `x`, `y` (yards), `map`, `zone`, `area`
(numbers), `fighting`, `dead` (booleans); oldest first.

**values** (numbers): `moving` (share of sample pairs with more than a yard
moved), `circling` (share of minute-long windows whose path turned half a
circle one way), `both_ways` (the smaller of clockwise and anticlockwise
circling windows over the larger), `winding` (median path length over
straight distance, per window), `covering` (share of the sub-zone's squares
a buddy came within 20 yards of; nil without squares), `still` and
`stacked` (the watcher's rule breaks, per buddy per 10 minutes).

**evidence**: lists behind the numbers, for the debug sequence: `standing`
(each standing sample: name, time, fighting, dead, the owner's distance
and whether the owner moved), `windows` (each window: name, time, net
turn in radians, winding, displacement, length), `still` (name, time,
seconds, owner's distance), `stacked` (the two names, time, whether by the
owner).
