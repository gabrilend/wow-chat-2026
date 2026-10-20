
require("movement")

FindMonsters = {}

package.loaded["behaviors/find-monsters"] = FindMonsters

SIGHT_RANGE        = 500
MAX_LEVEL_DIFF_UP  =   3
MAX_LEVEL_DIFF_DN  =  10
LOS_CHECK_LIMIT    =  20
SCAN_INTERVAL      = 5000
ENGAGE_RANGE       =  30

function FindMonsters.getNearbyCreatures(bot, range)
    local creatures = {}
    local bx, by, bz = bot:GetLocation()

    local nearby = bot:GetCreaturesInRange(range, 0, 1)

    if not nearby then return creatures end

    for _, creature in pairs(nearby) do
        if creature and creature:IsAlive() and creature:IsHostileTo(bot) then
            local cx, cy = creature:GetLocation()
            local dist   = Movement.squaredDistance(bx, by, cx, cy)

            table.insert(creatures, {
                creature = creature,
                dist     = dist,
                level    = creature:GetLevel(),
                entry    = creature:GetEntry()
            })
        end
    end

    table.sort(creatures, function(a, b) return a.dist < b.dist end)

    return creatures
end

function FindMonsters.isLevelAppropriate(botLevel, creatureLevel)
    local diff = creatureLevel - botLevel

    if diff > MAX_LEVEL_DIFF_UP then return false end
    if diff < -MAX_LEVEL_DIFF_DN then return false end

    return true
end

function FindMonsters.selectTarget(bot, creatures)
    local botLevel = bot:GetLevel()
    local checked  = 0

    for _, data in ipairs(creatures) do
        if checked >= LOS_CHECK_LIMIT then break end

        local creature = data.creature
        local level    = data.level

        if FindMonsters.isLevelAppropriate(botLevel, level) then
            if bot:IsWithinLoS(creature) then
                return creature
            end
        end

        checked = checked + 1
    end

    return nil
end

function FindMonsters.moveToTarget(bot, target)
    local tx, ty, tz = target:GetLocation()
    local bx, by     = bot:GetLocation()

    local dist = math.sqrt(Movement.squaredDistance(bx, by, tx, ty))

    if dist > ENGAGE_RANGE then
        bot:MoveTo(0, tx, ty, tz, true)
        return false
    else
        return true
    end
end

function FindMonsters.engageTarget(bot, target)
    bot:Attack(target)

    local name  = target:GetName()
    local level = target:GetLevel()
    print("[FindMonsters] " .. bot:GetName() .. " engaging " .. name .. " (L" .. level .. ")")
end

function FindMonsters.scan(bot)
    if bot:IsInCombat() then return true end

    if not bot:IsAlive() then return false end

    if not bot:IsBot() then return false end

    local creatures = FindMonsters.getNearbyCreatures(bot, SIGHT_RANGE)

    if #creatures == 0 then return false end

    local target = FindMonsters.selectTarget(bot, creatures)

    if not target then return false end

    local inRange = FindMonsters.moveToTarget(bot, target)

    if inRange then
        FindMonsters.engageTarget(bot, target)
        return true
    end

    return false
end

print("[FindMonsters] Behavior loaded - periodic registration via periodic_events.lua")
