# 617e16g - Monsters, Fights and Catching Up

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617e16 (the fish-school sandbox)
- Related: 617e16c (the ground), 617e16f (the walkable parts), 617e16d
  (the wanderers), 617e13 and `docs/pathfinding-improvements.md` 3 (the
  owner's track: what a buddy does when it finds no way to its owner),
  617e (buddies far from their owner), 178 (a level counted in kills)
- Priority: High
- State: in progress

## Origin

The owner, 2026-10-28:

> now can you use realistic monster spawning and make them stand in front
> of the monsters for equivalent time to how long it'd take a level
> appropriate stand-in defeat them? also if the dot is a certain distance
> away from the followers - like, 1/4th of the continent or so, it should
> appear directly in 100 yards at random from the destination pocket. And
> if they spawn like, in the mountains or whatever, then once they can
> guarantee that there's no way in, they'll get teleported onward a bit
> closer. We have similar, but different, examples of this, at the
> pathfinding document we made last month.

## Current Behavior

**Built 2026-10-28 in the ground sandbox** (steps 1-6; pictures 030-033):
- `scripts/generate-ground-sandbox-monsters` writes
  `docs/HTML/ground-sandbox/monsters-<map>.js`: 22,744 monster spawns of
  1,357 kinds on the Eastern Kingdoms, 22,585 of 1,329 on Kalimdor (each
  run prints them). A kind with health 0 (a training dummy) can't be
  killed and is left out by name; a kind whose level row is missing stops
  the tool. The monster rule moved to `scripts/lib/monster-factions.lua`,
  shared with the fish sandbox's data, whose fence order was made fixed
  on the way (ties at the per-zone cut came out differently each run).
- The page: the zone's spawns drawn (alive, fought, dead, in a cave: more
  than 8 yards below the ground); a bot within 12 yards of a living,
  untaken surface monster in the part in play walks up, stands 2.5
  yards in front of it for its health over `STANDIN_DPS` at its level
  (a Zhevra Runner: 273 health, 9.2 seconds), then it is dead until its
  respawn time. Formation members don't take fights.
- Catching up: the player more than a quarter of the continent's size
  from the bots' middle puts every bot at a random walkable point within
  100 yards of the part's middle.
- Dead ends: the points that can walk into the part in play (reach, from
  the part over ground not steeper than the limit); a bot outside it is
  moved to the first point in reach on its line to the part's middle,
  checked once a second.
- Address settings for tests: `start=scatter`, `start=far`.

## Intended Behavior

- **Monsters where the game puts them.** Every monster spawn of the zone
  (the sandbox's own rule: a creature not friendly to either side's
  players, not a critter, no vendor or trainer flags) at its spawn point,
  with its level, its health (the server's own: the level table's base
  health for its class and expansion, times its own health multiplier)
  and its respawn time (its spawn's own). Drawn alive, dead, and coming
  back.
- **Fights that take as long as they would.** A bot passing near a living
  monster no other bot has taken (ENGAGE yards) goes to it and stands in
  front of it, facing it, for as long as a stand-in of the monster's level
  would take to kill it: its health over that stand-in's damage a second.
  Then the monster is dead until its respawn time is up, and the bot goes
  back to wandering.
- **Catching up far.** When the player is more than a quarter of the
  continent's size from the bots (their middle), every bot appears at
  once at a random walkable point within 100 yards of the part in play's
  middle (the "destination pocket").
- **Out of a dead end.** A bot standing where the part in play can't be
  reached from at all (walled off by steep ground: "once they can
  guarantee that there's no way in") is moved onward, a little toward the
  part: to the nearest point along its way to the part's middle from which
  the part can be walked to.

## Suggested Implementation Steps

1. `scripts/generate-ground-sandbox-monsters`: per continent, every
   monster spawn (screen yards, height), each kind's name, levels, health
   and respawn time, into `docs/HTML/ground-sandbox/monsters-<map>.js`;
   the monster rule shared with `scripts/generate-fish-sandbox-data`
   (`scripts/lib/monster-factions.lua`).
2. The page: the spawns of the zone, their life and death; a bot's fight
   (claim, walk up, stand, the kill, the respawn).
3. The damage a stand-in does a second at each level: a stated curve
   (`STANDIN_DPS` in the page), with its reasons.
4. Catching up: the distance test, the jump into the pocket.
5. Reach: from the part in play, every point of the zone's ground that
   can walk to it (not steeper than the limit, joined); a bot outside it
   moved to the first reachable point on its line to the part's middle.
6. Measures: monsters alive and dead, fights now and done, seconds a
   fight on average; catch-ups; dead ends left.

## Open Questions

1. **A stand-in's damage a second**: the page uses 2 + 1.5 L + 0.04 L²
   at level L (about 21 at 10, 83 at 30, 236 at 60), a guess at a
   level-appropriate character with level-appropriate gear. Is there a
   number of the owner's (the stand-ins' own gear, the basic profile's
   fight multipliers, 155f1) it should come from instead?
2. **"the pathfinding document we made last month"**: read here as the
   owner's-track idea (`docs/pathfinding-improvements.md` 3,
   `docs/pathfinding-questing-and-dungeons.md`: a buddy that finds no way
   walks the owner's footsteps). Is that the one, or another document
   (perhaps in another project)?
3. **Several bots on one monster**: one bot a monster for now (the first
   to come near takes it). Should others join a fight, and shorten it?
