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
- **Role first.** A tree's concerns still answer to the buddy's role
  (617g: tank, healer, damage): a healer-shaped druid heals before it
  casts Wrath; its Balance answers come into play when no one needs
  healing, or when its own concern band is free (the healer-should-attack
  concerns the module already has).
- **Concerns stay separate.** Merging lists never mixes priorities across
  concerns (625: fleeing at 39 before healing at 21).

## Suggested Implementation Steps

1. List, for each class, the bot module's strategy per tree and the
   concerns each one adds (read from `InitTriggers`), as data.
2. The buddy strategy (in the buddy module) that, for a buddy's talent
   shape, gathers the concerns and answers of each tree with points,
   tagged with the tree's share.
3. The multiplier (625) reading the share and the talent weights.
4. A test: a 2/1 Restoration/Balance druid with no one hurt casts Balance
   spells; with an ally at low health it heals; across many draws its
   Balance answers come about a third as often as a full-Balance druid's.

## Open Questions

1. When two trees answer the same concern differently (a Feral and a
   Restoration druid both have answers to "low health" of their own),
   should both lists be pooled, or the role's tree speak first?
