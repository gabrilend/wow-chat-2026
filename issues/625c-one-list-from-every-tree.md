# 625c - One List from Every Tree a Buddy Has Points In

## Status
- Created: 2026-10-29
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Blocked by: 625a (what each talent touches: the weights)
- Blocks: 625d (choosing by the moment's economy draws from this list)
- Priority: High
- State: in progress (the shares, the running count and the role's tree
  first built offline; the bot module's lists per tree, as data, next)

## Origin

The owner, 2026-10-29, on being told that the bot module plays one tree's
list ("A druid with two thirds of its points in Restoration plays the
whole Restoration list, and its Balance third changes nothing"): "ah see
this is the part we need to upgrade."

## Current Behavior

**The arithmetic, built 2026-11-06 (offline, on a branch for review):**
`buddies_tree_shares.h`, the parts of steps 2 to 4 that need no server.
- **Each tree's share** (`FromPoints`, `Speaks`): the points spent per tree
  over all spent; with none spent yet (a low level), the role's tree,
  whole. A tree with no points offers no answers.
- **Each answer's weight** (`Weight`): its tree's share (a Balance answer
  counts a third for a 2/1 Restoration/Balance druid) times the running
  count's lean, multiplied into the talent weight before the draw (625),
  whose held nudge keeps it from leaping a concern.
- **The running count** (`Count`, `Behind`, `Lean`): this fight's casts per
  tree; a tree behind its share leans in by e^(0.4 per cast behind), held
  between 0.2 and 5. Only a choice between trees is counted
  (`FromSeveralTrees`).
- **The role's tree first** (`RoleFirst`): on a concern two trees answer,
  the other trees' answers are moved down together, keeping their order
  and spacing, until the highest is 0.01 below the role tree's lowest;
  nothing is lifted, so nothing leaves its concern's band.
- **The feral druid's answer to an ally at low health** (`AllyLow`), as
  the owner told it: heal when the attackers can't be beaten before the
  ally falls, the ally can hold on long enough for a heal (4 seconds) and
  the druid isn't under attack; otherwise a tank pulls them off in bear
  form, or strikes in cat form beside a tank; otherwise cat talents strike
  and bear talents pull off.
Checked by `scripts/test-buddy-tree-shares` (30 checks, a quick test): a
2/1 Restoration/Balance druid offered six Restoration answers and two
Balance ones casts 0.668 Restoration over 3,000 casts through the real
draw (0.932 without the count), and still about two thirds with someone
hurt only half the time; the feral cases in the owner's words; 20 of 20
deliberately broken versions of the header caught. Not yet: the bot
module's strategies per tree as data (step 1), the buddy strategy
gathering them (step 2) and the multiplier reading these weights (step 3),
which are server code for the owner's compile; and the other classes'
answers, told by the owner as they come up in play (step 5).

The bot module guesses one tree from a bot's talents and gives it that
tree's strategy: its concerns (triggers) and, for each, a fixed list of
answers with fixed priorities (`RestoDruidStrategy`, `BalanceDruidStrategy`
and the like). A buddy's talent shape (617g) spreads its points in
thirds: two thirds and one, or a third in each, or all in one. Every
shape but the last three plays as if all its points were in one tree.

## Intended Behavior

- **Every tree with points speaks.** A buddy's concerns and answers are
  gathered from the strategies of every tree it has points in: a
  two-thirds Restoration, one-third Balance druid hears Restoration's
  healing concerns and Balance's damage ones (Moonfire, Wrath, Starfire,
  Insect Swarm).
- **Each tree's answers weighted by its share.** An answer from the
  Balance list counts with a third of the weight it has for a
  full-Balance druid, a Restoration answer with two thirds; and the
  talents themselves (625a) lean further toward the abilities they touch.
- **Casts in the trees' shares** (the owner, 2026-10-29: "they should
  cast about 2/3rds of their spells as resto spells, and 1/3rd as balance
  spells."): over a fight, about two thirds of a 2/1 Restoration/Balance
  druid's casts are Restoration spells and a third Balance, not Balance
  only when no one needs healing. The draw (625) keeps a running count
  and leans toward whichever tree is behind its share.
- **The role's tree speaks first on a shared concern** (the owner,
  2026-10-29, word for word: "role tree should win, if we're 2/3rds feral
  and 1/3rd resto, we should address the "ally at low health" concern in
  a specific way, favoring our feral instincts first. If we have cat
  talents, we should try and pounce on their attackers. If we have bear
  talents, we try and pull them off. If they are too powerful to defeat
  easily, and our ally can hold on but needs healing and we're not under
  attack, then we can heal them, otherwise if we're a tank and they are
  not, then we should bear form and pull them off, otherwise if we're a
  tank and they are, then we can catform. Basically there's so many
  different priorities, and we can build them out one-by-one."). So a
  concern can be answered in a tree's own way, not only by its own spells:
  "ally at low health" for a feral druid means striking or pulling off
  what hurts the ally, and healing only when the ally can hold on, the
  druid is not under attack, and the attackers are too strong to beat
  quickly.
- **Each class told by the owner, one at a time.** The owner: "I know how
  to play EVERY SINGLE WORLD OF WARCRAFT CLASS. I can fully describe how
  they're supposed to interrelate, and how the various roles (tank,
  healer, dps) are meant to perform as well". Each class's concerns and
  their answers per tree are written from the owner's description, one
  class at a time, as data the buddy strategy reads.
- **States count** (the owner, 2026-10-30, on Furor, Natural
  Shapeshifter and warrior stances: "we should treat various states as
  important"): leaving a form or stance for another tree's answer is
  weighed as a trip, in 625g.
- **When the role is busy** (the owner's answer about a dying ally, in
  625i): the role's duty first; a healer's seat passes on if the healer
  falls.
- **Concerns stay separate.** Merging lists never mixes priorities across
  concerns (625: fleeing at 39 before healing at 21).

## Suggested Implementation Steps

1. List, for each class, the bot module's strategy per tree and the
   concerns each one adds (read from `InitTriggers`), as data.
2. The buddy strategy (in the buddy module) that, for a buddy's talent
   shape, gathers the concerns and answers of each tree with points,
   tagged with the tree's share.
3. The multiplier (625) reading the share and the talent weights.
4. A test: a 2/1 Restoration/Balance druid's casts over a long fight are
   about two thirds Restoration and a third Balance; a 2/1 Feral/
   Restoration druid answers an ally at low health by striking or pulling
   off the attacker first.
5. Each class's concerns and answers, from the owner's description, one
   class at a time.

## Open Questions

1. When two trees answer the same concern differently (a Feral and a
   Restoration druid both have answers to "low health" of their own),
   should both lists be pooled, or the role's tree speak first?
   **Answered 2026-10-29:** the role's tree speaks first (above).
2. Which class should the owner describe first? The druid (its three
   trees answer the same concerns three ways) is the one the examples so
   far have used.
   **Answered 2026-10-29** (the owner: "as we're playing I will describe
   behavior and we will add it to the capabilities"): no order; each
   class as the owner meets it in play.

## Decisions (2026-11-06)

The agent's calls while building the arithmetic, for the owner to curate;
each number is one constant in `buddies_tree_shares.h`:
- **What the running count counts**: only casts chosen from more than one
  tree's answers. A stretch where one tree alone had anything to offer
  (nobody hurt, so no Restoration answer) is not owed back afterwards as a
  run of heals nobody needs; the shares hold among the choices that could
  have gone either way, and a dying ally (a concern one tree answers) is
  never put off for the count.
- **How hard it leans**: e^(0.4 per cast behind), held between 0.2 and 5:
  enough to bring six Restoration answers against two Balance ones back to
  two thirds, not so much that one long gap makes the next answer certain.
- **Role first, by moving down**: the other trees' answers on a shared
  concern are moved down together to 0.01 below the role tree's lowest
  answer, keeping their spacing, rather than scaled, so the draw's nudges
  among them are unchanged and no answer drops further than their own
  spread.
- **The feral reading of the owner's words**: "too powerful to defeat
  easily" is read as "the druid can't beat them before the ally falls"
  (seconds to beat them against the ally's seconds at the damage it
  takes), and "can hold on" as four seconds or more (a global cooldown out
  of the form and a heal's cast). The heal is checked first, as the
  owner's sentence puts it before the tank's choices; a druid with both
  cat and bear talents goes by whichever side has more points, cat on a
  tie.
