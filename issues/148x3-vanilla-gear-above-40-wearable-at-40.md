# 148x3 - Vanilla: Gear Above 40, Wearable at 40 and Scaled

## Status
- Created: 2026-10-27
- Phase: 1
- Parent: 148x
- Blocked by: none
- Related: 155k (basic's Outland gear: "proportional, by item level", the
  tool this reuses), 155f (the dungeon gear's ladder), 155z10 (drops by
  rank and quality)
- Priority: Medium
- State: plan only

## Current Behavior

Stock: gear of the zones and dungeons above 40 needs levels 41-60; a
level 40 can't wear it.

## Intended Behavior

- **Every item needing a level from 41 to 60 needs 40.**
- **Its stats scaled proportionally by item level** into a ladder above
  the gear of levels 20-40, each item keeping its place in its range and
  its loot table (the owner's rule for Outland, 2026-09-24: "scale the
  drops according to ilevel, and try to keep them proportionally at the
  same position in the new range that they were in the old range"). Same
  item, same look, smaller numbers.
- **The ranges, by analogy with basic** (to be confirmed): on basic,
  Outland's world greens start at the level-60 dungeon blues and end at
  the Emerald Dragons' epics; Outland's blues run on to the start of
  Naxxramas-40. Here: the greens above 40 would start at the blues of the
  level-40 dungeons (Uldaman, Razorfen Downs) and the raid epics would end
  where the ladder's top rung should be.
- **Made by basic's gear scaling tool**, given vanilla's ranges.

## Suggested Implementation Steps

1. The gear tool takes its source range and target range per quality as
   settings.
2. Vanilla's ranges written out as a table for the owner to confirm.
3. Its SQL as an install step gated on `vanilla`; a quick test that no
   item on vanilla needs more than 40, and that scaling keeps each item's
   order within its quality.

## Open Questions

1. The top of the ladder: how strong should Molten Core's and Naxxramas's
   epics be at 40, against the best gear of levels 20-40?
