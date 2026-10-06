# 808a - Karazhan's Level

## Status
- Created: 2026-10-04
- Phase: 8
- Parent: 808 (Karazhan, an endgame raid in Azeroth)
- Blocked by: None
- Priority: Medium

## Origin

See 808 (the owner's words, 2026-10-04).

## Current Behavior

Stock: level 70-73 monsters.

## Intended Behavior

Every creature of map 532 (spawned, and those its scripts summon) set by
the owner's levels (2026-10-04: "the NPCs should be level scaled such that
the earliest ones are level 53ish I think? Same approximate level as BRD.
The final boss and the last 20% of bosses are level 60 only."): the first
bosses and their halls about 53 (as Blackrock Depths), rising boss by boss,
the last fifth of the bosses (and the final boss) 60; a step table in a
generated block, saved originals and an exact revert.

## Suggested Implementation Steps

1. Run 155f's generator for map 532.
2. Apply/revert SQL; the RAM test (`scripts/test-basic-sql-in-ram`).

## Open Questions

None beyond the parent's.
