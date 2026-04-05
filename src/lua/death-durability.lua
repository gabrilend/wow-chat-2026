---------------------------------------------------------------------------------------------------
-- Death Durability System
-- Issue: 152 - Death causes 100% durability damage, items at 0 are destroyed
-- On resurrection, random 3 items at 1 durability, others restore to pre-death values

DeathDurability = {}

-- WoW 3.3.5a Item Update Field indices
-- These are client version specific - verify if using different core
local ITEM_FIELD_DURABILITY    = 21
local ITEM_FIELD_MAXDURABILITY = 22

-- Equipment slot constants
local SLOT_HEAD      =  0
local SLOT_NECK      =  1
local SLOT_SHOULDERS =  2
local SLOT_BODY      =  3  -- shirt
local SLOT_CHEST     =  4
local SLOT_WAIST     =  5
local SLOT_LEGS      =  6
local SLOT_FEET      =  7
local SLOT_WRISTS    =  8
local SLOT_HANDS     =  9
local SLOT_FINGER1   = 10
local SLOT_FINGER2   = 11
local SLOT_TRINKET1  = 12
local SLOT_TRINKET2  = 13
local SLOT_BACK      = 14
local SLOT_MAINHAND  = 15
local SLOT_OFFHAND   = 16
local SLOT_RANGED    = 17
local SLOT_TABARD    = 18

local WEAPON_SLOTS = { SLOT_MAINHAND, SLOT_OFFHAND, SLOT_RANGED }

-- Durability cache: keyed by player GUID
-- Structure: { [slot] = durability_value, ... }
local DurabilityCache = {}

---------------------------------------------------------------------------------------------------
-- Helper functions

-- {{{ getDurability
-- Gets current durability of an item using low-level field access
function DeathDurability.getDurability(item)
    if not item then return 0 end
    return item:GetUInt32Value(ITEM_FIELD_DURABILITY)
end -- }}}

-- {{{ setDurability
-- Sets durability of an item using low-level field access
function DeathDurability.setDurability(item, value)
    if not item then return end
    local maxDur = item:GetUInt32Value(ITEM_FIELD_MAXDURABILITY)
    -- Clamp value between 0 and max
    value = math.max(0, math.min(value, maxDur))
    item:SetUInt32Value(ITEM_FIELD_DURABILITY, value)
end -- }}}

-- {{{ getMaxDurability
-- Gets max durability of an item
function DeathDurability.getMaxDurability(item)
    if not item then return 0 end
    return item:GetUInt32Value(ITEM_FIELD_MAXDURABILITY)
end -- }}}

-- {{{ hasDurability
-- Returns true if item has durability (armor, weapons - not rings, etc)
function DeathDurability.hasDurability(item)
    if not item then return false end
    return DeathDurability.getMaxDurability(item) > 0
end -- }}}

-- {{{ cacheDurability
-- Cache durability values for all equipped items before applying death damage
function DeathDurability.cacheDurability(player)
    local guid = player:GetGUIDLow()
    DurabilityCache[guid] = {}

    for slot = 0, 18 do
        local item = player:GetItemByPos(255, slot)
        if item and DeathDurability.hasDurability(item) then
            DurabilityCache[guid][slot] = DeathDurability.getDurability(item)
        end
    end

    print("[DeathDurability] Cached durability for player " .. player:GetName())
end -- }}}

-- {{{ clearCache
-- Clear durability cache for player
function DeathDurability.clearCache(player)
    local guid = player:GetGUIDLow()
    DurabilityCache[guid] = nil
    print("[DeathDurability] Cleared cache for player " .. player:GetName())
end -- }}}

-- {{{ selectRandomSlots
-- Select n random slots that have items with durability
function DeathDurability.selectRandomSlots(player, count)
    local validSlots = {}

    for slot = 0, 18 do
        local item = player:GetItemByPos(255, slot)
        if item and DeathDurability.hasDurability(item) then
            table.insert(validSlots, slot)
        end
    end

    -- Shuffle and take first 'count' slots
    local selected = {}
    for i = 1, math.min(count, #validSlots) do
        local idx = math.random(1, #validSlots)
        table.insert(selected, validSlots[idx])
        table.remove(validSlots, idx)
    end

    return selected
end -- }}}

-- {{{ findRandomWeaponInBags
-- Find a random weapon in player's bags
function DeathDurability.findRandomWeaponInBags(player)
    local weapons = {}

    -- Scan bag slots (bags 0-4, slots vary by bag size)
    -- Bag 0 = backpack (16 slots), bags 1-4 = equipped bags
    for bag = 0, 4 do
        local bagSize = 16
        if bag > 0 then
            local bagItem = player:GetItemByPos(255, 19 + bag - 1)  -- bag slots 19-22
            if bagItem then
                bagSize = bagItem:GetBagSize()
            else
                bagSize = 0
            end
        end

        for slot = 0, bagSize - 1 do
            local item = player:GetItemByPos(bag, slot)
            if item then
                -- Check if item is a weapon (class 2 = weapons)
                local itemClass = item:GetClass()
                if itemClass == 2 and DeathDurability.hasDurability(item) then
                    table.insert(weapons, { bag = bag, slot = slot, item = item })
                end
            end
        end
    end

    if #weapons == 0 then return nil end
    return weapons[math.random(1, #weapons)]
end -- }}}

-- {{{ destroyItem
-- Remove item from player (destroyed - does NOT go to treasure pool)
function DeathDurability.destroyItem(player, item)
    local name = item:GetName()
    local entry = item:GetEntry()
    player:RemoveItem(entry, 1)
    print("[DeathDurability] DESTROYED: " .. name .. " (entry " .. entry .. ")")
    player:SendBroadcastMessage("|cffff0000" .. name .. " was destroyed!|r")
end -- }}}

---------------------------------------------------------------------------------------------------
-- Event handlers

-- {{{ onPlayerDeath
-- Called when player dies - apply 100% durability damage
function DeathDurability.onPlayerDeath(event, player, killer)
    print("[DeathDurability] Player " .. player:GetName() .. " died")

    -- Cache durability values BEFORE applying damage
    DeathDurability.cacheDurability(player)

    local destroyedCount = 0

    -- Apply death damage to all equipped items
    for slot = 0, 18 do
        local item = player:GetItemByPos(255, slot)
        if item and DeathDurability.hasDurability(item) then
            local currentDur = DeathDurability.getDurability(item)
            if currentDur == 0 then
                -- Already at 0 - DESTROY IT
                DeathDurability.destroyItem(player, item)
                destroyedCount = destroyedCount + 1
            else
                -- Set to 0 durability
                DeathDurability.setDurability(item, 0)
            end
        end
    end

    -- Handle empty weapon slots - damage random weapon from bags
    for _, weaponSlot in ipairs(WEAPON_SLOTS) do
        local equippedWeapon = player:GetItemByPos(255, weaponSlot)
        if not equippedWeapon then
            local bagWeapon = DeathDurability.findRandomWeaponInBags(player)
            if bagWeapon then
                local currentDur = DeathDurability.getDurability(bagWeapon.item)
                if currentDur == 0 then
                    DeathDurability.destroyItem(player, bagWeapon.item)
                    destroyedCount = destroyedCount + 1
                else
                    DeathDurability.setDurability(bagWeapon.item, 0)
                    print("[DeathDurability] Damaged bag weapon: " .. bagWeapon.item:GetName())
                end
                break  -- Only damage one weapon per empty slot
            end
        end
    end

    if destroyedCount > 0 then
        player:SendBroadcastMessage("|cffff0000" .. destroyedCount .. " item(s) destroyed by death!|r")
    end
end -- }}}

-- {{{ onPlayerResurrect
-- Called when player accepts resurrection
function DeathDurability.onPlayerResurrect(event, player)
    local guid = player:GetGUIDLow()
    local cache = DurabilityCache[guid]

    if not cache then
        print("[DeathDurability] No cache found for " .. player:GetName() .. " - skipping recovery")
        return
    end

    print("[DeathDurability] Processing resurrection recovery for " .. player:GetName())

    -- Select random 3 slots for penalty
    local penaltySlots = DeathDurability.selectRandomSlots(player, 3)
    local penaltySet = {}
    for _, slot in ipairs(penaltySlots) do
        penaltySet[slot] = true
    end

    -- Apply recovery
    for slot = 0, 18 do
        local item = player:GetItemByPos(255, slot)
        if item and DeathDurability.hasDurability(item) then
            if penaltySet[slot] then
                -- Penalty slot: set to 1 durability
                DeathDurability.setDurability(item, 1)
                print("[DeathDurability] Penalty slot " .. slot .. ": " .. item:GetName() .. " set to 1 durability")
            elseif cache[slot] then
                -- Restore to pre-death value
                DeathDurability.setDurability(item, cache[slot])
                print("[DeathDurability] Restored slot " .. slot .. ": " .. item:GetName() .. " to " .. cache[slot])
            end
        end
    end

    -- Clear cache after recovery
    DeathDurability.clearCache(player)

    player:SendBroadcastMessage("|cff00ff00Durability partially restored. 3 items remain damaged.|r")
end -- }}}

-- {{{ onPlayerRelease
-- Called when player releases spirit (no recovery)
function DeathDurability.onPlayerRelease(event, player)
    local guid = player:GetGUIDLow()
    if DurabilityCache[guid] then
        print("[DeathDurability] Player released spirit - no recovery, clearing cache")
        DeathDurability.clearCache(player)
        player:SendBroadcastMessage("|cffff0000Released spirit - items remain at 0 durability.|r")
    end
end -- }}}

---------------------------------------------------------------------------------------------------
-- Registration

-- Player killed by creature
RegisterPlayerEvent(8, DeathDurability.onPlayerDeath)  -- PLAYER_EVENT_ON_KILLED_BY_CREATURE

-- Player accepts resurrection
RegisterPlayerEvent(36, DeathDurability.onPlayerResurrect)  -- PLAYER_EVENT_ON_RESURRECT

-- Player releases spirit (repop)
RegisterPlayerEvent(35, DeathDurability.onPlayerRelease)  -- PLAYER_EVENT_ON_REPOP

print("[DeathDurability] Death durability system loaded")
