# 129 - Portal Dimension System

## Status: Open (Design Phase)

## Vision

Transform battleground portals and dungeon entrances into a unified
exploration system where physical locations become shared spaces,
faction barriers become permeable, and empty spaces regenerate with
new configurations.

## Current Behavior (Retail WoW 3.3.5a)

### Battleground Portals
- Clicking BG portal queues you for instanced PvP
- Teleports to separate BG instance when queue pops
- Horde/Alliance completely separated
- BG ends, you return to where you were

### Dungeon Portals
- Walking through portal loads dungeon map
- Instance is private to your party
- Resets on timer or manual reset
- Static layout every time

### Faction Portals
- Each faction has exclusive portals (e.g., Orgrimmar vs Stormwind)
- Cannot interact with opposite faction's portals
- No cross-faction mingling in cities

## Intended Behavior

### Battleground Portals → Shared Dimension Gates
```
CURRENT:  Portal → Queue → Instance → Isolated BG
INTENDED: Portal → Teleport → Shared World Location → Open PvP/RP
```

- BG portals teleport directly to that map's location
- BUT: location exists on the main world server
- Horde and Alliance occupy the same space
- No instancing - everyone sees everyone
- Creates organic world PvP and social encounters

### Faction Portal Rules
```
                    ┌─────────────────┐
     HORDE ────────►│  HORDE PORTAL   │──► Horde destinations
                    └─────────────────┘
                           ╳
                    (blocked for Alliance)

                    ┌─────────────────┐
   ALLIANCE ───────►│ ALLIANCE PORTAL │──► Alliance destinations
                    └─────────────────┘
                           ╳
                    (blocked for Horde)

                    ┌─────────────────┐
     EITHER ───────►│ NEUTRAL PORTAL  │──► Secret dimensions
                    └─────────────────┘
```

### Neutral Portals → Secret Dimensions
- Unmarked or hidden portals in the world
- Lead to "pocket dimensions" - rare maps
- Could be: GM Island, Designer Island, unused zones
- Discoverable through exploration

### Dynamic Aperture System
```
When a door/portal area becomes EMPTY (no players inside):
  1. Timer starts (configurable, e.g., 5 minutes)
  2. On timer expiry: randomize destination
  3. Next player through gets NEW destination
  4. Creates exploration mystery - "where does this lead now?"
```

## Battleground Map Mirroring

### Why Mirror BG Maps?

Battleground maps are beautiful, purpose-built arenas that normally only exist
during PvP matches. By "mirroring" them as persistent world zones, we create:

1. New exploration content from existing assets
2. Shared faction spaces for emergent PvP/RP
3. No queue times - just walk through the portal and you're there
4. Familiar terrain repurposed for open-world gameplay

### Battleground Maps to Mirror

| Map ID | Name | Size | Good For |
|--------|------|------|----------|
| 30 | Alterac Valley | Large | Full zone exploration, multiple objectives |
| 489 | Warsong Gulch | Small | Quick PvP, flag capture mechanics |
| 529 | Arathi Basin | Medium | Territory control, multiple nodes |
| 566 | Eye of the Storm | Medium | Floating platforms, vertical gameplay |
| 607 | Strand of the Ancients | Large | Beach invasion, vehicles |
| 628 | Isle of Conquest | Large | Combined arms, vehicles, siege |

### How Mirroring Changes BG Behavior

```
RETAIL BATTLEGROUND:
  Player queues → Matchmaking → New instance created → Timed match
  → Instance destroyed → Player returns to original location

MIRRORED BATTLEGROUND:
  Player clicks portal → Direct teleport → Shared persistent map
  → Open-ended stay → Hearthstone/portal to leave
  → Map persists between visits
```

## Dungeon Map Mirroring

### Why Mirror Dungeon Maps?

To use BG/dungeon maps as explorable world zones, we need them
accessible without instancing. "Mirroring" means:

1. Loading the map geometry into the main world
2. Treating it as a regular zone (not instance)
3. Allowing multiple players to coexist

### Current WoW Map System
```
Maps are defined in Map.dbc:
  - Continent maps (0=Eastern Kingdoms, 1=Kalimdor, 530=Outland, 571=Northrend)
  - Instance maps (33=Shadowfang Keep, 36=Deadmines, etc.)
  - Battleground maps (30=Alterac Valley, 489=Warsong Gulch, etc.)

Instance maps have:
  - resetTime: when the instance resets
  - maxPlayers: party/raid size limit
  - instanceType: dungeon/raid/battleground

The server creates INSTANCES of these maps on demand.
Each instance is isolated - players in instance A can't see instance B.
```

### How to "Mirror" a Map

Option A: Fake Continent Coordinates
```sql
-- Conceptual: map BG coordinates onto unused continent space
-- Warsong Gulch (map 489) could be placed at:
--   Eastern Kingdoms (map 0), coordinates (far north, off normal play area)
--
-- Problems:
--   - Collision data not present on continent
--   - Would need custom map extraction
--   - Client expects specific map IDs
```

Option B: Non-Instanced Instance Maps
```cpp
// In MapMgr, when creating map for BG/dungeon:
// Instead of: CreateInstance(mapId, instanceId)
// Do:         CreatePersistentMap(mapId)
//
// The "persistent" version:
//   - Only one copy exists
//   - Never resets
//   - All players share it
//
// See: src/server/game/Maps/MapMgr.cpp
// See: src/server/game/Maps/Map.cpp
```

Option C: Teleport to Existing Map with Custom Rules
```lua
-- ALE/Eluna approach:
-- Hook the portal interaction
-- Instead of queueing for BG, teleport player directly

-- Pseudocode:
function OnPortalClick(player, portalEntry)
    local destination = GetPortalDestination(portalEntry)

    if destination.type == "battleground" then
        -- Don't queue, just teleport
        player:Teleport(destination.mapId, destination.x, destination.y, destination.z)

        -- The map already exists as a regular instance
        -- But we ensure only ONE instance exists (instanceId = 0 always)
    end
end

-- See: issues/126-dungeon-room-spawn-zones.md for zone definitions
```

## Implementation Phases

### Phase 1: Portal Hook System
- [ ] Hook portal/BG queue interactions in Lua
- [ ] Intercept battleground queue requests
- [ ] Redirect to direct teleport
- Related: This requires ALE working (see current ALE debugging)

### Phase 2: Shared Instance Management
- [ ] Modify instance creation to support "shared" mode
- [ ] Prevent instance reset while players present
- [ ] Handle cross-faction visibility rules
- Related: issues/126-dungeon-room-spawn-zones.md (room awareness)

### Phase 3: Faction Portal Logic
- [ ] Define which portals are Horde/Alliance/Neutral
- [ ] Add faction check before teleport
- [ ] Create "access denied" feedback for wrong faction
- Related: Database entries in gameobject_template

### Phase 4: Neutral Portal Discovery
- [ ] Identify unused/hidden portals in world
- [ ] Map out secret dimension destinations
- [ ] Add portal discovery tracking per character

### Phase 5: Dynamic Aperture Randomization
- [ ] Track "empty" state for portal areas
- [ ] Implement randomization timer
- [ ] Build destination pool per portal type
- Related: issues/127-contextual-creature-spawns.md (similar randomization)

## Database Considerations

### Portal Definitions
```sql
-- Custom table for portal behavior
CREATE TABLE portal_dimensions (
    portal_entry INT PRIMARY KEY,      -- gameobject entry
    portal_type ENUM('horde', 'alliance', 'neutral', 'dynamic'),
    destination_map INT,
    destination_x FLOAT,
    destination_y FLOAT,
    destination_z FLOAT,
    destination_o FLOAT,
    randomize_when_empty BOOLEAN DEFAULT false,
    empty_timeout_seconds INT DEFAULT 300
);

-- Example entries:
-- Warsong Gulch portal (Horde side)
INSERT INTO portal_dimensions VALUES
(180498, 'horde', 489, 933.3, 1430.1, 345.5, 0, false, 0);

-- Secret neutral portal
INSERT INTO portal_dimensions VALUES
(999001, 'neutral', 1, -6100, -3500, 300, 0, true, 600);
```

### Map Sharing Configuration
```sql
-- Define which maps should be shared (non-instanced)
CREATE TABLE shared_maps (
    map_id INT PRIMARY KEY,
    max_players INT DEFAULT 0,        -- 0 = unlimited
    faction_mixing BOOLEAN DEFAULT true,
    reset_when_empty BOOLEAN DEFAULT false,
    reset_delay_seconds INT DEFAULT 0
);

-- Make Warsong Gulch a shared map
INSERT INTO shared_maps VALUES (489, 0, true, false, 0);
```

## Visual Representation

### Portal Network Topology
```
                         ┌──────────────────────┐
                         │   SECRET DIMENSIONS  │
                         │  (GM Island, etc.)   │
                         └──────────┬───────────┘
                                    │
                              neutral portals
                                    │
    ┌───────────────────────────────┼───────────────────────────────┐
    │                               │                               │
    │  HORDE TERRITORY              │              ALLIANCE TERRITORY
    │                               │                               │
    │   [Org Portal]────────────────┼──────────────[SW Portal]      │
    │        │                      │                    │          │
    │        ▼                      │                    ▼          │
    │   ┌─────────┐                 │               ┌─────────┐    │
    │   │ WSG (H) │◄────shared──────┼───────────────│ WSG (A) │    │
    │   └─────────┘     map 489     │               └─────────┘    │
    │                               │                               │
    │   [AB Portal]─────────────────┼──────────────[AB Portal]     │
    │        │                      │                    │          │
    │        ▼                      │                    ▼          │
    │   ┌─────────┐                 │               ┌─────────┐    │
    │   │ AB (H)  │◄────shared──────┼───────────────│ AB (A)  │    │
    │   └─────────┘     map 529     │               └─────────┘    │
    │                               │                               │
    └───────────────────────────────┴───────────────────────────────┘
```

### Dynamic Portal State Machine
```
    ┌─────────────────┐
    │  PORTAL ACTIVE  │◄──────────────────────────────┐
    │ (has destination)│                               │
    └────────┬────────┘                               │
             │                                         │
        player enters                                  │
             │                                         │
             ▼                                         │
    ┌─────────────────┐                               │
    │  AREA OCCUPIED  │                               │
    │ (players inside)│                               │
    └────────┬────────┘                          randomize
             │                                   destination
        last player                                   │
           leaves                                     │
             │                                        │
             ▼                                        │
    ┌─────────────────┐                               │
    │   AREA EMPTY    │                               │
    │  (timer starts) │                               │
    └────────┬────────┘                               │
             │                                        │
        timer expires                                 │
        (5 minutes)                                   │
             │                                        │
             ▼                                        │
    ┌─────────────────┐                               │
    │   RANDOMIZING   │───────────────────────────────┘
    │(picking new dest)│
    └─────────────────┘
```

## Related Issues

- **126 - Dungeon Room Spawn Zones**: Room detection needed for "empty" checks
- **127 - Contextual Creature Spawns**: Similar randomization patterns
- **128 - Embedding-Based Creature Selection**: Could extend to portal selection
- **113 - Ambush System**: Spawning in shared BG maps

## Technical Notes

### Map Files Required
```
Battleground maps to analyze:
  30  - Alterac Valley
  489 - Warsong Gulch
  529 - Arathi Basin
  566 - Eye of the Storm
  607 - Strand of the Ancients
  628 - Isle of Conquest

Files per map (in data-files/):
  maps/{mapId}.map         - Height data
  vmaps/{mapId}_*.vmtree   - Visibility/collision
  mmaps/{mapId}*.mmap      - Pathfinding
  dbc/Map.dbc              - Map definitions
```

### AzerothCore Map Loading
```cpp
// Key files:
// src/server/game/Maps/MapMgr.h    - Map manager
// src/server/game/Maps/Map.h       - Map class
// src/server/game/Maps/MapInstanced.h - Instance handling

// To create a shared (non-instanced) version of an instance map:
// 1. Modify MapInstanced::CreateInstanceForPlayer
// 2. Add check: if map is in shared_maps table, return existing
// 3. Skip normal instance creation logic
```

## Open Questions

1. **Collision**: Do BG maps have working collision when not instanced?
2. **Creatures**: How to handle BG-specific NPCs (flag carriers, etc.)?
3. **Objectives**: Remove or repurpose BG objectives (flags, nodes)?
4. **Resurrection**: Where do players respawn in shared BG maps?
5. **Exits**: How do players leave? Hearthstone? Return portals?

## Future Enhancements

- **Portal Attunement**: Discover portals to unlock them permanently
- **Portal Keys**: Items that grant access to secret dimensions
- **Temporal Portals**: Same location, different time period
- **Faction Disguises**: Items to use opposite faction portals
- **Portal Events**: Scheduled portal openings to rare locations

## Files to Create

- src/lua/portals.lua - Portal hook and teleport logic
- src/lua/shared-maps.lua - Shared instance management
- assets/sql/portal_dimensions.sql - Portal definition data
- docs/portal-system.md - Player-facing documentation

