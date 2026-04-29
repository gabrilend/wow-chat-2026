# 903b1 - Outland Demon and Fel Orc Spawns

**SUPPLEMENTAL TO:** issue 903b (regional-creature-spawn-themes)

This file contains detailed Outland-specific implementation notes.
See the main issue for the full continental spawn system.

## Status: Open

## Dependencies
- Issue 127: contextual-creature-spawns (optional - can implement as simple override)

## Current Behavior
- Ambush system queries creature_template for level-appropriate creatures
- Filters by type: `type IN (2, 3, 4, 5, 6, 9, 10)`
- Spawns randomly from pool regardless of map/continent
- Outland spawns same creature variety as Eastern Kingdoms/Kalimdor

## Intended Behavior
- When player is in Outland (map 530), override creature selection
- Only spawn demons (type 3) and fel orcs (humanoid type 7, specific entries)
- Maintains thematic consistency with Burning Crusade Outland lore
- Fel orcs = red-skinned orcs corrupted by demon blood

## Why This Change?
- Outland is demon-infested wasteland in WoW lore
- Burning Legion presence throughout all zones
- Fel orcs (Fel Horde) are the dominant humanoid faction
- Spawning wolves and spiders breaks immersion
- Creates distinct gameplay feel when entering Outland

## Map Reference
```
Map 530 = Outland (all zones)
  - Hellfire Peninsula
  - Zangarmarsh
  - Terokkar Forest
  - Nagrand
  - Blade's Edge Mountains
  - Netherstorm
  - Shadowmoon Valley
```

## Creature Types
```
3 = Demon     (primary spawn type for Outland)
7 = Humanoid  (filtered to fel orc entries only)
```

## Fel Orc Identification

### By Name Pattern
Fel orcs typically have names containing:
- "Fel Orc"
- "Bleeding Hollow"
- "Bonechewer"
- "Shattered Hand"
- "Shadowmoon" (clan)
- "Dragonmaw" (some corrupted)

### By Faction
Fel Horde factions in WoW 3.3.5a:
```sql
-- Query to find fel orc faction IDs
SELECT DISTINCT faction, name
FROM creature_template
WHERE name LIKE '%Fel Orc%'
   OR name LIKE '%Bonechewer%'
   OR name LIKE '%Bleeding Hollow%'
   OR name LIKE '%Shattered Hand%';
```

### Sample Fel Orc Entries
```
16871 = Bonechewer Hungerer
16876 = Bonechewer Ravener
16880 = Bonechewer Destroyer
16907 = Shattered Hand Savage
17035 = Bleeding Hollow Scryer
17060 = Fel Orc Neophyte
17083 = Fel Orc Convert
```

## Implementation Steps

### Option A: Simple Map Override (Recommended First)
Modify ambush.lua creature selection to check map ID before querying.

1. Add map check in `Ambush.setupAmbushQueue`:
```lua
-- {{{ Ambush.getCreatureTypeFilter
-- Returns SQL type filter based on player location.
-- Outland (map 530) restricts to demons and fel orcs.
function Ambush.getCreatureTypeFilter(player)
    local mapId = player:GetMapId()

    if mapId == 530 then
        -- Outland: demons only (fel orcs handled separately)
        return "type = 3"
    end

    -- Default: standard spawnable types
    return "type IN (1, 2, 3, 4, 5, 6, 7, 9)"
end -- }}}
```

2. Add fel orc entry list:
```lua
-- {{{ FEL_ORC_ENTRIES
-- Humanoid entries that are valid for Outland spawns.
-- These are fel orcs - red-skinned demon-corrupted orcs.
FEL_ORC_ENTRIES = {
    16871, 16876, 16880,  -- Bonechewer clan
    16907, 16908, 16909,  -- Shattered Hand
    17035, 17036,         -- Bleeding Hollow
    17060, 17083,         -- Fel Orc generic
    -- Add more as discovered
}
-- }}}
```

3. Modify queue population to include fel orcs when in Outland:
```lua
-- In Outland, also add fel orcs to the queue
if mapId == 530 then
    local felOrcQuery = "SELECT entry FROM creature_template " ..
        "WHERE entry IN (" .. table.concat(FEL_ORC_ENTRIES, ",") .. ") " ..
        "AND minlevel <= " .. playerLevel .. " " ..
        "AND maxlevel >= " .. playerLevel
    WorldDBQueryAsync(felOrcQuery, Ambush.pushToAmbushQueue)
end
```

### Option B: Use Contextual Spawns (After 127)
If issue 127 (contextual-creature-spawns) is implemented, this becomes configuration:

```lua
-- In zone-types.lua
ZoneTypeOverrides = {
    [530] = {  -- Outland map
        types     = { 3 },           -- demons only
        whitelist = FEL_ORC_ENTRIES, -- plus these humanoids
    },
}
```

## Spawn Ratio
When both demons and fel orcs are available:
- 70% chance: spawn demon
- 30% chance: spawn fel orc

This ratio reflects demon dominance while maintaining orc presence.

```lua
-- {{{ Ambush.selectOutlandCreature
function Ambush.selectOutlandCreature(player, demonQueue, felOrcQueue)
    local roll = math.random(1, 100)

    if roll <= 70 and #demonQueue > 0 then
        return table.remove(demonQueue, math.random(#demonQueue))
    elseif #felOrcQueue > 0 then
        return table.remove(felOrcQueue, math.random(#felOrcQueue))
    elseif #demonQueue > 0 then
        return table.remove(demonQueue, math.random(#demonQueue))
    end

    return nil
end -- }}}
```

## SQL: Find All Fel Orcs
```sql
-- Run against acore_world to build FEL_ORC_ENTRIES list
SELECT entry, name, minlevel, maxlevel, faction
FROM creature_template
WHERE type = 7  -- Humanoid
  AND (
    name LIKE '%Fel Orc%'
    OR name LIKE '%Bonechewer%'
    OR name LIKE '%Bleeding Hollow%'
    OR name LIKE '%Shattered Hand%'
    OR name LIKE '%Shadowmoon Orc%'
    OR name LIKE '%Dragonmaw%'
  )
  AND npcflag = 0
  AND lootid != 0
ORDER BY minlevel, name;
```

## Testing
1. Create character or teleport to Outland (.tele Hellfire)
2. Wait for ambush spawn
3. Verify spawned creature is demon or fel orc
4. Repeat 10+ times to confirm no beasts/undead/etc spawn
5. Check spawn ratio roughly matches 70/30

## Edge Cases

### Level Mismatch
If no demons/fel orcs exist at player's level in Outland:
- Fall back to any demon regardless of level? (scaled)
- Or fall back to general pool with warning logged?

Recommendation: Fall back to general pool, log warning for balancing.

### Zone-Specific Overrides
Future enhancement: different ratios per Outland zone
- Hellfire Peninsula: 60% fel orc, 40% demon (Fel Horde stronghold)
- Shadowmoon Valley: 90% demon, 10% fel orc (Legion stronghold)
- Nagrand: could allow beasts (less corrupted zone)

## Related Files
- src/lua/ambush.lua (creature selection logic)
- issues/127-contextual-creature-spawns.md (general system)
- issues/128-embedding-based-creature-selection.md (diversity within type)

## Notes
- "Red rage orcs" = fel orcs in WoW terminology
- Fel = demonic corruption, gives red skin and increased aggression
- This is a thematic override, not a balance change
- Consider similar overrides for other continents (Northrend = undead?)
