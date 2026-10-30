# 625f - The Action Economy

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625h (the resource economy), 625j (the threat economy), 625g
  (forms and stances), 617z (tank-paced pulls: the movement economy),
  617e5b (boss fights by the warnings: the boss-mechanic economy)
- Priority: High (the owner: "I am very excited to work on the action
  economy.")
- State: in progress (window values and the cooldown timeline built; the
  worker threads and the multiplier next)

## Origin

The owner, 2026-10-30, word for word:

> Remember... there's multiple economies we need to balance. There's mana
> economy, (rage energy etc for the others), action economy (global
> cooldowns primarily, but also cast-times and such. Putting abilities on
> cooldown is valued to the action economy, especially if it can line up
> the times on when they come off cooldown so that they can be cast as
> often as optimizable), movement economy (how much to move, how fast the
> party is moving "slow down" or "go faster" or "out of mana" style),
> threat economy (can the tank handle more monsters, should an off-tank
> pull off of a faltering main tank, etc). These economies (and possibly
> others, including boss-mechanic economy (unique to each boss probably))
> need to be balanced artfully and skillfully to create systems that react
> dynamically and appropriately. Ideally, they could adjust with time
> spent learning, though only if we keep track of both A. how to learn,
> and B. where we started from, so if we wanted to we could either 1.
> learn from scratch as a batch, to see if we grow into different
> conclusions (the ideal state), or 2. to learn individually and become
> better at the game and our class as we level up and get better.
>
> I am very excited to work on the action economy.

## Current Behavior

Not built. The bot module takes the first answer a concern offers that is
useful and possible: an ability on cooldown is simply skipped, and nothing
weighs the time a cast costs, or plans when cooldowns come back. The
talent draw (625, built) and the economy plan (625d) weigh answers but
not time.

**Built so far (2026-10-30, committed, offline):** the window values
(`buddies_window_buffs.h`), each buff's gifts read from the game; every
class's abilities read from the game's tables by
`scripts/generate-ability-data` (`buddies_ability_data.h`, listing
`docs/ability-data.md`: 768 abilities, each one's cast time, cooldown,
global cooldown, resource and cost, and whether it is channelled, hits
at once, works over time or heals); each ability's profile for a window
read from that data, nothing set by hand. Checked by
`scripts/test-buddy-window-buffs`: from the data, Bloodlust is worth 1.30
to a Fireball mage, 1.075 to a Sinister Strike rogue, 1.15 to a
Corruption and Shadow Bolt warlock.

**The cooldown timeline, built 2026-10-30 (committed, offline):**
`buddies_cooldown_plan.h`. For one long cooldown it works out the best
moments to use it over the time the fight has left: the time is cut into
half-second steps, and from the end backwards each step keeps the most the
cooldown can still be worth if it is ready then (never used again, or used
at some moment within one cooldown from then and ready again a cooldown
later; a hold longer than a whole cooldown is never better, since using it
now and again at the held moment beats it). A use is worth the windows'
factor over the time it keeps working. **What the fight's end means
depends on the fight** (the owner, 2026-10-30, word for word: "for trash
mobs, yes it diminishes the value. But for a boss, even if it's the end
of the fight we still wanna burn it down as fast as we can, so use
everything."): against trash a buff counts only the part before the end,
and a cooldown still ready when the fight ends is worth a plain use in
the next pack, less the longer it would still be cooling then (so a
20-second buff isn't spent on a pack 10 seconds from dead; a single
strike, landing whole, still is); against a boss a buff counts whole
however near the end, and nothing is kept for after. What comes out: the worth of using it the moment it is ready, the best plan's
worth, its first use and every use, and the weight (the first over the
second: 1 when using it at once is best, less the more holding gains).
Lining up: a buddy's own cooldowns are planned with each other's planned
uses as windows, three passes, longest cooldown first.

**Kept quick** (the owner, 2026-10-30: "sounds performance intensive,
maybe someday we can make this stuff into equations rather than discrete
checks. For now this is fine."). Trying every moment within a cooldown
for every step cost about 90 milliseconds for a 30-minute plan of three
cooldowns. Now each use's worth comes from running totals of the windows'
factor (a long buff's average is one subtraction), and the best next use
from a running maximum (a queue of moments, each better than all earlier
ones after it, so no moment is looked at twice): about 1 millisecond, and
0.1 for a 5-minute fight. The step-by-step way is kept in the test as the
reference, and 400 random fights agree with it. Equations in place of the
steps (each window's edges as the only moments worth trying) stay the
later direction.

Checked by `scripts/test-buddy-cooldown-plan` (25 checks): a 10-second
wait for Bloodlust that costs no use is taken; a wait that costs a whole
use is taken only for a window worth more than the lost use (x2.5, not
x1.3); nothing is held for nothing; a boss's end burns everything; trash's
end keeps a long buff for the next pack; a 120-second cooldown waits for a
180-second one and its second use slides onto the other's second. Not yet: the worker threads, the fight's
length (625h's estimate), the windows from the party's buffs and a boss's
phases, and the weight handed to the talent draw's multiplier, all in the
server and waiting for those.

## Intended Behavior

**Time is the currency.** Every answer costs time: the global cooldown it
starts (1.5 seconds, less with haste), its cast time (a channel's whole
length), and the cooldown it puts itself on. The action economy weighs
what each answer gets done against the time it spends, and:
- **Using a cooldown is worth something in itself**: an ability off
  cooldown and not used is time wasted, so an ability whose cooldown is
  ready leans upward the longer it sits ready ("putting abilities on
  cooldown is valued").
- **Cooldowns lined up.** A buddy keeps a small timeline of its own
  abilities: when each comes back. It prefers the order that has the
  most of them used as soon as they return, and lines up the long
  cooldowns with each other and with empowered moments (625d: Bloodlust,
  a boss's weak phase), "so that they can be cast as often as
  optimizable".
- **Cast times against the moment**: a long cast is worth more when
  nothing will interrupt it (standing still, nobody hitting the caster),
  less when movement is coming (625d's movement measure) or the target
  may die first.
- **The global cooldown as the scarce slot**: off-global abilities
  (some instants, item uses) are slipped between global cooldowns rather
  than spending one.

**Most valuable uptime** (the owner, 2026-10-30, asked how long a ready
cooldown may wait: "we want to maximize valuable uptime. Can you think of
a way to do that?"). The agent's way, for the owner to curate: a
cooldown's worth over the rest of the fight is the sum, over every use it
will get, of what a use is worth at that moment (more inside an
empowered window: Bloodlust, a weak phase, another cooldown). Holding it
is right only when the plan with the hold is worth more than the plan
without:
- with T seconds of fight left (625h's estimate) and a cooldown of C
  seconds, using it now leaves room for about T / C more uses; holding it
  w seconds may cost one of them (when the remainder of T / C is small);
- a window starting in w seconds that multiplies a use by m is worth
  holding for when the held use's gain (m - 1) is more than the use it
  costs, a lost use counting at its own worth;
- so short holds for big windows are taken, long holds that cost a use
  are not, and near the fight's end every cooldown is used (nothing to
  save it for).
The check is plain arithmetic over each ability's timeline, worked out
again whenever the fight's estimate or a window's timing changes.

**Planning lives in the weights** (the owner, 2026-10-30: "this planning
should be reflected in the weights that we dynamically adjust as the
world around them changes and the situation they're addressing develops.
Lots of number crunching, gotta use parallel threads for each buddy-bot
and such..."). A buddy's plan (its next casts, its holds) is not a script
it follows: it is the weights its answers carry, worked out again as the
fight changes. The working out is heavy, so it is done off the world's
thread, by a pool of worker threads (one buddy's plan a task), each
finished plan handed to the multiplier the draw reads (625) between the
bot module's choices.

The action economy is one of several (625h resources, 625j threat, 617z
movement, 617e5b boss mechanics): each says how much an answer is worth
by its own measure, and the draw (625) weighs them together. Learning
(625k) may move its numbers, keeping how it learned and where it started.

## Suggested Implementation Steps

1. Designed with the owner (the open questions below), in a sandbox page
   first: one buddy's ability timeline over a fight, each choice shown
   with what each economy said.
2. The timeline as plain arithmetic in the buddy module's pure core
   (each ability's global cooldown, cast time, cooldown, readiness), with
   tests. (Done for long cooldowns: `buddies_cooldown_plan.h`; the global
   cooldown and cast times of the rotation's short abilities are next.)
3. Its weight joined to the talent draw's multiplier.

## Open Questions

1. How long may a buddy hold a ready cooldown to line it up with another,
   or with an empowered moment, before using it anyway? **Answered
   2026-10-30:** "we want to maximize valuable uptime": held only while the
   plan with the hold is worth more (above).
2. Should the timeline look ahead (plan the next few casts, as a skilled
   player does), or only weigh the next one by what is ready? **Answered
   2026-10-30:** the planning is reflected in the weights, worked out
   again as things change, on worker threads per buddy (above).
3. A use inside a window is worth m times a plain one: should m be what
   the window gives in numbers (Bloodlust's 30% haste: 1.3), or larger, to
   count the moment's importance (a weak phase, a burn) beyond its numbers?
   **Answered 2026-10-30:** "technically this is something we'd
   theorycraft and build reasonable answers for, but for now just give it
   an appropriate value for each buff. Bloodlust for example can't be 1.3x
   because some classes use haste rating more and value it more strongly.
   Focus on the buff it provides and have it interface with the ability
   economy." Built as `buddies_window_buffs.h`: each buff as what it
   provides (read from the game's spell table: Bloodlust and Heroism 30%
   haste, Power Infusion 20% casting speed and 20% cheaper, Avenging Wrath
   20% damage and healing, and so on), each ability as how much each
   provision moves it, and a buddy's m its abilities' factors weighed by
   their share of its casts. Checked by `scripts/test-buddy-window-buffs`:
   Bloodlust is worth 1.30 to a fire mage, 1.075 to an energy-bound rogue,
   1.15 to an affliction warlock (its damage over time isn't hastened).
   Starting values, kept for theorycraft to move. **Then, the same day:**
   "Remember we don't want to specify exact values. We want their value
   to come cleanly from the roots of the weights that determine their
   output - at the end of the day, EVERYTHING that we weigh collapses to
   just damage, and health." The buffs' gifts are the game's own numbers;
   how much each ability is moved by them (set by hand per kind of
   ability) is to be read from the ability's own data (cast time, global
   cooldown, resource, ticks), and the window's worth said in damage and
   health (`strategems/everything-is-damage-and-health.md`).
