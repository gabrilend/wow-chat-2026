# 148x1 - Vanilla: the Open World Above 40, on a Level Ladder

## Status
- Created: 2026-10-27
- Phase: 1
- Parent: 148x
- Blocked by: none
- Related: 155k (basic's Outland world levels: the step and the tool this
  reuses), 155m (true creature levels), 155z1 (Outland's folk scaled to
  their threats), 803 (level-gap caps)
- Priority: Medium
- State: plan only

## Current Behavior

Stock: the creatures of the zones above 40 stand at levels 41-60 (elites
and named ones a little higher), out of reach of vanilla's level-40 cap.

## Intended Behavior

- **Every hostile creature of stock level above 40 in the open world** is
  moved onto the vanilla ladder (148x's first open question: a straight
  squeeze of 41-63 onto 41-58 is proposed), its health and damage those of
  its new level. Friendly folk are not moved, or move with the threats
  around them as basic's Outland folk do (155z1).
- **Loot tables unchanged**: a drop belongs to the creature, not its level;
  the gear's own numbers are 148x3's.
- **Made by basic's world levels tool**, given vanilla's range and mapping
  as settings, gated on the vanilla profile.

## Suggested Implementation Steps

1. The world levels tool takes a mapping (stock level to new level) as a
   setting; basic's "+4 in Outland" becomes one mapping, vanilla's squeeze
   another.
2. Its SQL for vanilla, as an install step gated on `vanilla`, with a
   reverse.
3. A quick test: no hostile open-world creature on vanilla above the
   ladder's top, and none moved below 41.

## Open Questions

- Follows 148x's first question (the ladder's shape).
