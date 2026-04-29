# 118 - Point and Line Definition Tools

## Status
- Created: 2026-04-05
- Phase: 2
- Priority: Medium
- Depends: None
- Blocks: 165 (cave/dungeon entrance population)

## Current Behavior
- Cave/dungeon entrances are hardcoded in `CAVE_DUNGEON_ENTRANCES` table
- No way to define arbitrary points in-game
- No visualization of defined points
- No tooling for defining paths, roads, or boundary lines

## Intended Behavior
In-game tools for manually defining and visualizing points and lines (chains of points).
These tools will be used to populate:
- Cave and dungeon entrances (issue 165)
- Road paths for traveller NPCs
- Coastlines and dangerous ledges (bot pathfinding fences)
- Other arbitrary location data

### Point Definition
Players can create/delete points via chat commands:
```
#point create <category> [name]     -- Create point at current location
#point delete                        -- Delete nearest point within 10 yards
#point list [category]               -- List nearby points
#point export [category]             -- Export points as Lua table
```

### Categories
- `cave` - Cave/dungeon entrances
- `road` - Road waypoints
- `fence` - Impassable boundaries (coastlines, cliffs)
- `poi` - Points of interest (future use)

### Visualization via Dummy NPCs
- Each point spawns a dummy NPC for visualization
- NPC displays point info via gossip menu
- Gossip options:
  - "Show point info" - Displays category, name, coordinates
  - "Delete this point" - Removes point and despawns NPC
  - "Link to next point" - Creates chain link to next created point
  - "Break chain" - Removes chain link

### Chain/Line Support
Points can be linked into chains for paths and boundaries:
```
#chain start <category> [name]      -- Start a new chain
#chain add                           -- Add current point to active chain
#chain end                           -- Finish active chain
#chain delete <chainId>              -- Delete entire chain
#chain show <chainId>                -- Highlight chain NPCs
```

### Database Storage
Points stored in custom table:
```sql
CREATE TABLE IF NOT EXISTS `custom_defined_points` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `category` VARCHAR(32) NOT NULL,
    `name` VARCHAR(64) DEFAULT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `chain_id` INT UNSIGNED DEFAULT NULL,
    `chain_order` INT UNSIGNED DEFAULT NULL,
    `created_by` VARCHAR(32) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_category` (`category`),
    KEY `idx_map_category` (`map_id`, `category`),
    KEY `idx_chain` (`chain_id`)
);
```

### Export to Lua
Command generates Lua table code for pasting into source:
```lua
-- Output of: #point export cave
CAVE_DUNGEON_ENTRANCES = {
    [0] = {  -- Eastern Kingdoms
        { x = -8787, y = -2161, z = 136, name = "Deadmines" },
        { x = -11208, y = 1666, z = 24, name = "Fargodeep Mine" },
        -- ...
    },
    [1] = {  -- Kalimdor
        -- ...
    },
}
```

## Implementation

### Step 1: Database Table
Create SQL file for custom_defined_points table.

### Step 2: Dummy NPC Template
Create NPC entry for visualization marker:
- Entry: 900100 (reserved range)
- Model: Small visible marker (candle, flag, or invisible + nameplate)
- Flags: Non-attackable, non-interactable except gossip
- Gossip menu for point management

### Step 3: Chat Commands
Register player chat commands in Lua:
```lua
local function OnCommand(event, player, command)
    local cmd, args = command:match("^#point%s+(%S+)%s*(.*)")
    if cmd then
        PointTools.handleCommand(player, cmd, args)
        return false  -- Handled
    end
    -- Similar for #chain commands
end

RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, OnCommand)
```

### Step 4: Point Management Module
```lua
PointTools = {}

-- {{{ PointTools.createPoint
function PointTools.createPoint(player, category, name)
    local x, y, z = player:GetPosition()
    local mapId = player:GetMapId()

    -- Insert into database
    CharDBExecute(string.format(
        "INSERT INTO custom_defined_points (category, name, map_id, x, y, z, created_by) " ..
        "VALUES ('%s', %s, %d, %.2f, %.2f, %.2f, '%s')",
        category,
        name and ("'" .. name .. "'") or "NULL",
        mapId, x, y, z,
        player:GetName()
    ))

    -- Spawn visualization NPC
    local npc = PerformIngameSpawn(1, 900100, mapId, 0, x, y, z, 0)
    if npc then
        npc:SetData("point_category", category)
        npc:SetData("point_name", name)
    end

    player:SendBroadcastMessage("Point created: " .. category .. (name and (" - " .. name) or ""))
end
-- }}}

-- {{{ PointTools.deleteNearestPoint
function PointTools.deleteNearestPoint(player)
    local x, y, z = player:GetPosition()
    local mapId = player:GetMapId()

    -- Find nearest point within 10 yards
    local query = CharDBQuery(string.format(
        "SELECT id, x, y, z FROM custom_defined_points " ..
        "WHERE map_id = %d AND " ..
        "SQRT(POW(x - %.2f, 2) + POW(y - %.2f, 2)) < 10 " ..
        "ORDER BY SQRT(POW(x - %.2f, 2) + POW(y - %.2f, 2)) LIMIT 1",
        mapId, x, y, x, y
    ))

    if query then
        local pointId = query:GetUInt32(0)
        CharDBExecute("DELETE FROM custom_defined_points WHERE id = " .. pointId)
        -- Despawn visualization NPC (if tracked)
        player:SendBroadcastMessage("Point deleted: #" .. pointId)
    else
        player:SendBroadcastMessage("No points within 10 yards")
    end
end
-- }}}

-- {{{ PointTools.exportPoints
function PointTools.exportPoints(player, category)
    local query = CharDBQuery(string.format(
        "SELECT map_id, x, y, z, name FROM custom_defined_points " ..
        "WHERE category = '%s' ORDER BY map_id, name",
        category
    ))

    if not query then
        player:SendBroadcastMessage("No points in category: " .. category)
        return
    end

    -- Build Lua table output
    local output = {}
    local currentMap = nil

    repeat
        local mapId = query:GetUInt16(0)
        local x = query:GetFloat(1)
        local y = query:GetFloat(2)
        local z = query:GetFloat(3)
        local name = query:GetString(4)

        if mapId ~= currentMap then
            if currentMap then
                table.insert(output, "    },")
            end
            table.insert(output, "    [" .. mapId .. "] = {")
            currentMap = mapId
        end

        local entry = string.format(
            "        { x = %.0f, y = %.0f, z = %.0f%s },",
            x, y, z,
            name and (', name = "' .. name .. '"') or ""
        )
        table.insert(output, entry)
    until not query:NextRow()

    table.insert(output, "    },")

    -- Print to player (will need to copy from chat/logs)
    for _, line in ipairs(output) do
        player:SendBroadcastMessage(line)
    end
end
-- }}}
```

### Step 5: Gossip Menu for Visualization NPCs
```lua
local function OnGossipHello(event, player, npc)
    player:GossipClearMenu()

    local category = npc:GetData("point_category") or "unknown"
    local name = npc:GetData("point_name") or "(unnamed)"
    local x, y, z = npc:GetPosition()

    player:GossipMenuAddItem(0, "Point Info: " .. category .. " - " .. name, 0, 1)
    player:GossipMenuAddItem(0, string.format("Location: %.1f, %.1f, %.1f", x, y, z), 0, 2)
    player:GossipMenuAddItem(0, "[Delete this point]", 0, 3)
    player:GossipSendMenu(1, npc)
end

local function OnGossipSelect(event, player, npc, sender, action)
    if action == 3 then
        -- Delete point
        PointTools.deletePointAtLocation(npc:GetPosition())
        npc:DespawnOrUnsummon()
        player:GossipComplete()
    else
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(900100, 1, OnGossipHello)
RegisterCreatureGossipEvent(900100, 2, OnGossipSelect)
```

### Step 6: Load Points on Server Start
Spawn visualization NPCs for all stored points when server starts.

## Files to Create
- `src/lua/point-tools.lua` - Main point management module
- `source-beta/data/sql/custom/db_characters/custom-defined-points.sql` - Database table
- `source-beta/data/sql/custom/db_world/point-marker-npc.sql` - Visualization NPC template

## Testing
1. `#point create cave Fargodeep Mine` - Create point at current location
2. Walk to point, gossip with marker NPC - Verify info displayed
3. `#point delete` - Delete nearest point
4. `#point list cave` - List nearby cave points
5. `#point export cave` - Generate Lua table for cave entrances
6. `#chain start road Elwynn Road` - Start a road chain
7. Walk along road, `#chain add` at each waypoint
8. `#chain end` - Finish chain
9. `#chain show 1` - Verify chain visualization

## Waypoint Direction Lookup API

Once chains are defined, bots need to traverse them. Core function:

```lua
-- {{{ PointTools.getNextWaypoint
-- Given a waypoint and direction, return the next waypoint in the chain
-- direction: 1 = forward along chain, -1 = backward
-- Returns next waypoint table {x, y, z, name} or nil if at end
function PointTools.getNextWaypoint(chainId, currentOrder, direction)
    direction = direction or 1
    local nextOrder = currentOrder + direction

    local query = CharDBQuery(string.format(
        "SELECT x, y, z, p.name FROM custom_defined_points p " ..
        "WHERE chain_id = %d AND chain_order = %d",
        chainId, nextOrder
    ))

    if query then
        return {
            x = query:GetFloat(0),
            y = query:GetFloat(1),
            z = query:GetFloat(2),
            name = query:GetString(3),
            order = nextOrder
        }
    end

    return nil  -- End of chain
end
-- }}}

-- {{{ PointTools.findNearestChainPoint
-- Find the closest point on any chain of given category
-- Returns chainId, order, distance, and point data
function PointTools.findNearestChainPoint(x, y, mapId, category)
    local query = CharDBQuery(string.format(
        "SELECT chain_id, chain_order, x, y, z, name, " ..
        "SQRT(POW(x - %.2f, 2) + POW(y - %.2f, 2)) as dist " ..
        "FROM custom_defined_points " ..
        "WHERE map_id = %d AND category = '%s' AND chain_id IS NOT NULL " ..
        "ORDER BY dist LIMIT 1",
        x, y, mapId, category
    ))

    if query then
        return {
            chainId = query:GetUInt32(0),
            order = query:GetUInt32(1),
            x = query:GetFloat(2),
            y = query:GetFloat(3),
            z = query:GetFloat(4),
            name = query:GetString(5),
            distance = query:GetFloat(6)
        }
    end

    return nil
end
-- }}}
```

### Usage: Bot Following a Road
```lua
-- Bot finds nearest road point, then walks the chain
local nearest = PointTools.findNearestChainPoint(botX, botY, mapId, "road")
if nearest and nearest.distance < 50 then
    -- On or near a road - follow it
    local direction = math.random() < 0.5 and 1 or -1  -- Random direction
    bot:SetData("road_chain", nearest.chainId)
    bot:SetData("road_order", nearest.order)
    bot:SetData("road_direction", direction)

    -- Get next waypoint
    local next = PointTools.getNextWaypoint(nearest.chainId, nearest.order, direction)
    if next then
        bot:MoveTo(0, next.x, next.y, next.z, false)
    end
end
```

## Future Use Cases
- **Road paths**: Traveller NPCs follow defined roads instead of random wandering
- **Coastlines**: Bots avoid crossing into water at defined coastal boundaries
- **Cliff edges**: Bots avoid dangerous ledges where pathfinding fails
- **Quest objectives**: Mark locations for custom quest system
- **Spawn regions**: Define areas for contextual creature spawning

## Related Issues
- 165: Activity selection (needs cave/dungeon entrances)
- 161: Bot wandering (will use road paths)
- 162: Dungeon pathfinding (uses entrance locations)

## Notes
- Points persist in database across server restarts
- Visualization NPCs respawn on server start
- Export format matches existing CAVE_DUNGEON_ENTRANCES structure
- Chain support enables line/path definition (roads, boundaries)
- Consider admin-only commands (GM level check)
