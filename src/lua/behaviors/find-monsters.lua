-- {{{ Everland Ghostsong - Find Monsters Behavior
-- Playerbots attack nearest visible, level-appropriate monsters
-- Integrates with avoid-monsters for danger awareness
--
-- Config values at top. Git greps are cheap.
-- Vertical alignment connects related values.
-- Dense math, few functions.
-- }}}

require("movement")

FindMonsters = {}

-- Register in package.loaded so require() is a no-op after ALE loads this
-- Must be AFTER FindMonsters table is created so require() returns the module
package.loaded["behaviors/find-monsters"] = FindMonsters

-- {{{ Configuration
SIGHT_RANGE        = 500   -- yards to scan for creatures
MAX_LEVEL_DIFF_UP  =   3   -- will attack creatures up to 3 levels higher
MAX_LEVEL_DIFF_DN  =  10   -- will attack creatures up to 10 levels lower
LOS_CHECK_LIMIT    =  20   -- max creatures to LoS check per scan
SCAN_INTERVAL      = 5000  -- ms between scans when idle
ENGAGE_RANGE       =  30   -- yards to start combat
-- }}}

-- {{{ FindMonsters.getNearbyCreatures
-- Returns table of hostile creatures within range, sorted by distance
-- Does not check LoS - that's done in selectTarget
function FindMonsters.getNearbyCreatures(bot, range)
    local creatures = {}
    local bx, by, bz = bot:GetLocation()

    -- GetCreaturesInRange(range, entryId, hostile, dead)
    -- hostile: 0=both, 1=hostile, 2=friendly
    -- dead: 0=both, 1=alive, 2=dead (default 1)
    local nearby = bot:GetCreaturesInRange(range, 0, 1)  -- hostile only

    if not nearby then return creatures end

    for _, creature in pairs(nearby) do
        -- IsHostileTo provided by ElunaCompat.ext
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

    -- sort by distance (squared, but order is same)
    table.sort(creatures, function(a, b) return a.dist < b.dist end)

    return creatures
end -- }}}

-- {{{ FindMonsters.isLevelAppropriate
-- Check if creature level is within our comfort zone
function FindMonsters.isLevelAppropriate(botLevel, creatureLevel)
    local diff = creatureLevel - botLevel

    if diff > MAX_LEVEL_DIFF_UP then return false end  -- too hard
    if diff < -MAX_LEVEL_DIFF_DN then return false end -- too easy (grey)

    return true
end -- }}}

-- {{{ FindMonsters.selectTarget
-- Iterate through sorted creatures, check LoS, return first valid target
-- Returns nil if no valid target found
function FindMonsters.selectTarget(bot, creatures)
    local botLevel = bot:GetLevel()
    local checked  = 0

    for _, data in ipairs(creatures) do
        if checked >= LOS_CHECK_LIMIT then break end

        local creature = data.creature
        local level    = data.level

        -- level check (fast)
        if FindMonsters.isLevelAppropriate(botLevel, level) then
            -- LoS check (expensive)
            if bot:IsWithinLoS(creature) then
                return creature
            end
        end

        checked = checked + 1
    end

    return nil
end -- }}}

-- {{{ FindMonsters.moveToTarget
-- Move bot toward target creature
function FindMonsters.moveToTarget(bot, target)
    local tx, ty, tz = target:GetLocation()
    local bx, by     = bot:GetLocation()

    local dist = math.sqrt(Movement.squaredDistance(bx, by, tx, ty))

    if dist > ENGAGE_RANGE then
        -- move closer
        bot:MoveTo(0, tx, ty, tz, true)
        return false  -- not in range yet
    else
        -- in range, can engage
        return true
    end
end -- }}}

-- {{{ FindMonsters.engageTarget
-- Set target and begin attack
function FindMonsters.engageTarget(bot, target)
    bot:SetTarget(target)
    bot:Attack(target)

    -- notify (debug)
    local name  = target:GetName()
    local level = target:GetLevel()
    print("[FindMonsters] " .. bot:GetName() .. " engaging " .. name .. " (L" .. level .. ")")
end -- }}}

-- {{{ FindMonsters.scan
-- Main scan function - find and engage nearest appropriate target
-- Returns true if engaging, false if idle
function FindMonsters.scan(bot)
    -- skip if already in combat
    if bot:IsInCombat() then return true end

    -- skip if dead
    if not bot:IsAlive() then return false end

    -- skip if not a bot
    if not bot:IsBot() then return false end

    -- get nearby creatures
    local creatures = FindMonsters.getNearbyCreatures(bot, SIGHT_RANGE)

    if #creatures == 0 then return false end

    -- select best target
    local target = FindMonsters.selectTarget(bot, creatures)

    if not target then return false end

    -- move to target
    local inRange = FindMonsters.moveToTarget(bot, target)

    if inRange then
        FindMonsters.engageTarget(bot, target)
        return true
    end

    return false  -- moving, not yet engaged
end -- }}}

-- {{{ Module initialization
-- NOTE: Per-bot registration moved to periodic_events.lua (issue 160)
-- This file exposes: FindMonsters.scan(bot)
print("[FindMonsters] Behavior loaded - periodic registration via periodic_events.lua")
-- }}}
