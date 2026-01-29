--[[

local function InitialLogin(event, player)
    player:SetInt32Value(0, math.random())
    player:SendBroadcastMessage(player:GetInt32Value(0))
end

local PLAYER_EVENT_ON_LOGIN = 3
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, InitialLogin)

--]]
