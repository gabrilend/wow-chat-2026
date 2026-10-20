
local GOSSIP_EVENT_ON_HELLO  = 1
local GOSSIP_EVENT_ON_SELECT = 2
local WORLD_EVENT_ON_STARTUP = 14
local GOSSIP_ICON_MONEY      = 6

local CRYSTAL_KEEPER = 1550210
local NEXUS_CRYSTAL  = 20725
local GREETING_TEXT  = 1553000
local RARE_CHANCE    = 10

local WRATH_UNCOMMON = { 36917, 36920, 36923, 36926, 36929, 36932 }
local WRATH_RARE     = { 36918, 36921, 36924, 36927, 36930, 36933 }

local PYLONS = {
    { event = 201, guid = 15501015 },
    { event = 202, guid = 15501017 },
    { event = 203, guid = 15501019 },
}
local UNGORO_MAP       = 1
local SWAP_EVERY_MS    = 30 * 60 * 1000
local NEARBY_YARDS     = 200

local function on_hello(event, player, creature)
    player:GossipClearMenu()
    if player:GetItemCount(NEXUS_CRYSTAL) > 0 then
        player:GossipMenuAddItem(GOSSIP_ICON_MONEY, "Trade a Nexus Crystal for an uncut gem.", 0, 1)
    end
    player:GossipSendMenu(GREETING_TEXT, creature)
end

local function on_select(event, player, creature, sender, intid)
    player:GossipComplete()
    if intid ~= 1 or player:GetItemCount(NEXUS_CRYSTAL) < 1 then return end
    local pool = (math.random(100) <= RARE_CHANCE) and WRATH_RARE or WRATH_UNCOMMON
    local gem  = pool[math.random(#pool)]
    player:RemoveItem(NEXUS_CRYSTAL, 1)
    if not player:AddItem(gem, 1) then
        player:AddItem(NEXUS_CRYSTAL, 1)
        player:SendBroadcastMessage("Your bags are full; the Crystal-Keeper hands your crystal back.")
    end
end

local positions_read = false
local function pylon_positions()
    if positions_read then return true end
    for _, p in ipairs(PYLONS) do
        local q = WorldDBQuery("SELECT position_x, position_y FROM creature WHERE guid = " .. p.guid)
        if not q then
            print("[titan-jewelers] ERROR: spawn " .. p.guid .. " missing; is 19-titan-jewelers applied? The Un'Goro pair will not wander.")
            return false
        end
        p.x, p.y = q:GetFloat(0), q:GetFloat(1)
    end
    positions_read = true
    return true
end

local function current_pylon()
    for i, p in ipairs(PYLONS) do
        if IsGameEventActive(p.event) then return i end
    end
    return nil
end

local function anyone_near(p)
    for _, player in ipairs(GetPlayersInWorld() or {}) do
        if player:GetMapId() == UNGORO_MAP then
            local dx, dy = player:GetX() - p.x, player:GetY() - p.y
            if dx * dx + dy * dy < NEARBY_YARDS * NEARBY_YARDS then return true end
        end
    end
    return false
end

local function swap()
    if not pylon_positions() then return end
    local now = current_pylon()
    if not now then
        StartGameEvent(PYLONS[math.random(#PYLONS)].event, true)
        return
    end
    if anyone_near(PYLONS[now]) then return end
    local next_one = ((now - 1 + math.random(2)) % #PYLONS) + 1
    StopGameEvent(PYLONS[now].event, true)
    StartGameEvent(PYLONS[next_one].event, true)
end

local function on_startup()
    swap()
end

RegisterCreatureGossipEvent(CRYSTAL_KEEPER, GOSSIP_EVENT_ON_HELLO,  on_hello)
RegisterCreatureGossipEvent(CRYSTAL_KEEPER, GOSSIP_EVENT_ON_SELECT, on_select)
RegisterServerEvent(WORLD_EVENT_ON_STARTUP, on_startup)
CreateLuaEvent(swap, SWAP_EVERY_MS, 0)
