# 903b - Regional Creature Spawn Themes

## Status: Open

## Dependencies
- Issue 127: contextual-creature-spawns (optional - can implement as simple override)

## Current Behavior
- Ambush system queries creature_template for level-appropriate creatures
- Filters by type: `type IN (2, 3, 4, 5, 6, 9, 10)`
- Spawns randomly from pool regardless of map/continent
- No thematic distinction between continents

## Intended Behavior
Each continent spawns creatures matching its lore and aesthetic:

| Map | Region | Hostile Spawns | Special |
|-----|--------|----------------|---------|
| 0 (south) | Azeroth | Green trolls, Dark Iron, Defias, Murlocs, Crocs | Crocs: no fire/cold/underground |
| 0 (north) | Lordaeron | Scarlet Crusade, Blood Elves, Forest Trolls | Kirin Tor: friendly, sells tomes |
| 1 (south) | Kalimdor South | Quilboar, Furbolgs, Dryads, Goblins | Qiraji in Silithus/AQ/Tanaris |
| 1 (north) | Kalimdor North | Opposite-faction NPCs | Same-faction: guard-and-follow |
| 530 | Outland | Demons, Fel Orcs (red) | |
| 571 | Northrend | Undead, Ice Trolls (blue) | |

**+ Elementals everywhere** (mixed into main pool, not separate)

**Universal Rules**:
- Elementals (type 4) spawn on ALL continents, mixed into main pool
- **NO UNDEAD** in Kalimdor (land of the living)

## Level Offset Rule
Creatures NEVER spawn at exact player level. Always offset by 1 or 2 levels:

```lua
-- {{{ Ambush.getLevelOffset
-- Returns level offset: -2, -1, +1, or +2 (never 0)
-- Each bit is independent: sign bit, magnitude bit
function Ambush.getLevelOffset()
    local sign      = (math.random(0, 1) == 0) and -1 or 1
    local magnitude = (math.random(0, 1) == 0) and 1  or 2
    return sign * magnitude
end -- }}}

-- Usage in query:
local offset      = Ambush.getLevelOffset()
local targetLevel = playerLevel + offset
-- Query for creatures where minlevel <= targetLevel AND maxlevel >= targetLevel
```

This creates slight unpredictability - sometimes you fight weaker foes, sometimes stronger.

## Why This Change?
- Each continent has distinct visual and thematic identity
- Spawning contextual creatures increases immersion
- Players experience different threats in different lands
- Leverages existing creature variety in the database

---

## Map Reference

```
Map   0 = Eastern Kingdoms (Stormwind, Ironforge, Undercity, etc.)
Map   1 = Kalimdor (Orgrimmar, Darnassus, Thunder Bluff, etc.)
Map 530 = Outland (Hellfire, Nagrand, Shadowmoon, etc.)
Map 571 = Northrend (Borean Tundra, Icecrown, Storm Peaks, etc.)
```

## Creature Types Reference
```
1  = Beast
2  = Dragonkin
3  = Demon
4  = Elemental    <-- UNIVERSAL (all maps)
5  = Giant
6  = Undead
7  = Humanoid     <-- filtered by name patterns per continent
8  = Critter
9  = Mechanical
10 = Not specified
```

---

## Continental Configurations

### Eastern Kingdoms - Azeroth (Map 0, Southern Zones)
**Theme**: Classic fantasy, bandits, swamps, mines

**Zones**: Elwynn, Westfall, Duskwood, Stranglethorn, Redridge, Burning Steppes,
Searing Gorge, Badlands, Loch Modan, Wetlands, Swamp of Sorrows, Blasted Lands

**Allowed Types**:
- Type 4: Elementals (universal)
- Type 7: Humanoids (filtered below)
- Type 1: Beasts (crocodiles only, with zone restrictions)

**Humanoid Groups**:
```
-- Green Trolls (jungle tribes)
Gurubashi       -- Stranglethorn
Bloodscalp      -- Stranglethorn
Skullsplitter   -- Stranglethorn

-- Dark Iron Dwarves (fire mountain regions)
Dark Iron       -- Searing Gorge, Burning Steppes, Blackrock

-- Defias Brotherhood (Westfall, Duskwood)
Defias          -- Bandits, rogues, pirates

-- Murlocs (coastal and wetland areas)
Murloc          -- Shores, rivers, swamps
```

**Crocodile Spawn Restrictions**:
Crocodiles (Beast type) spawn ONLY when:
- Zone is NOT a fire zone (Burning Steppes, Searing Gorge, Blackrock)
- Zone is NOT underground (dungeons, caves)
- Zone is NOT a city
- Zone is NOT cold (Dun Morogh)

```lua
-- {{{ CROC_FORBIDDEN_ZONES
-- Crocodiles don't spawn in these area types
CROC_FORBIDDEN_ZONES = {
    -- Fire zones
    [46]  = true,  -- Burning Steppes
    [51]  = true,  -- Searing Gorge
    [1584] = true, -- Blackrock Depths (instance)
    [1583] = true, -- Blackrock Spire (instance)
    -- Cold zones
    [1]   = true,  -- Dun Morogh
    [133] = true,  -- Gnomeregan
    -- Cities handled separately via IsInCity check
}
-- }}}
```

**SQL: Find Azeroth Humanoids**:
```sql
SELECT entry, name, minlevel, maxlevel
FROM creature_template
WHERE type = 7
  AND (
    -- Green trolls
    name LIKE '%Gurubashi%' OR name LIKE '%Bloodscalp%' OR name LIKE '%Skullsplitter%'
    -- Dark Iron
    OR name LIKE '%Dark Iron%'
    -- Defias
    OR name LIKE '%Defias%'
    -- Murlocs
    OR name LIKE '%Murloc%'
  )
  AND npcflag = 0
  AND lootid != 0
ORDER BY minlevel, name;
```

---

### Eastern Kingdoms - Lordaeron (Map 0, Northern Zones)
**Theme**: Fallen kingdom, zealots, magic academies

**Zones**: Tirisfal, Silverpine, Hillsbrad, Alterac, Arathi, Hinterlands,
Western/Eastern Plaguelands, Ghostlands, Eversong Woods

**Allowed Types**:
- Type 4: Elementals (universal)
- Type 7: Humanoids (filtered below)

**Humanoid Groups**:
```
-- Scarlet Crusade (zealot paladins/priests)
Scarlet         -- Tirisfal, Plaguelands, Scarlet Monastery

-- Hostile Blood Elves (Ghostlands rogues, wretched)
Blood Elf       -- Hostile ones only
Wretched        -- Magic-addicted elves

-- Forest Trolls (Lordaeron variants)
Amani           -- Ghostlands, Zul'Aman
Vilebranch      -- Hinterlands
Witherbark      -- Arathi, Hinterlands
Shadowpine      -- Ghostlands
Mossflayer      -- Eastern Plaguelands
```

**Kirin Tor Mages (FRIENDLY)**:
Special spawn type - not hostile ambushes but friendly travelers.

```lua
-- {{{ KIRIN_TOR_CONFIG
-- Friendly mage NPCs that sell random tomes.
-- Spawn rate: rare, and only at every OTHER level range where they exist.
KIRIN_TOR_CONFIG = {
    enabled = true,
    spawn_chance = 0.05,  -- 5% chance instead of hostile spawn
    -- Level ranges where Kirin Tor appear (every other)
    -- Pattern: exist at 10, skip 12, exist at 14, skip 16, etc.
    level_ranges = { 10, 14, 18, 22, 26, 30, 34, 38 },
    behavior = "friendly_merchant",  -- sells random tome
    name_patterns = { "Kirin Tor", "Dalaran", "Archmage" },
}
-- }}}
```

When Kirin Tor spawns instead of hostile:
1. NPC approaches player
2. Offers to sell a random tome (ability/spell)
3. Despawns after transaction or timeout

---

### Kalimdor - Southern Regions (Map 1, South of Ashenvale)
**Theme**: Tribal warfare, desert insects, goblin merchants

**Zones**: Durotar, Barrens, Mulgore, Thousand Needles, Tanaris, Un'Goro,
Silithus, Ahn'Qiraj, Dustwallow, Desolace, Feralas (southern part)

**Explicitly Forbidden**:
- Type 6: Undead (Kalimdor is land of the living - enforced continent-wide)

**Allowed Types**:
- Type 4: Elementals (universal)
- Type 7: Humanoids (filtered below)

**Humanoid Groups**:
```
-- Quilboar (pig-men, Barrens/Mulgore)
Quilboar
Razormane
Bristleback
Death's Head

-- Furbolgs (bear-men, scattered)
Furbolg
Deadwood

-- Dryads/Nature Spirits
Dryad
Keeper
Treant

-- Goblins (ONLY south of Ashenvale)
Goblin
Venture Co
Steamwheedle
```

**Qiraji Zones (Silithus, Ahn'Qiraj, Tanaris)**:
```lua
-- {{{ QIRAJI_ZONES
-- Zones where Qiraji (insect-men) spawn
QIRAJI_ZONES = {
    [1377] = true,  -- Silithus
    [3428] = true,  -- Ahn'Qiraj: The Fallen Kingdom
    [3429] = true,  -- Ruins of Ahn'Qiraj
    [440]  = true,  -- Tanaris (scarabs in caves)
}
-- }}}

-- Qiraji name patterns
Qiraji
Silithid
Anubisath
Obsidian
```

---

### Kalimdor - Northern Regions (Map 1, Ashenvale and North)
**Theme**: Faction conflict, ancient forests, warrior cultures

**Zones**: Ashenvale, Felwood, Darkshore, Teldrassil, Moonglade,
Winterspring, Azshara, Stonetalon (northern part)

**Explicitly Forbidden**:
- Type 6: Undead (Kalimdor is land of the living)

**Faction-Dependent Spawns**:
Northern Kalimdor spawns are **faction-aware**:

| Player Faction | Hostile Spawns | Friendly Spawns |
|----------------|----------------|-----------------|
| Alliance | Hostile Orcs (Warsong, etc.) | Night Elf Sentinels |
| Horde | Hostile Night Elves (Sentinels) | Orc Warriors (Warsong) |

**Hostile Spawn Patterns**:
```lua
-- {{{ KALIMDOR_NORTH_HOSTILE
-- Faction-opposite hostiles in northern Kalimdor
KALIMDOR_NORTH_HOSTILE = {
    -- For Alliance players: hostile Horde orcs
    alliance_sees = {
        "Warsong",      -- Warsong clan
        "Horde",        -- Generic Horde NPCs
        "Kor'kron",     -- Elite orcs
    },
    -- For Horde players: hostile night elves
    horde_sees = {
        "Sentinel",     -- Night Elf Sentinels
        "Warden",       -- Wardens
        "Cenarion",     -- Some hostile druids (context-dependent)
    },
}
-- }}}
```

**Friendly Spawns - Guard and Follow Behavior**:
When same-faction NPC spawns, it's NOT hostile. Instead:

```lua
-- {{{ KALIMDOR_NORTH_FRIENDLY
-- Same-faction NPCs use guard-and-follow behavior
-- They act as temporary escorts, not enemies
KALIMDOR_NORTH_FRIENDLY = {
    behavior = "guard_and_follow",
    duration = 300,  -- 5 minutes escort
    follow_distance = 8,  -- yards behind player
    combat_assist = true,  -- helps in fights
    despawn_on_zone_change = true,
}
-- }}}

-- {{{ Ambush.spawnFriendlyEscort
-- Spawns a same-faction NPC that guards the player
function Ambush.spawnFriendlyEscort(player, entry, x, y, z)
    local npc = PerformIngameSpawn(1, entry, player:GetMapId(), 0, x, y, z, 0)
    if npc then
        npc:SetFaction(player:GetFaction())  -- ensure friendly
        npc:SetReactState(1)  -- defensive
        -- Start follow behavior
        npc:MoveFollow(player, KALIMDOR_NORTH_FRIENDLY.follow_distance, 0)
        -- Schedule despawn
        npc:RegisterEvent(function()
            npc:DespawnOrUnsummon(0)
        end, KALIMDOR_NORTH_FRIENDLY.duration * 1000, 1)
    end
    return npc
end -- }}}
```

**Selection Logic**:
```lua
-- {{{ Ambush.selectKalimdorNorthCreature
function Ambush.selectKalimdorNorthCreature(player)
    local faction = player:GetFaction()
    local isAlliance = (faction == 1 or faction == 3 or faction == 4 or faction == 7)

    -- 70% hostile opposite faction, 30% friendly same faction
    local roll = math.random(1, 100)

    if roll <= 70 then
        -- Hostile spawn
        if isAlliance then
            return Ambush.selectFromPatterns(KALIMDOR_NORTH_HOSTILE.alliance_sees), "hostile"
        else
            return Ambush.selectFromPatterns(KALIMDOR_NORTH_HOSTILE.horde_sees), "hostile"
        end
    else
        -- Friendly escort spawn
        if isAlliance then
            return Ambush.selectFromPatterns(KALIMDOR_NORTH_HOSTILE.horde_sees), "friendly"
            -- Wait, this is backwards. Alliance friendlies are night elves
        else
            return Ambush.selectFromPatterns(KALIMDOR_NORTH_HOSTILE.alliance_sees), "friendly"
        end
    end
end -- }}}
```

**Correction - Friendly Patterns**:
```lua
KALIMDOR_NORTH_FRIENDLY_PATTERNS = {
    alliance = { "Sentinel", "Warden", "Darnassian" },  -- Night elf allies
    horde    = { "Warsong", "Orgrimmar", "Grunt" },    -- Orc allies
}
```

---

### Outland (Map 530)
**Theme**: Demonic corruption, fel orcs

**Allowed Types**:
- Type 3: Demons (primary)
- Type 4: Elementals (universal)
- Type 7: Humanoids (filtered to fel orcs)

**Fel Orc Name Patterns**:
```
Fel Orc         -- Generic fel orcs
Bonechewer      -- Bonechewer clan
Bleeding Hollow -- Bleeding Hollow clan
Shattered Hand  -- Shattered Hand clan
Shadowmoon      -- Shadowmoon clan (some corrupted)
Dragonmaw       -- Dragonmaw clan (some corrupted)
```

**SQL: Find Fel Orcs**:
```sql
SELECT entry, name, minlevel, maxlevel
FROM creature_template
WHERE type = 7
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

**Spawn Ratio**:
- 50% Demons
- 30% Fel Orcs
- 20% Elementals

---

### Northrend (Map 571)
**Theme**: Scourge, frozen wastes, ice trolls

**Allowed Types**:
- Type 4: Elementals (universal)
- Type 6: Undead (Scourge presence)
- Type 7: Humanoids (filtered to ice trolls)

**Ice Troll Name Patterns** (blue-skinned):
```
Drakkari        -- Drakkari Empire (Zul'Drak, Drak'Tharon)
Ice Troll       -- Generic ice trolls
Frost           -- Frost trolls
Winterax        -- Winterax tribe (if present)
```

**SQL: Find Ice Trolls**:
```sql
SELECT entry, name, minlevel, maxlevel
FROM creature_template
WHERE type = 7
  AND (
    name LIKE '%Drakkari%'
    OR name LIKE '%Ice Troll%'
    OR name LIKE '%Frost Troll%'
    OR name LIKE '%Winterax%'
  )
  AND npcflag = 0
  AND lootid != 0
ORDER BY minlevel, name;
```

**Spawn Ratio**:
- 60% Undead
- 25% Ice Trolls
- 15% Elementals

---

## Implementation

### Data Structure
```lua
-- {{{ REGIONAL_SPAWN_CONFIG
-- Continental creature spawn configuration.
-- Each continent defines allowed types and humanoid name filters.
-- Elementals (type 4) are implicitly allowed everywhere.
--
REGIONAL_SPAWN_CONFIG = {
    [0] = {  -- Eastern Kingdoms
        name = "Eastern Kingdoms",
        types = { 4 },  -- elementals only as base type
        humanoid_patterns = {
            "Amani", "Vilebranch", "Witherbark", "Shadowpine",
            "Mossflayer", "Forest Troll", "Gurubashi",
            "Bloodscalp", "Skullsplitter"
        },
        forbidden_types = {},
        ratios = { humanoid = 70, elemental = 30 },
    },

    [1] = {  -- Kalimdor
        name = "Kalimdor",
        types = { 4 },  -- elementals only as base type
        humanoid_patterns = {
            -- Quilboar
            "Quilboar", "Razormane", "Bristleback", "Death's Head",
            -- Furbolgs
            "Furbolg", "Deadwood", "Timbermaw", "Felpaw", "Gnarlpine",
            -- Nature spirits
            "Dryad", "Keeper of", "Treant"
        },
        forbidden_types = { 6 },  -- NO UNDEAD
        ratios = { humanoid = 70, elemental = 30 },
    },

    [530] = {  -- Outland
        name = "Outland",
        types = { 3, 4 },  -- demons + elementals
        humanoid_patterns = {
            "Fel Orc", "Bonechewer", "Bleeding Hollow",
            "Shattered Hand", "Shadowmoon Orc", "Dragonmaw"
        },
        forbidden_types = {},
        ratios = { demon = 50, humanoid = 30, elemental = 20 },
    },

    [571] = {  -- Northrend
        name = "Northrend",
        types = { 4, 6 },  -- elementals + undead
        humanoid_patterns = {
            "Drakkari", "Ice Troll", "Frost Troll", "Winterax"
        },
        forbidden_types = {},
        ratios = { undead = 60, humanoid = 25, elemental = 15 },
    },
}
-- }}}
```

### Core Functions

```lua
-- {{{ Ambush.getRegionalConfig
-- Returns spawn configuration for player's current continent.
-- Falls back to default config if map not configured.
function Ambush.getRegionalConfig(player)
    local mapId  = player:GetMapId()
    local config = REGIONAL_SPAWN_CONFIG[mapId]

    if config then
        return config
    end

    -- Default: all standard types, no filters
    return {
        name = "Unknown",
        types = { 1, 2, 3, 4, 5, 6, 7, 9 },
        humanoid_patterns = {},
        forbidden_types = {},
        ratios = {},
    }
end -- }}}


-- {{{ Ambush.buildTypeFilter
-- Builds SQL WHERE clause for creature types.
-- Always includes elementals (4), respects forbidden types.
function Ambush.buildTypeFilter(config)
    local types = {}

    -- Add configured types
    for _, t in ipairs(config.types) do
        types[t] = true
    end

    -- Always include elementals
    types[4] = true

    -- Remove forbidden types
    for _, t in ipairs(config.forbidden_types or {}) do
        types[t] = nil
    end

    -- Build SQL fragment
    local typeList = {}
    for t, _ in pairs(types) do
        table.insert(typeList, t)
    end
    table.sort(typeList)

    return "type IN (" .. table.concat(typeList, ",") .. ")"
end -- }}}


-- {{{ Ambush.buildHumanoidQuery
-- Builds SQL query to find humanoids matching regional patterns.
-- Returns nil if no patterns defined.
function Ambush.buildHumanoidQuery(config, playerLevel)
    local patterns = config.humanoid_patterns
    if not patterns or #patterns == 0 then
        return nil
    end

    local likes = {}
    for _, pattern in ipairs(patterns) do
        table.insert(likes, "name LIKE '%" .. pattern .. "%'")
    end

    return "SELECT entry FROM creature_template " ..
           "WHERE type = 7 " ..
           "AND (" .. table.concat(likes, " OR ") .. ") " ..
           "AND minlevel <= " .. playerLevel .. " " ..
           "AND maxlevel >= " .. playerLevel .. " " ..
           "AND npcflag = 0 AND lootid != 0"
end -- }}}


-- {{{ Ambush.selectByRatio
-- Selects creature category based on configured ratios.
-- Returns: "demon", "undead", "humanoid", or "elemental"
function Ambush.selectByRatio(config)
    local ratios = config.ratios or {}
    local roll   = math.random(1, 100)
    local cumulative = 0

    for category, percent in pairs(ratios) do
        cumulative = cumulative + percent
        if roll <= cumulative then
            return category
        end
    end

    -- Fallback to elemental
    return "elemental"
end -- }}}
```

### Integration with Ambush Queue

```lua
-- {{{ Ambush.setupRegionalQueue
-- Populates ambush queue with regionally appropriate creatures.
function Ambush.setupRegionalQueue(player)
    local config      = Ambush.getRegionalConfig(player)
    local playerLevel = player:GetLevel()
    local mapId       = player:GetMapId()

    -- Query base types (demons, undead, elementals, etc.)
    local typeFilter = Ambush.buildTypeFilter(config)
    local baseQuery  = "SELECT entry FROM creature_template " ..
                       "WHERE " .. typeFilter .. " " ..
                       "AND minlevel <= " .. playerLevel .. " " ..
                       "AND maxlevel >= " .. playerLevel .. " " ..
                       "AND npcflag = 0 AND lootid != 0"

    WorldDBQueryAsync(baseQuery, function(results)
        Ambush.pushToQueue(player, results, "base")
    end)

    -- Query regional humanoids separately
    local humanoidQuery = Ambush.buildHumanoidQuery(config, playerLevel)
    if humanoidQuery then
        WorldDBQueryAsync(humanoidQuery, function(results)
            Ambush.pushToQueue(player, results, "humanoid")
        end)
    end

    PrintInfo("[Ambush] Regional queue for " .. config.name ..
              " (map " .. mapId .. ")")
end -- }}}
```

---

## Testing

### Per-Continent Tests
1. **Eastern Kingdoms**: `.tele Stormwind` - verify green trolls + elementals only
2. **Kalimdor**: `.tele Orgrimmar` - verify quilboar/furbolg/dryads, NO undead
3. **Outland**: `.tele Hellfire` - verify demons + fel orcs + elementals
4. **Northrend**: `.tele Borean` - verify undead + ice trolls + elementals

### Validation Steps
1. Teleport to continent
2. Wait for 10+ ambush spawns
3. Record creature names and types
4. Verify all match continental theme
5. Confirm elementals appear on all continents
6. Confirm Kalimdor has zero undead

### Ratio Validation
Run 50+ spawns per continent, tally categories:
- Outland should be ~50% demon, ~30% fel orc, ~20% elemental
- Northrend should be ~60% undead, ~25% ice troll, ~15% elemental

---

## Edge Cases

### Level Mismatch - The Lonely Wind
If no thematic creatures exist at player's level range:

**Phase 1**: Display atmospheric message
```lua
player:SendBroadcastMessage("The wind seems to be your only companion.")
```

**Phase 2**: Begin whispering false phrases and crowsong
```lua
-- {{{ LONELY_WIND_WHISPERS
-- Atmospheric phrases when no creatures spawn.
-- Mix of unsettling non-sequiturs and crow sounds.
LONELY_WIND_WHISPERS = {
    -- False phrases (things that almost make sense)
    "You left it behind, but it remembers.",
    "The path you didn't take still waits.",
    "Someone is counting your steps.",
    "The shadows know your name.",
    "You've been here before. You will be here again.",
    "It watches from the treeline.",
    "The silence has teeth.",
    "You forgot to bring it.",
    "They stopped looking for you.",
    "The door you closed is open now.",

    -- Crowsong (corvid vocalizations as text)
    "Caw. Caw caw.",
    "Kraa... kraa kraa kraa.",
    "Caw.",
    "...caw.",
    "Kraa.",
    "Caw caw... caw.",
}
-- }}}


-- {{{ Ambush.whisperLonelyWind
-- Whispers atmospheric phrases when no spawns available.
-- Called periodically instead of spawning creatures.
function Ambush.whisperLonelyWind(player)
    local whispers = player:GetData("lonely-wind-count") or 0

    if whispers == 0 then
        -- First time: send the wind message
        player:SendBroadcastMessage("The wind seems to be your only companion.")
    else
        -- Subsequent: whisper false phrases or crowsong
        local phrase = LONELY_WIND_WHISPERS[math.random(#LONELY_WIND_WHISPERS)]
        player:SendBroadcastMessage("|cff666666" .. phrase .. "|r")
    end

    player:SetData("lonely-wind-count", whispers + 1)
end -- }}}
```

**Reset Condition**: Clear lonely wind state when:
- Player changes zone (new creatures available)
- Player levels up (new level range)
- Creatures successfully spawn again

```lua
-- {{{ Ambush.resetLonelyWind
function Ambush.resetLonelyWind(player)
    player:SetData("lonely-wind-count", nil)
end -- }}}
```

**Timing**: Lonely wind whispers use the same random walk interval as spawns.
Player experiences increasing unease as empty spawns accumulate.

**Fallback Order**:
Spawns ALWAYS use the offset level pool (never exact player level).
Elementals are part of the main pool, not a separate fallback.

1. Query regional creatures at offset level (player level +/- 1 or 2)
   - Includes: regional humanoids + elementals + any other allowed types
   - Level offset determined by `Ambush.getLevelOffset()` (see above)
2. If pool is empty: lonely wind whispers

There is no intermediate fallback. Either the regional pool has creatures
at the offset level, or the wind whispers begin.

### Empty Patterns
If humanoid query returns zero results:
- Use base types only (demons/undead/elementals)
- Skip humanoid category in ratio selection

### Instance Maps
Dungeon/raid maps (not 0, 1, 530, 571):
- Fall back to default config
- Or define per-instance overrides

---

## SQL: Generate Entry Lists

Run these queries to build static entry lists for each continent:

### All Queries Combined
```sql
-- Eastern Kingdoms: Green Trolls
SELECT 'EK_TROLLS', entry, name FROM creature_template
WHERE type = 7 AND (
    name LIKE '%Amani%' OR name LIKE '%Vilebranch%' OR
    name LIKE '%Witherbark%' OR name LIKE '%Shadowpine%' OR
    name LIKE '%Mossflayer%' OR name LIKE '%Forest Troll%' OR
    name LIKE '%Gurubashi%' OR name LIKE '%Bloodscalp%' OR
    name LIKE '%Skullsplitter%'
) AND npcflag = 0

UNION ALL

-- Kalimdor: Quilboar/Furbolg/Dryads
SELECT 'KALIMDOR', entry, name FROM creature_template
WHERE type = 7 AND (
    name LIKE '%Quilboar%' OR name LIKE '%Razormane%' OR
    name LIKE '%Bristleback%' OR name LIKE '%Furbolg%' OR
    name LIKE '%Deadwood%' OR name LIKE '%Timbermaw%' OR
    name LIKE '%Dryad%' OR name LIKE '%Treant%'
) AND npcflag = 0

UNION ALL

-- Outland: Fel Orcs
SELECT 'OUTLAND', entry, name FROM creature_template
WHERE type = 7 AND (
    name LIKE '%Fel Orc%' OR name LIKE '%Bonechewer%' OR
    name LIKE '%Bleeding Hollow%' OR name LIKE '%Shattered Hand%'
) AND npcflag = 0

UNION ALL

-- Northrend: Ice Trolls
SELECT 'NORTHREND', entry, name FROM creature_template
WHERE type = 7 AND (
    name LIKE '%Drakkari%' OR name LIKE '%Ice Troll%' OR
    name LIKE '%Frost Troll%'
) AND npcflag = 0

ORDER BY 1, 3;
```

---

## Related Files
- src/lua/ambush.lua (creature selection logic)
- src/lua/regional-spawns.lua (new - continental configuration)
- issues/903b1-outland-demon-felorc-spawns.md (supplemental - Outland detail)
- issues/127-contextual-creature-spawns.md (zone-level system)
- issues/128-embedding-based-creature-selection.md (diversity within type)

## Notes

### Design Principles
- Elementals are universal because they represent natural forces present everywhere
- Kalimdor's "no undead" rule reflects night elf/tauren spirituality
- Green trolls vs blue trolls vs fel orcs creates visual continent identity
- This system can layer with issue 127 for zone-specific overrides within continents

### Level System
- Creatures NEVER spawn at exact player level
- Always offset by +/- 1 or 2 levels (two independent coin flips)
- Creates unpredictability: sometimes easier fights, sometimes harder
- Elementals are part of the main pool, not a separate fallback tier

### Regional Boundaries
- Eastern Kingdoms splits at roughly Hillsbrad/Arathi line (Azeroth vs Lordaeron)
- Kalimdor splits at Ashenvale (south = tribal, north = faction warfare)
- Goblins only appear south of Ashenvale boundary
- Crocodiles respect environmental logic (no fire, no cold, no underground)

### Faction Mechanics (Northern Kalimdor)
- Opposite faction NPCs are hostile ambushes
- Same faction NPCs become temporary escorts (guard-and-follow)
- Creates asymmetric experience between Alliance and Horde in same zones
- Orcs must be Horde-affiliated (Warsong, Kor'kron) not neutral

### Special NPCs
- Kirin Tor: friendly mages, appear at every-other level range, sell tomes
- Night Elf Sentinels: guard Alliance players in northern Kalimdor
- Warsong Orcs: guard Horde players in northern Kalimdor

### Atmospheric Fallback
- "The Lonely Wind" creates dread when no creatures available at offset level
- Crowsong uses onomatopoeia: "caw" (American crow), "kraa" (raven/European crow)
- False phrases are designed to feel like half-remembered warnings or prophecies
- No intermediate fallback - either creatures spawn or whispers begin
