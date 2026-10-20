# 195 - See Past 250 Yards

## Status
- Created: 2026-10-20
- Phase: 2 (The Empty World)
- Related: 194 (players see the full distance, bots only as far as they
  act), `docs/wow-chat-1-settings.md` (wow-chat-1's 333)
- Priority: Medium
- State: planned; open questions first. A source patch: the owner compiles.

## Origin

Told the server caps every view distance at 250 yards, so wow-chat-1's 333
was 250 in effect, the owner, 2026-10-20: "sounds like we need a
source-patch."

## Current Behavior

`MAX_VISIBILITY_DISTANCE` is 250 (`src/server/game/Entities/Object/ObjectDefines.h`,
"experimental"). Three things lean on it:

- `World.cpp` clamps `Visibility.Distance.Continents`, `.Instances` and
  `.BGArenas` to it at start, logging an error for each one over.
- `Map.cpp:269` loads the map's grids (533-yard squares,
  `SIZE_OF_GRIDS`) around each player out to it when they arrive, so that
  everything within sight is in memory.
- `InstanceMap::InitVisibilityDistance` (`Map.cpp`) forces some instances'
  distances: 175 in Dire Maul, the Eye and the Oculus; 150 in Trial of the
  Crusader and Champion, Culling of Stratholme and Pit of Saron; 200 in
  Obsidian Sanctum, Eye of Eternity, Ulduar, Halls of Reflection,
  Icecrown Citadel and Ruby Sanctum; and 300 in Ahn'Qiraj's temple,
  already past 250 despite the comment beside it ("this CAN NOT exceed
  MAX_VISIBILITY_DISTANCE").

Bots see no farther than they act wherever this goes (B056, 194).

## Intended Behavior

Players can see as far as the profile's settings say, past 250, with the
grids loaded far enough around them that what is in sight is in memory.
Bots stay at their own largest distance (B056), so the cost is for real
players only.

## Suggested Implementation Steps

1. A source patch raising `MAX_VISIBILITY_DISTANCE` to the chosen limit
   (question 1).
2. Decide the instance overrides (question 2).
3. The settings for the profiles that want it (C037 for beta's continents,
   C039 for instances and battlegrounds).
4. Measure: memory and update time with a player standing still, at 250
   and at the new distance (`.server info`, the server's own timings), on
   beta with its 200 bots.
5. Tests: the patch round-trips (`scripts/test-source-patches`); the
   settings test.

## Open Questions

1. **How far?** wow-chat-1 asked for 333. Each grid is 533 yards, so a
   sight of 250 can touch up to 4 grids around a player and 533 up to 9;
   the game client also stops drawing at its own far clip (its view
   distance setting). 333, or the most the client will draw?
2. **The instances that force a shorter distance** (150-200: the
   Wrath raids and a few dungeons, probably for performance in their
   crowded fights): keep them, or let every instance see the full
   distance as C039 asks?
