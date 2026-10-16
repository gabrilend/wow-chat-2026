# 617j2 - Gems and Sockets: Buddies Gem Their Own Gear by Their Plan

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617j
- Blocked by: 617a4 (the starting kit), 617g (talent plans), 155p
  (sockets on basic gear, the gem tiers)
- Related: 617j (upgrades always worn), 617k (professions: a
  jewelcrafting buddy cuts gems)
- Priority: Medium

## Origin

The owner, 2026-10-03: "Can we spawn buddy-bots who have gear that has
sockets (most white gear if I remember correctly after our patches) Can
we have them spawn with gems that match their talent set? We should have
different stat priorities for each talent profile they can spawn with.
Make sure their gear is socketed correctly, but more importantly make
sure that they'll socket their own gear when they get the chance."

## Current Behavior

**A random colour per socket, 2026-10-15; syntax-checked, not yet rebuilt
or run** (`buddies_gems.cpp`, the kit's choice). The owner: "the
buddy-bots don't seem to be gemming according to the set bonuses... Can
we make each gemstone slot that they fill have a random color? for
example, red slots could be red, purple, or orange. We should pick a
random number between 1 and 3 and make the gemstone that they slot that
color. Then, they'll pick the one according to their spec profile's stat
weights." and "we might need to fix the gemstones in the currently built
buddy-bots to align to this new pattern." Built: each socket draws one
colour among those that fit it (red: red, orange, purple; yellow:
yellow, orange, green; blue: blue, purple, green; basic's weapon sockets:
any of the six) and that the tier has gems of (tier I has only red,
yellow and blue), then the best gem of exactly that colour by the plan.
Every socket bonus is then earned. Before, each socket took the best gem
whatever its colour, so a buddy wore one gem everywhere (Usanda:
seventeen "+3 hit, +4 spell power", 51 hit rating, 9.2% spell hit at 44,
over the 5% cap on all but Uldaman's last boss; Drerjokin: twenty-one
"+6 hit"). A console command, `.buddy gems <name>`, re-gems a buddy in
the world by the new rule, for buddies gemmed by the old one.

Built 2026-10-03 (`buddies_gems.cpp`), compiles with the source patches
applied (syntax-checked with B046 on); `scripts/test-buddy-gems` passes
(each tier has gems: 13, 32 and 61 plain cut gems; no white has a meta
socket; no white below item level 17 has a socket). Not yet tested in
game.

- A new buddy's kit, and a returning buddy's reset (617a6), fill every
  non-meta socket of what it wears with its items' tier gems, by step 3,
  free.
- When an item enters a buddy's bags (the server's "new item stored"
  moment: loot, rewards, purchases, crafting, a hand-over; and items
  taken from the mail), it is queued and handled on the world's thread,
  routed by a table keyed by the item's kind: a gem goes to the clan
  buddy it gains most (the holder on a tie), handed over if needed and
  socketed through the server's own socketing, the result checked and a
  refusal logged; armour or a weapon with sockets has the clan's loose
  gems offered again 5 seconds later (after the bot module equips it).
  Nothing is checked on a timer. (A first build checked every 10
  seconds; replaced 2026-10-04.)
- On the town visit's auction errand, after its own listings, a buddy
  buys, for each empty socket it wears,
  the best single gem listed for a buyout that fits the socket's colour
  (equal scores: the cheaper), spending at most a quarter of its money;
  the gems arrive by mail; collected, they arrive in its bags and are
  placed. (Vendor buying,
  built first, was removed.)
- Not done: the owner is never given or socketed gems (open question
  below); gems under a limit category are never placed.

## Intended Behavior

- **Stat priorities per plan**: each of the ten talent plans (617g) of
  each class has a list of stats it wants most, from its trees' kinds
  (the bot module's own kinds: healing, spell damage, tanking, melee or
  ranged damage), weighted by the plan's thirds; e.g. a holy paladin:
  spell power, mana per 5, crit; a retribution one: strength, crit, hit.
- **Gems at creation**: each socket of the kit's gear gets the gem of
  the right tier for that item's level, of the socket's colour, carrying
  the plan's most wanted stat that colour can carry (a two-stat gem when
  it carries two wanted stats); the socket bonus is taken when the gem
  that earns it is nearly as good.
- **Gemming its own gear**: whenever a buddy has gems in its bags and a
  worn item has an empty socket (a new item worn, a gem looted or bought),
  it puts the best gem for that socket in, by the same priorities; and at
  the auction house, with spare bag slots, it buys what its sockets lack,
  from its own purse.

## Suggested Implementation Steps

1. **The priorities** are not a written table: a gem is scored at the
   moment by the bot module's own stat weights for each tree of the
   buddy's plan (the same scorer, told "score as this tree", that B046
   uses for items), each tree's score weighted by its share of the plan's
   points. So a plan's priorities are exactly the bot module's weights
   blended by the plan's thirds, and they follow any change to either.
   The plan's shape per class (thirds and each tree's kind) is read from
   one place, `buddies_loot.cpp`, shared with the item scoring.
2. **The tiers** (`buddies_gems.cpp`): the three 155p tiers are the cut
   gems the game already has, picked out by item level and quality:
   I the item-level-55 whites (Tourmaline, Zircon, Amber: +4), II the
   item-level-60 greens (Outland's uncommon cuts: +6 and the +3/+3
   mixes), III the item-level-70 blues (Outland's rare cuts: +8 and the
   +4/+4 mixes). An item takes the tier of its own item level (I below
   30, II below 45, III from 45). Meta gems, gems unique-equipped or
   under a limit category, and gems needing a profession are left out of
   the kit's choice.
3. **Choosing an item's gems** (one rule for the kit and for socketing):
   per socket, the best-scoring gem that fits; and, separately, the best
   gem of the socket's own colour in every socket plus the item's socket
   bonus; whichever adds up higher is taken. A socket of several colours
   (basic's weapon sockets, red-yellow-blue) counts every one as its
   own.
4. **The kit gems its gear**: after the gear is chosen, every socket of
   every worn item is filled by step 3 with gems of the item's tier,
   free, written straight into the item (the buddy is not in the world
   yet; at a return's reset it is, and the stats are applied as the
   server's socketing does).
5. **The clan places loose gems as they arrive** (`buddies_gems.cpp`,
   "arrivals"; the owner, 2026-10-04: "How about we check whenever an
   item enters a buddy-bots bags, and depending on what it is, we have a
   dispatch table [...] route our decisions through data rather than run
   a bunch of checks if this, then that style"): an item entering a
   buddy's bags is queued and handled on the world's thread, going
   through a list of readers, each turning the item into a key (first:
   its kind) with a table of functions per key, every listed function
   run in turn. A gem: each online buddy of the clan (with its owner,
   out of combat) is asked what the gem gains it: over every socket of every item it
   wears, the score of the item's gems and bonus with this gem in that
   socket minus as it is now. The gem goes to the buddy it gains most
   (a tie: the one holding it) and is socketed at once through the
   server's own socketing (unique-equipped checks and all), so a socketed
   gem never moves again; a gem gaining nobody stays in the bags (to be
   sold). Moving a gem to another buddy hands one over (taken from the
   holder, given to the receiver); a receiver with full bags is passed
   over.
6. **Buying gems** (the town visit's auction errand, `buddies_town.cpp`
   calling `BuddyBuyGemsAtAuction`): for each empty socket the best-scoring single gem listed for a buyout that
   fits, cheaper first among equals, at most a quarter of its money per
   visit, bought through the server's own bid request; the mail brings it
   and, collected at a mailbox (waiting mail makes the mailbox an errand;
   what doesn't fit stays for the next visit), it arrives and is placed.
   (The quarter is a first guess, logged in `docs/balance-updates.md`.)
7. **A test** (`scripts/test-buddy-gems`): every plan of every class gets
   a full set of gems for a level-45 white set, and none for a meta
   socket.

## Open Questions

- (Answered 2026-10-03) Meta sockets: "We shouldn't let them have meta
  slots... Not on white gear at least." Checked the same day: no white or
  green item has one (a single grey test item does).
- (Answered 2026-10-03, with a question back) Replacing a socketed gem:
  "Let's say no, unless nobody in the clan could use the gem better than
  they could. Then they can replace the old gem. Though, it also depends
  on if it's a more valuable stat for them - how do we calculate that
  now?" Read as: a buddy puts a new gem over an old one only when (1) the
  new gem scores higher for it than the old one does, and (2) no
  clan-mate would score the new gem higher than it does (else the gem
  goes to that clan-mate). Scoring, as now: the bot module's stat weights
  (StatsWeightCalculator: a weight per stat for the bot's kind, healer,
  caster, tank, melee or ranged damage), blended by the buddy's plan
  through source patch B046; a gem's score is its stats times those
  weights, the same sum an item's stats get. The owner, the same day:
  "Mostly, For (2) make sure that we're examining the gems in the
  clan-mate's gear and we notice an upgrade for them. I am also worried
  about bots passing gems back and forth and never slotting one." So:
  - (2) is judged against what each clan-mate already has socketed: a
    gem is an upgrade for a clan-mate when it beats the gem in one of
    their matching sockets (or fills an empty one) by their own weights;
  - no passing back and forth: a loose gem is placed once, by the clan as
    a whole: it goes to the member it gains the most for (a tie: the
    member already holding it), who sockets it at once; a gem never
    moves again after that placing.
- (Answered 2026-10-03) The owner and gems: "jewelcrafters who are
  passing around the gems they made can give them to the owner if they
  want." So a jewelcrafting buddy's own cut gems (617k) may go to the
  owner; looted gems stay among the buddies. Not built (needs 617k's
  crafting).
- (Answered 2026-10-03, changes the design; not yet rebuilt) Buying
  gems: "from the auction house, when they have spare slots." Buying
  from vendors is to be replaced by buying at the auction house (617h),
  when the buddy has free bag slots. Later, buddies of different clans
  meeting while adventuring will talk and trade (a jewelcrafter among
  them is another source of gems); the owner wonders whether the
  auction house goes away then, once bots have language-model replies
  and personalities. Not part of this issue.

- (Answered 2026-10-04) Bag room when buying: bought gems arrive by mail,
  so the owner: "Whenever an item enters the mailbox, visiting the
  mailbox should be made a valid todo list option." The town visit's
  errand list already takes the mailbox whenever collectable mail waits;
  the buying no longer asks for free bag slots.
- (Open, 2026-10-04) The dispatch table was asked for "in lua cached for
  everyone"; it is in C++ (`buddies_gems.cpp`, the readers), because what
  its gem function does (scoring by the bot module's stat weights,
  socketing) exists only in C++. Moving the table into Lua needs the Lua
  engine to be able to call the module's functions (a binding for each).
  Keep it in C++, or add the bindings and move it?

## Related Issues

- **617j** parent; blocked by **617a4**, **617g**, **155p**; related
  **617k**
