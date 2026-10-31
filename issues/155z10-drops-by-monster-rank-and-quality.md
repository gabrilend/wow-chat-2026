# 155z10 - Drop Rates and Amounts by Monster Rank and Item Quality

## Status
- Created: 2026-10-22
- Phase: 1
- Parent: 155 (basic profile)
- Related: 155z8 (rares on the common clock), 718e (the west path out of
  the Enclave through Tyr's Hand: "extra rewards")
- Priority: Medium
- State: built 2026-10-30 (basic_rules.cpp and C044), waiting for the compile; no knob turned yet

## Origin

Verbatim, 2026-10-22:

> Can we find the tuning knob that calibrates how much more each tier of
> mob will be rewarded with certain quality item drops? For example, if
> rares get 2x the green drop rate and quantity, then we should be able to
> turn a knob that would adjust it to 3x, or 2 rate and 3 quantity, just
> for greens, for that specific monster type. We can store it in the
> config file.

## Current Behavior

**Built 2026-10-30, waiting for the compile** (syntax-checked with the
build's own flags): basic's rules (`src/cpp-basic/basic_rules.cpp`) read a
table of knobs, `Basic.Drop.<Rank>.<Quality>.Rate` and `.Quantity`, for
ranks Normal, Elite, Rare, RareElite, Boss and qualities Poor to
Legendary, each 1 when unset, on top of C040's rates. On each item rolled
from a monster's own loot, its chance is multiplied by the cell's rate;
a plain item with its own chance gets the quantity as tries
(1 - (1 - p)^n); a one-quality table is processed that many times. Items
sharing a group's chance equally are left as they are. The knobs are the
lines of `C044_CELLS` in config patch C044 (basic), none turned yet, so
nothing changes. Quantity as tries is the first form; the same-quality
copies the owner intends are not built.

Before it, there was no such knob in the stock server. What exists:

- **By quality, for every monster alike** (worldserver.conf, all 1 on
  basic): `Rate.Drop.Item.Poor`, `.Normal`, `.Uncommon` (greens), `.Rare`
  (blues), `.Epic`, `.Legendary`, `.Artifact`, `.Referenced` (the shared
  loot lists), `.ReferencedAmount` and `.GroupAmount` (how many rolls a
  shared list or a loot group makes), `Rate.Drop.Money`.
- **By monster:** each monster's own loot list (`creature_loot_template`):
  a rare drops more greens than its neighbours because its list says so,
  not because of its rank. There is no "rares get 2x greens" anywhere.

Where a knob can be added: the server lets compiled scripts adjust each
item's drop chance as it is rolled (`OnItemRoll`, GlobalScript.h) and the
number of times a shared list is rolled (`OnAfterRefCount`); the loot knows
which monster it came from.

## Intended Behavior

A table of multipliers, by **monster rank** (ordinary, elite, rare, rare
elite, boss) and **item quality** (grey to epic), each with two numbers:
**rate** (the chance each item drops) and **quantity** (how many of it, or
how many rolls a shared list makes). All 1 to start (stock). The table is
in worldserver.conf, so turning a knob is an edit and a restart, not a
compile:

```
Basic.Drop.Rare.Uncommon.Rate     = 2
Basic.Drop.Rare.Uncommon.Quantity = 3
```

## Suggested Implementation Steps

1. Answer the open questions.
2. The settings: a config patch for basic writes the table's keys (all 1)
   into worldserver.conf.
3. The rule in basic's compiled rules (`src/cpp-basic/basic_rules.cpp`):
   reads the keys at start (and on the server's config reload); on each
   item rolled from a monster's loot, multiplies its chance by the rate
   for the monster's rank and the item's quality; on each shared list,
   the count by the quantity.
4. A line in `docs/balance-updates.md` for each knob turned.
5. Tests: kill a rare a hundred times with greens at 3x (a GM command
   that rolls a monster's loot without killing it would make this fast).

## Open Questions

1. **"Quantity":** more copies of the same item (a stack of 3 instead of
   1, which only makes sense for stackables like cloth), or more rolls
   (three chances at a green instead of one)? **Answered 2026-10-30**
   (the owner, word for word): "for stackable items, it gives multiple
   quantity. For non-stackable things like greens, then if it rolls one,
   then instead of giving just one it gives a second from the same loot
   type roll list as well. My understanding is that especially for
   Azeroth there's white, green, blue, etc items in the same lists, and
   in later expansions they separated that into "chance for a green,
   chance for a blue, etc" etc. So for now, just treat it like 3x rolls,
   though the intended behavior is that if a green drops, then instead 3x
   greens would drop if the quantity was set to 3. If a blue drops, then
   3x blues would drop." So: a stackable drop comes as that many copies;
   a non-stackable drop brings more drops of the same quality from the
   same loot list (quantity 3: a green drop is three greens, a blue
   three blues). Built for now as that many rolls of the list; the
   same-quality form is the intended one.
2. **Rank or something finer:** rank (rare, rare elite, elite) is what
   the server knows about each monster. Is "monster type" rank, or also
   beast/humanoid/undead and so on? **Answered 2026-10-30:** "just rank.
   the loot tables already handles monster type."
3. **Players only, or buddies too:** the multipliers apply to every kill,
   or only kills a real player took part in? **Answered 2026-10-30:**
   "every kill."
