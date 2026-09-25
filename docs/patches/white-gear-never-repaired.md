# White Gear Is Never Repaired Patch (B033)

## Overview

On the basic profile, white (common-quality) weapons and armor last twice as
long (their maximum durability is doubled by
`sql/basic/db_world.src/21-white-durability.apply.sql`, E036) but can never
be repaired: once worn out, they stay broken. Issue 155p. Ritz, 2026-09-25:
"Is it possible to make it so that white quality items have doubled
durability, but can never be repaired?" / "This is a separate patch by the
way."

Applied by `patches/B033-white-gear-never-repaired.sh`.

## Files to Modify

### 1. `src/server/game/Entities/Player/Player.cpp`

In `Player::DurabilityRepair` (every repair goes through it: a single item,
"repair all", a guild-bank repair), right after the line that reads the
item's current durability:

```cpp
    uint32 curDurability = item->GetUInt32Value(ITEM_FIELD_DURABILITY);
```

insert:

```cpp
    // >>> B033-white-no-repair BEGIN
    // Everland Ghostsong (issue 155p): white gear is never repaired
    if (item->GetTemplate()->Quality == ITEM_QUALITY_NORMAL)
        return TotalCost;
    // <<< B033-white-no-repair END
```

`TotalCost` is still 0 there, so a white item is neither repaired nor
charged for.

## Usage

Nothing to do in game: repairs skip white items.

Known mismatch, accepted (Ritz: "It might be the best that we can do."):
the vendor window computes the repair price in the game client from the
client's own tables, so the price it shows still includes white items; the
server charges only for what it repairs.

## Build Instructions

Part of the basic profile's source patch list (`patches/patches.sh`);
applied before compiling and reverted after by the build scripts. Check
the round trip with `scripts/test-source-patches`.
