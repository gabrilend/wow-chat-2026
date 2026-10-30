# 625c - One List from Every Tree a Buddy Has Points In

## Status
- Created: 2026-10-29
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Blocked by: 625a (what each talent touches: the weights)
- Blocks: 625d (choosing by the moment's economy draws from this list)
- Priority: High
- State: planned

## Origin

The owner, 2026-10-29, on being told that the bot module plays one tree's
list ("A druid with two thirds of its points in Restoration plays the
whole Restoration list, and its Balance third changes nothing"): "ah see
this is the part we need to upgrade."

## Current Behavior

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
