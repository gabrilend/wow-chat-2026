# 617h2 - Every Item a Buddy Carries, and When It Uses It

## Status
- Created: 2026-10-13
- Phase: 6
- Parent: 617h (buddies in town: selling, auctions, meals)
- Related: 617j (buddy loot judgement), 617d (quest rewards for
  buddies), 617n (buddy spells), B046 (the bot module's loot judgement
  for buddies)
- Priority: Medium
- State: planned; open questions first

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

## Suggested Implementation Steps

1. The catalogue generator (Lua, reading the world database read-only),
   writing a page under `docs/` with the counts by kind and level.
2. The use rules, read from the bot module's source (its use, drink,
   eat, potion and scroll actions and their triggers) and the buddy
   module's, written beside each kind.
3. The gap list, shown to the owner, decided one kind at a time.
4. Each new use rule; a test per rule where it can be checked offline.

## Open Questions

1. Openable items (a bag of coins, a clam, a locked box a rogue opens):
   open at once on pickup, or keep?
2. Scrolls (stat buffs): use before a fight, on themselves, or give to
   the owner?
3. Recipes a buddy picks up: learn it if it has the profession and the
   skill, else auction it?
4. Should buddies spend money on more than they do now (potions from
   vendors, better gear from the auction house, bags)?
