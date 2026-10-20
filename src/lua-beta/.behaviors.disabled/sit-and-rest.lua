
require("movement")
require("behaviors/avoid-monsters")

SitAndRest = {}

package.loaded["behaviors/sit-and-rest"] = SitAndRest

REST_HEALTH_PCT  =  50
REST_MANA_PCT    =  30
STAND_HEALTH_PCT =  90
STAND_MANA_PCT   =  80
CHECK_INTERVAL   = 3000
FOOD_SEARCH_SLOT =  -1

UNIT_STAND_STATE_STAND =  0
UNIT_STAND_STATE_SIT   =  1
UNIT_STAND_STATE_SLEEP =  3

function SitAndRest.needsRest(bot)
    if not bot or not bot:IsAlive() then return false, "dead" end
    if bot:IsInCombat()              then return false, "combat" end

    local healthPct = bot:GetHealthPct()
    local maxMana   = bot:GetMaxPower(0)
    local curMana   = bot:GetPower(0)
    local manaPct   = 100

    if maxMana > 0 then
        manaPct = (curMana / maxMana) * 100
    end

    if healthPct < REST_HEALTH_PCT then return true, "health" end
    if manaPct   < REST_MANA_PCT   then return true, "mana"   end

    return false, "full"
end

function SitAndRest.isFullyRecovered(bot)
    if not bot or not bot:IsAlive() then return false end

    local healthPct = bot:GetHealthPct()
    local maxMana   = bot:GetMaxPower(0)
    local curMana   = bot:GetPower(0)
    local manaPct   = 100

    if maxMana > 0 then
        manaPct = (curMana / maxMana) * 100
    end

    if healthPct < STAND_HEALTH_PCT then return false end
    if manaPct   < STAND_MANA_PCT   then return false end

    return true
end

function SitAndRest.findConsumable(bot, searchType)


    for bag = 0, 4 do
        for slot = 0, 35 do
            local item = bot:GetItemByPos(bag, slot)
            if item then
                local itemClass    = item:GetClass()
                local itemSubclass = item:GetSubClass()

                if searchType == "food" and itemClass == 0 and itemSubclass == 0 then
                    return item
                end

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
end

function SitAndRest.useConsumable(bot, item)
    if not item then return false end

    local spellId = item:GetSpellId(0)
    if spellId == 0 or item:GetSpellTrigger(0) ~= 0 then
        return false
    end
    bot:CastSpell(bot, spellId, false)
    bot:RemoveItem(item, 1)
    return true
end

function SitAndRest.sit(bot)
    if not bot then return end

    bot:SetStandState(UNIT_STAND_STATE_SIT)
    bot:SetData("resting", true)

    print("[SitAndRest] " .. bot:GetName() .. " sitting to rest")
end

function SitAndRest.stand(bot)
    if not bot then return end

    bot:SetStandState(UNIT_STAND_STATE_STAND)
    bot:SetData("resting", false)

    print("[SitAndRest] " .. bot:GetName() .. " standing up")
end

function SitAndRest.checkAndRest(bot)
    if not bot or not bot:IsBot() then return false end

    local isResting = bot:GetData("resting") or false

    if bot:IsInCombat() then
        if isResting then
            SitAndRest.stand(bot)
        end
        return false
    end

    if isResting then
        local shouldFlee = AvoidMonsters.shouldFlee(bot)
        if shouldFlee then
            SitAndRest.stand(bot)
            AvoidMonsters.flee(bot)
            return false
        end
    end

    local needRest, reason = SitAndRest.needsRest(bot)

    if needRest and not isResting then
        SitAndRest.sit(bot)

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

    if isResting and SitAndRest.isFullyRecovered(bot) then
        SitAndRest.stand(bot)
        return false
    end

    return isResting
end

print("[SitAndRest] Behavior loaded - periodic registration via periodic_events.lua")
