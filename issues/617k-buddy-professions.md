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

**Secondary professions built 2026-09-27; compile-checked, not yet run**
(`modules/mod-buddies/src/buddies_create.cpp`): every buddy made learns
Cooking (spell 2550), First Aid (3273) and Fishing (7620), each its
apprentice spell, which carries the skill itself (a "skill" effect naming
the skill line, checked in Spell.dbc): skill 1 of 75, plus the recipes the
game gives with the skill (first aid's Linen Bandage, cooking's Basic
Campfire). None is cast by learning, so this is done on the new character
before its first save. It also gets a Fishing Pole (item 6256, the bot
module's own choice) in its bags. A buddy's login catches up anything
missing (buddies made earlier, or full bags), logged when it can't. The
pole is used for fishing in towns (617e4).

Primary professions: not designed. What the bot module offers today (per
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

### Gathering mode, answers (Ritz, 2026-09-25)

- **Other players' nodes**: no special rule, first come first served ("sucks
  2 suck").
- **Whose level**: the owner's ("the owner's level").
- **Zone levels**: a list built from outside sources ("we can build a list
  from external sources. fan guides and such"): a data file of zones and
  their level ranges, kept by a generator or a checked-in table with its
  sources named.
- **Spreading out**: "they should try and spread themselves out in the zone,
  moving in the direction that has the fewest clan-members in it, weighted
  by distance. So a distant clan member would contribute less of a malus
  [...] we should set their goal direction toward the spot that is
  equidistant to the other clan members, generally. [...] they should try
  and fill the zone, ensure that they visit all the nearby potential nodes
  while also moving primarily in a straight-wavy line, circling the zone
  and ideally, not passing over the path they took the next time they
  circle the zone. Remember they're going either clockwise or
  counter-clockwise."
  - each gathering buddy steers toward the point farthest from its clan
    (clan members' pull weakening with distance), not simply outward;
  - it loops the zone in its own direction, sweeping nearby node spawns in a
    wavy line, and shifts its loop each lap so it doesn't retrace its path;
  - prior art: the beta behaviours' dispersion (issue 610) in
    `src/lua-beta/behaviors.disabled/zone-consensus.lua`, and the 2-yard
    anti-clump rule in `bot-wander.lua` (both disabled today).
- **Materials that don't come from gathering** (cloth, things to
  disenchant, vendor parts): "The buddy buys them. They should try and have
  some supplies on-hand, and when at the auction house they should consider
  bag slots to be an upgrade-able metric they can help their clanmates
  with. They should pick them up while in town, they shouldn't seek out
  towns specifically."
- **Low-level crafting skill**: "for low level crafting professions [...]
  we should buy materials on the auction house whenever we have extra gold.
  It should be a higher priority than clanmate upgrades, but only if
  they're low enough level that they can't find profession materials in the
  zones that are level appropriate for their owner. If they can, then it's
  the same priority as clanmate upgrades. They should also consider the
  items they craft for their crafting profession as viable 'targets' for an
  upgrade they can supply to a clanmate, and should consider the cost to be
  the cost of materials on the AH minus the materials they have on hand."
  - buying materials to level crafting outranks buying clan upgrades while
    the buddy's skill is too low for materials in the owner's zones;
    otherwise they rank equally;
  - a craftable upgrade for a clanmate counts as an upgrade to buy, priced
    at the auction-house cost of its missing materials.
- **Full bags**: head to the nearest town. "If they get to town and there's
  no auction house, and they have full bags, they should sell the 50% of
  their bag space with the lowest value, not counting things they just want
  to keep like hearthstone, consumables, tradegoods for their profession,
  etc. If they do this and they're still 90% or more full, then they sell
  all the tradegoods as well. If they're still 90% full, then they sell all
  their consumables. Past that I think it's a bug lmao" — past that, it is
  logged as an error.
- **Bags as upgrades**: "The bags that they buy / tailor should be one size
  larger than the smallest size the upgrade-able player possesses." A
  buddy buying or sewing a bag for a clanmate makes it one size up from
  that clanmate's smallest bag.
- **Consumables** (answering how they're handed out): "they will give away
  things they don't need, and they will craft them at random. The ones that
  they do need they will give away if they have more than 5, or if they
  have any number of a higher level version of that thing, they'll give
  away the low level ones. They will mail them to clanmates while in town."
  - a buddy crafts consumables at random from its recipes;
  - it gives away those it can't use; of those it uses it keeps 5 and gives
    the rest; lower-level versions of something it has a better version of
    are all given away;
  - it mails them to clanmates during its town errands;
  - the gift is spread evenly among the clanmates who can use it, without
    regard to what each already holds (Ritz, 2026-09-25: "The consumables
    should be spread evenly. They'll redistribute themselves naturally over
    time."). A clanmate who ends up with too many passes the extras on by
    the same keep-5 rule, so supplies level out over time without a buddy
    tracking anyone else's bags.
- **Party**: a dispersed buddy leaves the proximity party (617c) when being
  in it brings no benefit ("they should drop out of the proximity party if
  there's no benefit to being in a party together"), so its fights never
  pull onto the owner.
- **Server load**: accepted ("that's fine. They're players too.").

### Decision, 2026-09-27 (Ritz): cooking, first aid, fishing for all

"They need real food. They should all have cooking and first aid and
fishing." Every buddy knows the three secondary professions from its
creation (the apprentice skill and its first recipes), on top of any
primary professions; it cooks what it catches and uses bandages it makes.
Towns: fishing as a pastime (617e4).

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
- (Answered 2026-09-25) Crafting on request: yes eventually, with the buddy
  paying, but it needs the language model work, so it is its own issue
  (617m, task hunts). Until then buddies take no requests.
- (Answered 2026-09-25) Surplus goes to the auction house by 617h's rules,
  and buddies buy clan upgrades there with what they earn.
- (Answered 2026-09-25) Consumables are mailed to clanmates in town:
  whatever the buddy can't use, its extras beyond 5, and lower-level
  versions of ones it has better.
- (Answered 2026-09-25) Consumables are spread evenly among the clanmates
  who can use them; the keep-5 rule redistributes them over time.
