---------------------------------------------------------------------------------------------------
-- Custom Class Selection System
-- Issue: 155 - Custom classes as curated spell arrangements from multiple base classes
--
-- Custom class definitions loaded from: src/custom-class-json/
-- (rmail inbox for community uploads)

CustomClasses = {}

-- NPC entry for the Custom Class Selector
-- Must be created in creature_template first
local SELECTOR_NPC_ENTRY = 900001  -- placeholder - create in DB

-- Data key for storing custom class on player
local DATA_KEY_CUSTOM_CLASS = "custom-class"

-- How close to check for nearby players before despawning
local NEARBY_PLAYER_RANGE = 30

-- How often to check for nearby players (ms)
local NEARBY_CHECK_INTERVAL = 5000

---------------------------------------------------------------------------------------------------
-- Custom Class Definitions
-- Structure: { [customClassId] = { name, baseClass, spells, trainers, tomeClasses } }

CustomClasses.definitions = {}

-- {{{ Example Custom Classes
-- These would normally be loaded from src/custom-class-json/

-- Spellblade: Warrior + Mage fire/frost
CustomClasses.definitions[1001] = {
    name = "Spellblade",
    baseClass = 1,  -- Warrior
    spells = {
        -- Warrior base abilities
        78, 100, 772, 6546,           -- Heroic Strike, Charge, Rend, Rend R2
        -- Mage fire/frost additions
        133, 143, 145,                -- Fireball R1-R3
        116, 205, 837,                -- Frostbolt R1-R3
        122,                          -- Frost Nova
    },
    -- Which trainers teach which spells for this class
    trainers = {
        -- [npcEntry] = { spellIds... }
    },
    tomeClasses = { 1, 8 },  -- Can find Warrior and Mage tomes
    description = "A warrior who channels arcane fire and frost through their weapons.",
}

-- Shadow Apostle: Priest + Warlock curses
CustomClasses.definitions[1002] = {
    name = "Shadow Apostle",
    baseClass = 5,  -- Priest
    spells = {
        -- Priest shadow abilities
        589, 594,                     -- Shadow Word: Pain R1-R2
        8092, 8102,                   -- Mind Blast R1-R2
        -- Warlock curse additions
        702, 1108,                    -- Curse of Weakness R1-R2
        980, 1014,                    -- Curse of Agony R1-R2
    },
    trainers = {},
    tomeClasses = { 5, 9 },  -- Priest and Warlock tomes
    description = "A priest who has delved into forbidden warlock arts.",
}

-- Beast Shaman: Shaman + Hunter beast abilities
CustomClasses.definitions[1003] = {
    name = "Beast Shaman",
    baseClass = 7,  -- Shaman
    spells = {
        -- Shaman nature abilities
        403, 529,                     -- Lightning Bolt R1-R2
        8042, 8044,                   -- Earth Shock R1-R2
        -- Hunter beast abilities
        1515,                         -- Tame Beast
        883,                          -- Call Pet
        2641,                         -- Dismiss Pet
    },
    trainers = {},
    tomeClasses = { 3, 7 },  -- Hunter and Shaman tomes
    description = "A shaman with deep bonds to the animal kingdom.",
}

-- }}}

---------------------------------------------------------------------------------------------------
-- Custom Class Loading

-- {{{ loadFromDirectory
-- Load custom class definitions from src/custom-class-json/
-- Format: Each file defines one class with spell lists, trainer mappings, etc.
function CustomClasses.loadFromDirectory()
    -- TODO: Implement file loading when directory structure is finalized
    -- For now, using hardcoded examples above
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
    for _, id in ipairs(def.spells) do
        if id == spellId then
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
-- NPC Spawning and Gossip

-- {{{ spawnSelectorNPC
-- Spawn the custom class selector NPC near a player
function CustomClasses.spawnSelectorNPC(player)
    local px, py, pz, po = player:GetLocation()
    local map = player:GetMap()

    -- Find position in front of player
    local spawnDist = 3
    local x = px + math.cos(po) * spawnDist
    local y = py + math.sin(po) * spawnDist
    local z = map:GetHeight(x, y) or pz

    -- Spawn NPC facing player
    local npcFacing = po + math.pi  -- face towards player
    local npc = player:SpawnCreature(SELECTOR_NPC_ENTRY, x, y, z, npcFacing, 1, 0)

    if npc then
        -- Register periodic check for nearby players
        npc:RegisterEvent(CustomClasses.checkNearbyPlayers, NEARBY_CHECK_INTERVAL, 0)
        print("[CustomClasses] Spawned selector NPC for " .. player:GetName())
    else
        print("[CustomClasses] Failed to spawn selector NPC (entry " .. SELECTOR_NPC_ENTRY .. " not in DB?)")
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
end -- }}}

---------------------------------------------------------------------------------------------------
-- Registration

-- First login event (new characters)
RegisterPlayerEvent(30, CustomClasses.onFirstLogin)  -- PLAYER_EVENT_ON_FIRST_LOGIN

-- Regular login
RegisterPlayerEvent(3, CustomClasses.onLogin)  -- PLAYER_EVENT_ON_LOGIN

-- Chat commands
RegisterPlayerEvent(18, CustomClasses.handleChat)  -- PLAYER_EVENT_ON_CHAT

-- NPC gossip (requires NPC entry to be registered)
-- RegisterCreatureGossipEvent(SELECTOR_NPC_ENTRY, 1, CustomClasses.onNPCGossip)
-- RegisterCreatureGossipEvent(SELECTOR_NPC_ENTRY, 2, CustomClasses.onNPCGossipSelect)

print("[CustomClasses] Custom class system loaded")
print("[CustomClasses] NOTE: Requires creature_template entry " .. SELECTOR_NPC_ENTRY .. " in database")
print("[CustomClasses] NOTE: Gossip events need manual registration after NPC is created")
