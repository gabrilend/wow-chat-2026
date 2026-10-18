# ambush.lua

Monsters sent at every player and bot on beta, from 120-160 yards away,
on a clock that drifts a few seconds each time. The danger half of the
wow-chat loop (concepts in `docs/concept-catalog.md`, phase 3; issues 210,
302, 303). Checked offline by `scripts/test-ambush`.

## How a player's ambush runs

At login the clock starts (30 s grace after 10+ minutes away, otherwise
one step of the walk). Each tick: wind the clock again, then check the
holds; if none applies, spawn a monster from the player's queue, or refill
the queue from the world database when it is empty. A spawned monster
chases until it is close enough to attack, fights, and is counted against
the player until it dies or is despawned.

## Functions

### `Ambush.setupPlayer(event, player)`
Login handler: empties the queues, sets the ambusher count to 0, and
starts the clock.

### `Ambush.onPlayerLogout(event, player)`
Logout handler: remembers the logout time (for the grace period).

### `Ambush.spawnAndAttackPlayer(eventId, delay, repeats, player)`
One tick of the clock: winds it, checks `Ambush.HOLDS`, then spawns or
refills.

### `Ambush.getNextInterval(player) -> ms (number)`
The next interval by the random walk: previous interval ±2, 3 or 4
seconds, floor 10 s, pulled down above 100 s (2 in 3) and 200 s (4 in 5).

### `Ambush.getJitterMagnitude() -> ms (number)`, `Ambush.getJitterSign(interval) -> 1 or -1`
The walk's two halves: a step of 2, 3 or 4 seconds, and its direction
(always up at the floor, even below 100 s, 1 in 3 up above it, 1 in 5 up
above 200 s).

### `Ambush.setupAmbushQueue(player, rank)`
Asks the world database, asynchronously, for creatures of `rank` (0
normal, 4 rare, 2 rare elite) at the player's level; the answer goes to
`Ambush.pushToAmbushQueue` for that player only (by name, issue 210).

### `Ambush.pushToAmbushQueue(player, query, rank)`
Fills the player's queue (`"queue"` or `"rare-queue"`, up to 8 entries)
from the answer, leaving out banned creatures. Nothing fits: asks the next
rank down (`Ambush.NEXT_RANK_WHEN_NONE`), or logs an error for normals.

### `Ambush.randomSpawn(player, isRare)`
Spawns one monster from a queue round the player (an arc ahead when
moving, a plus shape when still), retries water and cliffs round the
player, counts it, and starts its chase.

### `Ambush.chasePlayer(eventId, delay, repeats, creature)`
The chase step, every second: dead → released; player gone → despawned;
player sitting → circles; close or fighting → attacks; across a map
border → despawned and sent again; too far → despawned.

### `Ambush.inCombatCheck(eventId, delay, repeats, creature)`
Every half second while fighting: dead → released; fight over → back to
the chase.

### `Ambush.release(creature)`
Takes a monster off its player's count, once (rare: the boss-fight flag).

### `Ambush.layToRest(creature)`
A dead monster becomes scenery: released, its timers stopped, its last
move cancelled so the corpse stays where it fell, its ambush data cleared
(issues 304 and 305). Called wherever a death is seen.

### `Ambush.onCreatureDeath(event, killer, creature)`
A player's kill (the kill-creature event): lays the monster to rest. A
death by anything else is seen by the chase or fight check instead.

### `Ambush.despawn(creature)`, `Ambush.addCreatureToQueue(player, entry, min, max, isRare)`,
### `Ambush.isCreatureBanned(entry, isRare) -> boolean`, `Ambush.memoryOf(player) -> table`

## Data

- `Ambush.HOLDS`: list of `{ why = string, holds = function(player) -> boolean }`:
  sitting, dead, in water, 3 or more chasing, in a rare's fight.
- `Ambush.NEXT_RANK_WHEN_NONE`: `{ [2] = 4, [4] = 0 }`.
- `Ambush.BANNED_CREATURE_IDS`, `Ambush.BANNED_RARE_IDS`: lists of creature
  entries (numbers) never sent.
- Per player (`player:SetData`, wiped at logout): `"queue"`, `"rare-queue"`
  (lists of creature entries), `"num-ambushers"` (number),
  `"is-in-boss-fight"` (boolean).
- Per player, kept through logouts until a restart (`AmbushMemory`, by
  character guid low part): `{ interval = ms, logoutTime = unix seconds }`.
- Per monster: `"ambush-chase-target"` (player guid), `"is-rare"`,
  `"ambush-counted"` (booleans), `"wander-radius"`, `"ambush-max-distance"`
  (yards), `"orbit-direction"` (1 or -1).
- Settings: the `AMBUSH_*` globals at the top of the file.
