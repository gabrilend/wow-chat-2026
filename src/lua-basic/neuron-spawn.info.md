# neuron-spawn.lua

One reusable, ground-probed creature placement. See issue 162.

## Functions

### `NeuronSpawn.at(entry, mapId, x, y, z, orientation, permanent) -> creature | nil`

Places one creature of kind `entry` at `(x, y, z)` on `mapId`, after reading
the real ground height under it and refusing (logging why, returning `nil`)
if there is none within `NeuronSpawn.GROUND_TOLERANCE` yards — open water or
a hole in the terrain. `permanent` (boolean) controls whether the spawn
point survives a worldserver restart; the default meaning, `false`,
despawns it when the server next stops.

| Parameter     | Type    | Meaning                                                |
|---------------|---------|---------------------------------------------------------|
| `entry`       | int     | `creature_template` entry number, not a name            |
| `mapId`       | int     | the map to spawn on                                      |
| `x`, `y`, `z` | float   | target position; `z` is checked against the real map     |
| `orientation` | float   | facing, in radians                                       |
| `permanent`   | boolean | survives a restart if true                                |

## Configuration

`GROUND_TOLERANCE` (40 yards), `PROBE_HEIGHT` (10 yards above `z`, so the
ground probe ray finds the floor rather than starting inside it),
`CORPSE_DESPAWN` (300 seconds).

## Where this fits

Mirrors, line for line, the ground-probe-then-`PerformIngameSpawn` sequence
`../wow-chat-neuron/src/049-spawn.lua`'s `Spawn.script` currently generates
as a fresh string for every creature `world.spawn` places. **Not called by
neuron today** — see the header comment in `neuron-spawn.lua` and issue
162's Open Questions for why wiring that up has to wait on where this file
is loaded from under the active profile.

Not related to `ambush.lua`'s spawn functions, which place creatures through
a different primitive (`player:SpawnCreature`) and are not interchangeable
with this.

## Unverified

No worldserver has been up in any session that wrote this file. The claim
that it matches `Spawn.script` is a claim about the two files' text, not
about anything observed running.
