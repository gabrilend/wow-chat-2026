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
  tested offline); the catalogue and hooking it to the game are not

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
  items never reach buddies.

1. Openable items (a bag of coins, a clam, a locked box a rogue opens):
   open at once on pickup, or keep?
2. Scrolls (stat buffs): use before a fight, on themselves, or give to
   the owner?
3. Recipes a buddy picks up: learn it if it has the profession and the
   skill, else auction it?
4. Should buddies spend money on more than they do now (potions from
   vendors, better gear from the auction house, bags)?

## Decisions, 2026-11-06 (an agent, answering what was still open)

Built: the per-item plan from the 2026-10-28 design and the owner's
2026-10-30 words, as a pure Lua module
(`src/lua-basic/lib/buddy-item-plan.lua`, page `buddy-item-plan.info.md`),
tested by `scripts/test-buddy-item-plan` (quick test: the owner's pearl
and axe examples, each kind of item, and 400 random buddies against a
referee; a mutation pass of 44 changes to the module, all caught). Not
built: step 1 (the catalogue needs the world database), step 2's survey
of the bot module's use rules (its source isn't in this repository), and
hooking pickups and town stops to the module (needs the server). These
were open, and are decided here so the model could be built; each can be
changed in one line of the rule table:

1. **The order of the rules** (first that fits wins): what it can't spare
   (hearthstone, a profession tool, a fishing pole, a weapon kept as a
   runner-up), wear, open, learn, feed its pet, use, craft, give to a
   clan-mate, disenchant, auction, vendor, junk. Its own uses come before
   a clan-mate's, and a clan-mate's before money.
2. **Whether to wear it is not judged here.** The bot module's item usage
   and 617e4b's kept weapons already decide that; the caller passes
   `wear = "now"` or `"kept"`.
3. **Wear, open, learn and disenchant are done at once**, at pickup; what
   comes out (the old gear, the clam's pearl, the dust) is picked up as new
   items with plans of their own.
4. **A plan changes only when a recipe is learned** (its reagents become
   "craft", the owner's pearl), as nothing else a pickup does changes a
   fact a held plan reads. A login works every plan out again from the
   bags; the test checks that this always gives the plans the pickups
   gave.
5. **The owner's axe is a "want"**: a price it saves for, "ready" once its
   money plus what its planned sales should bring cover it, cheapest want
   first, and bought at the next auction house the money (after the sales
   made so far) covers. What a want is (which gear, from where) is the
   caller's.
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
