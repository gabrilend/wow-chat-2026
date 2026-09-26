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
  Leatherworking: Skinning). A Tailor or an Enchanter takes a gathering
  profession at random (Ritz, 2026-09-25: "if tailoring or enchanting is
  selected, a random gathering profession is chosen. One crafting
  profession per character.").
- **Crafting priorities**: first, items that are upgrades for someone in the
  clan (the owner and their buddies, 617j); then consumables, handed out to
  the clan from time to time.
- **Surplus** (what nobody in the clan needs, likelier when professions
  overlap) is sold at the auction house under 617h's rules.
- **Spending**: the coin buddies earn buys upgrades for clan members at the
  auction house (a buying side for 617h).
- **A guild per clan**, created automatically and named by the owner; the
  clan chats in it (see 617l).

### Gathering mode in lower zones (Ritz, 2026-09-25)

"if the player is in a zone that is lower than their level, say, 5 levels
at the suggested max lower than their current level, then buddy-bots will
disperse through that zone and gather materials according to what their
gathering professions are. For example they might hunt beasts if they have
skinning, they might wander around areas with a high differential in Z
values if they have mining, they might hang around tree doodads and plains
if they have herbalism, etc. Perhaps we can load the spawn locations of the
nodes and try to chart a general path around the area. When they enter this
mode, it will be randomly chosen whether they traverse the zone clockwise
or counter-clockwise, on a per-bot basis. They will gather materials if
they can, but if they can't, they will hang out around the player. If the
player enters a town, they will gather toward the town until they are also
in the town and then they will do their town behaviors. This allows players
to pull them in, or push them out toward the edges of the zones at will.
The extra materials will probably be auctioned. This can apply for profit
or for skill level ups. [...] This behavior will never apply to the highest
level zones by design, however they will gather materials in the same area
that they are questing in, so the player will have to walk them around the
map instead of doing it automatically. Remember, bots won't auction things
if there's too many in the auction house, and guild banks are disabled and
you can't leave your guild. So at a certain point you're farming for vendor
price, which decreases the AFK-ability of this system, while still allowing
it if the user wants."

- **When**: the owner stands in a zone whose top level is at least 5 below
  the owner's level. Never in the highest zones; there, buddies gather only
  where they already quest.
- **What**: each buddy works its gathering profession over the zone:
  Skinning hunts beasts; Mining keeps to rough, steep ground; Herbalism to
  trees and open plains. Route: a loop round the zone through the places
  its nodes spawn (read from the spawn tables), each buddy picking
  clockwise or counter-clockwise at random.
- **Nothing to gather**: it stays near the owner.
- **The owner walks into a town**: buddies gather their way toward it, then
  do their town errands there. The owner steers them: into town, or out to
  the zone's edges.
- **Surplus** goes to the auction house under 617h's rules; once the house
  is full of it (617h's glut rule), the rest sells to vendors. That limit is
  the brake on leaving buddies to farm unattended, by design.

## Suggested Implementation Steps

1. Read the bot module's profession code paths (learning, gathering,
   crafting, the maintenance command) and record what each already does.
2. Design with Ritz, one question at a time (below).
3. Then split into sub-steps here.

## Open Questions

- (Answered 2026-09-25) Each buddy picks at random; the gathering profession
  follows from the crafting one.
- (Answered 2026-09-25) Tailors and Enchanters take a random gathering
  profession; one crafting profession per character.
- (Answered 2026-09-25) Buddies level professions by gathering (and
  crafting) as they go, including the gathering mode above.
- Do buddies craft for the clan on request (gems for 155p's sockets,
  potions, bags), and who pays for materials?
- (Answered 2026-09-25) Surplus goes to the auction house by 617h's rules,
  and buddies buy clan upgrades there with what they earn.
- How often does a buddy hand out consumables, and how: in person when
  near, or by mail?
