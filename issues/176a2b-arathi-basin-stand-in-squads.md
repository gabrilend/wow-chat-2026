# 176a2b - Arathi Basin: Stand-in Squads

## Status
- Created: 2026-10-08
- Phase: 1
- Parent: 176a2 (an Arathi Basin match)
- Blocked by: 176a2a (the match)
- Related: 617t (stand-ins, roles), 617c3 (roles: tank and healer sums),
  176a2c (where squads go), 176a2d (how they walk)
- Priority: Medium

## Origin

The owner, 2026-10-08 (whole request in 176a2): "we should have
stand-ins spawn in groups of three, two dps and one healer. [...] They
should be able to claim bases, and when they respawn they should know how
to leave the graveyard and travel one way or the other. Whenever a
friendly base is taken, a tank character spawns at your base and waits
for the next group before advancing. The stand-ins don't use the
powerups. They just fight enemy units and attempt to cap bases."

## Current Behavior

Not built. Bots in a stock match each play alone by the bot module's
battleground tactics, use the power-ups, and have no squads.

## Intended Behavior

- **Trios.** Stand-ins appear at their home base in squads of three: two
  damage and one healer, each wholly its role (617t's rule: no
  part-healer), of a random race and class of its side that can take the
  role.
- **A tank per base taken.** Each time the side fully captures a base, a
  tank stand-in appears at the home base and waits there. The next trio to
  set out from home takes it in: four go out together, the tank leading
  (176a2d's diamond).
- **What they do.** Walk their route (176a2c); fight any enemy they meet
  (619's footwork); at a base that isn't theirs, click its banner and
  guard it until the capture completes, then go on. They never pick up
  the power-ups (speed, restoration, berserking).
- **Respawning.** A dead stand-in rises at its graveyard as the stock
  rules say. Out of the graveyard it does not wander: it waits a few
  seconds for others rising there, forms a squad with them (or goes alone
  if none come), and leaves by the graveyard's exits the alternating way
  (176a2c), "one way or the other".

## Suggested Implementation Steps

1. Making a squad: three stand-ins of the right roles at the tier, in a
   group, at the home spawn (617t's maker, 176a1's spawning).
2. The capture: walking to a banner, using it, staying near until the
   base flips, as the bot module's own tactics already do.
3. The tank: listen for a full capture by the side, make a tank at home,
   hold it there until the next trio leaves, then group it with them.
4. Leaving out the power-ups: the bot module's battleground tactics
   choose to collect them; stand-ins don't.
5. Respawning: gather at the graveyard, then the route's graveyard exit.

## Open Questions

1. **Tanks: how many?** One per capture, every time (a base taken, lost
   and taken again gives two), or one per base, or a cap per side?
2. **Where the tank waits:** "spawns at your base": the home base
   (Trollbane Hall or the Defiler's Den), or the base just taken?
3. **Guarding:** after a capture, does the squad stay to defend the base
   at all, or always move on? And if the side holds everything, do squads
   push into the enemy's home graveyard, or wait at the bases?
4. **Squads breaking up:** when one of a trio dies, do the two left go on,
   wait for it to come back, or fall back?
5. **Respawn gathering:** how long does a risen stand-in wait at the
   graveyard for others before going alone?
