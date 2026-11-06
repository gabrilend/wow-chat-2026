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
- State: in progress (window values, the cooldown timeline and the short
  abilities' look ahead built; the worker threads and the multiplier next)

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
however near the end. **Which fights are boss fights** (the owner,
2026-10-30: "should be for rare elites in the open world as well, but not
regular elites."): a boss (the game's boss rank, or on the dungeon's boss
list) or a rare elite; a regular elite is trash. **What is kept for the
next fight**: one use there at what it is worth there against one here,
less by the share of a cooldown it would still be cooling when the next
fight starts. After trash the next pack is the same and pulled at once.
After a boss with no boss known to follow, nothing, so everything is used;
before a harder boss more than one, so a big cooldown is saved for it (the
owner, 2026-10-30, on Bloodlust: "I'm concerned we won't use it... But,
better to get the full use of a BL on the next boss than waste it on an
easier boss."). The agent's call, for the server's side: the next boss's
worth against this one's is the ratio of their expected lengths (each
boss's health over the party's damage per second; the dungeon's boss list
gives the next one, and its pull time is guessed from the trash between),
and Bloodlust and Heroism are planned with the party's lockout as their
cooldown (Sated and Exhaustion, 10 minutes, read from the spell table;
their own cooldown is 5). Checked: with a minute of this boss left and a
harder one 2 minutes after it, Bloodlust is saved; with an equal one, or
one 10 minutes off, it is spent. What comes out: the worth of using it the moment it is ready, the best plan's
worth, its first use and every use, and the weight (the first over the
second: 1 when using it at once is best, less the more holding gains).
Lining up: a buddy's own cooldowns are planned with each other's planned
uses as windows, three passes, longest cooldown first.

**Lockouts** (the owner, 2026-10-30, word for word, after Bloodlust was
planned by Sated: "consider a paladin's forebearance similarly. But keep
in mind some spells like Blessing of Protection can put it on other
targets, not just the casting paladin."). A lockout is a mark on the
character an ability reaches (the caster for one cast on oneself, the
target otherwise) that refuses some abilities to that character for a
while. `scripts/generate-ability-data` writes them beside the abilities
(`BUDDY_LOCKOUTS`, and a table in `docs/ability-data.md`): Forbearance (2
minutes) and the Avenging Wrath marker (30 seconds), put on whoever
Divine Shield, Divine Protection or Hand of Protection reaches (and by a
Lay on Hands on oneself; the marker by Avenging Wrath too); Sated and
Exhaustion (10 minutes) by Bloodlust and Heroism; Hypothermia by Ice
Block; Weakened Soul by Power Word: Shield; and three "while up" pairs
read from the spell table (Berserk refuses Tiger's Fury, Arcane Power and
Presence of Mind each other). Durations are read from the table. Who
puts what on comes from the server: its general rule (a class spell
refused while a debuff is on its caster or target puts that debuff on)
and the paladin and shaman scripts, each cited in the generator, which
stops if the table's own exclusions disagree with its rows.
`buddies_lockouts.h` turns them into plans:
- an ability is planned on the longer of its cooldown and the mark it
  leaves on itself (Bloodlust 10 minutes; Divine Shield its own 5);
- one of a buddy's cooldowns refuses another for so long (Divine Shield
  and Avenging Wrath, 30 seconds each way): the timeline holds no use in
  the stretch a planned use blocks, and a cooldown never takes a moment
  whose lockout would land on another's planned use. Lining up then tries
  each cooldown first in turn and keeps the set worth most together: with
  200 seconds of a boss left, Avenging Wrath at 0 and 180 and Divine
  Shield at 30 (worth 3), not the shield at once and one wrath (2);
- a mark someone else left refuses the buddy's own abilities until it
  runs out (another paladin's Hand of Protection: no Divine Shield for 2
  minutes), and a party member bearing one is no one to give that ability
  to (625l): read by the server from the marks on each character.
Checked by `scripts/test-buddy-lockouts` (21 checks).

**Kept quick** (the owner, 2026-10-30: "sounds performance intensive,
maybe someday we can make this stuff into equations rather than discrete
checks. For now this is fine."). Trying every moment within a cooldown
for every step cost about 90 milliseconds for a 30-minute plan of three
cooldowns. Now each use's worth comes from running totals of the windows'
factor (a long buff's average is one subtraction), and the best next use
from a running maximum (a queue of moments, each better than all earlier
ones after it, so no moment is looked at twice): about 1 millisecond, and
0.1 for a 5-minute fight (with the lockouts and every order tried in
lining up: 3.6 and 0.5). The step-by-step way is kept in the test as the
reference, and 400 random fights agree with it. Equations in place of the
steps (each window's edges as the only moments worth trying) stay the
later direction.

Checked by `scripts/test-buddy-cooldown-plan` (30 checks): a 10-second
wait for Bloodlust that costs no use is taken; a wait that costs a whole
use is taken only for a window worth more than the lost use (x2.5, not
x1.3); nothing is held for nothing; a boss's end burns everything; trash's
end keeps a long buff for the next pack; a harder boss next keeps
Bloodlust for it; a 120-second cooldown waits for a
180-second one and its second use slides onto the other's second. Not yet: the worker threads, the fight's
length (625h's estimate), the windows from the party's buffs and a boss's
phases, and the weight handed to the talent draw's multiplier, all in the
server and waiting for those.

**The short abilities' global cooldown and cast times, built 2026-11-06
(offline, on a branch for review):** `buddies_rotation_time.h` (step 2's
"next"). A look ahead of 6 seconds tries every order of a buddy's
abilities on the global cooldown (and waiting for one about to come
back): each cast holds the next for the longer of its cast time and its
global cooldown (haste shortens both, the global cooldown no lower than
the game's 1 second), comes back a cooldown after it lands, and is worth
its worth when it lands: nothing if movement is coming before it lands
(instants go on while moving), nothing if the target dies under it (one
begun after is on the next enemy), nothing past the fight's end; a
channel keeps the part before. A cast straddling the look ahead's end
counts by its share inside, so a long cast begun at the edge earns no more
than its time there. After the look ahead, each ability with a cooldown
is used about once a cooldown from when it is next ready to the fight's
end, each use gaining its worth less what the buddy's filler (its best
ability without a cooldown, per second) would have earned in its slot:
so a cooldown started sooner is worth more, and one no better than the
filler is no hurry. Each ability's weight for the draw's multiplier is the
best order starting with it against the best of all (1 for the best first
cast, 0 for one not ready); the answer also says when waiting is best and
for how long. Abilities off the global cooldown are slipped in between,
weight 1 whenever ready. Cast times, global cooldowns and cooldowns come
from the generated ability data (a channel's length from its aura's).
Checked by `scripts/test-buddy-rotation-time` (31 checks, a quick test):
Fireball over Scorch standing still, Scorch with movement 2 seconds off,
Fireball again with 75% haste; Mortal Strike over a slightly weaker
filler, the two even when worth the same; Fire Blast back in 0.2 seconds
waited for rather than starting a Fireball; a 0.2-second hold in the
middle of a plan; a channel cut by movement. 27 of 27 deliberately broken
versions caught. About 0.2 milliseconds for eight abilities at no haste,
6 at 50% haste (more casts fit in the look ahead), for the worker threads
to carry. Not yet: the resource each cast costs (625h's), pushback when
the caster is hit, the worth handed in from the talent draw, the weights
handed to it, and the worker threads.

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
   tests. (Done for long cooldowns: `buddies_cooldown_plan.h`; for the
   rotation's short abilities, their global cooldown and cast times:
   `buddies_rotation_time.h`, 2026-11-06.)
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

## Decisions (2026-11-06)

The agent's calls while building `buddies_rotation_time.h`, for the owner
to curate; each number is one constant or setting there:
- **"Leans upward the longer it sits ready"** is read as: every moment a
  ready cooldown waits costs the uses it pushes past the fight's end, the
  same each moment (time already lost is gone, so the lean does not grow
  with it), and only by what a use gains over the filler it displaces. An
  ability no better than the filler gets no hurry from its cooldown.
- **The look ahead is 6 seconds** (four global cooldowns); a fight of
  unknown length is counted as 30 seconds (a pack's ordinary length)
  until 625h's estimate is handed in.
- **Movement** is said as when it comes and how long it lasts (2 seconds
  by default): a cast with a cast time begun before it and landing after,
  or begun during it, is lost; instants go on.
- **A dying target**: a cast begun before the death and landing after is
  wasted; one begun after is on the next enemy and counts.
- **The weight** is the best order starting with an ability against the
  best order of all, as the long cooldowns' plan does; when waiting is
  best, the answer says so (no ability first) and for how long, for the
  server to hold the cast.

