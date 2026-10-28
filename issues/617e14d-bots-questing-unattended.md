# 617e14d - Bots Questing Unattended

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 617e14
- Blocked by: 617e14a
- Related: 617e (buddies adventuring), 617e3 (creatures, chests and nodes),
  617e15 (places conquered)
- Priority: Medium
- State: plan only

## Current Behavior

A buddy roams only while its owner is online and near: its sub-zone is its
owner's. With its owner offline it is logged out.

## Intended Behavior

The owner, 2026-10-27: "We should watch the pattern of bots as they are
assigned to random sub-zones - we don't need a player to watch them
quest. "questing" is when they fight monsters in a particular sub-zone -
or, as I like to believe, NPC spawn location of a certain type. Follow the
goat goddess? Then you will wander wherever goats are blessed."

- **Assigned a place, not an owner**: a bot is given a sub-zone (or a kind
  of creature, and so every place that kind lives) and quests there: roams
  it, fights its monsters, loots, rests, goes to town to sell.
- **Questing is fighting**: the place's monsters, or a kind's ("the goat
  goddess": wherever goats spawn), are what the bot is there for.
- **Watched from above** (617e14c), not by a player.

## Suggested Implementation Steps

1. Which bots (open question 1), and how one is assigned a place.
2. The roaming core given a place in place of an owner's sub-zone.
3. "A kind of creature": the places a creature kind spawns, from the
   world database, as the bot's set of places.

## Open Questions

1. **Which bots**: buddies of offline owners (logged in for this), a test
   clan of buddies with no owner, or the bot module's random bots taught
   our roaming?
2. **A kind of creature**: by its creature family (beasts: boar, wolf,
   goat...), by its name, or by its type (beast, humanoid, undead)?
