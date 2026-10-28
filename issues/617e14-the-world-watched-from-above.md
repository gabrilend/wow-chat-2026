# 617e14 - The World Watched From Above

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 617e
- Related: 617e7 (one zone, The Barrens, drawn from a simulation: its data
  tool and its tints), 617e13 (the spread record and the live watcher),
  617e15 (what the watching is looking for: places conquered)
- Sub-issues: 617e14a, 617e14b, 617e14c, 617e14d, 617e14e, 617e14f
- Priority: High
- State: in progress (617e14a, b, c, f built 2026-10-27; d, e plan only)

## Origin

The owner, 2026-10-27:

> okay now can we create a renderer utility that displays a large map of
> azeroth, with dots for where all the players are. we should have one map
> per zone, with the entire screen used to visualize. We should watch the
> pattern of bots as they are assigned to random sub-zones - we don't need
> a player to watch them quest. "questing" is when they fight monsters in a
> particular sub-zone - or, as I like to believe, NPC spawn location of a
> certain type. Follow the goat goddess? Then you will wander wherever
> goats are blessed.
>
> ... then we feed it to an image recognition program, and we describe our
> task goal, then say "does this look like rippling waves of silk? Is this
> the flow of a school of tranquil fish? etc. We're looking for something
> that feels whirling, but semi chaotic, like a maelstrom of swirls but in
> all directions at once.

## Current Behavior

617e7 drew one zone from a simulation, not from the server. The spread
record (617e13) writes only game masters' buddies, on a Debug build.
Nothing draws where everyone in the real world is.

## Intended Behavior

- **Where everyone is, recorded** (617e14a): every character in the world,
  players and bots, every few seconds.
- **Every zone as a picture** (617e14b): each zone's ground, its sub-zones
  in tints of grey so touching ones differ (617e7's way), filling the
  screen.
- **The dots on it, over time** (617e14c): one picture per zone per
  moment, each character a dot with a fading tail, so swirls show; frames
  of a stretch of time make an animation.
- **Bots questing with no player watching** (617e14d): buddies sent to a
  random sub-zone to quest there, "we don't need a player to watch them
  quest"; questing being fighting the monsters of a sub-zone, or of a kind
  ("Follow the goat goddess? Then you will wander wherever goats are
  blessed").
- **A judge of the pictures** (617e14e): the frames given to an image
  model with the task's goal, and asked the owner's questions ("does this
  look like rippling waves of silk? Is this the flow of a school of
  tranquil fish?"), toward "whirling, but semi chaotic, like a maelstrom of
  swirls but in all directions at once".

| ID      | Name                                  | Dependencies     | Description |
|---------|---------------------------------------|------------------|-------------|
| 617e14a | where-everyone-is-recorded            | None             | Every character's position, every 5 seconds, to a record in RAM |
| 617e14b | every-zone-as-data                    | None             | Every zone's squares, sub-zones and tints, from the server's map files |
| 617e14c | the-zone-renderer                     | 617e14b          | A full-screen picture per zone with every dot and its tail; frames to an animation |
| 617e14d | bots-questing-unattended              | 617e14a          | Buddies sent to random sub-zones to quest with no player |
| 617e14e | the-picture-judge                     | 617e14c          | The frames shown to an image model and asked the owner's questions |
| 617e14f | the-movement-benchmark                | 617e14b          | Pass or try again, with a debug sequence naming what could be wrong (built) |

Data and drawing are kept apart (the house rule): the record and the zone
data are written by their own tools; the renderer only reads them.

## Suggested Implementation Steps

1. 617e14a, b, c (built 2026-10-27).
2. 617e14d's design questions; then its server behaviour.
3. 617e14e's model and its questions.

## Open Questions

- In the sub-issues.
