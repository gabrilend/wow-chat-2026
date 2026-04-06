-- levelling.lua
-- Awards talent points for every 1/3rd of a level gained.
-- Stores total talent points in database and updates on levelup or XP gain.
-- Assumes Rate.Talent = 3 in worldserver.conf
--
-- Issue 120: talent-points-level-20-cap
-- Fix: Use GetGUIDLow() instead of GetGUID() for SQL queries
--   - GetGUID() returns userdata (not usable in string.format)
--   - GetGUIDLow() returns number (safe for SQL)

-- {{{ Experience table - XP requirements for each level
Experience = {}
Experience[1]  = 400
Experience[2]  = 900
Experience[3]  = 1400
Experience[4]  = 2100
Experience[5]  = 2800
Experience[6]  = 3600
Experience[7]  = 4500
Experience[8]  = 5400
Experience[9]  = 6400
Experience[10] = 7500
Experience[11] = 8700
Experience[12] = 10000
Experience[13] = 11400
Experience[14] = 12300
Experience[15] = 13600
Experience[16] = 15000
Experience[17] = 16400
Experience[18] = 17800
Experience[19] = 19300
Experience[20] = 20800
Experience[21] = 22400
Experience[22] = 24000
Experience[23] = 25500
Experience[24] = 27200
Experience[25] = 28900
Experience[26] = 30500
Experience[27] = 32200
Experience[28] = 33900
Experience[29] = 36300
Experience[30] = 38800
Experience[31] = 41600
Experience[32] = 44600
Experience[33] = 48000
Experience[34] = 51400
Experience[35] = 55000
Experience[36] = 58700
Experience[37] = 62400
Experience[38] = 66200
Experience[39] = 70200
Experience[40] = 74300
Experience[41] = 78500
Experience[42] = 82800
Experience[43] = 87100
Experience[44] = 91600
Experience[45] = 96300
Experience[46] = 101000
Experience[47] = 105800
Experience[48] = 110700
Experience[49] = 115700
Experience[50] = 120900
Experience[51] = 126100
Experience[52] = 131500
Experience[53] = 137000
Experience[54] = 142500
Experience[55] = 148200
Experience[56] = 154000
Experience[57] = 159900
Experience[58] = 165800
Experience[59] = 172000
Experience[60] = 290000
Experience[61] = 317000
Experience[62] = 349000
Experience[63] = 386000
Experience[64] = 428000
Experience[65] = 475000
Experience[66] = 527000
Experience[67] = 585000
Experience[68] = 648000
Experience[69] = 717000
Experience[70] = 1523800
Experience[71] = 1539600
Experience[72] = 1555700
Experience[73] = 1571800
Experience[74] = 1587900
Experience[75] = 1604200
Experience[76] = 1620700
Experience[77] = 1637400
Experience[78] = 1653900
Experience[79] = 1670800
-- }}}

-- {{{ Configuration
TP_PER_LEVEL   = 3  -- talent points per level (if changed, update getExtraTalentPoints)
TP_AT_LEVEL_10 = 10 -- bonus points granted at level 10
-- }}}

-- {{{ Experience.getExtraTalentPoints
-- Returns 0, 1, or 2 based on XP progress within current level
-- Thresholds at 33% and 66% of level XP requirement
function Experience.getExtraTalentPoints(level, currentExp)
    if     currentExp > Experience[level] / TP_PER_LEVEL * 2 then return 2
    elseif currentExp > Experience[level] / TP_PER_LEVEL     then return 1
                                                             else return 0
    end
end
-- }}}

-- {{{ Experience.getTotalTalentPoints
-- Calculates total talent points earned at given level and XP
-- Formula accounts for: (level-1)*3 + partial points - offset for level 10 bonus
function Experience.getTotalTalentPoints(level, currentExp)
    return ((level - 1) * TP_PER_LEVEL) + Experience.getExtraTalentPoints(level, currentExp) - (TP_PER_LEVEL * 10 - TP_AT_LEVEL_10)
end
-- }}}

-- {{{ Experience.getSpentTalentPoints
-- Returns how many talent points the player has spent
function Experience.getSpentTalentPoints(level, currentExp, freePoints)
    return Experience.getTotalTalentPoints(level, currentExp) - freePoints
end
-- }}}

-- {{{ Experience.checkLevelProgress
-- Called on XP gain - checks if player has earned new talent points
function Experience.checkLevelProgress(_event, player)
    local  totalTalentPoints  = Experience.getTotalTalentPoints(player:GetLevel(), player:GetXP())
    local currentTalentPoints = player:GetData("current-talent-points")
    local difference = totalTalentPoints - currentTalentPoints

    if difference > 0 then
        Experience.awardTalentPoint(player, difference)
    end
end
-- }}}

-- {{{ Experience.updateTalentPointDB
-- Persists talent point total to database
function Experience.updateTalentPointDB(playerGuidLow, points)
    local query = string.format("UPDATE characters SET total_talent_points = %s WHERE guid = %s", points, playerGuidLow)
    CharDBQueryAsync(query, function() end)
end
-- }}}

-- {{{ Experience.awardTalentPoint
-- Awards talent points to player and updates database
-- FIX: Use GetGUIDLow() instead of GetGUID() for SQL compatibility
function Experience.awardTalentPoint(player, num)
    print("You feel more capable. +" .. num .. " talent point.")
    local currentTalentPoints = player:GetData("current-talent-points")
    player:SetData("current-talent-points", currentTalentPoints + num)
    player:SetFreeTalentPoints(player:GetFreeTalentPoints() + num)
    Experience.updateTalentPointDB(player:GetGUIDLow(), currentTalentPoints + num)
end
-- }}}

-- {{{ Experience.onLevelChange
-- Called when player levels up - adjusts talent points
-- At level 10: grants TP_AT_LEVEL_10 bonus points
-- Above level 10: removes server-granted points (we handle them ourselves)
function Experience.onLevelChange(_event, player)
    local num
    if player:GetLevel() > 10 then
        player:SetFreeTalentPoints(player:GetFreeTalentPoints() - TP_PER_LEVEL)
        num = 1
    elseif player:GetLevel() == 10 then
        player:SetFreeTalentPoints(0)
        num = TP_AT_LEVEL_10
    end
    Experience.awardTalentPoint(player, num)
end
-- }}}

-- {{{ Experience.updatePlayerData
-- Callback for database query - restores player's talent point state
function Experience.updatePlayerData(query)
    if query then
        local   playerID   = query:GetUInt64(0)
        local talentPoints = query:GetUInt32(1)
        local    player    = GetPlayerByGUID(playerID)

        if player then
            player:SetData("current-talent-points", talentPoints)
            if player:GetFreeTalentPoints() > 0 then
                player:SetFreeTalentPoints(0)
            end
        end
    else
        print("player query not found, cannot update talent point data")
    end
end
-- }}}

-- {{{ Experience.onLogin
-- Called on player login - loads talent points from database
-- FIX: Use GetGUIDLow() instead of GetGUID() for SQL compatibility
function Experience.onLogin(event, player)
    local query = string.format("SELECT guid, total_talent_points FROM characters WHERE guid = %s", player:GetGUIDLow())
    CharDBQueryAsync(query, Experience.updatePlayerData)
end
-- }}}

-- {{{ Event Registration
PLAYER_EVENT_ON_LEVEL_CHANGE = 13
PLAYER_EVENT_ON_GIVE_XP      = 12
PLAYER_EVENT_ON_LOGIN        = 3

RegisterPlayerEvent(PLAYER_EVENT_ON_GIVE_XP,      Experience.checkLevelProgress)
RegisterPlayerEvent(PLAYER_EVENT_ON_LEVEL_CHANGE, Experience.onLevelChange)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,        Experience.onLogin)
-- }}}
