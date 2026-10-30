# 625n - The Fight's Forward Pass

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625d (choosing by the moment's economy: the answers layer),
  625f (the action economy), 625h (the fight's length), 625i (the
  healer's seat), 625j (threat and the fight curves), 625k (learning that
  can start over), 625l (buffs given to who uses them most), 625m (pets),
  627 (the bots think only when something happens)
- Priority: High
- State: in progress (all six layers built and tested offline; the
  server's side, the draw's hookup included, written and waiting for the
  compile; replays, casts and cooldowns read from the game next)

## Origin

The owner, 2026-10-30, word for word:

> okay so the curve is a path through a series of weights, sorta like
> when an LLM is processing a long string of output text. At the instant
> when it processes it's next token, it feeds all the previous data
> through the same weights and sees where it trajectorizes to. We want to
> do something similar, all of the status effects of the fight should be
> charted and mapped and routed through these weights, each moment we
> supply the entire state and it updates the fight curve according to the
> new, and extended, and desired, state.
>
> tell me soooo much about how you plan to architect this.

Asked what is desired beyond victory, what a buddy may know, how far back
it remembers, and which weights grow, word for word:

> depends on the group. What do they value? besides victory, bots prefer
> lower gold cost (use fewer consumables) and faster time (3 minute kill
> instead of 4). When questing and such, they prefer things like
> gold-per-hour, and exp-per-hour. If the player is grinding a certain
> mob, they will try to find those, but that's later so don't worry about
> that now.

> we can let them know. Yes, it's not human, but humans have better
> capabilities in some ways and worse in others. So, with an eventual
> goal of equalizing the presented information, let's just let them see
> the numbers for now.

> a minute is fine.

> I don't imagine they will grow very much. They are things like, how
> much certain talents benefit certain abilities, how critical strike
> rating relates to certain spells, how resistant a target is to a
> certain type of shadow blast, how important mana is to this particular
> fight, stuff like that.

## Current Behavior

Not built as a whole. Its layers exist offline, each in its own issue
and tested: the rates (the fight's length, 625h), attention (625j), the
fight curves and the tanks' swaps (625j), the cooldown timeline (625f).

**Layer 2, marks into modifiers, built 2026-10-30 (committed, offline):**
`buddies_marks.h`. Every aura effect on a character, by its type and
value, folded into what the fight curves read: damage taken by kind
(physical, magic) and dealt, healing received, attack haste and cast
haste (kept apart: Bloodlust's two effects haste each once), movement
speed, damage and healing ticking each second, an absorb, armour flat and
by a share; stacks counted once each, as the server applies them; types
the curves don't read add nothing. The kinds of damage are weighed by
the enemy's physical share, and armour turns into a reduction by the
server's own rule (checked against `Unit::CalcArmorReducedDamage`). In the
server each aura's effects will be read live; for planning an ability
before it is cast, `scripts/generate-ability-data` writes every class
ability's aura effects (`BUDDY_ABILITY_AURAS`, 216 of them: Shield Wall
-60% taken, Mortal Strike -50% healing, Corruption 180 every 3 seconds).
Checked by `scripts/test-buddy-marks` (18 checks), the last carrying
Shield Wall into a tank's fight curve (2000 short without, none with).

**The snapshot and the minute of events, built 2026-10-30 (committed,
offline):** `buddies_fight_state.h`. The snapshot as plain data (the
fight's time and windows; each member with health, resource, role,
class, position, cast, cooldowns and marks, a pet naming its master; each
enemy with health, rank, cast, marks, whom it attacks and its threat
list), what kind of fight it is (a boss or rare elite makes it a boss
fight), and what someone's marks add up to (layer 2). The minute of
events: each hit and heal added as it comes and taken back off as it
falls out of the minute, so damage taken, healing received and damage
dealt per second, and each dealer's physical share, are always one
division (over the time covered, at least a second); the enemies' health
read once per snapshot, for the fight's time left. Checked by
`scripts/test-buddy-fight-state` (12 checks), among them 4000 uneven
events whose running sums match re-reading the whole minute.

**One step, snapshot to verdict, built 2026-10-30 (committed, offline):**
`buddies_forward_pass.h`. In order: the fight's time left (or the
horizon from the party's classes' regularly used cooldowns while it can't
be seen); every member's marks as they stand; whom each enemy attacks;
each enemy's real damage, read back through the armour and marks of the
one it was hitting over the minute; for each member, what comes at it,
how much its armour lets through (by the attackers' physical share), and
the healing reaching it before its healing marks; each member's fight
curve, its marks riding on it until they wear off; the party's
shortfall; which tank should hold the hardest hitter. An answer is tried
on a copy (a buff or debuff it would put on someone, a heal now, a
taunt): a tried taunt changes whom the enemy attacks next and moves the
healing with it (the healers heal whoever is hit), never what the enemy
has done. Its worth is the shortfall it takes away, in health. Checked by
`scripts/test-buddy-forward-pass` (15 checks) on a made-up boss fight: a
tank under 2 seconds from dead; Shield Wall worth about 52000, Lay on
Hands 24000 (what it adds before the tank is full), the off-tank's taunt
about 4000, and more when the tank carries a boss's debuff, the tanks'
plan then handing the boss over.

**The desired state's measures, built 2026-10-30 (committed, offline):**
an answer is judged in two parts, compared in order: the health it saves
(the shortfall it takes away: victory first), then the group's time it
saves, in seconds: seconds off the fight's end (an answer can bring a
burst, the party's damage multiplied for a while, which the fight-length
guess works through), less the gold it uses up as the seconds the group
takes to earn that much back at its own gold per hour (measured by the
server from what the group has gained; nothing earned yet, gold counts
nothing). Checked (21 checks in all): Bloodlust brings a minute's fight
12 seconds sooner; a potion is drunk when the tank is dying, whatever it
costs, and not when the tank is healed faster than hurt (20 seconds of
earning for nothing).

**The server's side, written 2026-10-30, waiting for the owner's
compile** (compiler-checked on a RAM copy; not committed until it
compiles): `buddies_forward_pass.cpp`, behind `Buddies.ForwardPass` (0
off; `Buddies.ForwardPass.Threads`, default 2). Each hit (the damage-dealt
hook, after absorbs; a plain attack read as physical, a spell or tick as
magic, the hook giving the kind of damage but not its school) and each
heal (the heal hook, overhealing already left out) on someone in a party
goes into that party's minute, behind a lock (the map threads run side by
side). The party leader's own update, while the party fights and
something has happened, takes a snapshot at most every half second,
reading the game outside the lock: members on the leader's map (health,
power, class, level, armour, role by the bot module's tank and healer
tests, position, every aura's effects as the game holds them now, whose
values already count their stacks), and the enemies attacking them (rank,
level, target, marks, the sorted threat list with each entry's state,
taunt and melee reach). The snapshot and a copy of the minute go to a
pool of worker threads, which run the step and keep the party's latest
verdict; the pool stops at shutdown. `.buddy fight` prints it. Not read
yet: casts in progress, cooldowns, the group's gold per hour (gold counts
nothing until it is).

**Layer 6, the answers, built 2026-10-30** (the arithmetic committed and
tested; its server half waiting for the compile with the rest). For each
buddy, every answer its abilities give is tried and leaned (`Leans`): a
mark or heal that reaches only its caster on the buddy itself, one that
reaches another on whoever's curve ends soonest among those attacked; Lay
on Hands as the caster's whole health; a taunt on the hardest hitter; an
empowering buff as a burst on the party's damage (on the buddy's own
share of it when the buff is its own). What each ability reaches, heals
and how long it lasts is read from the game by the ability generator
(`BUDDY_ABILITY_REACH`, 212 abilities; heals before the caster's bonuses).
An answer leans by the share of the gap it closes (`Lean`): of the
party's shortfall when it saves health (all of it: x2), else of the time
left (a minute's fight ended 12 seconds sooner: x1.2), or away by what it
costs; nothing either way, 1; never below 0.05. In the server the workers
keep each buddy's leans, and the talent draw's multiplier multiplies each
cast by its lean (fresh within 3 seconds), on while `Buddies.ForwardPass`
is 1 even with the talent weights off. Checked (27 checks): on the
made-up dying-tank fight the warrior's Shield Wall leans x1.28, the
paladin's Lay on Hands x1.13 and its taunt x1.02, the priest's Pain
Suppression x1.12; the tank's own taunt and Mortal Strike don't lean; in
the calm fight nothing leans toward the emergencies. A party of four's
leans take about 2.4 milliseconds.

**The windows already open, 2026-10-30 (committed, offline):** the
empowering buffs on the party now (any in the window table: Bloodlust,
Heroism, Avenging Wrath and the rest, matched by their aura's spell) are
windows on the party's damage, each on its wearer's share of the party's
damage over the minute, for the time it has left (`OpenWindows`). The
enemies' fall measured over the last ten seconds is taken as measured
under them, so the steady rate is the measured one over them and they are
counted once, where they still run. Checked (31 checks in all): Bloodlust
on the rogue doing all the damage with 40 seconds left makes a minute's
fight 66 seconds; Avenging Wrath on a paladin who has dealt nothing opens
no window.
Nothing yet takes the snapshot, keeps the history, runs the layers on
worker threads or hands their verdict to the draw. The page
`docs/HTML/fight-forward-pass.html` (made by
`scripts/generate-fight-forward-pass-page`) lays the design out.

## Intended Behavior

**The analogy, kept exact.** A language model runs everything said so
far through fixed weights to find the next token. A buddy runs the fight
so far (the context) through fixed weights (the game's numbers and the
economies' arithmetic) to find the trajectory of every fight curve to the
fight's end, and the worth of each answer it could give now (its next
token). The draw (625) then picks among the answers by those worths.

**The context: one snapshot, one party.** Taken by the world thread when
something has happened (627: no thinking while nothing does; at most every
half second in combat), once per party, so every buddy reads the same
picture. Plain values copied, never game objects, so worker threads can
read it while the game moves on:
- the fight: seconds run (decimal); its kind (boss, rare elite or trash);
  the windows open (each a start, length and factor, decimals);
- each party member and pet: health and most (decimals); resource and
  most, and which resource; role; position (three decimals); the cast in
  progress (spell id, a whole number; time left, a decimal); each
  cooldown (spell id, seconds until ready); its marks;
- each mark: the aura's spell id; seconds left; stacks (small whole
  number); who put it on;
- each enemy: health and most; rank; its cast; its marks; whom it attacks;
  its threat list (per character: threat, a decimal; available, passed
  over or out; taunting, none or turned away; within melee reach, yes or
  no).
Buddies see every number (the owner: "let's just let them see the numbers
for now"), with equalizing what they are shown, against what a player
beside them could see, as the later goal.

**The tokens: a minute of events.** Each hit, heal, mark landing or
wearing off, cast and death is appended to a ring holding the last minute
(the owner: "a minute is fine"), each stamped with its time. Running
summaries are updated as each event arrives, so a step never re-reads the
whole minute (as a language model keeps its cache): damage taken and
healing received per second per character, damage dealt per second per
enemy, each enemy's health trend.

**The weights: mostly fixed.** The owner: "I don't imagine they will grow
very much." Three kinds:
1. the game's own tables, read by generators: abilities, buffs, talents'
   touches, lockouts, threat levers; to add, what each debuff does to its
   bearer, read from its aura types the same way;
2. each buddy's own: its abilities, talents and gear, worked out again
   when they change;
3. the few that may move with play, each kept with where it started and
   how it moves (625k): how much a talent benefits an ability, how a
   rating relates to a spell, how resistant a target is to a school, how
   much mana matters in this fight; and the starting values written in
   the issues (the regular-cooldown line, the look-back).

**The layers, run in order each step** (each reading the one before):
1. rates: health lost and gained per character, enemies' health falling,
   so the fight's time left (625h, built);
2. marks into modifiers: every mark a multiplier on damage taken, healing
   received, damage dealt or haste, each ending when its mark does (625f
   for buffs and lockouts, built; debuffs to do);
3. attention: whom each enemy attacks now and next (625j, built);
4. fight curves: each character's health to the end, by who holds the
   attention, marks wearing off and planned cooldowns (625j, built);
5. plans: each buddy's cooldown timeline (625f, built), the tanks' swaps
   (625j, built), the healer's plan (625i), who gets each buff (625l);
6. answers: each answer a buddy could give now, tried through layers 3 to
   5 as if given, its change to the curves said in damage and health and
   handed to the draw as a weight (625d).

**New, extended, desired.** New is the snapshot just taken. Extended is
the curves carried to the fight's end with the plans in them. Desired is
what the group values (the owner: "depends on the group. What do they
value?"): victory first (every enemy dead before anyone of the party, no
curve below nothing); then, by default, fewer consumables used (lower
gold cost) and a faster kill (3 minutes over 4); when questing, gold and
experience per hour. Gold cost is each consumable used up at "whatever
price the bot can acquire it by" (the owner). Each is a measure said in the same units the curves
are, so a step's verdict is how much an answer closes the gap from
extended to desired. What a group values is its own setting, the
defaults above until it says otherwise. (Grinding a chosen monster comes
later: "that's later so don't worry about that now.")

**Where it runs.** The world thread only takes the snapshot and reads the
last verdict. A pool of worker threads runs the layers: one task per
party for what is shared (attention, the fight curves, the tanks' swaps,
the buffs' targets), one per buddy for its own (its cooldown plan, its
answers). Verdicts are double-buffered: the workers write the next while
the bot module reads the last, at most one step old. Measured: a buddy's
cooldown plan takes about half a millisecond for a five-minute fight, a
fight curve microseconds.

**Calm.** The server's own switching margins, no swap or hold for
nothing, weights that change smoothly, and the weighted draw at the end
keep it natural rather than scripted (625j: "serenity in flow").

**Replays.** Each step's snapshot and verdict can be written to a log in
the RAM drive; a recorded fight run back through the layers offline gives
the same verdicts every time (the layers are arithmetic from snapshot to
verdict), so changes are tested on real fights and learning (625k) has
its material.

## Suggested Implementation Steps

1. (Done) The design page (`scripts/generate-fight-forward-pass-page`, done with
   this issue).
2. (Done, offline) Debuffs read as modifiers, from the game's aura
   types, beside the buffs (`buddies_marks.h`, the ability generator).
3. The snapshot and the minute of events as plain data, with the running
   summaries, tested on made-up event streams.
4. (Done, offline) The layers joined into one step from snapshot to
   verdict, tested on those streams (`buddies_forward_pass.h`); the
   desired state's measures: health first, then the group's time (kill
   time, gold cost as time to earn it back).
5. In the server: the snapshot taken on events, the worker pool, the
   latest verdict kept per party and shown by `.buddy fight`; each
   buddy's leans read by the draw, behind the switch (written, waiting for
   the compile: `buddies_forward_pass.cpp`, `buddies_talents.cpp`); replay
   logging.

## Open Questions

1. Gold cost: which consumables count (potions, food, flasks, reagents,
   ammunition, repairs), and is each counted at its vendor price, or at
   the auction house's when there is one (617h)? **Answered 2026-10-30**
   (the owner, word for word): "for whatever price the bot can acquire it
   by." So every consumable a fight uses up counts, each at the cheapest
   way that buddy could get another now (a vendor it can reach, the
   auction house's lowest listing, or what its own crafting costs), worked
   out when the cost is needed rather than fixed.
