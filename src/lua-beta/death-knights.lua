-- =============================================================================
-- Death Knight Level 1-20 Scaling (Issue 206)
-- =============================================================================
-- DKs start at level 1 with basic abilities (Blood Presence, Icy Touch).
-- Additional abilities are learned from trainers at levels 4, 6, 8, etc.
-- Quest auto-completion allows DKs to leave Ebon Hold immediately via
-- teleport boxes (dock, road, beach).
--
-- Ability progression defined in death-knights.sql (trainer template 200019)
-- =============================================================================

-- {{{ Quest data
-- DK starting zone quests - completed on first login to unlock teleport exits
local quests = { 12593, 12619, 12842, 12848, 12636, 12641, 12657, 12678, 12679, 12680, 12687,
                 12698, 12701, 12706, 12716, 12719, 12720, 12722, 12724, 12725, 12727, 12733, -1,
                 12751, 12754, 12755, 12756, 12757, 12779, 12801, 13165, 13166
               }
-- Race-specific quests (index matches race ID)
local racequests = { 12742, 12748, 12744, 12743, 12750, 12739, 12745, 12749, -1, 12747, 12746 }
-- }}}

DK = { quests     = quests,
       racequests = racequests
     }

-- {{{ DK.printPosition
-- Debug command: type "pos" in chat to see coordinates
function DK.printPosition(_eventID, player, msg)
    if msg == "pos" then
        local x, y, z, o = player:GetLocation()
        player:SendBroadcastMessage("X: " .. x .. " Y: " .. y .. " Z: " .. z .. " O: " .. o)
        player:SendBroadcastMessage("MapID: " .. player:GetMapId())
        player:SendBroadcastMessage("ZoneID: " .. player:GetZoneId())
    end
end
-- }}}

PLAYER_EVENT_ON_CHAT = 18
RegisterPlayerEvent(PLAYER_EVENT_ON_CHAT, DK.printPosition)

-- {{{ DK.onFirstLogin
-- Complete all DK starting quests so player can leave Ebon Hold immediately
-- Does NOT set level or grant abilities - those come from trainers
function DK.onFirstLogin(_eventID, player)
    if player:GetClass() ~= 6 then
        return
    end

    local targetRace = player:GetRace()
    local targetTeam = player:GetTeam()

    -- Set faction-specific end quest
    if targetTeam == 0 then
        DK.quests[33] = 13188  -- Alliance end quest
    else
        DK.quests[33] = 13189  -- Horde end quest
    end

    -- Set race-specific quest
    DK.quests[23] = DK.racequests[targetRace]

    -- Complete all quests to unlock Ebon Hold exits
    for _, questId in ipairs(DK.quests) do
        if questId > 0 then
            player:AddQuest(questId)
            player:CompleteQuest(questId)
            player:RewardQuest(questId)
        end
    end

    -- Note: Starting gear handled by playercreateinfo_item table
    -- Note: Level remains at 1, abilities from trainer template 200019

    player:SaveToDB()
end
-- }}}

-- {{{ DK.onLogin
-- Start teleport check timer for DKs in Ebon Hold
function DK.onLogin(_eventID, player)
    -- Only check DKs in Ebon Hold (map 609)
    if player:GetClass() ~= 6 or player:GetMapId() ~= 609 then
        return
    end
    player:RegisterEvent(DK.teleportCheck, 2000, 1)
end
-- }}}

-- {{{ DK.teleportCheck
-- Teleport boxes in Ebon Hold that exit to the main world
-- Dock  -> Northrend (Borean Tundra)
-- Road  -> Eastern Kingdoms (Stormwind area)
-- Beach -> Northrend (Borean Tundra)
--
-- Dock box coordinates:
--   x: 1289.40 - 1309.79
--   y: -6166.92 - -6125.28
--   z: 13.99 - 14.21
--
-- Road box coordinates:
--   x: 1781.35 - 1801.34
--   y: -4875.36 - -4867.02
--   z: 88.45 - 89.94
--
-- Beach box coordinates:
--   x: 2043.25 - 2303.61
--   y: -6224.11 - -6150.62
--   z: -1.41 - 1.14
function DK.teleportCheck(eventID, delay, repeats, player)
    -- Only check if still in Ebon Hold
    if player:GetMapId() ~= 609 or player:GetZoneId() ~= 4298 then
        return
    end

    local x, y, z, o = player:GetLocation()

    -- Dock -> Northrend
    if     x > 1289.40 and x < 1309.79 and
           y > -6166.92 and y < -6125.28 and
           z > 13.99 and z < 14.21 then
        player:Teleport(571, 2473.49, -426.06, 2.91, 0.07)
        return

    -- Road -> Eastern Kingdoms
    elseif x > 1781.35 and x < 1801.34 and
           y > -4875.36 and y < -4867.02 and
           z > 88.45 and z < 89.94 then
        player:Teleport(0, 1786.73, -4878.47, 87.49, 1.34)
        return

    -- Beach -> Northrend
    elseif x > 2043.25 and x < 2303.61 and
           y > -6224.11 and y < -6150.62 and
           z > -1.41 and z < 1.14 then
        player:Teleport(571, 2473.49, -426.06, 2.91, 0.07)
        return
    end

    -- Still in Ebon Hold, keep checking
    player:RegisterEvent(DK.teleportCheck, 2000, 1)
end
-- }}}

-- {{{ Event registration
PLAYER_EVENT_ON_FIRST_LOGIN = 30
PLAYER_EVENT_ON_LOGIN       = 3
RegisterPlayerEvent(PLAYER_EVENT_ON_FIRST_LOGIN, DK.onFirstLogin)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, DK.onLogin)
-- }}}
