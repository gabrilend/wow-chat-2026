# The pretend world: testing game scripts without a server

*How to check a Lua script for the game server's Lua engine (mod-ale) on
your own machine, in a second, with no server, database or client. Written
2026-10-17. The library is `scripts/lib/toy-world.lua` (summary:
`scripts/lib/toy-world.info.md`).*

## Why it exists

A game script runs inside the world server: it is told when a player logs
in, asks where they stand, spawns a creature, books itself to run again in
40 seconds. Trying a change that way means a build, a server start, a
login, and waiting in game for the moment it matters. Most of what a
script does, though, is its own decisions: whether to send a monster now,
which trainer a level-7 druid meets, whether a cancelled hearth moves
anyone. Those can be checked without the game, if the few dozen game calls
the script makes are answered by something simple.

The pretend world is that something: plain tables standing in for
players, creatures, maps and chests, with the methods the scripts call,
and a clock a test winds forward by hand. A test loads the real script
into it, unchanged, and plays scenes. It checks the script's decisions,
not how the game carries them out; the in-game look is still needed, but
it starts from a script whose logic is known to hold.

## How a test uses it

```lua
local here = (arg[0]:match("^(.*[/\\])") or "./")
local Toy = dofile(here .. "lib/toy-world.lua")    -- installs the game's globals
dofile(DIR .. "/src/lua-beta/movement.lua")         -- the real scripts, as the engine loads them
dofile(DIR .. "/src/lua-beta/travel.lua")

local p = Toy.new_player("Ann", 101)                -- a player: set fields directly
p.class, p.level, p.horde = 11, 5, true             -- a level-5 horde druid
Toy.login(p)                                        -- runs every login handler the scripts registered
Toy.advance(60 * 1000)                              -- a minute passes: due timers run, in order
assert(#p.spawned == 1)                             -- one traveller came
```

What the world keeps, and a test reads or sets:
- **time**: `Toy.World.now` in milliseconds; `Toy.advance(ms)` runs every
  booked call that falls due, skipping those whose object has gone.
- **players**: position (`x, y, z`), `level`, `class`, `horde`, `bot`,
  `standing`, `dead`, `wet`; what they summoned (`spawned`, `objects`);
  where they were sent (`teleports`); the window they were shown (`window`).
- **creatures**: position, `dead`, `combat`, `gone`, `aggro`, how they
  were summoned (`summonKind`, `summonTimer`).
- **maps**: `Toy.new_map(id, height(x, y), water(x, y))`; a height of
  `nil` means no ground there.
- **the database's answer** to the ambush's question: `Toy.World.answer`
  by rank, filtered by level as the real query is.
- **groups, windows, spells**: `Toy.group(players)`, `Toy.answer(p, intid)`
  (pick an option in an open window), `Toy.spell(entry)`.

## Making a test worth having

- **Load the real file.** Never copy a script's logic into the test.
- **One scene per promise.** Each scene sets up a situation and checks what
  the script's comments or its issue say should happen.
- **Undo each fix and watch the test fail.** Every test here was checked
  this way: remove one line of the fix in a copy of the script, run the
  test on the copy, and see the scene that should catch it fail. A test
  that still passes is not testing that fix.
- **When the world is too simple, make it truer, not the script simpler.**
  The demo's first run sent no monster because the pretend database
  answered every row whatever the level, where the real query filters by
  level; the fix went into the world.
- **Add what a new script needs** as a new fold in `toy-world.lua`, named
  for the script that needs it ("extra pieces the treasure script uses"),
  extending players or creatures by wrapping `new_player`/`new_creature`.

## Where it is used

| Test | What it plays |
|---|---|
| `scripts/test-ambush` | the ambush: clock, holds, queues, spawns, chases, deaths |
| `scripts/test-travel` | travellers and trainers, every class at every level 1-20 |
| `scripts/test-treasure` | the treasure pool and chests, selling and buying back |
| `scripts/test-hearthstone` | the group hearthstone by invitation |
| `scripts/test-druid-moonglade` | druids' Teleport: Moonglade, out to a random spot in the glade and back |
| `scripts/demo-beta-toy-session` | all of beta at once, as a session, with a report |

Each test prints how many checks it ran and how many passed; run it for
the current count rather than trusting a number written here.

Beside it, two checks that need no world at all:
`scripts/test-beta-lua-load` reads every profile's scripts once, as the
engine does at boot, standing in for every engine function by name, and
fails on a file that stops; `scripts/test-movement` checks the shared
geometry helpers.

## What it does not do

It has no real map heights, no line of sight, no combat rules, no network.
A monster's path is a straight move; a fight ends when a test says so.
Anything the game itself decides (whether a spell lands, whether a
creature can reach a spot) is the in-game check's business.
