# 718f - A Death Knight's Buddies Eat What It Eats

## Status
- Created: 2026-10-22
- Phase: 7
- Parent: 718 (death knight sacrifice and open Acherus; its buddies)
- Related: 617a4 (the buddy starting kit: food and drink), 617h2 (every
  item a buddy carries), 718e (the buddies' arrival after the rise)
- Priority: Low
- State: planned; open questions first
- First profile: basic

## Origin

Verbatim, 2026-10-22:

> we should give the death knight buddy-bots the same food that the
> player has.

## Current Behavior

Every buddy is made with the buddy starting kit (617a4,
`patches/B036-mod-buddies/mod-buddies/src/buddies_kit.cpp`): 5 servings of
the best food a vendor sells for its level, and 5 of the best drink if it
uses mana. A death knight player's buddies get the same kit; nothing
looks at what the death knight carries. The death knight buddy gear
script (`src/lua-basic/death-knight-buddy-gear.lua`) dresses them 10
seconds after each appears, and leaves food alone.

## Intended Behavior

When a death knight's buddy appears, it is given the food the death knight
is carrying: the same items. The kit's own food stays as it is (or is
replaced: open question 2).

## Suggested Implementation Steps

1. Answer the open questions.
2. In `death-knight-buddy-gear.lua`, beside the dressing (it already
   finds the owner and waits for the buddy): read the owner's bags for
   items that are food (item class 0, consumable; subclass 5, food and
   drink; the spell that makes it eaten rather than drunk), and add the
   same items to the buddy.
3. A test beside `scripts/test-dk-buddy-gear`: an owner with two kinds of
   food and a potion, a buddy that receives only the two foods.

## Open Questions

1. **How much.** The same count the death knight carries, a fixed number
   of each kind (the kit's 5), or one stack?
2. **The kit's food.** Kept beside the owner's food, or taken away so the
   buddy carries only what its owner eats?
3. **Drink.** "food": only food, or drink too for buddies that use mana
   (death knights don't drink, but their buddies can be any class now)?
4. **When.** Only when a buddy first appears, or each time it appears
   (so it follows what the death knight carries now)?
