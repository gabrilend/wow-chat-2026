# 625h - The Resource Economy, and the Fight's Length

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625d (choosing by the moment's economy: its mana measure,
  which this refines), 625f (the action economy), 625i (the healer's seat)
- Priority: Medium
- State: in progress (the fight-length guess, the smooth lines and the thrift built offline;
  the server reading them next)

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

In the bot module, its health bands (critical below 25%, low 45%, medium
65%, almost full 85%) are hard lines, and its one mana rule a switch at
60%; nothing in the server reads the smooth lines below yet.

**The smooth lines and the thrift, built 2026-11-06 (offline, on a branch
for review):** `buddies_thrift.h`, steps 1 and 3.
- **The lines, smoothed** (`Hurt`, `Saving`): each band fades in over 10
  points either side of its line (two lines 20 apart meet without
  overlapping), by the smooth step 3t² - 2t³, so there is no jump and no
  kink; far from a line it is the bot module's own band (at 35%, three of
  four), and 44% and 46% differ by 0.04 where the bands set them a quarter
  apart. The save-mana switch slides the same way from 50% to 70%.
- **Regeneration as time** (`PerSecond`, `RefillSeconds`, `Thrift`): mana
  a second at the moment (mana per 5 always; spirit five seconds after the
  last cast, before that only the share a talent like Meditation keeps;
  a drink only between fights), and the seconds the missing part takes to
  come back; energy by its own 10 a second, focus 5, rage and runic power
  0 (they come from fighting: nothing to save). A cost counts by that
  time: not under 30 seconds, wholly past 120, smooth between.
- **The lean among answers** (`Weigh`, `Lean`): the speed weight is how
  hurt the ally is, the cost weight what is left of that times the
  thrift; each answer's lean is how near it comes to the fastest, to the
  speed weight's power, times how near to the cheapest, to the cost
  weight's power. A dying ally: the fast heal; a scratched one with mana
  slow to come back: the cheap one; a scratched one with mana back in
  seconds: nothing much preferred ("told to be extravagant").
- **The surplus** (`Surplus`, `DamageLean`): what a buddy holds, less
  what it loses by the fight's end (its need a second less what comes
  back, over the fight-length guess counted a third longer); no end seen,
  nothing spare; coming back faster than needed, all of it spare. Damage
  spells lean from 0.05 (nothing spare, as the healer's seat leans) to 1
  (spare mana for three of them), smoothly. A Bloodlust ahead shortens the
  guess as a stretch and so leaves more to spare.
- **Between fights** (`Between`): a buddy below 60% mana drinks and says
  "mana", drinks on until full and says "ready" (617z's words; the tank's
  pace, `roam/buddy_pace_core.h`, hears them as stop and go on). Rage and
  runic power never drink.
Checked by `scripts/test-buddy-thrift` (53 checks, a quick test), the
owner's three cases of 2026-10-30 among them (trash: damage spells freely;
a long fight: kept; a fight ending sooner than the mana demands: damage
again); 22 of 22 deliberately broken versions of the header caught. Not
yet: the server reading the character's regeneration and the party's
need for heals each half second, and the forward pass's leans taking the
thrift's (the draw multiplying them).

**The fight's length, built 2026-10-30 (committed, offline):**
`buddies_fight_length.h`. The rate is the slope of the straight line that
best fits the enemies' health over the last seconds (so one big hit or a
heal on an enemy moves it a little); fewer than two readings, or readings
under a second apart, say nothing yet, and a rising health is no fall. The
time left works through the bursts ahead stretch by stretch (between two
burst edges the rate is steady); a party member dying or joining rescales
the rate by their part of the party's damage. With no fall measured, the
end is not known and the time left is endless; the cooldown timeline
(625f) then plans over three of the buddy's longest *regularly used*
cooldown, long enough that nothing is used early for an end that isn't
coming (the owner, 2026-10-30, word for word: "longest regularly used
cooldown. I think Lay on Hands has a 1 hour cooldown for example? Dont'
wanna plan around that..."; it is 20 minutes in this version,
Reincarnation 30). Regularly used: 10 minutes or less, a starting value
(the Fire Elemental Totem, Army of the Dead and Rebirth are 10, used fight
after fight in a raid; Lay on Hands is an emergency's) standing in for its
root, each buddy's record of which cooldowns it is ready for fight after
fight (625k). None regular: nothing to plan around. Checked by
`scripts/test-buddy-fight-length` (20 checks): two plan a cooldown over
the guess, three choose the horizon (Lay on Hands left out). Not yet: reading the enemies' health in the
server, and the thrift that weighs mana against the time left.

## Intended Behavior

- **Smooth, not stepped.** The lean from cheap answers to fast ones slides
  with the ally's health, and the module's bands themselves are smoothed:
  an ally at 44% and one at 46% are treated almost alike.
- **Regeneration as time.** A buddy's resource is measured as how long it
  takes to refill (mana from spirit and mana per 5 seconds; rage, energy
  and runic power by their own rules): under about 30 seconds it barely
  matters; past two minutes every cost counts.
- **In combat and out** (the owner, 2026-10-30, asked "in combat / out of
  combat behavior?"; the agent's design, for the owner to curate): the
  refill time is measured with the regeneration that applies at the
  moment. In combat that is the slow kind (mana per 5 seconds, and spirit
  only past five seconds without casting, the game's own rule; rage and
  energy by their own); between fights it is the fast kind, with
  drinking. So in combat thrift weighs by the fight's length (below);
  out of combat a buddy below a share of its mana drinks before the next
  pull and says "mana" (617z's word) so the tank waits, and its thrift
  starts the next fight fresh.
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
   **Decided 2026-11-06 (the agent's call, for the owner to curate):**
   with the margin: the need is counted over the guess and a third more
   (`MARGIN`, one number). The guess is a straight line through the last
   seconds, and a boss's later phases or an add can make it short; a
   healer that spends on damage and then runs dry costs more than one that
   keeps a little back. Spending is not all or nothing either: damage
   spells lean in smoothly as the surplus grows past one cast toward three.

## Decisions (2026-11-06)

The agent's calls while building steps 1 and 3, for the owner to curate;
each number is one constant in `buddies_thrift.h`:
- **How soft a line is**: 10 points either side (the bands are 20 apart,
  so each slide ends where the next begins).
- **The thrift's two times**: the issue's own 30 seconds and two minutes.
- **Speed against cost**: the speed weight is the hurt; the cost weight is
  (1 - hurt) times the thrift, so a fast-refilling buddy weighs cost
  little even on a scratched ally (625d: "more mp5 ... means mana economy
  is devalued and action economy is told to be extravagant").
- **Rage and runic power**: nothing to save (they come from fighting), so
  their thrift is 0 and they never drink; energy and focus refill by
  their game rates.
- **Drinking between fights**: below 60% (the bot module's save-mana line,
  reused), until full, with "mana" and "ready" said as 617z hears them.
- **Damage spells' lean**: 0.05 with nothing spare (as the healer's seat
  leans a dry healer's heals), 1 with three casts' worth spare.
