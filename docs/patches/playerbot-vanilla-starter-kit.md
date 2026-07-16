# Playerbot Vanilla Starter-Kit Patch (148s)

## Overview

Makes vanilla random playerbots come up in the **148h starter kit** — the
same white level-20 gear a human player receives — instead of the
`PlayerbotFactory`'s randomized greens. The bot upgrades normally as it
levels past 20 (the existing `IncrementalGearInit` / `AutoUpgradeEquip`
path), so the kit is a *starting* state, not a pin.

There is no config knob for bot gearing — the factory always self-gears —
so this is a small source change to the module, delivered through the
patch system (a B-patch that injects it at build time + this doc), never a
raw in-place edit, so it survives the next upstream mod-playerbots update.

### Why it is safe in the shared module binary

The change is **self-scoping on the data**, not gated by a config flag or a
DB-name check. It runs a query for the bot's `(race, class)` 148h kit rows
(`playercreateinfo_item` where `Note LIKE 'vanilla-148h-%'`). On release and
beta those rows do not exist, so the query returns nothing, the branch is a
no-op, and gearing falls through to the stock random pass. Only a world DB
that actually carries the 148h kit (i.e. `acore_world_vanilla`) changes
behavior. Registered only in `PHASE_BEGIN_PATCHES["vanilla"]` as well, so
in practice it is applied only during vanilla builds.

## Files to Modify

### 1. `modules/mod-playerbots/src/Bot/Factory/PlayerbotFactory.cpp`

Insert a branch at the **top of `PlayerbotFactory::InitEquipment`**, right
after the incremental guard and before the `if (level < 5)` block.

**Context (before):**

```cpp
void PlayerbotFactory::InitEquipment(bool incremental, bool second_chance)
{
    if (incremental && !sPlayerbotAIConfig.incrementalGearInit)
        return;

    if (level < 5)
```

**After (inserted block shown between the guard and `if (level < 5)`):**

```cpp
void PlayerbotFactory::InitEquipment(bool incremental, bool second_chance)
{
    if (incremental && !sPlayerbotAIConfig.incrementalGearInit)
        return;
    // >>> B025-vanilla-starter-kit (148s) BEGIN
    // A freshly-geared level-20 bot wears the 148h starter kit (the same
    // playercreateinfo_item rows players get) instead of random gear. Self-
    // scoping: on release/beta the query returns no rows and this falls
    // through to the normal gearing below, so it is safe in the shared module
    // binary. Only the initial (non-incremental) level-20 gearing is touched;
    // past level 20 the ordinary upgrade path runs and the bot outgrows it.
    if (!incremental && level == 20)
    {
        if (QueryResult kitResult = WorldDatabase.Query(
                "SELECT itemid, amount FROM playercreateinfo_item "
                "WHERE race = {} AND class = {} AND Note LIKE 'vanilla-148h-%'",
                uint32(bot->getRace()), uint32(bot->getClass())))
        {
            do
            {
                Field* kitFields = kitResult->Fetch();
                uint32 kitItemId = kitFields[0].Get<uint32>();
                uint32 kitAmount = kitFields[1].Get<uint32>();
                if (sObjectMgr->GetItemTemplate(kitItemId))
                    bot->StoreNewItemInBestSlots(kitItemId, kitAmount);
            } while (kitResult->NextRow());
            return;  // kit applied — skip the random-gear pass
        }
    }
    // <<< B025-vanilla-starter-kit (148s) END

    if (level < 5)
```

### Notes on the implementation choices

- **`StoreNewItemInBestSlots(itemId, count)`** is the same helper the
  `level < 5` branch of `InitEquipment` already uses to equip the DBC
  starting outfit. It stores-and-equips into the best slot for the item, so
  armor/weapons equip and bags/consumables land in the pack. Reusing it
  keeps the change tiny and consistent with existing factory behavior.
- **`uint32(bot->getRace())` / `uint32(bot->getClass())`** — these accessors
  return `uint8`, which `fmt` (used by `WorldDatabase.Query`'s `{}` args)
  would render as a *character*, not a number. The `uint32` casts force the
  numeric formatting.
- **`level == 20`** gates to the vanilla start level (the factory's target
  `level`, per `C007c`). A bot re-geared at a higher level uses incremental
  gearing and skips this branch, so it is not reset back into the kit.
- **`Note LIKE 'vanilla-148h-%'`** — the `%` is a literal in `fmt` (only
  `{}` are special), so no escaping is needed.

## Usage

Applied automatically by the patch system during a **vanilla** build via
`patches/B025-playerbots-vanilla-starter-kit.sh`, which is listed in
`PHASE_BEGIN_PATCHES["vanilla"]` in `patches/patches.sh`. The patch is
idempotent (a `B025-vanilla-starter-kit` marker guards re-application) and
its `unpatch_*` deletes the marker-bracketed block cleanly, so the source
round-trips to upstream HEAD.

After a fresh level-20 bot is created on vanilla it will be wearing the
kit for its race/class. Bots already above level 20 are unaffected.

## Build Instructions

```bash
# Rebuild the vanilla worldserver; the patch pipeline applies B025 at
# PHASE_BEGIN (before cmake) and reverts it afterward.
./scripts/azerothcore update            # for the vanilla profile

# Then reset the random-bot fleet so fresh level-20 bots re-gear through
# the new path, and inspect a few in-world (see 148s validation checklist).
```

## Validation (in-world)

- Reset the bot fleet; inspect a fresh level-20 bot for a few race/class
  pairs — confirm it wears the 148h kit (white gear, the class weapon),
  not random greens.
- Confirm an **off-default kit weapon** equips (e.g. a Tauren Warrior's
  polearm). Bots gear diverse weapon types already, but this is the one
  spot to watch: if the bot spawns without its kit weapon, the factory's
  weapon-proficiency path needs the same grant the ALE hook does for
  players (148h proficiency pretrain) — add it here if so.
- Level a kitted bot past 20 and confirm it upgrades out of the kit
  normally.
- Confirm release/beta bots are unaffected (still random gear).
