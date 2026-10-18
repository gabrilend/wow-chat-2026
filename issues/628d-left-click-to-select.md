# 628d - Left-Click to Select: Heals and Buffs Reach the Buddy

## Status
- Created: 2026-10-17
- Phase: 6
- Parent: 628 (buddies wander as baked NPCs)
- Blocked by: 628b (the swap)
- Related: 616 (public healer frames)
- Priority: Medium

## Origin

See 628 (the owner's words, 2026-10-17, quoted in full there): "Left
click selects to heal or buff or whatever."

## Current Behavior

Not built. A wandering buddy is a player and is selected and cast on as
one.

## Intended Behavior

- **Left-click** selects the baked creature as a friendly target, as any
  friendly creature is selected.
- **What is cast on it reaches the buddy.** A heal heals the buddy; a
  buff is on the buddy, and stays on it when it swaps back to its player
  body; the creature shows the same buffs while it wanders.
- **Its health is the buddy's.** The creature's health and mana bars show
  the buddy's, so a player sees what needs healing.

## Suggested Implementation Steps

1. Answer 628's question 1: with the buddy hidden beside the creature
   (reading a), a spell landing on the creature is passed to the buddy
   (the same spell cast again by the caster on the buddy, or the effect
   copied); with the buddy logged out (reading b), the first spell logs
   it in and the swap happens first.
2. Health and mana kept equal both ways while baked.
3. Buffs copied onto the creature for display when it bakes, and the
   ones cast while baked kept on the buddy.
4. Test: heal and buff a baked buddy, swap it back, check health and
   buffs.

## Open Questions

1. Does casting a harmful spell on it count as "something happening"
   (628b's swap back), or is a buddy creature simply not attackable by its
   own side?
