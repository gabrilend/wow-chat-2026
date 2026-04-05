---------------------------------------------------------------------------------------------------
-- Custom Class Selection System
-- Issue: 155 - Custom classes as curated spell arrangements from multiple base classes
-- Issue: 157 - Dynamic trainer spawning based on learnable spells
--
-- Custom class definitions loaded from: src/custom-class-json/
-- (rmail inbox for community uploads)

CustomClasses = {}

-- Race-specific NPC entries for the Custom Class Selector
-- Each race has its own selector NPC with race-appropriate model
-- SQL: source-beta/data/sql/custom/db_world/custom-class-selector-npcs.sql
local SELECTOR_NPC_ENTRIES = {
    [1]  = 900001,  -- Human:     Mysterious Guide
    [2]  = 900002,  -- Orc:       Spirit Walker
    [3]  = 900003,  -- Dwarf:     Stone Seer
    [4]  = 900004,  -- Night Elf: Moonshadow Oracle
    [5]  = 900005,  -- Undead:    Deathwhisper Sage
    [6]  = 900006,  -- Tauren:    Earthmother's Voice
    [7]  = 900007,  -- Gnome:     Probability Engine
    [8]  = 900008,  -- Troll:     Loa Speaker
    [10] = 900010,  -- Blood Elf: Sunwell Seer
    [11] = 900011,  -- Draenei:   Light of the Naaru
}

-- Trainer NPC entries (one per class) - create in DB
-- Starting at 900021 to avoid conflict with selector NPCs (900001-900011)
local TRAINER_NPC_ENTRIES = {
    [1]  = 900021,  -- Warrior trainer
    [2]  = 900022,  -- Paladin trainer
    [3]  = 900023,  -- Hunter trainer
    [4]  = 900024,  -- Rogue trainer
    [5]  = 900025,  -- Priest trainer
    [6]  = 900026,  -- Death Knight trainer
    [7]  = 900027,  -- Shaman trainer
    [8]  = 900028,  -- Mage trainer
    [9]  = 900029,  -- Warlock trainer
    [11] = 900031,  -- Druid trainer
}

-- Data key for storing custom class on player
local DATA_KEY_CUSTOM_CLASS = "custom-class"

-- How close to check for nearby players before despawning
local NEARBY_PLAYER_RANGE = 30

-- How often to check for nearby players (ms)
local NEARBY_CHECK_INTERVAL = 5000

-- Trainer spawn settings
local TRAINER_MIN_DIST   = 15
local TRAINER_MAX_DIST   = 25
local TRAINER_SPAWN_CHANCE = 0.10  -- 10% chance per spawn check
local LEVEL_RANGE        = 3      -- ±3 levels for spell learning

-- Base class names for display
local CLASS_NAMES = {
    [1] = "Warrior", [2] = "Paladin", [3] = "Hunter", [4] = "Rogue",
    [5] = "Priest", [6] = "Death Knight", [7] = "Shaman", [8] = "Mage",
    [9] = "Warlock", [11] = "Druid",
}

---------------------------------------------------------------------------------------------------
-- Custom Class Definitions
-- Structure: { [customClassId] = { name, baseClass, spells, tomeClasses, description } }
-- Spell format: { id, level, sourceClass } - level is required player level, sourceClass is base class

CustomClasses.definitions = {}

-- {{{ Example Custom Classes
-- These would normally be loaded from src/custom-class-json/

-- Spellblade: Warrior + Mage fire/frost
CustomClasses.definitions[1001] = {
    name = "Spellblade",
    baseClass = 1,  -- Warrior (for armor/animations)
    spells = {
        -- Warrior base abilities
        { id = 78,   level = 1,  sourceClass = 1 },  -- Heroic Strike
        { id = 284,  level = 4,  sourceClass = 1 },  -- Heroic Strike R2
        { id = 100,  level = 4,  sourceClass = 1 },  -- Charge
        { id = 772,  level = 4,  sourceClass = 1 },  -- Rend
        { id = 6546, level = 10, sourceClass = 1 },  -- Rend R2
        { id = 6343, level = 6,  sourceClass = 1 },  -- Thunder Clap
        { id = 1715, level = 8,  sourceClass = 1 },  -- Hamstring
        -- Mage fire/frost additions
        { id = 133,  level = 1,  sourceClass = 8 },  -- Fireball R1
        { id = 143,  level = 6,  sourceClass = 8 },  -- Fireball R2
        { id = 145,  level = 12, sourceClass = 8 },  -- Fireball R3
        { id = 116,  level = 4,  sourceClass = 8 },  -- Frostbolt R1
        { id = 205,  level = 8,  sourceClass = 8 },  -- Frostbolt R2
        { id = 837,  level = 14, sourceClass = 8 },  -- Frostbolt R3
        { id = 122,  level = 10, sourceClass = 8 },  -- Frost Nova
        { id = 2136, level = 6,  sourceClass = 8 },  -- Fire Blast R1
    },
    tomeClasses = { 1, 8 },  -- Can find Warrior and Mage tomes
    description = "A warrior who channels arcane fire and frost through their weapons.",
}

-- Shadow Apostle: Priest + Warlock curses
CustomClasses.definitions[1002] = {
    name = "Shadow Apostle",
    baseClass = 5,  -- Priest
    spells = {
        -- Priest abilities
        { id = 585,  level = 1,  sourceClass = 5 },  -- Smite R1
        { id = 591,  level = 6,  sourceClass = 5 },  -- Smite R2
        { id = 589,  level = 4,  sourceClass = 5 },  -- Shadow Word: Pain R1
        { id = 594,  level = 10, sourceClass = 5 },  -- Shadow Word: Pain R2
        { id = 8092, level = 10, sourceClass = 5 },  -- Mind Blast R1
        { id = 8102, level = 16, sourceClass = 5 },  -- Mind Blast R2
        { id = 2944, level = 20, sourceClass = 5 },  -- Devouring Plague R1
        -- Warlock curse additions
        { id = 702,  level = 4,  sourceClass = 9 },  -- Curse of Weakness R1
        { id = 1108, level = 14, sourceClass = 9 },  -- Curse of Weakness R2
        { id = 980,  level = 8,  sourceClass = 9 },  -- Curse of Agony R1
        { id = 1014, level = 18, sourceClass = 9 },  -- Curse of Agony R2
        { id = 172,  level = 4,  sourceClass = 9 },  -- Corruption R1
        { id = 6222, level = 14, sourceClass = 9 },  -- Corruption R2
    },
    tomeClasses = { 5, 9 },  -- Priest and Warlock tomes
    description = "A priest who has delved into forbidden warlock arts.",
}

-- Beast Shaman: Shaman + Hunter beast abilities
CustomClasses.definitions[1003] = {
    name = "Beast Shaman",
    baseClass = 7,  -- Shaman
    spells = {
        -- Shaman abilities
        { id = 403,  level = 1,  sourceClass = 7 },  -- Lightning Bolt R1
        { id = 529,  level = 8,  sourceClass = 7 },  -- Lightning Bolt R2
        { id = 548,  level = 14, sourceClass = 7 },  -- Lightning Bolt R3
        { id = 8042, level = 4,  sourceClass = 7 },  -- Earth Shock R1
        { id = 8044, level = 8,  sourceClass = 7 },  -- Earth Shock R2
        { id = 8045, level = 14, sourceClass = 7 },  -- Earth Shock R3
        { id = 324,  level = 8,  sourceClass = 7 },  -- Lightning Shield R1
        { id = 331,  level = 1,  sourceClass = 7 },  -- Healing Wave R1
        -- Hunter beast abilities
        { id = 1515, level = 10, sourceClass = 3 },  -- Tame Beast
        { id = 883,  level = 10, sourceClass = 3 },  -- Call Pet
        { id = 2641, level = 10, sourceClass = 3 },  -- Dismiss Pet
        { id = 6991, level = 12, sourceClass = 3 },  -- Feed Pet
        { id = 136,  level = 10, sourceClass = 3 },  -- Mend Pet R1
    },
    tomeClasses = { 3, 7 },  -- Hunter and Shaman tomes
    description = "A shaman with deep bonds to the animal kingdom.",
}

-- Knight: Paladin + Priest/Rogue/DK/Warrior/Mage support abilities
-- Issue 159 - holy bodyguard, single-target protector, parry + crit focused
-- Stats: Int > Agi > Str, scales with crit
-- Weapons: 2H only (swords, maces, axes, polearms, staves)
-- Talents (high level req) learned via AIO addon on login
-- Party buffs: Blessing of Kings, Arcane Intellect, Horn of Winter
CustomClasses.definitions[1004] = {
    name = "Knight",
    baseClass = 2,  -- Paladin (for plate armor, holy theme)
    spells = {
        -- === LEVEL 1-4: Early buffs ===
        { id = 1459,  level = 1,  sourceClass = 8 },  -- Arcane Intellect R1 (+Int buff)
        { id = 20217, level = 4,  sourceClass = 2 },  -- Blessing of Kings (+10% stats)

        -- === LEVEL 6: Parry foundation ===
        { id = 3127,  level = 6,  sourceClass = 2 },  -- Parry (enables parry playstyle)
        { id = 1152,  level = 6,  sourceClass = 2 },  -- Purify (poison + disease only)
        { id = 13854, level = 6,  sourceClass = 4 },  -- Rogue Deflection R3 (+6% parry)
        { id = 20064, level = 6,  sourceClass = 2 },  -- Paladin Deflection R5 (+5% parry)
        { id = 19297, level = 6,  sourceClass = 3 },  -- Hunter Deflection R3 (+3% parry)
        { id = 57330, level = 6,  sourceClass = 6 },  -- Horn of Winter (str/agi buff)

        -- === LEVEL 8: First healing + parry boost ===
        { id = 139,   level = 8,  sourceClass = 5 },  -- Renew R1 (HoT)
        { id = 20208, level = 8,  sourceClass = 2 },  -- Spiritual Focus R5 (70% pushback reduction)
        { id = 16466, level = 8,  sourceClass = 1 },  -- Warrior Deflection R5 (+5% parry)

        -- === LEVEL 10: Mobility + emergency heal ===
        { id = 19236, level = 10, sourceClass = 5 },  -- Desperate Prayer (emergency self-heal)
        { id = 2983,  level = 10, sourceClass = 4 },  -- Sprint (gap closer)
        { id = 26023, level = 10, sourceClass = 2 },  -- Pursuit of Justice R2 (+15% speed, -50% disarm)

        -- === LEVEL 12: Armor + crit synergy ===
        { id = 588,   level = 12, sourceClass = 5 },  -- Inner Fire R1 (armor + sp)
        { id = 12974, level = 12, sourceClass = 1 },  -- Flurry R5 (+25% attack speed on crit)
        { id = 34476, level = 12, sourceClass = 3 },  -- Combat Experience R2 (+4% Agi/Int)

        -- === LEVEL 14: Parry payoff + Int upgrade ===
        { id = 6074,  level = 14, sourceClass = 5 },  -- Renew R2
        { id = 1460,  level = 14, sourceClass = 8 },  -- Arcane Intellect R2 (+Int buff stronger)
        { id = 20177, level = 14, sourceClass = 2 },  -- Reckoning (parry -> extra attacks)
        { id = 19306, level = 14, sourceClass = 3 },  -- Counterattack (parry -> damage + 5s immobilize)

        -- === LEVEL 16: Crit amplification + spell defense ===
        { id = 14751, level = 16, sourceClass = 5 },  -- Inner Focus (100% crit, no mana)
        { id = 53503, level = 16, sourceClass = 2 },  -- Sheath of Light R3 (30% AP -> SP, crit heal HoT)
        { id = 49497, level = 16, sourceClass = 6 },  -- Spell Deflection R3 (parry -> 45% spell dmg redux)

        -- === LEVEL 18: Core talent synergies ===
        { id = 59578, level = 18, sourceClass = 2 },  -- Art of War R2 (melee crit -> instant Flash)
        { id = 47515, level = 18, sourceClass = 5 },  -- Divine Aegis R3 (crit heal -> 30% absorb)

        -- === LEVEL 20: Capstone abilities ===
        { id = 19750, level = 20, sourceClass = 2 },  -- Flash of Light (fast heal)
        { id = 53601, level = 20, sourceClass = 2 },  -- Sacred Shield (core identity)
        { id = 6075,  level = 20, sourceClass = 5 },  -- Renew R3
        { id = 7128,  level = 20, sourceClass = 5 },  -- Inner Fire R2
    },
    tomeClasses = { 2, 5, 4, 6, 1, 8, 3 },  -- Paladin, Priest, Rogue, DK, Warrior, Mage, Hunter tomes
    description = "A holy bodyguard who protects one ally through sacred shields and focused healing. Parry-focused combat with crit scaling.",
}

-- }}}

---------------------------------------------------------------------------------------------------
-- Custom Class Loading

-- {{{ loadFromDirectory
-- Load custom class definitions from src/custom-class-json/
-- Format: Each file defines one class with spell lists, trainer mappings, etc.
-- Directory is an rmail inbox - community uploads via password from website
function CustomClasses.loadFromDirectory()
    -- TODO: Implement file loading when directory structure is finalized
    -- For now, using hardcoded examples above
    --
    -- VALIDATION REQUIREMENTS (reject malformed files):
    -- 1. Required fields: name (string), baseClass (1-11), spells (table), tomeClasses (table)
    -- 2. Each spell entry must have: id (number), level (number 1-20), sourceClass (1-11)
    -- 3. Spell IDs must be valid (exist in spell DBC)
    -- 4. sourceClass must match one of the tomeClasses
    -- 5. baseClass must be valid WoW class ID (1-11, skip 10)
    -- 6. No duplicate spell IDs within a class definition
    -- 7. Class ID must not conflict with existing definitions
    -- 8. One contribution per immutable contact password (dedupe by uploader)
    --
    -- On validation failure: log error with filename and reason, skip file, continue loading others
    -- Never load partially valid files - reject entire file if any validation fails
    --
    print("[CustomClasses] Using hardcoded class definitions (file loading not implemented)")
end -- }}}

---------------------------------------------------------------------------------------------------
-- Custom Class Management

-- {{{ getCustomClass
-- Get player's custom class ID (or nil if using base class)
function CustomClasses.getCustomClass(player)
    local classId = player:GetData(DATA_KEY_CUSTOM_CLASS)
    if classId and classId ~= 0 then
        return classId
    end
    return nil
end -- }}}

-- {{{ setCustomClass
-- Set player's custom class
function CustomClasses.setCustomClass(player, customClassId)
    player:SetData(DATA_KEY_CUSTOM_CLASS, customClassId)
    print("[CustomClasses] " .. player:GetName() .. " selected custom class: " .. customClassId)
end -- }}}

-- {{{ getDefinition
-- Get custom class definition by ID
function CustomClasses.getDefinition(customClassId)
    return CustomClasses.definitions[customClassId]
end -- }}}

-- {{{ canLearnSpell
-- Check if player with custom class can learn a specific spell
function CustomClasses.canLearnSpell(player, spellId)
    local customClassId = CustomClasses.getCustomClass(player)
    if not customClassId then
        return true  -- base class, use default behavior
    end

    local def = CustomClasses.getDefinition(customClassId)
    if not def then
        return true  -- unknown class, allow default
    end

    -- Check if spell is in custom class spell list
    -- Spell format: { id, level, sourceClass }
    for _, spellData in ipairs(def.spells) do
        if spellData.id == spellId then
            return true
        end
    end
    return false
end -- }}}

-- {{{ getTomeClassesFor
-- Get list of base class IDs to draw tomes from
function CustomClasses.getTomeClassesFor(player)
    local customClassId = CustomClasses.getCustomClass(player)
    if not customClassId then
        return { player:GetClass() }  -- base class only
    end

    local def = CustomClasses.getDefinition(customClassId)
    if not def or not def.tomeClasses then
        return { player:GetClass() }
    end

    return def.tomeClasses
end -- }}}

---------------------------------------------------------------------------------------------------
-- Trainer Level Scaling

-- {{{ getScaledSpellLevel
-- Scale trainer level to player max level (20) to determine teachable spell range
-- trainerLevel / maxNpcLevel * maxPlayerLevel = scaledLevel
-- Trainer teaches spells in range [scaledLevel - 2, scaledLevel + 2]
local MAX_NPC_LEVEL = 80
local MAX_PLAYER_LEVEL = 20

function CustomClasses.getScaledSpellLevel(trainerLevel)
    local ratio = trainerLevel / MAX_NPC_LEVEL
    return math.floor(ratio * MAX_PLAYER_LEVEL)
end -- }}}

-- {{{ trainerCanTeachSpell
-- Check if trainer at given level can teach a spell at given required level
function CustomClasses.trainerCanTeachSpell(trainerLevel, spellRequiredLevel)
    local scaledLevel = CustomClasses.getScaledSpellLevel(trainerLevel)
    local minLevel = scaledLevel - 2
    local maxLevel = scaledLevel + 2
    return spellRequiredLevel >= minLevel and spellRequiredLevel <= maxLevel
end -- }}}

---------------------------------------------------------------------------------------------------
-- Dynamic Trainer Spawning (Issue 157)
-- Trainers spawn weighted by learnable spells in player's level range

-- Track spawned trainers per player
local SpawnedTrainers = {}  -- { [playerGUID] = trainerObject }

-- {{{ countLearnableSpells
-- Count spells from a source class that player can learn in level range
-- Returns count of spells that are: in range, from sourceClass, not already known
function CustomClasses.countLearnableSpells(player, customClassDef, sourceClass, minLevel, maxLevel)
    local count = 0

    for _, spellData in ipairs(customClassDef.spells) do
        -- Check source class matches
        if spellData.sourceClass == sourceClass then
            -- Check level is in range
            if spellData.level >= minLevel and spellData.level <= maxLevel then
                -- Check not already known
                if not player:HasSpell(spellData.id) then
                    count = count + 1
                end
            end
        end
    end

    return count
end -- }}}

-- {{{ getLearnableSpells
-- Get list of learnable spells from a source class in level range
-- Returns table of { id, level, name } for each learnable spell
function CustomClasses.getLearnableSpells(player, customClassDef, sourceClass, minLevel, maxLevel)
    local spells = {}

    for _, spellData in ipairs(customClassDef.spells) do
        if spellData.sourceClass == sourceClass then
            if spellData.level >= minLevel and spellData.level <= maxLevel then
                if not player:HasSpell(spellData.id) then
                    table.insert(spells, {
                        id    = spellData.id,
                        level = spellData.level,
                    })
                end
            end
        end
    end

    return spells
end -- }}}

-- {{{ selectTrainerClass
-- Select trainer class weighted by learnable spell count
-- Returns sourceClass or nil if no learnable spells
function CustomClasses.selectTrainerClass(player, customClassDef)
    local playerLevel = player:GetLevel()
    local minLevel    = playerLevel - LEVEL_RANGE
    local maxLevel    = playerLevel + LEVEL_RANGE

    -- Collect weights per source class
    local weights     = {}
    local totalWeight = 0
    local seenClasses = {}  -- deduplicate tomeClasses

    for _, sourceClass in ipairs(customClassDef.tomeClasses) do
        if not seenClasses[sourceClass] then
            seenClasses[sourceClass] = true
            local count = CustomClasses.countLearnableSpells(player, customClassDef, sourceClass, minLevel, maxLevel)
            if count > 0 then
                weights[sourceClass] = count
                totalWeight = totalWeight + count
            end
        end
    end

    -- No learnable spells in range
    if totalWeight == 0 then
        return nil
    end

    -- Weighted random selection
    local roll       = math.random(1, totalWeight)
    local cumulative = 0

    for sourceClass, weight in pairs(weights) do
        cumulative = cumulative + weight
        if roll <= cumulative then
            return sourceClass
        end
    end

    -- Fallback (shouldn't reach)
    return nil
end -- }}}

-- {{{ spawnDynamicTrainer
-- Spawn a trainer for the player's custom class
-- Returns trainer object or nil if no learnable spells
function CustomClasses.spawnDynamicTrainer(player)
    local customClassId = CustomClasses.getCustomClass(player)
    if not customClassId then
        return nil  -- base class players use world trainers
    end

    local def = CustomClasses.getDefinition(customClassId)
    if not def then
        return nil
    end

    -- Select which class trainer to spawn
    local trainerClass = CustomClasses.selectTrainerClass(player, def)
    if not trainerClass then
        print("[CustomClasses] No learnable spells for " .. player:GetName() .. " - no trainer spawned")
        return nil
    end

    -- Get trainer NPC entry for this class
    local trainerEntry = TRAINER_NPC_ENTRIES[trainerClass]
    if not trainerEntry then
        print("[CustomClasses] No trainer entry defined for class " .. trainerClass)
        return nil
    end

    -- Spawn position: random distance/angle from player
    local px, py, pz, po = player:GetLocation()
    local map            = player:GetMap()
    local theta          = math.random() * 6.28
    local radius         = math.random(TRAINER_MIN_DIST, TRAINER_MAX_DIST)
    local x              = px + math.cos(theta) * radius
    local y              = py + math.sin(theta) * radius
    local z              = map:GetHeight(x, y) or pz

    -- Calculate facing towards player
    local dx      = px - x
    local dy      = py - y
    local facing  = math.atan2(dy, dx)

    -- Spawn trainer
    local trainer = player:SpawnCreature(trainerEntry, x, y, z, facing, 1, 0)

    if trainer then
        -- Store trainer class on the creature for gossip handling
        trainer:SetData("trainer-class", trainerClass)
        trainer:SetData("spawned-for", player:GetGUIDLow())

        -- Store reference for cleanup
        local playerGUID           = player:GetGUIDLow()
        SpawnedTrainers[playerGUID] = trainer

        -- Register despawn check
        trainer:RegisterEvent(CustomClasses.checkTrainerDespawn, NEARBY_CHECK_INTERVAL, 0)

        local className = CLASS_NAMES[trainerClass] or "Unknown"
        print("[CustomClasses] Spawned " .. className .. " trainer for " .. player:GetName())
        player:SendBroadcastMessage("|cff00ffff[Trainer] A " .. className .. " trainer has appeared nearby.|r")
    else
        print("[CustomClasses] Failed to spawn trainer (entry " .. trainerEntry .. " not in DB?)")
    end

    return trainer
end -- }}}

-- {{{ checkTrainerDespawn
-- Despawn trainer if spawning player is gone or too far
function CustomClasses.checkTrainerDespawn(eventId, delay, repeats, trainer)
    local spawnedFor = trainer:GetData("spawned-for")
    if not spawnedFor then
        trainer:RemoveEvents()
        trainer:DespawnOrUnsummon(0)
        return
    end

    -- Check if spawning player is nearby
    local nearbyPlayers = trainer:GetPlayersInRange(NEARBY_PLAYER_RANGE * 2)
    local playerNearby  = false

    if nearbyPlayers then
        for _, player in ipairs(nearbyPlayers) do
            if player:GetGUIDLow() == spawnedFor then
                playerNearby = true
                break
            end
        end
    end

    if not playerNearby then
        print("[CustomClasses] Player left - despawning trainer")
        trainer:RemoveEvents()
        trainer:DespawnOrUnsummon(0)
        SpawnedTrainers[spawnedFor] = nil
    end
end -- }}}

-- {{{ trySpawnTrainer
-- Called from periodic events to potentially spawn a trainer
-- Returns true if trainer spawned, false otherwise
function CustomClasses.trySpawnTrainer(player)
    -- Only for custom class players
    local customClassId = CustomClasses.getCustomClass(player)
    if not customClassId then
        return false
    end

    -- Check spawn chance
    if math.random() > TRAINER_SPAWN_CHANCE then
        return false
    end

    -- Check if player already has a spawned trainer
    local playerGUID = player:GetGUIDLow()
    if SpawnedTrainers[playerGUID] then
        local existing = SpawnedTrainers[playerGUID]
        if existing:IsInWorld() then
            return false  -- already has trainer
        else
            SpawnedTrainers[playerGUID] = nil  -- clean up stale reference
        end
    end

    -- Try to spawn
    local trainer = CustomClasses.spawnDynamicTrainer(player)
    return trainer ~= nil
end -- }}}

-- {{{ calculateTrainingCost
-- Calculate gold cost for training a spell based on level
-- Simple formula: level * 5 copper (50c at level 10, 1g at level 20)
function CustomClasses.calculateTrainingCost(spellLevel)
    return spellLevel * 5  -- in copper
end -- }}}

-- {{{ onDynamicTrainerGossip
-- Handle gossip with dynamically spawned trainer
function CustomClasses.onDynamicTrainerGossip(event, player, trainer)
    local customClassId = CustomClasses.getCustomClass(player)
    if not customClassId then
        player:SendBroadcastMessage("|cff888888This trainer has nothing to teach you.|r")
        return false
    end

    local def          = CustomClasses.getDefinition(customClassId)
    local trainerClass = trainer:GetData("trainer-class")

    if not def or not trainerClass then
        return false
    end

    -- Get learnable spells for this trainer's class
    local playerLevel = player:GetLevel()
    local minLevel    = playerLevel - LEVEL_RANGE
    local maxLevel    = playerLevel + LEVEL_RANGE
    local spells      = CustomClasses.getLearnableSpells(player, def, trainerClass, minLevel, maxLevel)

    if #spells == 0 then
        player:SendBroadcastMessage("|cff888888This trainer has nothing new to teach you right now.|r")
        return true
    end

    -- Build gossip menu
    player:GossipClearMenu()

    for _, spellData in ipairs(spells) do
        local spellName = GetSpellInfo(spellData.id)
        local cost      = CustomClasses.calculateTrainingCost(spellData.level)
        local costStr   = ""

        -- Format cost display
        if cost >= 100 then
            costStr = string.format("%dg %ds", math.floor(cost / 100), (cost % 100) / 10)
        elseif cost >= 10 then
            costStr = string.format("%ds", cost / 10)
        else
            costStr = string.format("%dc", cost)
        end

        local label = (spellName or "Spell " .. spellData.id) .. " (Lv" .. spellData.level .. ") - " .. costStr
        player:GossipMenuAddItem(3, label, 0, spellData.id)  -- icon 3 = trainer
    end

    player:GossipMenuAddItem(0, "Nevermind", 0, 0)
    player:GossipSendMenu(1, trainer)
    return true
end -- }}}

-- {{{ onDynamicTrainerGossipSelect
-- Handle spell selection from trainer gossip
function CustomClasses.onDynamicTrainerGossipSelect(event, player, trainer, sender, intid, code)
    player:GossipComplete()

    if intid == 0 then
        return  -- cancelled
    end

    local spellId = intid

    -- Verify player can learn this spell
    if player:HasSpell(spellId) then
        player:SendBroadcastMessage("|cffff0000You already know this spell.|r")
        return
    end

    if not CustomClasses.canLearnSpell(player, spellId) then
        player:SendBroadcastMessage("|cffff0000This spell is not available to your class.|r")
        return
    end

    -- Find spell level for cost calculation
    local customClassId = CustomClasses.getCustomClass(player)
    local def           = CustomClasses.getDefinition(customClassId)
    local spellLevel    = 1

    for _, spellData in ipairs(def.spells) do
        if spellData.id == spellId then
            spellLevel = spellData.level
            break
        end
    end

    -- Check cost
    local cost = CustomClasses.calculateTrainingCost(spellLevel)
    if player:GetCoinage() < cost then
        player:SendBroadcastMessage("|cffff0000You don't have enough money.|r")
        return
    end

    -- Teach spell
    player:ModifyMoney(-cost)
    player:LearnSpell(spellId)

    local spellName = GetSpellInfo(spellId) or "Spell"
    player:SendBroadcastMessage("|cff00ff00You have learned " .. spellName .. "!|r")

    -- Despawn trainer after teaching (optional - could keep around)
    trainer:RemoveEvents()
    trainer:DespawnOrUnsummon(3000)  -- 3 second delay
    local playerGUID           = player:GetGUIDLow()
    SpawnedTrainers[playerGUID] = nil
end -- }}}

---------------------------------------------------------------------------------------------------
-- NPC Spawning and Gossip (Selector NPC)

-- {{{ spawnSelectorNPC
-- Spawn the custom class selector NPC near a player
-- Uses race-specific NPC entry so player sees one of their own kind
-- Skips spawn if any selector NPC already exists within 20 yards (players can share)
local SELECTOR_SHARE_RANGE = 20

function CustomClasses.spawnSelectorNPC(player)
    local px, py, pz, po = player:GetLocation()
    local map            = player:GetMap()
    local race           = player:GetRace()

    -- Check if any selector NPC is already nearby (any race)
    local nearbyCreatures = player:GetCreaturesInRange(SELECTOR_SHARE_RANGE)
    if nearbyCreatures then
        for _, creature in ipairs(nearbyCreatures) do
            local entry = creature:GetEntry()
            -- Check if this creature is any of our selector NPCs
            for _, selectorEntry in pairs(SELECTOR_NPC_ENTRIES) do
                if entry == selectorEntry then
                    print("[CustomClasses] Selector NPC already nearby - skipping spawn for " .. player:GetName())
                    return nil
                end
            end
        end
    end

    -- Get race-specific NPC entry
    local npcEntry = SELECTOR_NPC_ENTRIES[race]
    if not npcEntry then
        print("[CustomClasses] No selector NPC entry for race " .. race)
        return nil
    end

    -- Find position in front of player
    local spawnDist = 3
    local x         = px + math.cos(po) * spawnDist
    local y         = py + math.sin(po) * spawnDist
    local z         = map:GetHeight(x, y) or pz

    -- Spawn NPC facing player
    local npcFacing = po + math.pi  -- face towards player
    local npc       = player:SpawnCreature(npcEntry, x, y, z, npcFacing, 1, 0)

    if npc then
        -- Register periodic check for nearby players
        npc:RegisterEvent(CustomClasses.checkNearbyPlayers, NEARBY_CHECK_INTERVAL, 0)
        print("[CustomClasses] Spawned selector NPC (race " .. race .. ", entry " .. npcEntry .. ") for " .. player:GetName())
    else
        print("[CustomClasses] Failed to spawn selector NPC (entry " .. npcEntry .. " not in DB?)")
    end

    return npc
end -- }}}

-- {{{ checkNearbyPlayers
-- Periodic check - despawn NPC if no players nearby
function CustomClasses.checkNearbyPlayers(eventId, delay, repeats, npc)
    local nearbyPlayers = npc:GetPlayersInRange(NEARBY_PLAYER_RANGE)
    if not nearbyPlayers or #nearbyPlayers == 0 then
        print("[CustomClasses] No players nearby - despawning selector NPC")
        npc:RemoveEvents()
        npc:DespawnOrUnsummon(0)
    end
end -- }}}

-- {{{ onNPCGossip
-- Handle gossip with selector NPC
function CustomClasses.onNPCGossip(event, player, npc)
    -- Only talk to level 1 characters
    if player:GetLevel() > 1 then
        player:SendBroadcastMessage("|cff888888The figure seems uninterested in you.|r")
        return false
    end

    -- Check if already selected a class
    local currentClass = CustomClasses.getCustomClass(player)
    if currentClass then
        player:SendBroadcastMessage("|cff888888You have already chosen your path.|r")
        return false
    end

    -- Build gossip menu with custom class options
    player:GossipClearMenu()

    for classId, def in pairs(CustomClasses.definitions) do
        -- Only show classes compatible with player's base class
        if def.baseClass == player:GetClass() then
            player:GossipMenuAddItem(0, def.name, 0, classId)
        end
    end

    -- Option to stay with base class
    player:GossipMenuAddItem(0, "Stay with my training (Base Class)", 0, 0)

    player:GossipSendMenu(1, npc)  -- npcTextId 1 = default
    return true
end -- }}}

-- {{{ onNPCGossipSelect
-- Handle selection from gossip menu
function CustomClasses.onNPCGossipSelect(event, player, npc, sender, intid, code)
    player:GossipComplete()

    if intid == 0 then
        -- Chose base class
        player:SendBroadcastMessage("|cff00ff00You have chosen to follow your original training.|r")
        return
    end

    local def = CustomClasses.getDefinition(intid)
    if def then
        CustomClasses.setCustomClass(player, intid)
        player:SendBroadcastMessage("|cff00ffff You have become a " .. def.name .. "!|r")
        player:SendBroadcastMessage("|cff888888" .. def.description .. "|r")
    else
        player:SendBroadcastMessage("|cffff0000Unknown class selection.|r")
    end
end -- }}}

---------------------------------------------------------------------------------------------------
-- Event Handlers

-- {{{ onFirstLogin
-- Spawn selector NPC when player first logs in at level 1
function CustomClasses.onFirstLogin(event, player)
    if player:GetLevel() > 1 then
        return  -- only for level 1
    end

    -- Small delay to ensure player is fully loaded
    player:RegisterEvent(function(eventId, delay, repeats, player)
        CustomClasses.spawnSelectorNPC(player)
    end, 2000, 1)

    print("[CustomClasses] Scheduled NPC spawn for new character: " .. player:GetName())
end -- }}}

-- {{{ onLogin
-- Restore custom class data on login (if stored in DB, it persists)
function CustomClasses.onLogin(event, player)
    local customClassId = CustomClasses.getCustomClass(player)
    if customClassId then
        local def = CustomClasses.getDefinition(customClassId)
        if def then
            print("[CustomClasses] " .. player:GetName() .. " logged in as " .. def.name)
        end
    end
end -- }}}

---------------------------------------------------------------------------------------------------
-- Test Commands

-- {{{ handleChat
function CustomClasses.handleChat(event, player, message)
    -- #customclass - show current custom class
    if message == "#customclass" then
        local classId = CustomClasses.getCustomClass(player)
        if classId then
            local def = CustomClasses.getDefinition(classId)
            player:SendBroadcastMessage("Custom class: " .. (def and def.name or "Unknown") .. " (ID: " .. classId .. ")")
        else
            player:SendBroadcastMessage("No custom class - using base class")
        end
        return false
    end

    -- #customset <classId> - set custom class (testing only)
    if message:sub(1, 10) == "#customset" then
        local classIdStr = message:sub(12)
        local classId = tonumber(classIdStr)
        if classId then
            CustomClasses.setCustomClass(player, classId)
            local def = CustomClasses.getDefinition(classId)
            player:SendBroadcastMessage("Set custom class to: " .. (def and def.name or "Unknown"))
        else
            player:SendBroadcastMessage("Usage: #customset <classId>")
        end
        return false
    end

    -- #customclear - clear custom class (testing only)
    if message == "#customclear" then
        player:SetData(DATA_KEY_CUSTOM_CLASS, nil)
        player:SendBroadcastMessage("Custom class cleared - now using base class")
        return false
    end

    -- #customlist - list available custom classes
    if message == "#customlist" then
        player:SendBroadcastMessage("Available custom classes:")
        for classId, def in pairs(CustomClasses.definitions) do
            player:SendBroadcastMessage("  " .. classId .. ": " .. def.name .. " (base: " .. def.baseClass .. ")")
        end
        return false
    end

    -- #customspawn - manually spawn selector NPC
    if message == "#customspawn" then
        CustomClasses.spawnSelectorNPC(player)
        return false
    end

    -- #trainerspawn - manually spawn dynamic trainer (testing)
    if message == "#trainerspawn" then
        local trainer = CustomClasses.spawnDynamicTrainer(player)
        if not trainer then
            player:SendBroadcastMessage("No trainer spawned (no custom class or no learnable spells in range)")
        end
        return false
    end

    -- #trainerinfo - show learnable spells per class in level range
    if message == "#trainerinfo" then
        local customClassId = CustomClasses.getCustomClass(player)
        if not customClassId then
            player:SendBroadcastMessage("No custom class - base class players use world trainers")
            return false
        end

        local def         = CustomClasses.getDefinition(customClassId)
        local playerLevel = player:GetLevel()
        local minLevel    = playerLevel - LEVEL_RANGE
        local maxLevel    = playerLevel + LEVEL_RANGE

        player:SendBroadcastMessage("Learnable spells at level " .. playerLevel .. " (range " .. minLevel .. "-" .. maxLevel .. "):")

        local totalSpells = 0
        for _, sourceClass in ipairs(def.tomeClasses) do
            local count     = CustomClasses.countLearnableSpells(player, def, sourceClass, minLevel, maxLevel)
            local className = CLASS_NAMES[sourceClass] or "Unknown"
            player:SendBroadcastMessage("  " .. className .. ": " .. count .. " spells")
            totalSpells = totalSpells + count
        end

        if totalSpells > 0 then
            player:SendBroadcastMessage("Trainer spawn weights:")
            for _, sourceClass in ipairs(def.tomeClasses) do
                local count = CustomClasses.countLearnableSpells(player, def, sourceClass, minLevel, maxLevel)
                if count > 0 then
                    local className = CLASS_NAMES[sourceClass] or "Unknown"
                    local pct       = math.floor((count / totalSpells) * 100)
                    player:SendBroadcastMessage("  " .. className .. ": " .. pct .. "% chance")
                end
            end
        else
            player:SendBroadcastMessage("No learnable spells - no trainer can spawn")
        end
        return false
    end
end -- }}}

---------------------------------------------------------------------------------------------------
-- Registration

-- First login event (new characters)
RegisterPlayerEvent(30, CustomClasses.onFirstLogin)  -- PLAYER_EVENT_ON_FIRST_LOGIN

-- Regular login
RegisterPlayerEvent(3, CustomClasses.onLogin)  -- PLAYER_EVENT_ON_LOGIN

-- Chat commands
RegisterPlayerEvent(18, CustomClasses.handleChat)  -- PLAYER_EVENT_ON_CHAT

-- Selector NPC gossip - register for all race-specific entries
for race, entry in pairs(SELECTOR_NPC_ENTRIES) do
    RegisterCreatureGossipEvent(entry, 1, CustomClasses.onNPCGossip)
    RegisterCreatureGossipEvent(entry, 2, CustomClasses.onNPCGossipSelect)
end

-- Dynamic trainer gossip - register for all class trainer entries
-- SQL: source-beta/data/sql/custom/db_world/custom-class-trainers.sql
for classId, entry in pairs(TRAINER_NPC_ENTRIES) do
    RegisterCreatureGossipEvent(entry, 1, CustomClasses.onDynamicTrainerGossip)
    RegisterCreatureGossipEvent(entry, 2, CustomClasses.onDynamicTrainerGossipSelect)
end

print("[CustomClasses] Custom class system loaded")
print("[CustomClasses] Test commands: #customclass, #customset, #customclear, #customlist, #customspawn")
print("[CustomClasses] Trainer commands: #trainerspawn, #trainerinfo")
print("[CustomClasses] NOTE: Requires creature_template entries in database:")
print("[CustomClasses]   - Selector NPCs: 900001-900011 (race-specific)")
print("[CustomClasses]   - Trainer NPCs: 900021-900031 (one per class)")
