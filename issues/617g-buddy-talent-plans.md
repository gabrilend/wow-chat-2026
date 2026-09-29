# 617g - Buddy Talent Plans

## Status
- Created: 2026-09-23
- Phase: 6
- Parent: 617
- Blocked by: 155g (the capped trees these plans are made for)
- Priority: Medium

## Origin

Verbatim, 2026-09-23, on bots at 60 keeping points they can't spend in
capped rows:

> Yeah. Usually this is another spec tho - like 2/3rds arms, 1/3rd fury. Or
> 2/3rds disc, 1/3rd shadow. Buddies never change their spec. There should
> also be a 1/3rd in each talent tree option. So we'll need to create "talent
> plans" for all of these permutations, and estimate which talents to pick
> based on theme analysis and also a double-pass scoring system that repeats
> continuously, increasing the score for talents that aren't picked as much,
> searching for an equilibrium where all talents are near equally chosen in
> all the permutations. The main abilities, the ones that require a single
> talent point, they should always be chosen, and if they have pre-requisites,
> those prerequisites should also always be chosen as well.

## Current Behavior

**Built 2026-09-26; tested offline, not yet run on a server** (it needs
617a's roster table, which doesn't exist yet; until then the script says
so at startup and stays off).

- `scripts/generate-basic-talent-data` reads Talent.dbc, TalentTab.dbc
  and Spell.dbc and writes `src/lua-basic/data/buddy-talent-data.lua`: 10
  classes, 829 talents, each with its row, column, ranks, rank spells,
  prerequisite and whether basic's cap allows it; each tree's role and
  room; the ten shapes per class with their role. Two talents name a
  prerequisite the client file doesn't hold (Sanctified Retribution,
  Merciless Combat); the server skips such a check, so the generator
  drops those prerequisites (found by the test: both were never picked).
- `src/lua-basic/lib/buddy-talent-spender.lua`: the decisions, no server
  calls (read what a character holds, plan the points, draw a shape, can a
  class fill a role). Reference: its `.info.md` beside it.
- `src/lua-basic/buddy-talents.lua`: the server side. Spends on a buddy's
  level-up and login; on a talent reset it waits one tick, checks the
  reset really happened (the hook fires before the server can still refuse
  it for gold), then re-spends a buddy, or re-rolls every buddy of an
  owner (offline ones flagged and done at login). Reads the planned ranks
  back and logs an error for any the server refused; logs a warning for
  any point left unspent.
- `config/patches/C027-basic-buddy-own-talents.sh`: the module's alt
  maintenance leaves talents alone (checked by
  `scripts/test-profile-config-gates`).
- `scripts/test-buddy-talents`: every class, every shape, 100 seeds each
  (a career from 10 to 60 one point per level, plus a 51-point re-roll),
  each point checked by a referee written from the server's rules. Result
  2026-09-26: all checks pass; every two-thirds and all-in tree reaches
  its capstone at 60 (900/900 per class); every allowed talent is taken in
  9% to 63% of level-60 builds, none never. Checked against three broken
  copies of the spender (row lock, cap, finishing removed): each fails.
- One change from the plan, from the owner's first rule ("the main
  abilities, the ones that require a single talent point, they should
  always be chosen"): a legal one-point talent comes before finishing a
  started talent. The first run without it left about 1 main tree in 20
  without its capstone at 60.
- **New-row rule** (owner, 2026-09-26, below): once a tree opens a row,
  its next new talent is a random one from that row (not the leftmost),
  after one-pointers, the
  unfinished talent and prerequisite chains. Simulated before adopting
  (200 runs per class and two-thirds shape): the main tree's deepest row
  at level 20 rose from 0.59 to 0.80 on average and at 50 from 4.27 to
  4.67; unchanged elsewhere, since five points per row already forces the
  depth. Placed ahead of the prerequisite chains at first, it cost warlock
  main trees their capstone in 64 of 900 runs; after the chains it costs
  nothing (900/900 every class). The referee checks it on every point.

Not yet verified in game: that a bot's login and level-up fire the Lua
engine's player events (they go through the ordinary login and level
paths, so they should).

What was read before building, 2026-09-26, from the bot module and the Lua
engine:

- **The module only auto-spends talents for random bots.** Its level-up
  talent pick checks "is this a random bot" and does nothing otherwise.
  Buddies are owned characters logged in as bots (617a/617c), not random
  bots, so without this issue a buddy's points would sit unspent.
- **One module path does touch owned bots**: the maintenance command,
  when the config switch for alt talent maintenance is on (it is, by
  default). It fills talents from the module's premade WotLK orders, then
  randomly. It would fight our picks, so basic turns it off.
- **The module has its own vanilla-style limit** (a "limit talents
  expansion" switch) that skips row 6 except the middle column. Our rule
  (155g, one-point talents) differs in two trees (affliction's Dark Pact is
  right of centre), so it is not used.
- **The Lua engine can do all of it**: learn a talent at a rank, read a
  player's free points, reset talents for free, and hooks for level-up and
  for a talent reset. Nothing here needs compiled code.
- **Points**: stock rate, one per level from 10: 41 at level 50, 51 at 60.
- **Room under the cap** (rows 0–5 whole, row 6 one-point talents only),
  counted from Talent.dbc 2026-09-26: 45 (retribution, demonology) to 58
  (fury) per tree. So a two-thirds tree (34 points at 60) always fits and
  always reaches its capstone (30 points); a one-third tree (17) stops in
  row 3.

Stock, for reference: bots follow premade talent orders from
`playerbots.conf` (spent by the module's factory), written for full WotLK
trees. Under basic's cap (155g) the deep rows are refused and those points
stay unspent.

## Intended Behavior

- **Plan shapes**, per class, for the 51 points of a level-60 character in
  trees capped at tier 6 (capstone only):
  - two-thirds / one-third in every ordered pair of trees (6 per class);
  - one-third in each tree (1 per class);
  - all in one tree (3 per class; added 2026-09-26, ten in all).
- **Always taken**: every talent that is a single-point ability (grants a
  spell), and its prerequisites.
- **The rest is drawn at random** within the plan's per-tree amounts (the
  2026-09-25 decision below). The first design, a generator with theme
  scores and a balancing pass toward equally-picked talents, is replaced;
  its evenness count survives only as a test report.
- **Buddies never change spec**: a buddy gets one plan at creation (617a) and
  keeps it for life; its points are spent by that plan as it levels.
- Spent by the project's own server script, not by the bot module: the
  module's premade-order format can't express "random within a share".

### Decision, 2026-09-25 (Ritz): one profile, random talents within it

"we might have to say that bots will randomly select their talents up to a
certain amount in each tree, always prioritizing the ones that have 1
talent point cost, and they can be re-randomly chosen whenever the player
respecs. [...] Also I kinda want them to pick one profile and stick with
it - so if they're a holy paladin, they'll always be a holy paladin, but
the exact talents they choose can be randomly picked every time you
re-roll. Is that terrible?"
- A buddy's **profile** (how many points go in each tree, e.g. two-thirds
  holy and one-third protection) is fixed for life, as before.
- Within it, **talents are picked at random**, single-point abilities
  first, each tree filled up to its amount.
- **Re-rolled when the owner respecs**: the buddy's talents are drawn again
  within the same profile.
- This replaces the generator's balancing pass as the way talents are
  chosen; the plan shapes (the per-tree amounts) stay.
- Removed from basic alongside: dual spec; and the gold cost of a respec
  grows without a cap and comes down over time (155r).

### Decision, 2026-09-25 (Ritz): random profiles, a tank and a healer guaranteed

"random, but each clan is guaranteed at least one tank, and one healer."
- A buddy's profile is drawn at random at creation.
- **Guarantee**: a clan's buddies always include at least one tank and
  one healer; the owner's class is ignored ("the owner's class is
  ignored"). When a buddy is created while the buddies
  lack one, its draw is limited to profiles that fill the missing role
  (tank first, then healer) if its class can fill it; a random class draw
  at Sargobras (617b) is likewise limited to classes that can.
- Tank profiles: most points in protection (warrior, paladin), feral
  (druid, the bear side) or a death knight tree played as a tank. Healer
  profiles: most points in holy or discipline (priest), holy (paladin),
  restoration (shaman, druid). The exact list is for the generator.

### Decision, 2026-09-25 (Ritz): death knight clans

"death knights should ignore the guarantee. Their specs might not even be
"tank" specs, and that's okay. Death knights are expected to be able to
handle very difficult types of content without dedicated healers. They
should try and tank swap between each other, taunting enemies when they
have more health than their target's target (unless in a regular group
with "real" tanks, of course) and prioritize the abilities that provide
healing when they need it. They should also start with level 300 in
professions, so they should be able to create consumables which should
help."
- A death knight owner's buddies (all death knights, 617b) skip the
  tank-and-healer guarantee; their profiles are random with no role
  required.
- **Tank swapping**: a death knight buddy taunts an enemy when its own
  health is higher than that of the enemy's current target, so the
  healthiest death knight holds it. Not when the group has a "real" tank
  (a tank-profile member of another class).
- **Self-healing first when hurt**: below some health, the abilities that
  heal the death knight (Death Strike, Rune Tap, Death Pact and the like)
  come before damage.
- **Professions maxed (300 on basic) from the start**, "the professions
  they knew in life" (Ritz, 2026-09-25), picked the way 617k picks any
  buddy's (a random crafting profession and its gathering one), so they make their own
  consumables (617k).

### Decision, 2026-09-26 (Ritz): ten shapes, our own spender

Verbatim: "I think we might not even need the default playerbots profiles,
we just need the general shape - 2:1 for each combination (2 holy 1 prot,
2 holy 1 ret, 2 prot 1 holy, 2 prot 1 ret, 2 ret 1 holy, 2 ret 1 prot, and
1/3rd in each. Maybe we also have 100% in one tree for each, so 100% holy,
100% prot, 100% ret, for a total of... 10 options each?) so anyway as the
bot levels they place talents according to the general shape, randomly.
With priority given to talents that either are 1 cost, or talents which
open up talents that are 1 cost." And on the module: "sounds like we need
to implement our own solution then."
- **Ten shapes per class**: six two-to-one pairs, one-third in each, and
  all in one tree (three). The module's premade talent orders are not used.
- **Priority**: one-point talents, and the talents that open them (their
  prerequisite, to the rank it requires), come before any other pick.
- **One-third each** stays: at 60, 17 points per tree, the last 2 in each
  tree's fourth row (confirmed: "yes 2 points per tree in the fourth row").
- **Re-rolled on every owner respec** (confirmed).
- **Roles**: all-in-one-tree follows its tree (all protection is a tank,
  all holy a healer); one-third each is damage.

### Decision, 2026-09-26 (Ritz): the guarantee only steers, never forbids

Verbatim: "the tank and healer guarantee has a problem - let's say when they
level up, the player talks to Sargobras and asks for a mage... 7 times.
There's no way to get tanks or healers from that. That should be allowed.
So it only applies if they pick a class that can tank or heal, and it's
just for validating the profile of the talents spent. Also, if the player
picks a race, it should check at the last two (level 50 and 60) if they
have tanks or healers. If no, then when they pick a race it should
guarantee a class that can either tank or heal depending on what they
might need, and then it should guarantee a talent profile for their
required role."
- **Picking a class never gets refused or changed.** Seven mages is a
  legal clan.
- **Only the last two slots are checked** (the buddies owed at levels 50
  and 60). Clarified, verbatim: "The class limit on race picks only applies
  at 50 and 60, correct. It should be the same for if you pick a class
  instead - only check if we have a healer or tank at the last two
  opportunities." At those two slots, if the clan still lacks a tank or a
  healer (tank first):
  - a picked class that can fill the missing role gets a shape from that
    role; a class that can't draws freely;
  - a picked race gets its class drawn from that race's classes that can
    fill the role, and a shape from that role.
- Every earlier slot draws its class and shape freely.

### Decision, 2026-09-26 (Ritz): no two buddies of a class share a shape

Verbatim: "we should ensure that if there's two buddy-bots of the same
class, that they don't pick the same talent profile." A buddy's shape is
drawn from its class's ten minus those its clan-mates of the same class
already hold. Seven buddies and ten shapes per class, so a free shape
always exists. Nor can steering and this rule collide: steering asks for a
role only while no buddy holds it, and a clan-mate holding one of that
role's shapes would already hold the role, so the role's shapes are all
free whenever they are asked for. The spender still checks, and an empty
draw is an error in the log, not a silent substitute.

### Decision, 2026-09-26 (Ritz): finish a talent before starting another

"okay I'm sold, let's max them." The spender continues a talent that has a
point in it until it is full, then draws a new one. Only a tree's last
points (its share running out) may leave a talent partial. Reasons, as
argued to the owner: random single points average every bot into the
same spread of 1/5 and 2/5 ranks, where finished talents make builds
differ; many talents pay off only at full rank; and finishing a 5-rank
talent often opens exactly the next row.

### Decision, 2026-09-26 (Ritz): overflow from a tree that's too small

"a random other tree." All in one tree needs 51 points at 60, and 18 of
the 30 trees hold fewer under the cap (45 to 50). The points left over go
to one of the class's other two trees, drawn at random, spent with the
same priority (one-point talents and what opens them first).
- Death-knight clans skip all of this (confirmed 2026-09-26).

### Decision, 2026-09-26 (Ritz): a new row's first pick

Verbatim: "I'm concerned that bots will take the less powerful higher tier
talents and not the lower ones. How about whenever we unlock a new row,
ignoring the 1 point talents, we (after 1 point talents), prioritize that
row for one complete talent pick? Then it's random again. I think that
should encourage a bit more progression. What do you think?" Measured and
recommended; answered "yes".

## Suggested Implementation Steps

Replanned 2026-09-26 after the random-within-a-profile decision; the
generator's theme scores and balancing loop are dropped. Data generation
and the spending are kept apart.

1. **Talent data generator** (LuaJIT, `scripts/generate-basic-talent-data`):
   reads Talent.dbc and TalentTab.dbc and writes a Lua data file for the
   server scripts. Per class, per tree (in the client's left-to-right
   order): every talent with its id, row, column, rank count, the talent
   and rank it depends on, and whether basic's cap allows it (the same test
   as 155g). Also the tree's room under the cap.
2. **Profile table** (in the same generated file): per class, the ten
   shapes: two-thirds / one-third for each ordered pair of trees (6),
   one-third in each (1), and all in one tree (3). A shape is three fractions, not point counts, so
   it works at any level. Each carries a role (tank, healer, damage) taken
   from its two-thirds tree, from a hand-written table of which trees tank
   and heal (the list in the tank-and-healer decision above).
3. **The spender** (`src/lua-basic/`, a Lua script): given a buddy, its
   shape and its free points, it spends them one talent at a time:
   - the tree to spend in keeps the shape's split at every level (the
     2026-09-26 answer): each point goes to the tree furthest below its
     share of the points spent so far, so a two-thirds / one-third buddy
     puts two points in its main tree for every one in the other, and
     reaches its capstone around level 54;
   - within the tree, the candidates are the talents the cap allows whose
     row is unlocked (5 points per row in the tree) and whose prerequisite
     is met or can be met;
   - a talent that already has a point and is not full is continued first
     (finish before starting another);
   - otherwise a one-point talent among the candidates is taken, with its
     prerequisite; otherwise one candidate is drawn at random;
   - an all-in-one-tree shape whose tree is full sends the rest to one of
     the other two trees: the one already holding overflow points if
     there is one (so the rest stays together without storing anything),
     else one drawn at random;
   - it stops when the points are gone or no candidate is left, and says
     so in the server log when points are left unspent (a warning, not a
     silent fallback).
4. **When it runs**: on a buddy's level-up; on a buddy's login (catches
   anything missed); and when the owner resets their talents, every one of
   the owner's buddies is reset for free and spent again (the re-roll).
5. **Storage**: the shape is drawn once, at creation (617a), from the
   class's ten minus those held by same-class clan-mates, steered by the
   tank-and-healer guarantee at the level-50 and level-60 slots, and saved
   with the buddy's roster row. The
   picks themselves are not stored: they live on the character as normal
   talents.
6. **Config patch for basic**: alt talent maintenance off, so the module
   never refills a buddy from its WotLK orders.
7. **Tests**: a LuaJIT test that runs the spender against the generated
   data for every class and shape at levels 10, 20, 30, 40, 50 and 60 many
   times with different seeds, and checks every pick obeys the cap, row
   locks and prerequisites, one-point talents come first, the share per
   tree holds, and no point is left while a candidate exists; then counts
   how often each talent is picked (the old balancing idea, kept as a
   report).

## Related Issues

- **155g** the talent cap; **617a** buddy creation (plan chosen there);
  **617** parent

## Open Questions

- (Answered 2026-09-25) Random, with at least one tank and one healer
  guaranteed per clan (see the decision above).
- (Answered 2026-09-25) The owner doesn't count ("the owner's class is
  ignored"): the buddies alone always include a tank and a healer.
- (Closed 2026-09-26) Random (non-buddy) bots: basic has none (155b), so
  there is nothing to plan for them.
- (Answered 2026-09-26) Leveling order: keep the two-to-one split at
  every level (capstone around level 54), not main-tree-first.
- (Answered 2026-09-26) One-third each: kept; at 60, 2 points per tree
  in the fourth row.
- (Answered 2026-09-26) Feral druids: a feral two-thirds buddy is a tank
  (bear).
- (Answered 2026-09-26) Death knights: their roles never matter, since
  death-knight clans skip the guarantee.
- (Answered 2026-09-26) Finish a talent before starting another. The
  owner asked: "do you think it would be better to have partial talents,
  like 3/5 in one talent, or should we max out each one? [...] I think if
  we don't do that, then the bots might all feel kinda average. But if we
  do, they might be a bit more distinguished from one another."
- (Answered 2026-09-26) All in one tree, when the tree is too small: the
  extra points go to a random other tree.
- (Answered 2026-09-26) Shape steering waits for the last two slots, the
  same as the race-pick class limit.

