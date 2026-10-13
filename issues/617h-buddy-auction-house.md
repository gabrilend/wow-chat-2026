# 617h - Buddy Town Errands and the Auction House

## Status
- Created: 2026-09-24
- Phase: 6
- Parent: 617
- Blocked by: 617e (town behavior)
- Priority: Medium
- Sub-issues: 617h1 (the selling trip: full bags send a buddy to a vendor)

## Origin

Verbatim, 2026-09-24, asked what on basic leaned on random bots:

> bots should use the auction house when they are in cities or towns like
> Gadgetzan or Booty Bay that have auction houses. They should list their
> trade goods, greens, etc, rather than vendor them.

> How does playerbots handle it? They just simulate AH stock, right? If so,
> then we need to design our own system, and we should make a separate
> issue file for that.

The design, verbatim, 2026-09-24:

> okay so... when buddies are in a town or city with an auction house, they
> should build a small little task list to do while they're there, based on
> the capabilities present in the town or city. This includes vendors,
> repairs, auction houses, and trainers. Repairing is the highest priority
> if they have a single red item, otherwise trainers are the highest. If
> they have no red items but at least one yellow item, then repair is the
> 2nd highest priority behind trainers. Otherwise repair is below auction
> house, which comes next. Then, repair if they don't have any items that
> are damaged enough to be "yellow", and vendoring trash goods at the final
> priority level after that. When at a repair or vendor stop, they might buy
> items that are considered beneficial as well, like food or potions or
> something, as long as we know that they will use these items in the
> field. We should try and ensure that they do. We will update the vendor
> lists later to include things like potions and such... Don't worry about
> that now though. Once they're done with that, they'll walk to random NPCs
> chosen either as "the next closest NPC in the general direction of either
> the most distant NPC in the town, or the next closest NPC in the general
> direction of one of their class trainers in the city" either that, or as
> just selecting a random NPC in the town or city and walking to them. Make
> sure they path naturally to the destination.

> When they're at an auction house, they will sell greens, trade goods, and
> other valuable items by first checking to see if there's any items that
> are higher than their minimum price, which is 1.5x the vendor price. If
> so, for example if a battleaxe is listed for 2x the vendor price, then
> they will undercut that listing by 10% of it's cost if it's an equipment
> item, 5% if it's anything else. They'll do 48hr listings for equipment, 12
> hr for trade goods, and 24 hours for everything else that a player might
> want or need. If there's only items at 1.5x the vendor price they will
> either list theirs or just vendor them. For equipment, they'll list it if
> there's another item of that type but a different enchantment (of the
> tiger, of the whale, etc). The random enchantments are considered unique
> items. If there's the exact item on the AH and there's at least 5 of them,
> then they'll just vendor it unless it's an epic and then they'll always
> post it. Quality adds .5x to the modifier, so greens are 1.5x vendor
> price, whites are not auctioned at all, blue is 2x vendor price, and epic
> is 2.5x vendor price. However if it's a level 60 or 60+ epic, they will
> never auction them, and always mail them to their player instead. Any
> edge cases? The money goes to the bot, not the player that they're
> following.

Answers to the edge cases, verbatim, 2026-09-24:

> [level 60 or 60+ epic:] required level I think? Edge cases?

> for equipment they will vendor it. For trade goods they will list it. Can
> playerbots do trade skills? If not, we should build out a system for that
> eventually. For now, just let them list the extra trade goods.

> [no vendor price:] we will have to go through them one-by-one. These
> items are rare, I don't mind manually fiat'ing.

> trade goods should be sold at random stacks just to mess with players.
> Well, let's say they have 56 items that stack up to 20. They'd make random
> number stacks between 1 and 20 unless the total that they have is 20 or
> fewer. If so, then they post all of them.

> Treat any listing that is close enough to the minimum to cause any
> undercut to be below the minimum, as at the minimum. If they still need to
> post (for example, to meet the 5 item quota) then their price should be
> their minimum price even if it is more than the undercut would suggest, so
> long as it is still below the price of the listing they're undercutting.

> That's fine. If there's high demand, then prices will slide back up
> again. If they have an expired listing that has no items left in the AH,
> they should increase the price by 0.5x. This should repeat infinitely if
> necessary.

> A buddy that can't afford the deposit vendors in general, even if it's at
> a regular auction house. They need the coin, and they need it now! Once
> they attempt to auction something but can't, then they stop auctioning
> things and do not return to the auction house until the next time they're
> in town. Or in a different city of course.

> Oh yeah! Mailbox stops should be just below yellow item repair.

> finish the current task first.

> yeah epics are always posted.

## Current Behavior

**Built 2026-09-30, not yet compiled or tried in game**
(`buddies_town.cpp`: "the auction house", the errand list, the mail
errand). The town errands follow the priority table (broken repair,
trainer, badly-worn repair (a fifth of durability or less, assumed from
the client's warning), mailbox, auction house, any repair, vendor); a
town lacking a service skips it. At the auctioneer each bag item is
sorted: kept (whites and greys to the vendor's own rules; anything it has
a use for by the bot module's item judgement; bound items), auctioned,
vendored, or mailed to the owner (bind-on-equip epic gear with a required
level and no use to it); auctions priced by every auction rule below
(minimum by quality, undercut, near-minimum, only-minimum, glut, random
enchantments apart, epics always posted, random stacks, durations,
deposit), posted through the auction window's own request, bid equal to
buyout. Rising prices in `buddy_price` (per auction house), counted from
its auction mail at the mailbox (sold resets, expired adds half the vendor
price). Fixed prices in `buddy_fixed_price`, characters database (617a's
model put it in the world database), empty until filled.

**Built 2026-10-02, syntax-checked with the last build's flags, not yet
compiled or tried in game** (`buddies_town.cpp`: "the wander", "the
meals", "full bags without an auction house"):

- **The wander.** Leisure's townsperson visit now picks its next
  townsperson within 100 yards one of the three ways, at random: the
  nearest within 45° of the bearing to the town's farthest townsperson;
  the same toward one of its class trainers (lessons or not); or anyone.
  A way with nothing to go on (no class trainer in reach) gives way to the
  others in a fresh random order; the one just visited is never next. The
  walk is the visit's own (navigation mesh, walking). Chairs, beds and
  fishing keep their odds (617e4); the wander is the townsperson share.
- **Meals.** At a vendor or repair stop (after selling or repairing) the
  buddy buys food, and drink if it uses mana, up to 20 servings each,
  spending at most a quarter of its money per stop, gold prices only. What
  it buys is what its meal eats (the roam action's meal: real food, since
  the bot module's own eating is its food cheat and is off for buddies):
  food-type consumables whose spell restores health or mana, usable at its
  level, best item level first. Under 10 servings, the vendor stop goes to
  the nearest vendor that sells its meal, even with nothing to sell. 20 is
  one stack, under the bot module's two-stack line, so its item judgement
  never marks the food for sale.
- **Everything sellable, every vendor stop** (owner, 2026-10-13: "we
  should sell all we are able every time we are at a vendor"; written the
  same day, syntax-checked, not yet built). At each vendor stop the buddy
  sells everything a vendor pays for, not only greys and what the bot
  module judges surplus. Kept: what the full-bags rounds never sell
  (below: the hearthstone, tools, fishing pole, gear and ammo in use,
  quest items, epics for the owner); its consumables (food, drink and
  potions, which it would buy back at the same stop); its trade goods
  (kept for the auction house and its professions, sold to a vendor only
  by the full-bags rounds below: owner 2026-09-26, "not counting things
  they just want to keep like hearthstone, consumables, tradegoods for
  their profession"); anything with a
  "Use:" effect (owner, 2026-10-13: "any item with a 'use' should be kept
  to be used when required"); unbound greens and better, in every town,
  for the auction house (owner, 2026-10-13: "Green and blue items should
  be sold on the AH instead of vendored"; bound ones can't be auctioned
  and are sold); and, in a town with an auction house, the whites the bot
  module would rather auction. The vendor stop is
  still chosen as before (always when bags are 90% full with no
  auctioneer, otherwise at odds equal to how full the bags are).
- **Full bags without an auction house.** With no auctioneer in the town
  and bags 90% full or more, the vendor stop is always made; after the
  junk, three rounds at the vendor: (1) the cheapest items by vendor value
  of the stack, up to half the bag slots, keeping hearthstone, consumables
  and trade goods; (2) if still 90% full, trade goods, cheapest first,
  until under the line; (3) consumables likewise. Never sold in any
  round: bind-on-equip epics for the owner, profession tools and fishing
  poles, gear it would wear, ammo, quest items. Still full after round 3:
  an error in the server log naming each round's result, what is left and
  why, and what to check.
- Fixed in passing: the errand survey and the townsperson check took an
  NPC indoors in a town (its own area number) for outside the town, so a
  trainer or vendor in a building was never an errand; both now read the
  ground under the NPC as `BuddyTownArea` does for players.

**Not built:** buying clan members' upgrades (bag slots, gear, and
materials for a low crafting skill, 2026-09-25). It needs 617j's
clan scoring (who an item upgrades, by stat weights), being built
separately; it goes here once that exists.

Before:

Buddies do not exist yet. 617e's town behavior has buddies walk (never run)
between NPCs: merchants weighted by how full their bags are, their class
trainer first when they have spells to learn, otherwise a random NPC.

**The bot module has no working auction behavior** (read 2026-09-24). Its
only auction code, an "auction item" step in its loot action, is commented
out. Even that was an auction-house *simulator*: it created brand-new
copies of an item and listed them at the item's vendor price times a
multiplier, instead of selling what a bot carries. So there is no pattern
to follow, and this issue is the owner's own design.

## Intended Behavior

### The errand list

On entering a town or city, a buddy builds a short task list from the
services that town has (vendor, repair vendor, auction house, trainer) and
its own state, in this priority order:

| Priority | Task | When it is on the list |
|---|---|---|
| 1 | Repair | at least one **red** item (broken) |
| 2 | Trainer | it has spells it can learn and afford |
| 3 | Repair | no red items, at least one **yellow** item (badly damaged) |
| 4 | Mailbox | the town has one: collect sold-auction money and returned items |
| 5 | Auction house | the town has one and the buddy has something to sell |
| 6 | Repair | anything damaged at all, nothing yellow |
| 7 | Vendor | trash goods and whatever the auction rules below send to a vendor |

If the owner leaves town mid-errand, the buddy **finishes the task it is
on**, then drops the list and follows (617e).

Red and yellow follow the client's durability warning (the armor figure
turns yellow when an item is badly worn and red when one is broken).

At a repair or vendor stop the buddy may also **buy consumables it will
actually use in the field** (food, drink, later potions), and only those
its combat and rest logic is known to use. Vendor lists get potions later
(Ritz: "Don't worry about that now").

### After the errands

The buddy wanders the town until the owner leaves, choosing its next NPC
one of three ways, at random:

- the next closest NPC in the general direction of the town's most
  distant NPC;
- the next closest NPC in the general direction of one of its class
  trainers in the city;
- a random NPC in the town.

It walks there along the ground's navigation mesh, as a player would, never
cutting through walls or teleporting.

### Auction rules

- **Minimum price by quality** (multiplier on the item's vendor sell
  price): green 1.5×, blue 2×, epic 2.5×. Whites are never auctioned
  (quality adds 0.5× per step above white).
- **Undercut**: if the same item is listed above the buddy's minimum, it
  lists at the lowest such listing minus 10% (equipment) or 5%
  (everything else).
- **Near-minimum listings count as at the minimum**: a listing close
  enough that the undercut would drop below the minimum is treated as a
  minimum-price listing. If the buddy still posts (an epic, or fewer than
  5 listed), it posts at its minimum, provided that is still below the
  listing it is competing with.
- **Only minimum-price listings present**: equipment is vendored; trade
  goods are listed.
- **Random enchantments are distinct items**: "of the Tiger" and "of the
  Whale" versions of the same armor don't compete. Equipment is listed when
  the only competing listings have a different enchantment.
- **Glut rule**: if the exact item (same enchantment) already has 5 or
  more listings, vendor it. **Epics are always posted**, glut or not.
- **Epic gear**: an upgrade is equipped (617j). A **bind-on-equip epic
  that isn't an upgrade is never auctioned and never vendored**: the buddy
  holds it until it reaches a mailbox and mails it to its owner (Ritz,
  2026-09-24). This covers every Outland epic, all of which require 60 on
  basic. A **soulbound** epic that isn't an upgrade is vendored.
- **Other epics are auctioned**, always posted even into a glut: epics
  with no required level (e.g. enchanting materials) and epics that aren't
  gear (bags, recipes, mounts).
- **Stacks**: a buddy holding more than one full stack's worth posts
  random-sized stacks, each between 1 and the stack limit (56 of an item
  that stacks to 20 might become 7, 20, 13, 16); holding a full stack or
  less, it posts all of it at once. Prices compare per unit.
- **Durations**: equipment 48 hours, trade goods 12 hours, anything else a
  player might want 24 hours.
- **Rising prices**: when a listing expires and no copy of that item is
  on the auction house, the buddy relists it at its last price plus 0.5×
  the vendor price (1.5× → 2× → 2.5× …), and again after every unsold
  expiry, with no ceiling, **until any of its copies of that item sell;
  then its price for that item resets** to the normal rules (Ritz,
  2026-09-24: "until any of their items of that type sell. Then it
  resets."). "The price might rise quite
  high. This is intended." (Ritz, 2026-09-24)
- **Deposit**: a buddy that can't afford a deposit stops auctioning for
  the rest of that town visit and vendors instead ("They need the coin, and
  they need it now!"). It tries the auction house again on its next town
  visit, or in a different city.
- **Items with no vendor price** have no minimum; they are listed by hand,
  one by one, in a table of fixed prices the owner fills in (rare items).
- **Money goes to the buddy**, not the owner.
- **Trade skills**: the bot module crafts only on its master's request (a
  "craft" command); buddies have no professions of their own yet. For now
  they list surplus trade goods; buddy professions are a later issue
  (Ritz: "we should build out a system for that eventually").

### Decisions, 2026-09-25 (Ritz)

- The "mail step" and the mailing rule are one thing ("I think those refer
  to the same thing"): the mail step sends bind-on-equip epics that are not
  an upgrade for anyone in the clan to the owner.
- Towns behave by what they have (617e): the errand order above applies to
  the services a town offers; a town with no auction house or no repair
  simply skips those steps.

### Decisions, 2026-09-25 (Ritz), from buddy professions (617k)

- **Buying**: coin earned buys clan members' upgrades; bag slots count as an
  upgrade a buddy can buy for a clanmate; materials to level a low crafting
  skill outrank upgrades (see 617k for when); a craftable upgrade is priced
  at the auction cost of its missing materials.
- **Full bags in a town without an auction house**: sell the lowest-value
  half of the bag space (keeping hearthstone, consumables, profession trade
  goods); still 90% full: sell trade goods; still 90% full: sell
  consumables; past that, an error.

## Suggested Implementation Steps

1. A town-services survey: per town, which service NPCs exist (vendor,
   repair, auctioneer, trainer by class), read from creature spawns and
   their service flags; cached at startup.
2. The errand list as a bot strategy in mod-buddies, run on town entry
   (617e detects towns), with the priority table above.
3. Auction step: read current listings through the server's auction-house
   manager, price by the rules, and create the auction from the buddy's own
   item (moving it, not copying it), with the stock deposit.
4. Mail step for 60+ epics; collecting returned mail (see Open Questions).
5. Wandering step on the navigation mesh.
6. Tests: a buddy with a red item repairs first; a green with a listing at
   2× vendor price is undercut by 10%; a sixth identical white-free green is
   vendored; a level-60 epic is mailed.

## Related Issues

- **617** parent; **617e** town behavior (this replaces its merchant
  weighting when a town has an auction house)
- **155b** random bots off on basic, so buddies are the only bot sellers

## Open Questions

- (Answered 2026-09-24) After a sale the rising price resets.
- (Answered 2026-09-24) Price rise: +0.5× vendor price per unsold expiry,
  no ceiling. Epics: upgrades equipped; bind-on-equip non-upgrades mailed
  to the owner, never sold; soulbound non-upgrades vendored; non-gear and
  no-level epics auctioned.
- (Open, 2026-10-02) The full-bags rounds also never sell profession
  tools, fishing poles, gear the buddy would wear, ammo, quest items and
  the owner's epics, beyond the hearthstone, consumables and trade goods
  the rule names. Is that right, or should round 1 take any of them?
- (Open, 2026-10-02) Round 1 "the lowest-value half of the bag space" is
  read as: the cheapest stacks, by vendor price times count, up to half the
  total bag slots in number. Rounds 2 and 3 stop as soon as the bags are
  under 90%, not when every trade good or consumable is gone. Right?
- (Open, 2026-10-02) Meal stock 20 servings, restocked below 10 by a trip
  to a food vendor, at most a quarter of the buddy's money per stop.
  Right sizes?
- (Answered 2026-09-24) Required level decides "60+ epic". Only-minimum:
  equipment vendored, trade goods listed. No vendor price: a hand-kept
  price list. Random stacks. Near-minimum counts as minimum. Undercutting
  buddies is fine. No deposit: vendor for the rest of the visit. Mailbox
  after yellow repair. Finish the current task. Epics always posted.
- (Open, 2026-10-13) White trade goods at the auction house. The owner
  said "For trade goods they will list it" (2026-09-24) and also "whites
  are not auctioned at all" (the price multiplier, same day). Most trade
  goods are white (cloth, leather, ore, herbs), and the auction errand
  as built lists only greens and better, so today no trade good is ever
  listed: they are kept, and vendored only by the full-bags rounds.
  Should white trade goods be listed (an exception to "whites are not
  auctioned"), and at what minimum price?
