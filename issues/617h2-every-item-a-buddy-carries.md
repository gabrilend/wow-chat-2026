# 617h2 - Every Item a Buddy Carries, and When It Uses It

## Status
- Created: 2026-10-13
- Phase: 6
- Parent: 617h (buddies in town: selling, auctions, meals)
- Related: 617j (buddy loot judgement), 617d (quest rewards for
  buddies), 617n (buddy spells), B046 (the bot module's loot judgement
  for buddies)
- Priority: Medium
- State: the plan model built 2026-11-06 (`src/lua-basic/lib/buddy-item-plan.lua`,
  tested offline), and on 2026-11-05 given the owner's answers (quest
  items, ammo, the purse, the mailbox); the catalogue and hooking it to the
  game are not; one question open (who fills an ammo bag)

## Origin

Verbatim, 2026-10-13:

> what do buddies spend gold on in capital towns? Green and blue items
> should be sold on the AH instead of vendored. Also any item with a "use"
> should be kept to be used when required. Can you identify each of the
> items that a bot might be able to pick up, so no quest items because
> they skip them, but yes to quest rewards because they get them. and
> then see when exactly the bot would use it, and if there's any gaps,
> can we fill them?

## Current Behavior

**What a buddy spends money on in a town** (`buddies_town.cpp`): its
class trainer's lessons; repairs; food and drink (up to 20 servings
each, at most a quarter of its money per stop); auction deposits. Nothing
else: no gear, no gems, no bags, no potions, no profession recipes or
materials.

**What it keeps** (2026-10-13, not yet built): at a vendor it sells
everything a vendor buys except what it can't spare (hearthstone, tools,
fishing pole, gear and ammo in use, quest items, epics for its owner),
consumables, anything with a "Use:" effect, and unbound greens and better
(those wait for an auction house).

**When it uses what it carries:** not surveyed. The bot module has its
own rules for some kinds (eating and drinking, healing potions and
mana potions in a fight, bandages, some class reagents); the buddies' own
eating replaces the module's food cheat. Which items a buddy can come by
and which of them nothing ever uses is unknown.

## Intended Behavior

A catalogue, generated from the world database, of every item a buddy
can come by: creature and object loot (quest-only drops left out: buddies
skip quests' items), quest rewards (buddies receive them, 617d), what
vendors sell that it buys (food, drink), and profession products. Each
kind (healing potion, mana potion, elixir, flask, scroll, food, drink,
bandage, trinket with a use, openable bag or box, recipe, reagent, ...)
with:
- how many items of that kind, and at what levels;
- when the bot module or the buddy module uses it, naming the rule (or
  "never");
- the gap list: kinds it carries and never uses.

Then the gaps filled, one rule per kind (open questions decide which).

**A plan for each item, made when it is picked up** (the owner,
2026-10-30, word for word: "Remember, everytime a buddy-bot picks up an
item, they decide immediately what they want to do with it, and only
update this plan if a new items plan would change based on whether or
not they did something different with it, like hold onto it (a pearl for
a recipe they know for example) or if they sold it (finally have enough
money to buy that 2h axe from the AH) etc."). The moment a buddy picks
something up, it decides what that item is for (wear it, keep it for a
recipe it knows, keep it to use, earmark it for the owner, give it to a
clan-mate, sell it to a vendor, put it on the auction house), and keeps
that plan with the item. Plans are not revisited on every tick: an
item's plan changes only when a newer item's plan would come out
differently depending on it (a pearl kept because a newly learned
recipe needs it; an item now sold because the money would finally buy
the two-handed axe it wants from the auction house). The plans are what
"go sell", the earmarks and the full-bags asking (623) read. The plans
are every use an item can have (the owner, 2026-10-30, asked whether to
add disenchanting: "yeah. any use you can think of."): besides those
above, disenchant it, use it in a profession it has, open it, read or
learn it, feed it to a pet, and any other use the catalogue finds. Not
shown to the owner (asked about a command listing them: "nah. They might
tell the player if asked when we set up llm capabilities but that's for
later.").

## Suggested Implementation Steps

1. The catalogue generator (Lua, reading the world database read-only),
   writing a page under `docs/` with the counts by kind and level.
2. The use rules, read from the bot module's source (its use, drink,
   eat, potion and scroll actions and their triggers) and the buddy
   module's, written beside each kind.
3. The gap list, shown to the owner, decided one kind at a time.
4. Each new use rule; a test per rule where it can be checked offline.

## Open Questions

Gathered 2026-10-28 into 617's own list (question 25), merged with the
same questions from other sub-issues; answers are written back here.

- **Answered 2026-10-28** (617's question 25): openable items (bags of
  coin, clams, lockboxes a rogue can pick) are opened at once; a recipe the
  buddy's profession and skill can use is learned (others go on another
  list); buddies do buy more (potions, better gear at the auction house,
  bags); stat scrolls follow the inscription overhaul's rules (155o: one
  scroll active at a time per character, 30 minutes, stacking with class
  buffs), so a buddy keeps its best scroll up.

- **Answered 2026-10-28**: rare epics are treated as any item ("we should
  treat items as normal and skip that behavior for now"): no mailing them
  to the owner for now.

- **The design, 2026-10-28** (617's question 24): every item a buddy gets
  is put on a list of what to do with it, per buddy, kept in Lua and
  worked out again when the buddy logs in; each list is settled when the
  buddy is near what settles it (a vendor, the auction house, a profession
  trainer, a mailbox...); a buddy sells as much as it needs to. Quest
  items never reach buddies (changed 2026-11-05: those with a sell price
  do, below).

- **Answered 2026-11-05** (the owner, reviewing the plan model's pull
  request; word for word):
  - Quest items: "buddies shouldn't pick up quest items unless they have
    a sell price, and then they should vendor them, unless they're used in
    professions or something, then they should treat them like a trade
    good. Essentially, treat them like "white" quality items."
  - Ammo: "ammo needs to be kept. For hunters and others who are
    specifically ranged-weapon-forward (custom classes?) we want to fill up
    an ammo bag. Basically, if there's an ammo bag, always keep it full of
    the best ammo we can get our hands on. If we can get better ammo, we
    can sell the lowest quality one to replace it. For other classes
    (warrior, rogue, etc) we just need one stack of ammo."
  - Buying with auction money not yet in hand: "well that's silly. How
    could we buy something with money we don't have? We should count them
    as "sold", as in, we're not actively thinking about them, and if the
    auction doesn't get a buyer then we will re-prioritize the item again
    when we pick it up from the mailbox. If we get gold from a successful
    auction, then great! No re-categorization needed." Then: "no, money
    only counts when it's in their purse, after being picked up from the
    mailbox."
  - Wants bought in their list's order rather than cheapest first:
    "that's okay. So long as we can prune the list when needed."
  - The mailbox: "when buddy-bots have the mailbox open, they should be
    able to decide whether or not to pick up items. They will always get
    the mail that has just gold in it, and indeed if there's a message that
    has gold and items, they will always take the gold and possibly leave
    the items. When they have the mailbox open, they will run their
    prioritization system on the items that are in the mailbox. If they are
    in a town with an auction house, then they will pick up things they
    need to auction. Same for if they're in a town with a vendor. If
    they're at a mailbox without any vendors, like for example in the DK
    starting zone, then they won't pick up any items that they intend to
    vendor. For profession items, they will pick them up if they have
    profession stuff on their todo list, which they generate when they
    enter the town and update dynamically as they run errands. The todo
    list is wiped when the player leaves the town, so buddy-bots will drop
    what they're doing and follow the player." (The to-do list is 617e4's.)

1. Openable items (a bag of coins, a clam, a locked box a rogue opens):
   open at once on pickup, or keep?
2. Scrolls (stat buffs): use before a fight, on themselves, or give to
   the owner?
3. Recipes a buddy picks up: learn it if it has the profession and the
   skill, else auction it?
4. Should buddies spend money on more than they do now (potions from
   vendors, better gear from the auction house, bags)?
5. **Open (2026-11-05): who fills an ammo bag.** What makes a class
   "ranged-weapon-forward" (a hunter today; custom classes later): read
   from the class, or from the buddy's ranged slot being its main weapon?
   The owner: "I dunno. let's leave it unanswered for now." Until it is
   answered the caller says, as `buddy.ammo_stacks` (an ammo bag's slots,
   or 1).

## Decisions, 2026-11-06 (an agent, answering what was still open)

Built: the per-item plan from the 2026-10-28 design and the owner's
2026-10-30 words, as a pure Lua module
(`src/lua-basic/lib/buddy-item-plan.lua`, page `buddy-item-plan.info.md`),
tested by `scripts/test-buddy-item-plan` (quick test: the owner's pearl
and axe examples, each kind of item, quest items, ammo kept and replaced,
the mailbox, and 400 random buddies against a referee; a mutation pass of
44 changes to the module, all caught, and 19 more for the 2026-11-05
answers, all caught). Not
built: step 1 (the catalogue needs the world database), step 2's survey
of the bot module's use rules (its source isn't in this repository), and
hooking pickups and town stops to the module (needs the server). These
were open, and are decided here so the model could be built; each can be
changed in one line of the rule table:

1. **The order of the rules** (first that fits wins): a quest item nobody
   pays for is left where it lies ("leave"); what it can't spare
   (hearthstone, a profession tool, a fishing pole, a weapon kept as a
   runner-up, the ammo it fires), wear, open, learn, feed its pet, use,
   craft, give to a clan-mate, disenchant, auction, vendor, junk. Its own
   uses come before a clan-mate's, and a clan-mate's before money. A quest
   item with a price is judged as a white item, and as a trade good when a
   profession uses it (`item.material`, from the catalogue), per the owner's
   2026-11-05 answer.
2. **Whether to wear it is not judged here.** The bot module's item usage
   and 617e4b's kept weapons already decide that; the caller passes
   `wear = "now"` or `"kept"`.
3. **Wear, open, learn and disenchant are done at once**, at pickup; what
   comes out (the old gear, the clam's pearl, the dust) is picked up as new
   items with plans of their own.
4. **A plan changes only when a recipe is learned** (its reagents become
   "craft", the owner's pearl) **or better ammo comes** (the worst kept
   stack goes to the vendor). Ammo is ranked by damage per second, then
   the fuller stack, then the one held longest; the buddy keeps
   `ammo_stacks` stacks, and a spare stack still in the bags is kept again
   if that number grows. A login works every plan out again from the
   bags; the test checks that this always gives the plans the pickups
   gave, and that the same ammo in any order keeps the same stacks.
5. **The owner's axe is a "want"**: a price it saves for, "ready" once its
   purse plus what the items still in its bags should sell for cover it
   (cheapest want first, for the "ready" mark only). Wants are bought at an
   auction house in their list's order, each one the purse covers, and
   only from the purse: an item put up at the auction house is out of mind
   and brings nothing until its money is taken from the mailbox; an item
   that didn't sell comes back by mail and is planned again there. The
   list is pruned by name. What a want is (which gear, from where) is the
   caller's.
5a. **The mailbox** (`Plan.mailbox`): money is always taken; each item by
   the plan it would get: to auction only with an auction house near, to
   sell only with a vendor near, a profession item (a reagent it crafts
   with, a recipe it can learn, a bound item to disenchant) only when the
   to-do list holds a profession errand; what it keeps, wears, opens,
   uses, feeds its pet or gives on is always taken, junk never. What the
   town has and what is on the to-do list are the caller's facts (617e4's
   town visit).
6. **The auction estimate**, when the caller has none, is three times the
   vendor price, until 617h's auction pricing gives one.
7. **Disenchant only what can't be auctioned** (bound items), so the
   owner's "greens and blues go to the auction house" still holds for
   unbound ones; the enchanting skill must reach the item's.
8. **Food its pet eats is fed to the pet**, as the buddy buys its own food
   (617h's meals); food the pet doesn't eat is kept to use.
9. **Recipes it can't learn go to the auction house** when they can be
   traded (the "another list" of 617's question 25), to a vendor
   otherwise; a clan-mate who wants one gets it first.
10. **Trade goods for a profession are kept only as reagents of a recipe it
    knows**; other trade goods go to the auction house (owner, 2026-09-24:
    "For trade goods they will list it").
11. **Items nobody pays for are "junk"**, the first thing full bags (623)
    let go; nothing here destroys them.
