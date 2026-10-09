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
  tank stand-in appears at the home base and waits there ("one for every
  capture. No limit. It waits at the home base until another party
  departs the home base"). The next squad to set out from home takes it
  in: they go out together, the tank leading (176a2d's diamond). Waiting
  tanks all leave with the next departure.
- **What they do.** Walk their route (176a2c); fight any enemy they meet
  (619's footwork); at a base that isn't theirs, click its banner and
  guard it until the capture completes, then go on. They never pick up
  the power-ups (speed, restoration, berserking).
- **Respawning: dynamic squads.** A dead stand-in rises at its graveyard
  as the stock rules say. The owner, 2026-10-08: "they should try and form
  dynamic squads. Two damage, one healer, though if there's an uneven
  number of units respawning then they should just all group up if they
  can't evenly divide into groups of two dps and one healer." So the
  stand-ins rising together split into trios of two damage and a healer
  when they divide evenly that way; when they don't, they all go as one
  group. They leave by the graveyard's exits the alternating way (176a2c),
  "one way or the other".
- **Departures from home, on the resource tick.** Squads leave the home
  base periodically: "maybe once every... 12 seconds? We could tie it to
  when resources tick." A departure goes out on each of the side's
  resource ticks (every 12 seconds holding one base, faster with more,
  `BG_AB_TickIntervals`), taking whatever trio and waiting tanks are
  ready.
- **Guarding.** "at least one stays to guard, when a stand-in approaches
  a base that's already theirs, then it guards as well. Otherwise, they
  attack." After a capture, one of the squad stays at the base; a
  stand-in whose route brings it to a base its side holds stays there
  too; every other stand-in goes on attacking.

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

1. (Answered 2026-10-08) **Tanks:** one per capture, no limit.
2. (Answered 2026-10-08) **Where the tank waits:** the home base, until
   the next departure.
3. (Answered 2026-10-08) **Guarding:** at least one stays; a stand-in
   reaching a base its side holds guards it too; the rest attack. Still
   open: when the side holds all five, do the attackers push into the
   enemy's home graveyard?
4. **Squads breaking up:** when one of a trio dies, do the two left go on,
   wait for it to come back, or fall back?
5. **Respawn gathering:** how long does a risen stand-in wait at the
   graveyard for others before its group sets out?
6. **Departures with nobody ready:** on a tick with no trio at home but
   tanks waiting, do the tanks wait for the next tick, or go alone?
