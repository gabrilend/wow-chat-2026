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
- State: planned (its layers 1, 3, 4 and 5 built offline in their own
  issues; the frame that runs them, not yet)

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
and tested: the rates (the fight's length, 625h), the marks as modifiers
(window buffs and lockouts, 625f; debuffs not yet), attention (625j), the
fight curves and the tanks' swaps (625j), the cooldown timeline (625f).
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
experience per hour. Each is a measure said in the same units the curves
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
2. Debuffs read as modifiers, from the game's aura types, beside the
   buffs (the ability generator).
3. The snapshot and the minute of events as plain data, with the running
   summaries, tested on made-up event streams.
4. The layers joined into one step from snapshot to verdict, tested on
   those streams; the desired state's measures (gold cost, kill time).
5. In the server: the snapshot taken on events, the worker pool, the
   double-buffered verdict read by the draw, behind a switch; replay
   logging.

## Open Questions

1. Gold cost: which consumables count (potions, food, flasks, reagents,
   ammunition, repairs), and is each counted at its vendor price, or at
   the auction house's when there is one (617h)?
