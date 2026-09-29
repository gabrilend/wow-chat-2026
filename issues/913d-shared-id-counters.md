# 913d - Shared ID Counters

## Status
- Created: 2026-09-23
- Parent: Issue 913 (clustered-worldserver)
- Phase: 9 (numbered under its parent)
- **Blocked by:** 913b
- **Blocks:** 913e

## Overview

Every item, character, mail, group, pet and corpse needs an identifying
number that is unique across the whole characters database. Today one
worldserver hands them out. With two worldservers writing to one database,
both would hand out the same numbers, and two different items would share
one identity. The damage lands on player inventories.

## Current Behavior

- At startup the worldserver reads the highest identifier in use for each
  kind of object (items, characters, mail, and so on) from the characters
  database. After that it counts upward in its own memory
  (`ObjectMgr`, the "high GUID" counters). No other process is consulted.

## Intended Behavior

Each worldserver in the cluster gets its own non-overlapping range for each
kind of identifier, for example world machine 1 counts from 1 000 000 000
and world machine 2 from 2 000 000 000. Ranges are handed out by the
scheduler (913e), or written into each machine's config. A worldserver
refuses to start if its range overlaps another live worldserver's.

## Implementation Steps

1. List every counter `ObjectMgr` loads at startup, with the datatype of
   each (most are uint32; items are the ones that run out first).
2. A source patch that seeds each counter from the machine's range instead
   of the database's highest value, and stops with an error message when
   the range is exhausted.
3. A check tool that reads the characters database and reports any
   identifier outside its owner's range.

## Open Questions

1. Items use 32-bit identifiers. How wide must each machine's range be so
   that a long-running server never runs out?

## Related
- `source-beta/src/server/game/Globals/ObjectMgr.cpp`: the counters
