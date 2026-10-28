# 617e15 - Places Conquered, and the Monsters Push Back

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 617e
- Related: 617e6 (exploring as painting: the "bricks"), 617e14 (watching
  it from above), 617e5 (fighting together)
- Priority: Medium
- State: plan only (the owner's design, written down)

## Origin

The owner, 2026-10-27:

> the player-bot buddies should circle about, and sometimes dodge through
> scenery. They should explore, paving exploration bricks onto each part
> of the floor as they examine it for weakness. they should stand guard
> with their friends, and as they stay in a location, it becomes
> conquered, and theirs. But, the monsters fight back, and the more
> eagerly the warriors push in, the faster and more powerful they throw
> attacks back. Every quest is a raid, every dungeon a lair.

## Current Behavior

Buddies roam a sub-zone by the pinwheel and paint the cells they see
(617e6). Nothing is held: a place a clan has stood in is no different
after. Monsters spawn and fight as stock.

## Intended Behavior

- **Circling and dodging**: buddies circle about, sometimes slipping
  through the scenery (617e6's room orbit, 617e11's passing).
- **Exploring as paving**: each part of the floor they look over is paved
  with an exploration brick (617e6's paint), "as they examine it for
  weakness".
- **Standing guard together**: a clan staying in a place guards it.
- **Conquest**: the longer a clan holds a place, the more it becomes
  theirs ("it becomes conquered, and theirs").
- **The monsters push back**: "the more eagerly the warriors push in, the
  faster and more powerful they throw attacks back": the place's monsters
  answer a clan's pressure with more, and stronger, attacks.
- "Every quest is a raid, every dungeon a lair."

## Suggested Implementation Steps

1. What "conquered" is, as data: per sub-zone cell (617e6's grid), a
   holding of each clan that grows while they stand there.
2. What pressure is (open question 2), and the monsters' answer to it
   (the ambush system's spawns, 120-160 yards out, faster and stronger).
3. Shown from above (617e14c): held cells in the clan's colour.

## Open Questions

1. **What conquering a place gives**: a mark only (seen from above), or
   something in play (safer rest, a camp, a vendor)?
2. **Pressure**: kills per minute in the place, the clan's numbers, how
   deep into it they push, or all three?
3. **When the push ends**: does a conquered place stay theirs when they
   leave, or fade?
