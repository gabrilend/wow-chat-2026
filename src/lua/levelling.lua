-- {{{ Everland Ghostsong - Talent Point System
-- Awards 1 talent point for every 1/3rd of a level gained
-- Stores total AND free (unspent) talent points in database
-- Restores correctly on login
--
-- Max level: 20
-- Points per level: 3
-- Total at level 20: 60 talent points
-- }}}

-- {{{ Configuration
MAX_LEVEL      = 20
TP_PER_LEVEL   = 3
TP_AT_LEVEL_1  = 0   -- start with 0, earn them all
-- }}}

-- {{{ Experience thresholds per level (1-20 only for Everland Ghostsong)
Experience = {}
Experience[1]  =   400
Experience[2]  =   900
Experience[3]  =  1400
Experience[4]  =  2100
Experience[5]  =  2800
Experience[6]  =  3600
Experience[7]  =  4500
Experience[8]  =  5400
Experience[9]  =  6400
Experience[10] =  7500
Experience[11] =  8700
Experience[12] = 10000
Experience[13] = 11400
Experience[14] = 12300
Experience[15] = 13600
Experience[16] = 15000
Experience[17] = 16400
Experience[18] = 17800
Experience[19] = 19300
Experience[20] = 20800
-- }}}

-- {{{ Experience.getExtraTalentPoints
-- Returns bonus talent points based on XP progress within current level
-- 0-33%: 0 extra, 33-66%: 1 extra, 66-100%: 2 extra
function Experience.getExtraTalentPoints(level, currentExp)
    local threshold = Experience[level] or 20800  -- fallback to level 20

    if     currentExp > threshold / TP_PER_LEVEL * 2 then return 2
    elseif currentExp > threshold / TP_PER_LEVEL     then return 1
                                                     else return 0
    end
end -- }}}

-- {{{ Experience.getTotalTalentPoints
-- Calculate total earned talent points for a level and XP amount
-- Level 1 with 0 XP = 0 points
-- Level 20 with full XP = 60 points (20 levels * 3 points)
function Experience.getTotalTalentPoints(level, currentExp)
    local baseTalents  = (level - 1) * TP_PER_LEVEL
    local extraTalents = Experience.getExtraTalentPoints(level, currentExp)

    return baseTalents + extraTalents
end -- }}}

-- {{{ Experience.getSpentTalentPoints
-- Calculate how many talent points have been spent
function Experience.getSpentTalentPoints(totalEarned, freePoints)
    return totalEarned - freePoints
end -- }}}

-- {{{ Experience.checkLevelProgress
-- Called on XP gain - check if we crossed a 1/3 threshold
function Experience.checkLevelProgress(_event, player)
    local level     = player:GetLevel()
    local currentXP = player:GetXP()

    local totalEarned   = Experience.getTotalTalentPoints(level, currentXP)  -- calculated from level/XP
    local totalRecorded = player:GetData("total-talent-points") or 0         -- stored in memory/DB

    local newPoints = totalEarned - totalRecorded
    if newPoints > 0 then
        Experience.awardTalentPoints(player, newPoints)
    end
end -- }}}

-- {{{ Experience.updateTalentPointsDB
-- Persist both total earned AND free (unspent) talent points
-- Requires: ALTER TABLE characters ADD free_talent_points INT DEFAULT 0;
function Experience.updateTalentPointsDB(player)
    local guid        = player:GetGUID()
    local totalEarned = player:GetData("total-talent-points") or 0
    local freePoints  = player:GetFreeTalentPoints()

    local query = string.format(
        "UPDATE characters SET total_talent_points = %d, free_talent_points = %d WHERE guid = %d",
        totalEarned, freePoints, guid
    )
    CharDBQueryAsync(query, function() end)
end -- }}}

-- {{{ Experience.awardTalentPoints
-- Award new talent points to player
function Experience.awardTalentPoints(player, num)
    local totalRecorded = player:GetData("total-talent-points") or 0
    local newTotal      = totalRecorded + num

    -- update memory
    player:SetData("total-talent-points", newTotal)

    -- update game state
    player:SetFreeTalentPoints(player:GetFreeTalentPoints() + num)

    -- persist to database
    Experience.updateTalentPointsDB(player)

    -- notify player
    if num == 1 then
        player:SendBroadcastMessage("You feel more capable. +1 talent point.")
    else
        player:SendBroadcastMessage("You feel more capable. +" .. num .. " talent points.")
    end
end -- }}}

-- {{{ Experience.onLevelChange
-- Called on level up - suppress default talent point gain, we handle it
function Experience.onLevelChange(_event, player)
    -- The default system awards talent points on level up
    -- We need to remove those and let our XP-based system handle it
    -- This is done by resetting to our calculated value

    local level     = player:GetLevel()
    local currentXP = player:GetXP()

    -- don't exceed max level for our system
    if level > MAX_LEVEL then
        level = MAX_LEVEL
    end

    -- recalculate what they should have
    local totalEarned   = Experience.getTotalTalentPoints(level, currentXP)
    local totalRecorded = player:GetData("total-talent-points") or 0
    local spentPoints   = Experience.getSpentTalentPoints(totalRecorded, player:GetFreeTalentPoints())

    -- set correct free talent points (earned minus spent)
    local correctFree = totalEarned - spentPoints
    if correctFree < 0 then correctFree = 0 end

    player:SetData("total-talent-points", totalEarned)
    player:SetFreeTalentPoints(correctFree)

    Experience.updateTalentPointsDB(player)
end -- }}}

-- {{{ Experience.restorePlayerData
-- Callback for database query on login
-- Restores both total earned and free talent points
function Experience.restorePlayerData(query)
    if not query then
        print("[TalentPoints] Query failed, cannot restore talent data")
        return
    end

    local guid        = query:GetUInt64(0)
    local totalEarned = query:GetUInt32(1)
    local freePoints  = query:GetUInt32(2)
    local player      = GetPlayerByGUID(guid)

    if not player then
        print("[TalentPoints] Player not found for guid: " .. tostring(guid))
        return
    end

    -- restore to memory
    player:SetData("total-talent-points", totalEarned)

    -- restore free talent points
    -- clear default-awarded points first, then set to our stored value
    player:SetFreeTalentPoints(freePoints)

    print("[TalentPoints] Restored " .. totalEarned .. " total, " .. freePoints .. " free for player " .. guid)
end -- }}}

-- {{{ Experience.onLogin
-- Query database and restore talent point state
function Experience.onLogin(_event, player)
    local guid  = player:GetGUID()
    local query = string.format(
        "SELECT guid, total_talent_points, COALESCE(free_talent_points, 0) FROM characters WHERE guid = %d",
        guid
    )
    CharDBQueryAsync(query, Experience.restorePlayerData)
end -- }}}

-- {{{ Experience.onLogout
-- Save talent points on logout
function Experience.onLogout(_event, player)
    Experience.updateTalentPointsDB(player)
end -- }}}

-- {{{ Event Registration
PLAYER_EVENT_ON_LOGIN        =  3
PLAYER_EVENT_ON_LOGOUT       =  4
PLAYER_EVENT_ON_GIVE_XP      = 12
PLAYER_EVENT_ON_LEVEL_CHANGE = 13

RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,        Experience.onLogin)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT,       Experience.onLogout)
RegisterPlayerEvent(PLAYER_EVENT_ON_GIVE_XP,      Experience.checkLevelProgress)
RegisterPlayerEvent(PLAYER_EVENT_ON_LEVEL_CHANGE, Experience.onLevelChange)
-- }}}
