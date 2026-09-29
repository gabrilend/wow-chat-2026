# 913e - Map Placement Scheduler

## Status
- Created: 2026-09-23
- Parent: Issue 913 (clustered-worldserver)
- Phase: 9 (numbered under its parent)
- **Blocked by:** 913b, 913c, 913d
- **Blocks:** 913f, 913h

## Overview

The scheduler decides which worldserver runs which map. It runs on the same
machine as the authserver. Each worldserver announces how many map-update
threads it has. The scheduler treats those threads as capacity and hands out
**whole maps** (Eastern Kingdoms, Kalimdor, Outland, each dungeon) so that
players and their bots are spread according to that capacity. When the
balance shifts, it moves a map to another machine by redirecting the
players on it at their next loading screen.

A single map is never split between machines. The threads updating one map
share its memory, and across a network every one of those shared reads
would become a round trip.

## Current Behavior

- One worldserver loads every map it's asked for. `MapUpdate.Threads` in
  worldserver.conf sets how many threads divide the maps among themselves
  inside that one process.

## Intended Behavior

- A table of placements: map id (uint32) → worldserver node name (string),
  with player count and bot count (uint32 each) per map.
- A table of nodes: node name (string) → address (string), world port
  (uint16), thread count (uint32), last heartbeat (unix seconds, uint64).
- A new login is sent to the node that owns the character's saved map,
  by setting the realm's address for that login or by an immediate redirect
  (913c).
- A map moves only when a whole group of players is at a loading screen, and
  never in the middle of combat.

## Implementation Steps

1. Heartbeat: each worldserver reports its thread count and per-map
   population to the scheduler once a second.
2. Placement: the thread-weighted assignment, written as its own step,
   separate from the redirect plumbing.
3. Movement: pick the moments to move (map change, loading screen) and
   send the redirect through 913c.
4. A viewer that shows the placement table live, kept separate from the
   placement code.

## Open Questions

1. Should placement be fixed by hand (the original idea: one machine each
   for Eastern Kingdoms, Kalimdor, and Outland plus instances) before it
   becomes dynamic?
2. What happens to a map's players when its node stops sending heartbeats?

## Related
- `issues/913-clustered-worldserver`: "Map Placement by Thread Weight"
