--------------------------------------------------------------------------------
-- legendaries.lua (issue 182) - Atiesh becomes its bearer's own staff
--
-- For a general audience: Atiesh comes in four versions, one each for
-- mages, warlocks, priests and druids. On basic one Atiesh drops (the item
-- scripts/generate-basic-legendaries-sql makes, 1820001), and it turns into
-- the version for the class of whoever takes it (owner, 2026-10-08: "we
-- could drop a dummy item that, upon being looted, automatically transforms
-- into the correct variant of the four"). Any other class keeps it as it
-- is, unbound, so it can be traded to a caster, and it turns when the caster
-- has it ("It stays the generic Atiesh, which they can trade to a caster,
-- and it changes when the caster picks it up").
--
-- When it is checked: on looting, on any new item stored, at login, when
-- the staff is equipped, and for two minutes after a trade window opens
-- (the Lua engine has no "trade finished" event, so both traders are looked
-- at every 3 seconds until then).
--------------------------------------------------------------------------------

local PLAYER_EVENT_ON_LOGIN          = 3
local PLAYER_EVENT_ON_EQUIP          = 29
local PLAYER_EVENT_ON_LOOT_ITEM      = 32
local PLAYER_EVENT_ON_CAN_INIT_TRADE = 48
local PLAYER_EVENT_ON_STORE_NEW_ITEM = 53

local ATIESH_DUMMY    = 1820001                     -- the generic staff (generate-basic-legendaries-sql)
local ATIESH_BY_CLASS = {                           -- class id -> its stock Atiesh (by their Power of the Guardian auras)
    [8]  = 22589,                                   -- mage
    [9]  = 22630,                                   -- warlock
    [5]  = 22631,                                   -- priest
    [11] = 22632,                                   -- druid
}
local TRADE_WATCH_MS, TRADE_WATCH_EVERY_MS = 120000, 3000

-- {{{ local function turn
-- If the player holds the generic staff and has a version of its own, the
-- staff becomes that version. Returns true when it turned.
local function turn(player)
    local version = ATIESH_BY_CLASS[player:GetClass()]
    if not version then return false end             -- not a caster with an Atiesh: it stays as it is
    if not player:HasItem(ATIESH_DUMMY, 1, true) then return false end
    player:RemoveItem(ATIESH_DUMMY, 1)
    if not player:AddItem(version, 1) then
        -- no room: the generic staff comes back, so nothing is lost
        player:AddItem(ATIESH_DUMMY, 1)
        player:SendBroadcastMessage("Atiesh stirs, but your bags are full. Make room and it will take its true shape.")
        print("[legendaries] " .. player:GetName() .. ": Atiesh could not turn (bags full); the generic staff kept")
        return false
    end
    player:SendBroadcastMessage("Atiesh, Greatstaff of the Guardian, takes the shape it has for you.")
    return true
end
-- }}}

-- {{{ events
-- a moment after the event, so the item is in the bags before it is swapped
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
-- }}}

-- for scripts/test-basic-legendaries
return { turn = turn, ATIESH_DUMMY = ATIESH_DUMMY, ATIESH_BY_CLASS = ATIESH_BY_CLASS }
