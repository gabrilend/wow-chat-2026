# 617r7 - Buddies' Own Copies of Their Starting Gear

## Status
- Created: 2026-10-05
- Phase: 6
- Parent: 617r (gearset profiles)
- Blocked by: 175 (custom items told to the client ahead of time: without it a copy is drawn as nothing until the client has asked about it), 617r2
- Priority: Medium

## Origin

Verbatim, 2026-10-05:

> Great, so we need to make buddy-bot initial starting gear that lacks a
> required level, and we need to ensure that they only sell them to
> vendors, never on the AH or traded to a player. Also they should be BoP,
> that might make it easiest.

## Current Behavior

Not built. Buddies are dressed from the `buddy-white-<tier>` gearsets
(617r2), whose items are ordinary vendor whites no higher than the
record's own level, with their stock required level; anything a buddy
wears it could also trade, mail or auction like any item.

## Intended Behavior

Every item a buddy is given at its making is a **buddy copy**: a new
item number with the original's look (its display id, so the model,
textures and icon are the original's), stats, slot and kind, but:

- **no required level** (0), so a gearset record can dress a buddy in
  gear from anywhere in its tier, chosen for looks (617r5), not for level;
- **binds when picked up** (BoP, `Bonding = 1`): the game itself refuses
  to trade, mail or auction a bound item, so a copy can never reach a
  player or the auction house; it can still be sold to a vendor (which
  pays the original's sell price) and destroyed.

Copies are made by a tool, not by hand: for every item any buddy gearset
names, one copy in one number range kept for the project's own items
(the range recorded in 175), its name the original's; the gearsets name
the copies (the translator, or a mapping applied when the profiles are
written to the database). The copies' answers are sent to clients ahead
of time (175), so a buddy's gear is drawn and inspected right the first
time.

## Suggested Implementation Steps

1. 175's test first: does the client keep an item answer it didn't ask
   for? Everything here waits on it.
2. The copy maker: reads the buddy gearsets, writes the copies as an
   install step's SQL (`item_template` rows: the original's row with the
   new number, `RequiredLevel = 0`, `Bonding = 1`), and the copy numbers
   back into the gearsets.
3. Check with the bot module: buddies selling to vendors already works
   (617h1); confirm nothing in the bot module or the buddy module tries
   to auction, mail or trade bound items (the game refuses, but a bot
   that retries could log noise).
4. In game: a buddy made at level 5 wearing a level-9 piece; its gear
   inspected (model, icon, tooltip right); the auction house and trade
   window refuse it; a vendor buys it.

## Open Questions

1. Should the copies' names say they are a buddy's (for example the
   original's name unchanged, or with a mark), so a player inspecting
   can tell?
2. Bound copies a buddy sells sit in that buddy's vendor buyback, never a
   player's, so nothing leaks. Should they also be worth nothing to sell
   (sell price 0), so buddies don't earn money from their starting gear?
