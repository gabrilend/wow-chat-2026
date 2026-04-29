# 902 - Dungeon Room Spawn Zones

**Migrated from:** issues/126-dungeon-room-spawn-zones.md

## Status: Open

## Phase: 9 - Storytelling & World Structure

## Current Behavior
- Dungeons use static spawns (creatures always present)
- Or ambush system spawns randomly around player
- No awareness of dungeon room structure
- No concept of "clearing" a room

## Intended Behavior
- Dungeons spawn monsters when player enters a room
- Spawn zones defined by connected waypoints in 3D
- Z-level awareness for multi-floor dungeons
- Monsters spawn from zone's creature pool
- Room stays cleared until reset

## Why Room-Based Spawning?
- Creates tension: what's around the corner?
- Reduces memory: don't spawn entire dungeon at once
- Enables "cleared" state: room stays safe after combat
- Supports vertical dungeons: Z-level boundaries
- Dynamic difficulty: spawn count based on party size

## Spawn Zone Definition

### Waypoint Network
```
Zone defined by connected waypoints forming a 3D polygon:

     [wp1]----[wp2]
       |        |
       |  ZONE  |
       |        |
     [wp4]----[wp3]

Each waypoint has: x, y, z, zone_id
Connections form boundaries.
Player inside polygon = in zone.
```

### Z-Level Handling
```
Multi-floor example (side view):

  Floor 2:  [wp5]----[wp6]     z = 150
              |        |
  Floor 1:  [wp1]----[wp2]     z = 100
              |        |
  Basement: [wp7]----[wp8]     z = 50

Z boundaries defined per zone.
Player z between zone_z_min and zone_z_max = in zone.
```

### Data Structure
```lua
DungeonZone = {
    zone_id     = 1,
    map_id      = 36,  -- Deadmines
    name        = "Entrance Hall",
    waypoints   = { {x,y,z}, {x,y,z}, ... },  -- polygon vertices
    z_min       = 95,
    z_max       = 110,
    creatures   = { 634, 636, 637 },  -- entry IDs
    spawn_count = { min = 3, max = 5 },
    respawn     = false,  -- stays cleared
}
```

## Implementation Steps

### Phase 1: Zone Detection
1. Create src/lua/dungeon-zones.lua
2. Define zone polygons for test dungeon (Deadmines)
3. Implement point-in-polygon check (2D)
4. Add Z-level boundary check
5. Track player's current zone

### Phase 2: Spawn Logic
1. On zone enter: check if zone cleared
2. If not cleared: spawn creatures from pool
3. Position spawns at waypoints or random within zone
4. Track zone clear state (all creatures dead)
5. Mark zone as cleared

### Phase 3: Visualization
1. Export zone data to coordinates
2. Generate line diagrams (pngs/ directory)
3. Overlay on dungeon map images
4. Color code: red=active, green=cleared, gray=unvisited

### Phase 4: Data Entry
1. Create tools to define zones in-game
2. `/zone create <name>` - start new zone
3. `/zone waypoint` - add current position as waypoint
4. `/zone creature <entry>` - add creature to pool
5. `/zone save` - export to SQL

## Point-in-Polygon Algorithm

```lua
-- Ray casting algorithm for 2D polygon containment
-- Cast ray from point to infinity, count edge crossings
-- Odd crossings = inside, even = outside

function isPointInZone(px, py, pz, zone)
    -- Z check first (fast rejection)
    if pz < zone.z_min or pz > zone.z_max then
        return false
    end

    -- 2D polygon check
    local inside = false
    local j = #zone.waypoints

    for i = 1, #zone.waypoints do
        local xi, yi = zone.waypoints[i].x, zone.waypoints[i].y
        local xj, yj = zone.waypoints[j].x, zone.waypoints[j].y

        if ((yi > py) ~= (yj > py)) and
           (px < (xj - xi) * (py - yi) / (yj - yi) + xi) then
            inside = not inside
        end

        j = i
    end

    return inside
end
```

## SQL Schema

```sql
-- Zone definitions
CREATE TABLE dungeon_zones (
    zone_id INT PRIMARY KEY,
    map_id INT,
    name VARCHAR(64),
    z_min FLOAT,
    z_max FLOAT,
    spawn_min INT DEFAULT 3,
    spawn_max INT DEFAULT 5,
    respawn BOOLEAN DEFAULT false
);

-- Zone waypoints (polygon vertices)
CREATE TABLE dungeon_zone_waypoints (
    zone_id INT,
    waypoint_order INT,
    x FLOAT,
    y FLOAT,
    z FLOAT,
    PRIMARY KEY (zone_id, waypoint_order)
);

-- Zone creature pools
CREATE TABLE dungeon_zone_creatures (
    zone_id INT,
    creature_entry INT,
    weight INT DEFAULT 1,  -- spawn probability weight
    PRIMARY KEY (zone_id, creature_entry)
);

-- Zone clear state (per instance)
CREATE TABLE dungeon_zone_state (
    instance_id INT,
    zone_id INT,
    cleared BOOLEAN DEFAULT false,
    clear_time TIMESTAMP,
    PRIMARY KEY (instance_id, zone_id)
);
```

## Edge Cases

### Vertical Shafts
- Player falling through multiple zones rapidly
- Solution: check zone entry, not continuous presence
- Debounce zone transitions (500ms minimum)

### Zone Overlaps
- Some dungeons have overlapping areas
- Solution: priority system, check highest priority first
- Or: allow multiple active zones

### Boss Rooms
- Special handling for boss encounters
- Lock zone exits during combat
- Different spawn logic (single boss + adds)

### Patrol Paths
- Some creatures patrol between zones
- Solution: patrol spawns separate from zone spawns
- Or: patrol creatures belong to starting zone only

## Test Dungeon: Deadmines

### Zone Layout
1. Entrance Hall (z: 0-20)
2. Mining Tunnels (z: -30 to 0)
3. Goblin Foundry (z: -30 to -10)
4. Pirate Ship Deck (z: 0-15)
5. Captain's Quarters (z: 10-25)

### Why Deadmines?
- Classic low-level dungeon
- Multiple Z levels
- Clear room structure
- Mix of tight corridors and open areas
- Good test for vertical spawning

## Related Issues
- 903-contextual-creature-spawns (type filtering)
- 904-embedding-based-creature-selection (semantic selection)
- 905-portal-dimension-system (shared instance management)

## Related Files
- src/lua/ambush.lua (spawn logic reference)
- src/lua/movement.lua (position utilities)
- assets/waypoint_data (existing waypoint backup)
- pngs/dungeons/ (zone visualization output)
