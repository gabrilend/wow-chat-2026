# 812 - Enchanting Scrolls from Dungeon Bosses

## Status
- Created: 2026-10-04
- Phase: 8
- Profile: basic
- Priority: Low
- Related: 810 (the joined runs and their drop counts), 155p (the gem
  supply: Outland's monsters drop uncut gems, the higher-level side of
  this), 617t (stand-ins' dungeon rewards)

## Origin

Verbatim, 2026-10-04:

> can we also have raid bosses drop an enchanting vellum with a random
> enchantment from around that level on it? Just for the low level
> dungeons. The higher level ones give gems, I think. Or is it jewels? It
> shouldn't replace an item, but it should still drop more from
> characters with large loot tables.

## Current Behavior

Not built. Dungeon bosses drop their own items. An enchantment on
vellum is an item the game already has: an enchanter writes an
enchantment onto Armor or Weapon Vellum and gets a "Scroll of Enchant
..." anyone can use (265 such scrolls in the world database). None has a
required level of its own. At the higher end, 155p has Outland's monsters
drop uncut gems ("gems": in this expansion "jewel" means only the
jewelcrafters' own Dragon's Eyes).

## Intended Behavior

Bosses of the low-level dungeons (in the joined runs, 810) drop, besides
their items, enchanting scrolls: each a random enchantment from around
the boss's level.

- **Around that level**: a scroll's level is read from its enchantment:
  the Enchanting skill its recipe needs (the client's skill tables),
  mapped to a character level (about skill / 5, as a trainer teaches); a
  boss draws among scrolls within a few levels of its own.
- **Extra, never instead**: the scrolls are added to the boss's loot, not
  taking an item's place.
- **One per kill** (owner, 2026-10-04: "just one each time"): each boss
  drops one scroll per kill.
- Which dungeons: every dungeon up to the level-60 ones, never raids
  (owner, 2026-10-04: "up until level 60 dungeons. not in raids.").

## Suggested Implementation Steps

1. A generator: every scroll, its enchantment, its recipe's skill, its
   level; then per boss of the chosen dungeons, a shared loot list of the
   scrolls near its level and how many it drops; written as an install
   step with an exact revert.
2. A table for the owner: per boss, its level, scroll count, how many
   scrolls it can drop.

## Open Questions

1. (Answered 2026-10-04) Up to the level-60 dungeons; not in raids.
2. (Answered 2026-10-04) One scroll per boss kill.
