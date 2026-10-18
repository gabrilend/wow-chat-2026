# 503 - Dynamic Trainer Spawning for Custom Classes

## Status
- Created: 2026-04-05
- Status: Completed
- Completed: 2026-04-05
- Phase: 2
- Priority: High
- Depends: 155 (Custom class selection)

### Trainer Normalization (2026-04-05)

**Lua changes (travel.lua):**
- Uses ALL available trainers per class/faction (not reduced)
- 20 levels distributed evenly among N trainers per class
- More trainers = finer granularity (11 mage trainers → ~2 levels each)
- Fewer trainers = coarser granularity (3 druid trainers → ~7 levels each)
- Players see consistent trainers at each level for their class/faction
- Weapon trainers capped at 1-20 (teach at any level)

**Trainer counts:**
- Warriors: 9 horde, 11 alliance
- Paladins: 5 horde, 7 alliance
- Hunters: 7 horde, 8 alliance
- Rogues: 6 horde, 6 alliance
- Priests: 9 horde, 9 alliance
- Death Knights: 3 neutral
- Shamans: 6 horde, 5 alliance
- Mages: 11 horde, 7 alliance
- Warlocks: 6 horde, 6 alliance
- Druids: 3 horde, 5 alliance

**SQL changes:**
- Created `trainer-spell-level-cap.sql` with per-trainer DELETE statements
- Each trainer has spells removed above their specific maxLevel
- Example: Alliance warrior trainer 5113 (maxLevel 1) → `DELETE ... ReqLevel > 1`
- Example: Alliance warrior trainer 7315 (maxLevel 20) → `DELETE ... ReqLevel > 20`
- Deleted `custom-class-trainers.sql` (no longer needed)

**To deploy:**
```bash
mysql -u ritz -p -P 3307 acore_world < source-beta/data/sql/custom/db_world/trainer-spell-level-cap.sql
.reload ale
```

### Design Revision (2026-04-05)

Original design was over-engineered. Simplified approach:

1. **No custom gossip** - use existing world trainers with their built-in spell lists
2. **Equal probability** - not weighted by spell count, just equal chance per available class
3. **Normal despawn** - trainers despawn like any other traveller
4. **Level-appropriate trainer selection** - pick a trainer whose level range includes player level

## Overview

Custom class players can learn spells from multiple base classes. When the travel system would spawn a trainer, custom class players receive a trainer for one of their learnable classes instead of their base class trainer.

## Current Behavior

As of 2026-10-17 (branch beta-homework, to be merged):
- Travellers run on beta again (`src/lua-beta/travel.lua`, on its own
  clock: a minute after login, then every 130 s, not while dead, swimming
  or sitting; real players only). Among them, one class trainer of the
  player's class whose slice holds the player's level.
- The trainer table lives in `src/lua-beta/data/travel-trainers.lua`
  (129 rows: every class, levels 1-20, both factions; death knight
  trainers for either). Three slips were corrected there against the
  world database: a priest trainer that did not exist (4906, now 4606),
  a warrior trainer filed as a druid trainer (3043, now 3034), and druids
  numbered -10 where the game numbers them 11 (no druid met a trainer).
- "Each trainer has a level range they teach" is now true in the game:
  install step E014 gives each of these trainers its own copy of its
  class's lessons, cut at the top of its slice
  (`scripts/generate-beta-trainer-tiers-sql`, from the same data file).
  Until then E014 wrote `npc_trainer`, which the server no longer reads,
  so every trainer taught its whole class list.
- `scripts/test-travel` checks every class at every level 1-20 for both
  factions meets exactly one trainer of its class whose slice holds its
  level; `scripts/test-beta-sql-in-ram` checks the cut copies on a stock
  world database, and that their undo leaves it exactly as it was.
- The custom-class redirection below (a custom class meets base-class
  trainers of its eligible classes) is dormant: the custom-class
  framework is off. Issue 721 replaces it for beta: a custom class meets
  trainers of its own class only.

Originally:
- Travel system spawns trainers from a pool (travel.lua trainers table)
- Each trainer has a level range they teach
- Custom class players would receive their base class trainer

## Intended Behavior

### Trainer Selection Flow

1. Travel system triggers trainer spawn for custom class player (level 14)
2. Check custom class definition for learnable classes in ±3 range (levels 11-17)
   - Example: rogue, mage, warlock all have spells in that range
3. Equal probability roll: 1/3 rogue, 1/3 mage, 1/3 warlock
4. Find the standard trainer NPC for selected class whose level range includes 14
   - Rogue trainer might cover levels 12-15
   - Warlock trainer might cover levels 13-19
   - Either works for a level 14 player
5. Spawn that trainer as a normal traveller

### Key Points

- **Use existing trainers** - no custom trainer NPCs needed (900021-900031 SQL can be deleted)
- **Standard gossip** - trainer uses its normal built-in spell list
- **Normal traveller lifecycle** - spawns, wanders, despawns like any other traveller
- **Equal probability** - each learnable class has same chance, not weighted by spell count
- **Benefit of high-level players** - level 20 trainers teach all spells levels 1-20

### Level Range Determination

Custom class definitions specify which base classes they can learn from. The ±3 level range check determines which of those classes have any spells the player could learn:

```
Player level 14, ±3 range = levels 11-17
Custom class can learn: warrior, rogue, mage

Check each class:
- Warrior: has spells in 11-17 range? Yes → eligible
- Rogue: has spells in 11-17 range? Yes → eligible
- Mage: has spells in 11-17 range? Yes → eligible

Roll 1/3 for each, spawn the winning class trainer
```

If a class has NO spells in the ±3 range (rare edge case), it's excluded from the roll.

### Trainer Level Ranges

Each class has trainers at different level brackets. The system picks whichever trainer's range includes the player's level:

```
Rogue trainers:
- Trainer A: levels 1-6
- Trainer B: levels 6-10
- Trainer C: levels 10-14
- Trainer D: levels 14-20

Player level 14 → Trainer C or D both work, pick one
```

## Implementation Steps

### 1. Add trainer selection helper to travel.lua

The `trainers` table is local. Add a helper function after the trainer lookup table:

```lua
-- {{{ getTrainerForClass
-- Find a trainer for a specific class that covers the player's level
-- classId: positive class ID (1=warrior, 2=paladin, etc.)
-- playerLevel: player's current level
-- playerFaction: 1=horde, 2=alliance
-- Returns trainerID or nil if no matching trainer
function Travel.getTrainerForClass(classId, playerLevel, playerFaction)
    local negClass = -classId  -- trainers use negative class IDs
    for _, trainer in ipairs(trainers) do
        if trainer.id == negClass then
            if playerLevel >= trainer.minLevel and playerLevel <= trainer.maxLevel then
                -- Check faction: 3 = neutral (works for both)
                if trainer.rel == playerFaction or trainer.rel == 3 then
                    return trainer.trainerID
                end
            end
        end
    end
    return nil
end
-- }}}
```

### 2. Update spawnAndTravel() for custom class

Replace the current custom class trainer logic (lines 116-128) with:

```lua
if Travel.isTrainer(travellerId) and CustomClasses then
    local customClassId = CustomClasses.getCustomClass(player)
    if customClassId then
        -- Get eligible classes from custom class definition
        local eligibleClasses = CustomClasses.getEligibleClasses(player)
        if #eligibleClasses > 0 then
            -- Equal probability selection
            local selectedClass = eligibleClasses[math.random(#eligibleClasses)]
            local playerFaction = player:IsHorde() and 1 or 2
            local newTrainerId = Travel.getTrainerForClass(selectedClass, player:GetLevel(), playerFaction)
            if newTrainerId then
                print("[Travel] Custom class - spawning " .. selectedClass .. " trainer")
                travellerId = newTrainerId
            end
        end
        -- Fall through to normal spawn with (possibly replaced) travellerId
    end
end
```

### 3. Add getEligibleClasses to custom-classes.lua

```lua
-- {{{ getEligibleClasses
-- Returns list of class IDs that have spells in player's ±3 level range
-- Returns positive class IDs: 1=warrior, 2=paladin, 4=rogue, 8=mage, 9=warlock, 10=druid, etc.
function CustomClasses.getEligibleClasses(player)
    local customClassId = CustomClasses.getCustomClass(player)
    if not customClassId then return {} end

    local def = CustomClasses.getDefinition(customClassId)
    if not def or not def.tomeClasses then return {} end

    local playerLevel = player:GetLevel()
    local minLevel    = playerLevel - 3
    local maxLevel    = playerLevel + 3

    local eligible = {}
    for _, classId in ipairs(def.tomeClasses) do
        -- Check if this class has any spells in the level range
        -- (For now, assume all tome classes are always eligible)
        -- Could add spell level checking here if needed
        table.insert(eligible, classId)
    end
    return eligible
end
-- }}}
```

### 4. Remove unnecessary code from custom-classes.lua

- Remove gossip event registration for 900021-900031
- Remove `onDynamicTrainerGossip()` and `onDynamicTrainerGossipSelect()`
- Remove `spawnDynamicTrainer()`
- Remove `countLearnableSpells()`, `getLearnableSpells()`, `calculateTrainingCost()`

### 5. Delete SQL file (DONE)

```bash
rm source-beta/data/sql/custom/db_world/custom-class-trainers.sql
```

## Related Issues
- 155 - Custom class selection (provides class definitions)
- 156 - Monster accuracy level cap (±3 level philosophy)
- 151 - Ability tome system (alternative spell acquisition)

## Files Modified
- `src/lua/travel.lua` - trainer table normalized to 1-20, needs selection logic for custom class
- `source-beta/data/sql/custom/db_world/trainer-spell-level-cap.sql` - removes spells above trainer max level
- `source-beta/data/sql/custom/db_world/custom-class-trainers.sql` - DELETED

## Implementation Complete (2026-04-05)

### travel.lua changes:
1. Added `Travel.getTrainerForClass(classId, playerLevel, playerFaction)` helper
   - Finds trainer from local `trainers` table matching class, level, and faction
   - Returns trainerID or nil if no match
2. Updated `spawnAndTravel()` for custom class players:
   - Calls `CustomClasses.getEligibleClasses(player)` to get eligible classes
   - Equal probability selection: `eligibleClasses[math.random(#eligibleClasses)]`
   - Calls `Travel.getTrainerForClass()` to get trainer ID
   - Falls through to normal spawn logic with replaced travellerId

### custom-classes.lua changes:
1. Added `CustomClasses.getEligibleClasses(player)`:
   - Returns list of tomeClasses that have learnable spells in ±3 level range
   - Uses `countLearnableSpells()` to filter classes with no available spells
2. Removed old custom trainer system:
   - Removed TRAINER_NPC_ENTRIES table (900021-900031 no longer needed)
   - Removed `spawnDynamicTrainer()`, `selectTrainerClass()`, `trySpawnTrainer()`
   - Removed `checkTrainerDespawn()`, `calculateTrainingCost()`, `getLearnableSpells()`
   - Removed `onDynamicTrainerGossip()`, `onDynamicTrainerGossipSelect()`
   - Removed trainer gossip registration loop
   - Kept `countLearnableSpells()` for eligibility checking and #trainerinfo
3. Updated `#trainerinfo` command to show equal probability instead of weighted
4. Removed `#trainerspawn` command (no longer applicable)

### Key Design Points:
- Uses existing world trainers with their built-in spell lists
- Equal probability selection among eligible classes (not weighted by spell count)
- Trainers despawn normally like any other traveller (5 minute timer)
- Custom class trainer NPCs (900021-900031) are no longer needed in database
