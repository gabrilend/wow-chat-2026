# 127 - Contextual Creature Spawns

## Status: Open

## Dependencies
- Issue 126: dungeon-room-spawn-zones (waypoint grouping concept)

## Current Behavior
- Ambush system queries creature_template for level-appropriate creatures
- Filters by type: `type IN (2, 3, 4, 5, 6, 9, 10)`
- Spawns randomly from pool regardless of location
- Undead might spawn in a forest, beasts in a crypt

## Intended Behavior
- Pick spawn location first (random point around player)
- Find nearest waypoint grouping to that point
- Determine what creature types naturally belong there
- Filter creature pool to matching types
- Spawn contextually appropriate creature

## Why Contextual Spawning?
- Immersion: undead near graveyards, beasts in forests
- World feels alive and coherent
- Leverages existing waypoint data from creature spawns
- Players learn terrain = creature type associations
- Emergent strategy: avoid certain areas for certain threats

## Creature Types (WoW 3.3.5a)
```
0  = None
1  = Beast
2  = Dragonkin
3  = Demon
4  = Elemental
5  = Giant
6  = Undead
7  = Humanoid
8  = Critter
9  = Mechanical
10 = Not specified
11 = Totem
12 = Non-combat Pet
13 = Gas Cloud
```

## Waypoint Type Mapping

### Data Source
Use existing creature spawn data to determine area types:
```sql
-- Find dominant creature type near a point
SELECT ct.type, COUNT(*) as count
FROM creature c
JOIN creature_template ct ON c.id1 = ct.entry
WHERE c.map = ?
  AND ABS(c.position_x - ?) < 100
  AND ABS(c.position_y - ?) < 100
GROUP BY ct.type
ORDER BY count DESC
LIMIT 1;
```

### Precomputed Zone Types
```lua
-- Cache zone types at server start
-- Grid the world into cells, compute dominant type per cell

ZoneTypes = {
    -- map_id, grid_x, grid_y -> dominant creature type
    [0] = {  -- Eastern Kingdoms
        ["45,32"] = 6,  -- Undead (Tirisfal Glades)
        ["50,40"] = 1,  -- Beast (Silverpine Forest)
        ["60,55"] = 7,  -- Humanoid (Hillsbrad)
    },
}
```

## Implementation Steps

### Phase 1: Type Detection
1. Create src/lua/zone-types.lua
2. Query creature spawns per map grid cell
3. Compute dominant type per cell
4. Cache in memory at server start

### Phase 2: Spawn Integration
1. Modify Ambush.randomSpawn to:
   - Pick spawn location first
   - Look up zone type for that location
   - Pass type filter to queue selection
2. Modify setupAmbushQueue to accept type parameter
3. Filter query: `AND type = ?` instead of `type IN (...)`

### Phase 3: Fallback Handling
1. If no creatures match type + level, expand search
2. Try adjacent types (beast <-> critter, undead <-> humanoid)
3. Fall back to any type if nothing found
4. Log mismatches for zone data improvement

## Algorithm

```lua
function Ambush.randomSpawn(player, isRare)
    -- 1. Pick spawn location
    local px, py = player:GetPosition()
    local sx, sy = Movement.getArcSpawnPosition(px, py, MIN_DIST, MAX_DIST, player:GetO())

    -- 2. Get zone type for spawn location
    local zoneType = ZoneTypes.getTypeAt(player:GetMapId(), sx, sy)

    -- 3. Get creature from queue matching type
    local creature = Ambush.getCreatureOfType(player, zoneType, isRare)

    -- 4. Fallback if no match
    if not creature then
        creature = Ambush.getAnyCreature(player, isRare)
    end

    -- 5. Spawn
    if creature then
        local sz = player:GetMap():GetHeight(sx, sy)
        player:SpawnCreature(creature.id, sx, sy, sz, ...)
    end
end
```

## Queue Changes

### Current Queue
```lua
player:GetData("queue")  -- flat list of creature IDs
```

### New Queue (type-indexed)
```lua
player:GetData("queue")  -- table indexed by type
-- {
--     [1] = { 123, 456, 789 },  -- beasts
--     [6] = { 234, 567 },       -- undead
--     [7] = { 345, 678, 901 },  -- humanoids
-- }
```

## Edge Cases

### Ocean/Water
- No waypoints in deep water
- Default to beast (sea creatures) or elemental
- Or prevent spawns entirely

### Zone Boundaries
- Transition areas may have mixed types
- Use weighted random based on nearby proportions
- Or pick closest dominant cell

### Empty Cells
- Some grid cells have no creature data
- Inherit from nearest populated cell
- Or use map-wide default

### Player Level Mismatch
- Zone has undead but no level-appropriate undead
- Fall back to any level-appropriate creature
- Log for balancing review

## SQL Queries

### Precompute Zone Types
```sql
-- Run at server start or cache in file
-- Grid size: 100 yards per cell

SELECT
    map,
    FLOOR(position_x / 100) as grid_x,
    FLOOR(position_y / 100) as grid_y,
    ct.type,
    COUNT(*) as count
FROM creature c
JOIN creature_template ct ON c.id1 = ct.entry
WHERE ct.type IN (1, 2, 3, 4, 5, 6, 7, 9)  -- spawnable types
GROUP BY map, grid_x, grid_y, ct.type
ORDER BY map, grid_x, grid_y, count DESC;
```

### Type-Filtered Creature Query
```lua
-- Modified setupAmbushQueue
function Ambush.setupAmbushQueue(playerLevel, rank, creatureType)
    local typeFilter = ""
    if creatureType then
        typeFilter = " AND type = " .. creatureType
    else
        typeFilter = " AND type IN (1, 2, 3, 4, 5, 6, 7, 9)"
    end

    WorldDBQueryAsync(
        "SELECT entry, minlevel, maxlevel, rank, type FROM creature_template " ..
        "WHERE minlevel <= " .. playerLevel ..
        " AND maxlevel >= " .. playerLevel ..
        " AND rank = " .. rank ..
        " AND npcflag = 0 AND lootid != 0" ..
        typeFilter .. ";",
        Ambush.pushToAmbushQueue
    )
end
```

## Future Enhancements

### Biome System
- Define biomes (forest, swamp, mountain, etc.)
- Map biomes to creature types
- More granular than grid cells

### Time of Day
- Undead more common at night
- Beasts more common at dawn/dusk
- Elementals during weather events

### Event Spawns
- Invasion events override local types
- Scourge invasion = undead everywhere
- Demon portal = demons in area

## Related Files
- src/lua/ambush.lua (current spawn system)
- src/lua/zone-types.lua (new, type detection)
- issues/126-dungeon-room-spawn-zones.md (waypoint grouping)
- assets/smart_scripts_backup.sql (waypoint data reference)
