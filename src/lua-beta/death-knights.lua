
local quests = { 12593, 12619, 12842, 12848, 12636, 12641, 12657, 12678, 12679, 12680, 12687,
                 12698, 12701, 12706, 12716, 12719, 12720, 12722, 12724, 12725, 12727, 12733, -1,
                 12751, 12754, 12755, 12756, 12757, 12779, 12801, 13165, 13166
               }
local racequests = { 12742, 12748, 12744, 12743, 12750, 12739, 12745, 12749, -1, 12747, 12746 }

DK = { quests     = quests,
       racequests = racequests
     }

function DK.printPosition(_eventID, player, msg)
    if msg == "pos" then
        local x, y, z, o = player:GetLocation()
        player:SendBroadcastMessage("X: " .. x .. " Y: " .. y .. " Z: " .. z .. " O: " .. o)
        player:SendBroadcastMessage("MapID: " .. player:GetMapId())
        player:SendBroadcastMessage("ZoneID: " .. player:GetZoneId())
    end
end

local PLAYER_EVENT_ON_CHAT = 18
RegisterPlayerEvent(PLAYER_EVENT_ON_CHAT, DK.printPosition)

function DK.onFirstLogin(_eventID, player)
    if player:GetClass() ~= 6 then
        return
    end

    local targetRace = player:GetRace()
    local targetTeam = player:GetTeam()

    if targetTeam == 0 then
        DK.quests[33] = 13188
    else
        DK.quests[33] = 13189
    end

    DK.quests[23] = DK.racequests[targetRace]

    for _, questId in ipairs(DK.quests) do
        if questId > 0 then
            player:AddQuest(questId)
            player:CompleteQuest(questId)
            player:RewardQuest(questId)
        end
    end


    player:SaveToDB()
end

function DK.onLogin(_eventID, player)
    if player:GetClass() ~= 6 or player:GetMapId() ~= 609 then
        return
    end
    player:RegisterEvent(DK.teleportCheck, 2000, 1)
end

function DK.teleportCheck(eventID, delay, repeats, player)
    if player:GetMapId() ~= 609 or player:GetZoneId() ~= 4298 then
        return
    end

    local x, y, z, o = player:GetLocation()

    if     x > 1289.40 and x < 1309.79 and
           y > -6166.92 and y < -6125.28 and
           z > 13.99 and z < 14.21 then
        player:Teleport(571, 2473.49, -426.06, 2.91, 0.07)
        return

    elseif x > 1781.35 and x < 1801.34 and
           y > -4875.36 and y < -4867.02 and
           z > 88.45 and z < 89.94 then
        player:Teleport(0, 1786.73, -4878.47, 87.49, 1.34)
        return

    elseif x > 2043.25 and x < 2303.61 and
           y > -6224.11 and y < -6150.62 and
           z > -1.41 and z < 1.14 then
        player:Teleport(571, 2473.49, -426.06, 2.91, 0.07)
        return
    end

    player:RegisterEvent(DK.teleportCheck, 2000, 1)
end

local PLAYER_EVENT_ON_FIRST_LOGIN = 30
local PLAYER_EVENT_ON_LOGIN       = 3
RegisterPlayerEvent(PLAYER_EVENT_ON_FIRST_LOGIN, DK.onFirstLogin)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, DK.onLogin)
