# Cutting a Gem Through the Trade Window Patch (B034)

## Overview

Epic Wrath gems, cut and uncut, bind on pickup on the basic profile (issue
155p), so a gem's owner can't hand an uncut epic gem to a jewelcrafter. This
patch lets a jewelcrafter cut the other player's gem inside a trade, the way
an enchanter enchants an item in the "will not be traded" slot. Ritz,
2026-09-25: "If the jewelcrafter can cut the gem when it's in the 'will not
be traded' slot, then it's worth it, because they can exchange gold if
they'd like at the same transaction."

Two parts:
- `patches/B034-trade-gem-cut.sh` — the trade itself, in the core;
- the `.cut` chat command in `src/cpp-basic/basic_rules.cpp` (basic's
  compiled rules, put into the tree by B030), which starts it.

Why a command and not the Create button: the client's tradeskill window
disables Create whenever the crafter's own bags hold fewer reagents than
the recipe needs (`Interface\AddOns\Blizzard_TradeSkillUI\Blizzard_TradeSkillUI.lua`,
the `creatable` flag), so a gem in the other player's slot can never be
cut with it. The project uses no addons (docs/roadmap.md).

## Files to Modify

### 1. `src/server/game/Handlers/TradeHandler.cpp`

**Helpers**, inserted before `void WorldSession::SendTradeStatus(...)`:
- `B034_IsGemCut(spell, &reagent, &count, &product)` — a spell that creates
  one gem (item class 3) from exactly one reagent;
- `B034_CanCut(cutter, owner, spell, gem)` — the recipe is a gem cut, the
  cutter knows it, the owner's "will not be traded" item is its reagent in
  enough count, and the owner has room for the product; if not, both
  players are told why;
- `B034_Cut(cutter, owner, spell, gem)` — destroys the owner's uncut gem,
  stores the cut gem in the owner's bags (binding as its template says),
  marks the cutter as its crafter, and gives the cutter the skill-up.

**`HandleAcceptTradeOpcode`, both sides' pending-spell checks.** The lines

```cpp
        if (uint32 my_spell_id = my_trade->GetSpell())
        if (uint32 his_spell_id = his_trade->GetSpell())
```

become: if the pending spell is a gem cut that can't happen now, refuse the
accept (clear accept mode, clear the spell, return) before anything changes
hands; otherwise keep gem cuts out of the stock spell path (which would
look for the reagent in the caster's own bags):

```cpp
        if (uint32 my_spell_id = B034_IsGemCut(my_trade->GetSpell()) ? 0 : my_trade->GetSpell())
```

**After items and gold have moved**, before the line `        if (my_spell)`:
each side's gem cut is performed with `B034_Cut`.

### 2. `src/cpp-basic/basic_rules.cpp` (basic's compiled rules)

A `CommandScript` adds `.cut <recipe>` for players: in a trade, it checks
that the linked spell is a gem cut the player knows and that the other
player's "will not be traded" slot holds its uncut gem, then sets the cut as
the trade's pending spell (`TradeData::SetSpell`), which shows it under the
gem and resets both accept buttons.

## Usage

1. The gem's owner opens a trade with a jewelcrafter and puts the uncut gem
   in "Will not be traded"; either side may add gold.
2. The jewelcrafter types `.cut ` and shift-clicks the recipe in their
   Jewelcrafting window, then presses Enter.
3. Both accept. The cut gem appears in the owner's bags, bound to them.

To see in game: the text the trade window shows under the gem (the client
turns the spell id into words; a gem cut's spell carries its gem's name).

## Build Instructions

Both parts are in the basic profile's source patch list
(`patches/patches.sh`: B030 carries basic_rules.cpp, B034 the trade
change), applied before compiling and reverted after. Check the round trip
with `scripts/test-source-patches`.
