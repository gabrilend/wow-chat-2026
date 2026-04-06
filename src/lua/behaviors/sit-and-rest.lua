-- {{{ Everland Ghostsong - Sit and Rest Behavior
-- Bots sit and recover when low on resources
-- Creates natural pacing in gameplay
--
-- Config values at top. Git greps are cheap.
-- Vertical alignment connects related values.
-- Dense math, few functions.
-- }}}

require("movement")
require("behaviors/avoid-monsters")

SitAndRest = {}

-- {{{ Configuration
REST_HEALTH_PCT  =  50   -- start resting below this health %
REST_MANA_PCT    =  30   -- start resting below this mana %
STAND_HEALTH_PCT =  90   -- resume activity above this health %
STAND_MANA_PCT   =  80   -- resume activity above this mana %
CHECK_INTERVAL   = 3000  -- ms between resource checks
FOOD_SEARCH_SLOT =  -1   -- -1 = search all bags for food
-- }}}

-- {{{ Stand state constants (WoW client values)
UNIT_STAND_STATE_STAND =  0
UNIT_STAND_STATE_SIT   =  1
UNIT_STAND_STATE_SLEEP =  3
-- }}}

-- {{{ SitAndRest.needsRest
-- Check if bot needs to rest based on resources
-- Returns true/false and which resource triggered
function SitAndRest.needsRest(bot)
    if not bot or not bot:IsAlive() then return false, "dead" end
    if bot:IsInCombat()              then return false, "combat" end

    local healthPct = bot:GetHealthPct()
    local maxMana   = bot:GetMaxPower(0)  -- 0 = mana
    local curMana   = bot:GetPower(0)
    local manaPct   = 100

    if maxMana > 0 then
        manaPct = (curMana / maxMana) * 100
    end

    if healthPct < REST_HEALTH_PCT then return true, "health" end
    if manaPct   < REST_MANA_PCT   then return true, "mana"   end

    return false, "full"
end -- }}}

-- {{{ SitAndRest.isFullyRecovered
-- Check if bot has recovered enough to resume activity
function SitAndRest.isFullyRecovered(bot)
    if not bot or not bot:IsAlive() then return false end

    local healthPct = bot:GetHealthPct()
    local maxMana   = bot:GetMaxPower(0)
    local curMana   = bot:GetPower(0)
    local manaPct   = 100

    if maxMana > 0 then
        manaPct = (curMana / maxMana) * 100
    end

    -- both must be above threshold
    if healthPct < STAND_HEALTH_PCT then return false end
    if manaPct   < STAND_MANA_PCT   then return false end

    return true
end -- }}}

-- {{{ SitAndRest.findConsumable
-- Search bags for food or drink
-- Returns item or nil
function SitAndRest.findConsumable(bot, searchType)
    -- searchType: "food" or "drink"
    -- This is a placeholder - actual API depends on mod-ale
    -- May need to iterate bag slots and check item class/subclass

    -- food itemClass = 0, subclass = 0 (consumable, food)
    -- drink itemClass = 0, subclass = 3 (consumable, potion/elixir)

    for bag = 0, 4 do
        for slot = 0, 35 do
            local item = bot:GetItemByPos(bag, slot)
            if item then
                local itemClass    = item:GetClass()
                local itemSubclass = item:GetSubClass()

                -- consumable food
                if searchType == "food" and itemClass == 0 and itemSubclass == 0 then
                    return item
                end

                -- consumable drink (approximation)
                if searchType == "drink" and itemClass == 0 then
                    local name = item:GetName():lower()
                    if name:find("water") or name:find("drink") or name:find("juice") then
                        return item
                    end
                end
            end
        end
    end

    return nil
end -- }}}

-- {{{ SitAndRest.useConsumable
-- Attempt to use food or drink item
function SitAndRest.useConsumable(bot, item)
    if not item then return false end

    -- use item - API depends on mod-ale
    bot:UseItem(item)
    return true
end -- }}}

-- {{{ SitAndRest.sit
-- Make bot sit down
function SitAndRest.sit(bot)
    if not bot then return end

    bot:SetStandState(UNIT_STAND_STATE_SIT)
    bot:SetData("resting", true)

    print("[SitAndRest] " .. bot:GetName() .. " sitting to rest")
end -- }}}

-- {{{ SitAndRest.stand
-- Make bot stand up
function SitAndRest.stand(bot)
    if not bot then return end

    bot:SetStandState(UNIT_STAND_STATE_STAND)
    bot:SetData("resting", false)

    print("[SitAndRest] " .. bot:GetName() .. " standing up")
end -- }}}

-- {{{ SitAndRest.checkAndRest
-- Main check function - evaluate and act on rest needs
-- Returns true if resting, false otherwise
function SitAndRest.checkAndRest(bot)
    if not bot or not bot:IsBot() then return false end

    local isResting = bot:GetData("resting") or false

    -- if in combat, stand up immediately
    if bot:IsInCombat() then
        if isResting then
            SitAndRest.stand(bot)
        end
        return false
    end

    -- check for danger while resting
    if isResting then
        local shouldFlee = AvoidMonsters.shouldFlee(bot)
        if shouldFlee then
            SitAndRest.stand(bot)
            AvoidMonsters.flee(bot)
            return false
        end
    end

    -- check if we need rest
    local needRest, reason = SitAndRest.needsRest(bot)

    if needRest and not isResting then
        -- start resting
        SitAndRest.sit(bot)

        -- try to use consumables
        if reason == "health" or reason == "both" then
            local food = SitAndRest.findConsumable(bot, "food")
            if food then SitAndRest.useConsumable(bot, food) end
        end

        if reason == "mana" or reason == "both" then
            local drink = SitAndRest.findConsumable(bot, "drink")
            if drink then SitAndRest.useConsumable(bot, drink) end
        end

        return true
    end

    -- check if we're done resting
    if isResting and SitAndRest.isFullyRecovered(bot) then
        SitAndRest.stand(bot)
        return false
    end

    return isResting
end -- }}}

-- {{{ Module initialization
-- NOTE: Per-bot registration moved to periodic_events.lua (issue 160)
-- This file exposes: SitAndRest.checkAndRest(bot)
print("[SitAndRest] Behavior loaded - periodic registration via periodic_events.lua")
-- }}}
