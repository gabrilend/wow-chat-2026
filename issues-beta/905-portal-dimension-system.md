# 905 - Portal Dimension System

**Migrated from:** issues/129-portal-dimension-system.md

## Status: Open (Design Phase)

## Phase: 9 - Storytelling & World Structure

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

### Battleground Portals -> Shared Dimension Gates
```
CURRENT:  Portal -> Queue -> Instance -> Isolated BG
INTENDED: Portal -> Teleport -> Shared World Location -> Open PvP/RP
```

- BG portals teleport directly to that map's location
- BUT: location exists on the main world server
- Horde and Alliance occupy the same space
- No instancing - everyone sees everyone
- Creates organic world PvP and social encounters

### Faction Portal Rules
```
                    +------------------+
     HORDE -------->|  HORDE PORTAL    |---> Horde destinations
                    +------------------+
                           X
                    (blocked for Alliance)

                    +------------------+
   ALLIANCE ------->| ALLIANCE PORTAL  |---> Alliance destinations
                    +------------------+
                           X
                    (blocked for Horde)

                    +------------------+
     EITHER ------->| NEUTRAL PORTAL   |---> Secret dimensions
                    +------------------+
```

### Neutral Portals -> Secret Dimensions
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
  Player queues -> Matchmaking -> New instance created -> Timed match
  -> Instance destroyed -> Player returns to original location

MIRRORED BATTLEGROUND:
  Player clicks portal -> Direct teleport -> Shared persistent map
  -> Open-ended stay -> Hearthstone/portal to leave
  -> Map persists between visits
```

## Implementation Phases

### Phase 1: Portal Hook System
- [ ] Hook portal/BG queue interactions in Lua
- [ ] Intercept battleground queue requests
- [ ] Redirect to direct teleport
- Related: This requires ALE working

### Phase 2: Shared Instance Management
- [ ] Modify instance creation to support "shared" mode
- [ ] Prevent instance reset while players present
- [ ] Handle cross-faction visibility rules
- Related: 902-dungeon-room-spawn-zones (room awareness)

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
- Related: 903-contextual-creature-spawns (similar randomization)

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

### Dynamic Portal State Machine
```
    +------------------+
    |  PORTAL ACTIVE   |<-----------------------------+
    | (has destination)|                              |
    +--------+---------+                              |
             |                                        |
        player enters                                 |
             |                                        |
             v                                        |
    +------------------+                              |
    |  AREA OCCUPIED   |                              |
    | (players inside) |                              |
    +--------+---------+                         randomize
             |                                   destination
        last player                                  |
           leaves                                    |
             |                                       |
             v                                       |
    +------------------+                              |
    |   AREA EMPTY     |                              |
    |  (timer starts)  |                              |
    +--------+---------+                              |
             |                                        |
        timer expires                                 |
        (5 minutes)                                   |
             |                                        |
             v                                        |
    +------------------+                              |
    |   RANDOMIZING    |------------------------------+
    |(picking new dest)|
    +------------------+
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

## Related Issues

- **902 - Dungeon Room Spawn Zones**: Room detection needed for "empty" checks
- **903 - Contextual Creature Spawns**: Similar randomization patterns
- **904 - Embedding-Based Creature Selection**: Could extend to portal selection

## Files to Create

- src/lua/portals.lua - Portal hook and teleport logic
- src/lua/shared-maps.lua - Shared instance management
- assets/sql/portal_dimensions.sql - Portal definition data
- docs/portal-system.md - Player-facing documentation
