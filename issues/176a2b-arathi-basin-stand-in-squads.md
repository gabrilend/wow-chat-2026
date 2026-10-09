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

**2026-10-08: the squad rules are built on paper; no stand-in exists to
follow them yet.** `src/lua-cc-test/lib/arathi-basin-squads.lua`: grouping
(trios, or one group when uneven), the river merge (six that make two
trios split), departures every 12 seconds with the place drawn among held
bases and home (one waiting group a place, home stacking, home as the
fallback, said so), invisible until the graveyard wave, tanks waiting at
home, players' places. Open questions built both ways: question 8
(`claimed` = "assault" or "capture"), question 9 (`tanks` = "home only"
or "any group"). Checked by `scripts/test-arathi-basin-rules`;
`scripts/compare-arathi-basin-variants` plays fixed scenarios under each reading and writes the results (ten simulated minutes: tanks wait 16.8 seconds on
average under "home only", 1.6 under "any group").

Before this, not built. Bots in a stock match each play alone by the bot module's
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
- **Dying, and coming back** (owner, 2026-10-08, replacing the pool:
  "how about we respawn stand-ins separately from players, at the
  increment time, at a random fully controlled base or the home base. Once
  they're "spawned" they're invisible and disabled until the next
  graveyard respawn, and then they move and attack and such. If the base
  gets claimed while they're invisible and disabled, before the "next
  graveyard spawn", then they are teleported to the home base and spawned
  there next. If another group is waiting to spawn at a location, then
  that location is either skipped, or another is queued to spawn there at
  the same time if there's only the home base (or if all the others have
  a spawn waiting. The home base is the fallback spawning location
  whenever anything goes wrong."):
  - stand-ins come back separately from players: on each departure (every
    12 seconds), the dead ones come back as a group at one place: a base
    their side fully holds (held and not under attack), drawn at random,
    or the home base;
  - placed there, they are invisible and do nothing until the next
    graveyard wave (the stock spirit healers raise the dead every 30
    seconds in Arathi Basin); then they appear, move and fight;
  - if their base is claimed by the enemy while they wait, they are moved
    to the home base and appear there instead;
  - one waiting group a place: a base with a group already waiting is
    skipped; when only the home base is left (or every other place has a
    group waiting), another group waits at the home base too, and both
    appear together;
  - the home base whenever anything goes wrong.
  Players use the graveyards as stock. A player who dies at a graveyard,
  or who enters combat right after rising there and dies in that same
  combat, comes back at the home base instead (2026-10-08, earlier).
- **Dynamic squads.** The owner, 2026-10-08: "they should try and
  form dynamic squads. Two damage, one healer, though if there's an uneven
  number of units respawning then they should just all group up if they
  can't evenly divide into groups of two dps and one healer." Stand-ins
  coming back together (at home or at a base) split into trios of two
  damage and a healer when they divide evenly that way; when they don't,
  they all go as one group.
- **A departure every 12 seconds.** "they wait. We send out a party every
  12 seconds or so." Every 12 seconds the home base sends out what is
  ready: the trios (or the one uneven group) and every waiting tank. With
  no squad ready, tanks wait for the next departure; they never go alone.
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
5. Dying and coming back: the place drawn on each departure (a held base
   or home, one waiting group a place, home as fallback), invisible and
   inactive until the graveyard wave, moved home if their base is lost;
   players dying at a graveyard (or in their first fight after rising)
   sent home.

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
5. (Answered 2026-10-08) **How soon back:** placed on a departure,
   active from the next graveyard wave.
6. (Answered 2026-10-08) **Departures with nobody ready:** tanks wait;
   a party leaves every 12 seconds.
7. **"Immediately after spawning":** how long after rising does a
   player's first fight still count, if they die in it, for coming back at
   home instead of the graveyard?
8. **"Claimed":** a waiting group is moved home when its base is
   "claimed": when the enemy clicks the banner (the base under attack, its
   bonus off), or only when the enemy fully captures it?
9. **Tanks and spawning at bases:** tanks wait at home for a departure.
   With squads now also coming back at bases, does a tank join only a
   group appearing at home, or can it be placed with a group at a base?
