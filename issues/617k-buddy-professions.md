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

Ritz, 2026-09-25: "It picks totally randomly. It will prioritize crafting
items that are upgrades to other members in the clan. It will try and create
consumables and such and hand them out periodically. The crafting profession
is the one that is chosen, and the gathering profession for that crafting
profession is selected. If the buddy bot shares professions with members of
the clan, you'll probably find that you don't need extra of what they make -
these get sold on the auction house according to the standard rules. This
will cause the buddy-bots to have extra coin, which they can spend on the
auction house to buy upgrades for members of the clan. Each clan gets it's
own guild auto-created and named by the player, and they will use it to chat
with each other."

- **Choosing**: a buddy picks one crafting profession at random, and takes
  the gathering profession that feeds it (Alchemy and Inscription:
  Herbalism; Blacksmithing, Engineering and Jewelcrafting: Mining;
  Leatherworking: Skinning).
- **Crafting priorities**: first, items that are upgrades for someone in the
  clan (the owner and their buddies, 617j); then consumables, handed out to
  the clan from time to time.
- **Surplus** (what nobody in the clan needs, likelier when professions
  overlap) is sold at the auction house under 617h's rules.
- **Spending**: the coin buddies earn buys upgrades for clan members at the
  auction house (a buying side for 617h).
- **A guild per clan**, created automatically and named by the owner; the
  clan chats in it (see 617l).

## Suggested Implementation Steps

1. Read the bot module's profession code paths (learning, gathering,
   crafting, the maintenance command) and record what each already does.
2. Design with Ritz, one question at a time (below).
3. Then split into sub-steps here.

## Open Questions

- (Answered 2026-09-25) Each buddy picks at random; the gathering profession
  follows from the crafting one.
- Tailoring and Enchanting have no gathering profession that feeds them
  (cloth drops from creatures; enchanting materials come from
  disenchanting). What does a Tailor's or an Enchanter's second profession
  become: another random crafting one, or a gathering one at random?
- Do buddies level professions by gathering along the way, or do they
  arrive with them?
- Do buddies craft for the clan on request (gems for 155p's sockets,
  potions, bags), and who pays for materials?
- (Answered 2026-09-25) Surplus goes to the auction house by 617h's rules,
  and buddies buy clan upgrades there with what they earn.
- How often does a buddy hand out consumables, and how: in person when
  near, or by mail?
