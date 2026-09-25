# 617k - Buddy Professions

## Status
- Created: 2026-09-25
- Phase: 6
- Parent: 617
- Blocked by: 155p (the Jewelcrafting rework comes first, by Ritz's
  ordering), 617a (roster)
- Related: 617h (buddies at the auction house), 617j (buddies and loot),
  155n (professions stop at 300 on basic)
- Priority: Medium

## Origin

Verbatim, 2026-09-25:

> After we develop the jewelcrafting rework, let's add buddybot professions
> to the list of tasks to accomplish.

## Current Behavior

Not designed. What the bot module offers today (per
`docs/playerbots/Playerbot-Commands.md`): the `maintenance` command has a
bot learn its available spells and skills, restock consumables, enchant its
gear and repair; a `master fishing` strategy lets a bot fish near its
master; `who <profession>` reports a bot's skill level. Nothing yet decides
which professions a buddy takes, levels them, gathers, crafts for its
owner, or cuts gems into the sockets 155p adds.

## Intended Behavior

To be designed with Ritz once 155p is built.

## Suggested Implementation Steps

1. Read the bot module's profession code paths (learning, gathering,
   crafting, the maintenance command) and record what each already does.
2. Design with Ritz, one question at a time (below).
3. Then split into sub-steps here.

## Open Questions

- Does each buddy pick its own professions, or does the owner assign them?
- Do buddies level professions by gathering along the way, or do they
  arrive with them?
- Do buddies craft for the clan on request (gems for 155p's sockets,
  potions, bags), and who pays for materials?
- How does this meet the auction house (617h): do buddies sell what they
  gather or craft?
