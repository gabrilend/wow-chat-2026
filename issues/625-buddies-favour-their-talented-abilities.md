# 625 - Buddies Favour the Abilities Their Talents Touch

## Status
- Created: 2026-10-15
- Phase: 6
- Related: 617g (talent shapes), 622 (a buddy's own record of what works),
  309 (monsters that choose their attacks)
- Priority: Medium
- State: an idea; the design is open

## Origin

Verbatim, 2026-10-15:

> would it be possible to cause buddy-bots to be more likely to use the
> abilities that are mentioned or affected by the spec talents they are
> slotted? Just... in general.

Then, the same day, on stat weights (verbatim): "stat weights for spec
profiles must be modified by the current status of the character. The
profile has the defaults, and whatever the character's spec ends up being
determines which stats are preferred. We can do this by checking the
talents they actually pick, and then evaluating the stat weights for each
of the abilities mentioned, and how large and important of a discrepancy
the modification of the talent is, then we prefer that more or less
depending on how much it changed, and how often we are likely to use that
talent's mentioned abilities. Keep in mind we will always use some of
them sometime." And on the hunter asking for Trueshot Aura forty
thousand times: "we probably shouldn't be doing things in a loop if we're
just... standing around. Everything like that should be triggered by
something else, to keep it a game focused on user input and not a
simulation focused on backgrounds."

## Current Behavior

**The weights and the draw are built (2026-10-30), off by default; the
server side waits for the owner's compile.**
- `buddies_talent_draw.h` (plain arithmetic): each ability's weight from
  the talents touching it (by points, or by the talent's own percent), and
  the draw: every answer's priority nudged by a Gumbel draw scaled by its
  weight, held so it reorders one concern's answers (about a point apart)
  but never leaps a concern (fleeing at 39 always before healing at 34).
  Checked by `scripts/test-buddy-talent-draw` (a quick test): twice the
  weight wins about twice as often (1,231 to 2,399 wins in 20,000), every
  answer still wins sometimes, a weighted heal never beats fleeing.
- `buddies_talent_touches_data.h`, generated with 625a's table: each
  talent's rank spells, and each ability it touches with the percent its
  top rank states.
- `buddies_talents.cpp` (waits for the compile; the compiler check passes,
  with flags borrowed from the bot module): the "buddy talents" combat
  strategy, whose multiplier applies the draw to every spell a buddy might
  cast, its weights worked out from the talents it knows every 20 seconds;
  put on every buddy while `Buddies.TalentWeights` is 1 or 2.
- Not yet: 625c (every tree's list, cast in the trees' shares), 625d (the
  moment's economy), set bonuses.

A buddy fights by the bot module's strategies for its class and the tree
the module guesses from its talents; each action has a fixed priority.
A talent that improves an ability (more damage, less cost, a shorter
cooldown) changes nothing about how often that ability is chosen. Seen
the same day: the hunter Montahmu's strategy asked 41,000 times for
Trueshot Aura, a talent it does not have.

**How a concern becomes an ability today** (read 2026-10-29 in the bot
module, `Engine.cpp` and the class strategies):
- A **concern** is a trigger: "party member critical health" (below 25%
  health), "low health" (45%), "medium health" (65%), "almost full
  health" (85%); "medium aoe" (3 or more enemies within 8 yards);
  "medium threat"; "enemy too close for spell"; and many more, set in
  `playerbots.conf` and the triggers' own code.
- Each fired concern offers its **answers** as a list of actions, each
  with a fixed relevance number. The restoration druid, for a party
  member at low health: tree form 21.5, Swiftmend 21.4, Wild Growth 21.3,
  Nourish 21.2, Regrowth 21.1, Healing Touch 21.0. Rejuvenation is offered
  only at "almost full health" (10.2).
- Every tenth of a second the engine takes the most relevant answer that
  is useful and possible (known, off cooldown, enough mana). So the order
  is fixed: the same concern always gets the same first choice.
- The spec decides which strategy, and so which list, a bot uses: the
  module guesses the tree from the talents (a druid with two thirds in
  Restoration and a third in Balance plays the whole Restoration list).
- **The hook exists.** Before choosing, the engine multiplies each
  answer's relevance by every **multiplier** a strategy registers
  (`Multiplier::GetValue(action)`; the raid strategies use it to silence
  actions in a phase). A buddy strategy's multiplier can scale an answer
  by its talent weight without changing any class strategy.
- **The catch:** a list's answers stand 0.1 apart (21.0 to 21.5). Any
  multiplier above about 1.03 lifts Healing Touch over the whole list,
  every time, so a plain multiplier turns "more often" into "always".

The owner, 2026-10-29: "where we're at with NPCs using different
abilities more or less frequently when multiple ways to address a concern
are presented? Like, concern, ally low health, sub routine initiated heal
the ally because can and specialized to, cast healing touch but not
tejuvenation because that's how we're specced. Etc etc with more concerns
being things like "enemy nearby" or "enemy nearby 3+ enemies" or "ally
suddenly gained threat" or whatever."

## Intended Behavior

**More or less often, not always** (2026-10-29, from the catch above):
among the answers one concern offers, a buddy draws by chance, each
answer's chance in proportion to its weight: its place in the list (the
module's order, kept as the starting shape) times its talent weight. A
druid deep in talents that improve Healing Touch casts it more often
when an ally is low, and still casts the others sometimes ("Keep in mind
we will always use some of them sometime", 2026-10-15). An answer that
isn't possible right now (cooldown, mana) is passed over, and the draw
is made again among the rest. The draw is made inside the buddy module's
own multiplier, so the class strategies stay as upstream wrote them. It
reorders answers only within one concern's band of relevance (a list's
answers sit within about one point of each other), never across
concerns: fleeing a melee enemy (39) still comes before healing at low
health (21), and critical health (30 to 34) before low.

**Stat weights from the talents taken.** A talent shape's weights are the
starting point; the talents a buddy actually took move them: for each
ability a talent names, the stats that ability scales with count for
more, by how much the talent changes the ability and how often the buddy
uses it (and every ability is used sometimes). Gems (617j2), gear choice
and loot all read these weights. **The abilities learned move them
too** (the owner, 2026-10-30: "We're updating the stat weights based on
abilities learned (from the trainer) and talents picked, and it should
be dynamic to each buddy-bot."): each buddy's weights are its own,
worked out again when it learns an ability or spends a talent point,
and read by its weapon choice (speed included, 625b) and by which
lessons it buys first when it can't afford them all (617n).

**No idle asking.** The bot module checks each of its triggers every
moment ("does it have Trueshot Aura? no: cast it"), so an ability it can't
use (a talent not taken) is tried forever. An action for an unknown spell
should be dropped once, when the buddy's spells change, not checked
again every moment.

Every ability a buddy's talents name or change counts for more when the
buddy chooses what to do: the more talent points spent on it, the more
it is favoured. Abilities its talents never mention keep their ordinary
weight, and an ability it does not know is never asked for.

**Set bonuses count too** (owner, 2026-10-22: "in the issue files where
we make bots more likely to use abilities that are mentioned in the
talents that they picked, can we also do that for set bonuses on items?
It's rare, but a bot should be more likely to use an ability if it's
specifically mentioned on their super special useful gear."). An item
set bonus the buddy has earned (enough pieces worn) that names or changes
an ability favours that ability the same way a talent does: the bonus's
spell (the client's ItemSet.dbc lists each set's bonus spells and how
many pieces each needs) is read for the abilities it affects (its spell
class mask, as a talent's is). Re-read when the buddy's equipment
changes, not every moment.

**Not planned: weighting by how many talents mention an ability**
(2026-10-22). The owner asked whether abilities named by more of a
buddy's talents should be chosen even more often, then leaned away: "We
might wind up in a situation where druids only cast Healing Touch for
example, because it's mentioned in the most resto talents by number."
Counting mentions favours whatever the tree's designers wrote most
about, not what plays best. So the weight is by talent points spent on
talents that touch an ability (above), not by how many talents name it.

## Sub-issues

- 625a: what each talent (and set bonus) touches, read from the game's
  own tables (step 2 below).
- 625b: buddies wear the weapons their talents are for.
- 625c: one list from every tree a buddy has points in, each tree's
  answers weighted by its share (2026-10-29: "ah see this is the part we
  need to upgrade").
- 625d: choosing an answer by the moment's economy: urgency, action
  economy, mana economy, movement, and cooldowns spent together in
  empowered moments.
- 625e: what each fight taught (how much each phase made buddies move),
  written down to be read later.
- 625f: the action economy: time as the currency, window values, the
  cooldown timeline and the game's lockouts.
- 625g: forms and stances weighed.
- 625h: the resource economy, and the fight's length.
- 625i: the healer's seat.
- 625j: the threat economy: threat stored, attention placed, the curve
  toward victory.
- 625k: learning that can start over.
- 625l: buffs given to who uses them most.
- 625m: pets as a second pair of hands: their abilities the buddy's own,
  on their own lane of time.

**Pliable, and rigid** (the owner, 2026-10-29: "and through it all, we
need to make the systems very flexible - pliable, so that the story and
the AI or players can help guide it as they please. But, rigid, to
provide a structure and make sure we aren't standing still yet running
into trees. (or wandering about not knowing what we're doing)"). Every
weight, list and measure in this work is data in one place, open to the
story, an AI or a player to bend (a whispered wish, a story's mood, a
learned log); the structure that reads them (concerns, bands, the draw,
the checks) is fixed and tested, so a bent weight can change what a buddy
prefers but never leave it idle or walking into a tree.

## Suggested Implementation Steps

1. Answer the open questions.
2. (625a) From the client's tables, for each talent, the abilities it affects
   (its spell's effects that modify another spell's family flags, or that
   teach one), gathered once.
3. For a buddy, a weight per ability from the talent points it has in
   talents that touch it.
4. Those weights raise the priority of the bot module's matching actions
   (a source patch to the bot module's action choice, or the buddy
   module's own strategy), and an action for an unknown spell is dropped.

## The switches (2026-10-30, the design target: built both, the owner chooses)

- `Buddies.TalentWeights`: 0 off (the default: buddies choose as the bot
  module does); 1 a fixed raise per talent point (question 1's first
  answer); 2 as much as the talent's own effect where the game states a
  percent, and the per-point raise where it states a flat amount
  (question 1's second answer).
- `Buddies.TalentWeights.Broad`: how much a broad talent (a whole school,
  every weapon attack) counts on each ability it covers, as a share of a
  talent naming that ability: 100 (the default) or 50 (625a's question
  1's two answers), any percent allowed.

## Open Questions

1. How much more: a fixed raise per talent point, or as much as the
   talent's own effect (a talent adding 15% damage raises it by 15%)?
   **Both built, behind `Buddies.TalentWeights` (1 and 2), 2026-10-30;
   the owner chooses.** Asked again the same day, the owner, word for
   word: "we will handle this in the ability economy system."
2. Should this live in the bot module (a patch, every bot) or only for
   buddies? **Answered 2026-10-30** (the owner, word for word): "why is
   it different? It should be every bot. All the things we make should
   be A. sandboxed to a particular player, like how the original
   wow-chat was designed, and B. fully idempotent / functional style,
   with the only state available being the state that is stored on the
   player, which gets memory freed whenever they log out." Every bot,
   not only buddies. And a rule for all of this work: each piece works
   for one player at a time (as wow-chat-1 did), as pure functions of
   what is stored on that player, kept nowhere else, and freed when the
   player logs out.
