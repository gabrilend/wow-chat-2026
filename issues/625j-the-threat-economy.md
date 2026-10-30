# 625j - The Threat Economy

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625f (the action economy, whose origin names this), 617z
  (tank-paced pulls), 617c3 (the dungeon draw)
- Priority: Medium
- State: planned

## Origin

The owner, 2026-10-30 (the whole passage in 625f): "threat economy (can
the tank handle more monsters, should an off-tank pull off of a faltering
main tank, etc)".

## Current Behavior

Not built. The bot module's tanks taunt what they lose and its damage
dealers hold back by fixed threat triggers ("medium threat").

## Intended Behavior

- **What the tank can hold.** A running measure of the tank's load: how
  many enemies are on it, how fast its health falls against the healing
  coming in. While there is room, damage dealers may pull more (617z: "If
  the DPS wants to go faster, they should just pull more mobs"); when
  there isn't, they hold.
- **The off-tank.** A second buddy able to tank (a tank shape, or the
  talents) takes enemies off a faltering main tank: one whose health
  falls faster than it is healed, or who is stunned or down.
- **Threat as a cost.** An answer that draws a lot of threat costs more
  for a damage dealer near the top of the threat list, less for the tank.

## Suggested Implementation Steps

1. The tank's load as plain arithmetic (enemies on it, health falling,
   healing in), with tests.
2. The off-tank's rule: when to step in, and when to hand back.
3. Threat as a cost in the draw.

## Open Questions

1. When an off-tank takes enemies off a faltering main tank, should it
   hand them back once the main tank recovers, or keep them to the end of
   the fight?
