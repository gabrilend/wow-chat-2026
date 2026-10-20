
local PLAYER_EVENT_ON_LOGIN          = 3
local PLAYER_EVENT_ON_EQUIP          = 29
local PLAYER_EVENT_ON_LOOT_ITEM      = 32
local PLAYER_EVENT_ON_CAN_INIT_TRADE = 48
local PLAYER_EVENT_ON_STORE_NEW_ITEM = 53

local ATIESH_DUMMY    = 1820001
local ATIESH_BY_CLASS = {
    [8]  = 22589,
    [9]  = 22630,
    [5]  = 22631,
    [11] = 22632,
}
local TRADE_WATCH_MS, TRADE_WATCH_EVERY_MS = 120000, 3000

local function turn(player)
    local version = ATIESH_BY_CLASS[player:GetClass()]
    if not version then return false end
    if not player:HasItem(ATIESH_DUMMY, 1, true) then return false end
    player:RemoveItem(ATIESH_DUMMY, 1)
    if not player:AddItem(version, 1) then
        player:AddItem(ATIESH_DUMMY, 1)
        player:SendBroadcastMessage("Atiesh stirs, but your bags are full. Make room and it will take its true shape.")
        print("[legendaries] " .. player:GetName() .. ": Atiesh could not turn (bags full); the generic staff kept")
        return false
    end
    player:SendBroadcastMessage("Atiesh, Greatstaff of the Guardian, takes the shape it has for you.")
    return true
end

local function soon(player)
    player:RegisterEvent(function(_, _, _, p) turn(p) end, 200, 1)
end

local function on_item(event, player, item)
    if item and item:GetEntry() == ATIESH_DUMMY then soon(player) end
end

local function on_trade(event, player, target)
    for _, p in ipairs({ player, target }) do
        if p then p:RegisterEvent(function(_, _, _, pp) turn(pp) end, TRADE_WATCH_EVERY_MS, TRADE_WATCH_MS / TRADE_WATCH_EVERY_MS) end
    end
end

RegisterPlayerEvent(PLAYER_EVENT_ON_LOOT_ITEM, on_item)
RegisterPlayerEvent(PLAYER_EVENT_ON_STORE_NEW_ITEM, on_item)
RegisterPlayerEvent(PLAYER_EVENT_ON_EQUIP, on_item)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, function(event, player) soon(player) end)
RegisterPlayerEvent(PLAYER_EVENT_ON_CAN_INIT_TRADE, on_trade)

return { turn = turn, ATIESH_DUMMY = ATIESH_DUMMY, ATIESH_BY_CLASS = ATIESH_BY_CLASS }
