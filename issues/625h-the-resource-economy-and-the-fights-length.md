# 625h - The Resource Economy, and the Fight's Length

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625d (choosing by the moment's economy: its mana measure,
  which this refines), 625f (the action economy), 625i (the healer's seat)
- Priority: Medium
- State: planned

## Origin

The owner, 2026-10-30, answering questions about the healing economy,
word for word. On the lean from cheap heals to fast ones: "smoothly. Also
those breakpoints should be smoothed as well." On measuring regeneration
as how long a buddy takes to refill its mana:

> yes a trash mob fight for example might not require a long-duration
> stretch of healing, so they can freely throw out damage spells
> inbetween casting their most powerful and expensive spells on the tank
> or whoever needs it. However in a longer fight they are less likely to
> cast damage spells because they probably will need their mana. However
> if the fight is ending sooner than their mana supply demands, then they
> can cast out damage spells as well. We'll need an estimate for when the
> fight might end that dynamically updates as party members die or the
> speed of health on the boss adjusts. Though it should take into account
> things like bloodlust or whatever, not as a flat value, but as a time
> period where the party deals more damage and such.

And earlier: "the less mana we have, the more important mana economy is"
(625d); "mana economy, (rage energy etc for the others)" (625f).

## Current Behavior

Not built. The bot module's health bands (critical below 25%, low 45%,
medium 65%, almost full 85%) are hard lines, and its one mana rule a
switch at 60%.

## Intended Behavior

- **Smooth, not stepped.** The lean from cheap answers to fast ones slides
  with the ally's health, and the module's bands themselves are smoothed:
  an ally at 44% and one at 46% are treated almost alike.
- **Regeneration as time.** A buddy's resource is measured as how long it
  takes to refill (mana from spirit and mana per 5 seconds; rage, energy
  and runic power by their own rules): under about 30 seconds it barely
  matters; past two minutes every cost counts.
- **The fight's length.** A running estimate of when the fight will end:
  the enemies' health falling at the rate it has been falling, corrected
  as party members die or join, with known bursts (Bloodlust, a weak phase)
  counted as stretches of faster damage, not a flat amount. Against it,
  the resource a buddy will still need: when its mana outlasts the fight,
  a healer may spend the surplus on damage spells between its heals; in a
  long fight it keeps its mana.

## Suggested Implementation Steps

1. The smooth curves in place of the bands, as plain arithmetic with tests.
2. The fight-length estimate: health falling over the last seconds, the
   party's size, the bursts known; a test on recorded fights.
3. The surplus: resource left minus resource needed until the estimated
   end; positive lets damage spells in.

## Open Questions

1. How sure should the fight-length estimate be before a healer spends
   on damage: spend as soon as the estimate says there is surplus, or only
   with a margin (say the estimate could be a third too short)?
