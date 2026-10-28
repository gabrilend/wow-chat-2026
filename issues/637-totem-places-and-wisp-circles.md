# 637 - Totem Places and Wisp Circles

## Status
- Created: 2026-10-27
- Phase: 6
- Related: 636 (Earthliving), 635 (the Botanica party)
- Priority: Medium
- State: plan; open questions below

## Origin

The owner, 2026-10-27:

> protection stone totem field. can we draw a small circle of wisps around
> each totem? and make it so that you can only place one totem in each
> space. each shaman can do their own, so many can live and breathe and
> pwn. the circle of whisps should be experimentally 1/3rd of the total
> area, to know how close you are to it, players will learn when they are
> approaching and they feel how soon they get a bonus buff points. The
> most important things for making buffs and debuffs feel rewarding is
> feeling your combat change depending on their presence or absence.

## Current Behavior

A totem's effect reaches everyone in its party within its radius (most
are 20 or 30 yards), but nothing in the world shows where that edge is.
A shaman drops each totem at their feet, so their four totems stand
together in one spot.

## Intended Behavior

- **A circle of wisps round each totem**, small floating lights on the
  ground, enclosing a third of the totem's area ("experimentally 1/3rd of
  the total area": a radius of the totem's radius divided by the square
  root of 3, about 58% of it). Walking toward a totem, a player sees the
  wisps and learns how near the full area's edge is.
- **One totem to a space**: a totem can't be placed where another totem's
  wisp circle already stands; "each shaman can do their own", so each
  shaman's totems spread out, and many shamans fill a field of them.
- **The design principle** (the owner): "The most important things for
  making buffs and debuffs feel rewarding is feeling your combat change
  depending on their presence or absence." The wisps make the presence
  seen before it is felt.

## Suggested Implementation Steps

1. The wisps: a ring of small visual-only objects or a ground visual
   spawned with the totem and removed with it (a server hook on a totem's
   summon and its end), the ring's radius from the totem's own spell
   radius.
2. The placing rule: a totem's summon refused (with the reason shown) where
   another's wisp circle stands, or moved to the nearest free place (open
   question 2).
3. In game with the Botanica party's shaman.

## Open Questions

1. "One totem in each space": does it hold between the totems of one
   shaman (their four can't stand together) or only between different
   shamans' totems?
2. **A refused place**: the totem not placed and the shaman told, or
   placed at the nearest free spot?
3. "Protection stone totem field": Stoneskin Totem's field, the
   first totem to try this on, or a new totem?
4. "Bonus buff points": a stronger effect inside the inner third than in
   the rest of the area, or only a sign of where the edge is?
