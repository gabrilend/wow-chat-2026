# 811 - Razorfen Kraul's Empty Labyrinth

## Status
- Created: 2026-10-04
- Phase: 8
- Profile: basic
- Priority: Low
- Related: 810 (dungeons as raids, by their parallel paths)

## Origin

Verbatim, 2026-10-04, ruling on Razorfen Kraul for 810: "near the last
boss, by the tuber quest, there's a labyrinth that has hardly any
monsters in it. We should make an issue file for populating that area,
then we can have two groups in there I think."

## Current Behavior

Not built. The maze of tunnels near Razorfen Kraul's last boss, where the
tuber-digging quest is done, holds almost no monsters, so a second group
there would have nothing to fight.

## Intended Behavior

The labyrinth is populated with packs of the dungeon's own kinds of
creatures (quilboar, their beasts), at the levels of the nearby halls, so
it becomes a second path for a second group (810).

Owner, 2026-10-04: "we will need bosses too, so we should bring level
adjusted rare elite quilboards from everywhere in the map and have them
wander through the labyrinth. The patrols and the rares should try and
spread themselves throughout the maze, with both of them sharing separate
pathing maps. Make sure their loot is level adjusted too, we will probably
have to make duplicates or something because we want them to also spawn
in the world. It's just... they're wandering through. There should be
about as many as there are bosses on the previous path. ... The labyrinth
is very dense, which means that it will have less walking, meaning,
parties will clear it faster. So it's gotta be tougher too, and depending
on how fast... it might seem to speed up partway through. Or slow down if
you're doing great at your fights. But it only adjusts for monsters that
are not in combat."

- **Its bosses**: the rare elite quilboar of the world (Kalimdor's
  quilboar rares), copied as new creatures for the labyrinth (the world's
  own stay where they are), their levels and their loot's item and
  required levels set to the labyrinth's; as many as the bosses on the
  other path.
- **Wandering, spread out**: the patrols and the rares each walk the maze
  by their own distance map (two maps: one for patrols, one for rares),
  each moving away from where the others of its kind are, so they spread
  through it.
- **Tougher for being dense**: the maze has little walking between
  fights, so its monsters are harder than the other path's.
- **The pacing (810)**: when this path is ahead of the other by some
  share of progress (say 50% against 30%: 20 points ahead), its monsters
  not yet in combat get harder by that difference (open question 2: more
  levels or more stats); when it falls behind, easier again; a monster
  already fighting is never changed.

## Suggested Implementation Steps

1. Find the labyrinth on the map (its area or its tunnel cells on the
   navigation mesh) and list what stands there now.
2. Place packs by hand or by a generator over the tunnels' floor, saved as
   an install step with an exact revert.
3. A run with two groups.

## Open Questions

1. (Answered 2026-10-04) Packs: "enough so that it's hard to pull. they
   redistribute while you're in the labyrinth...": dense enough that a
   pull usually draws a neighbour, and they keep spreading out (the
   distance maps) while a party is inside.
2. The pacing's step: a 20-point lead means how much harder: levels (+2?)
   or stats (+20%)? (Owner, 2026-10-04: "not sure about the scaling on
   it..."; open.)
