--------------------------------------------------------------------------------
-- titan-jewelers.lua (issue 155p, stage 2)
--
-- The titan-site Earthen (spawned by sql/basic/db_world.src/19-titan-jewelers,
-- E034) need two behaviours the database can't express:
--
--   1. the Earthen Crystal-Keeper's trade: hand over one Nexus Crystal (what
--      disenchanting an Azeroth epic gives), get one random uncut Wrath gem,
--      uncommon, now and then rare. Ritz, 2026-09-25: "let's say it's an
--      uncommon Wrath gem, with a small chance to be a rare."
--   2. the Un'Goro pair's wandering between the Crystal Pylons. Ritz,
--      2026-09-25: "every 30 minutes, if there are no players within sight,
--      say... 200 yards, then they swap to a different, random one. They both
--      travel as a group." / "Actually how about we just make it so that it's
--      a 50/50 chance each time they swap". Each pylon's pair is a game event
--      of the "internal" kind (201 northern, 202 western, 203 eastern), which
--      the server never starts or stops on its own; this script starts one at
--      boot and swaps between them. A game event spawns and removes its
--      creatures whether or not anyone is nearby, where moving the creatures
--      themselves would fail once their part of the map has unloaded.
--
-- (The Earthen Gemcutter is an ordinary trainer; the database handles it.)
--------------------------------------------------------------------------------

local GOSSIP_EVENT_ON_HELLO  = 1
local GOSSIP_EVENT_ON_SELECT = 2
local WORLD_EVENT_ON_STARTUP = 14
local GOSSIP_ICON_MONEY      = 6

local CRYSTAL_KEEPER = 1550210           -- Earthen Crystal-Keeper <Crystal Trader>
local NEXUS_CRYSTAL  = 20725
local GREETING_TEXT  = 1553000           -- npc_text, from 19-titan-jewelers
local RARE_CHANCE    = 10                -- percent; a default, logged in docs/balance-updates.md

-- uncut Wrath gems, one of each colour (the stock raw gems)
local WRATH_UNCOMMON = { 36917, 36920, 36923, 36926, 36929, 36932 }   -- Bloodstone, Sun Crystal, Chalcedony, Shadow Crystal, Huge Citrine, Dark Jade
local WRATH_RARE     = { 36918, 36921, 36924, 36927, 36930, 36933 }   -- Scarlet Ruby, Autumn's Glow, Sky Sapphire, Twilight Opal, Monarch Topaz, Forest Emerald

-- the Un'Goro pylons: event, and the guid of the pair's first spawn there
-- (its position, read at startup, is where "nearby" is measured from)
local PYLONS = {
    { event = 201, guid = 15501015 },    -- Northern Crystal Pylon
    { event = 202, guid = 15501017 },    -- Western Crystal Pylon
    { event = 203, guid = 15501019 },    -- Eastern Crystal Pylon
}
local UNGORO_MAP       = 1
local SWAP_EVERY_MS    = 30 * 60 * 1000
local NEARBY_YARDS     = 200

-- {{{ local function on_hello
local function on_hello(event, player, creature)
    player:GossipClearMenu()
    if player:GetItemCount(NEXUS_CRYSTAL) > 0 then
        player:GossipMenuAddItem(GOSSIP_ICON_MONEY, "Trade a Nexus Crystal for an uncut gem.", 0, 1)
    end
    player:GossipSendMenu(GREETING_TEXT, creature)
end
-- }}}

-- {{{ local function on_select
-- One crystal out, one gem in; a full bag gives the crystal back.
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
-- }}}

-- {{{ local function pylon_positions
-- Where each pylon's pair stands, from the creature table (so the spots
-- live in one place: the generator that wrote the SQL). Read once.
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
-- }}}

-- {{{ local function current_pylon
local function current_pylon()
    for i, p in ipairs(PYLONS) do
        if IsGameEventActive(p.event) then return i end
    end
    return nil
end
-- }}}

-- {{{ local function anyone_near
local function anyone_near(p)
    for _, player in ipairs(GetPlayersInWorld() or {}) do
        if player:GetMapId() == UNGORO_MAP then
            local dx, dy = player:GetX() - p.x, player:GetY() - p.y
            if dx * dx + dy * dy < NEARBY_YARDS * NEARBY_YARDS then return true end
        end
    end
    return false
end
-- }}}

-- {{{ local function swap
-- Every 30 minutes: stay while someone is near, else move to one of the other
-- two pylons, 50% each. With none running (a fresh boot), start one at random.
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
-- }}}

-- {{{ local function on_startup
-- After a restart no pylon event runs: place the pair at once rather than
-- after the first 30 minutes.
local function on_startup()
    swap()
end
-- }}}

RegisterCreatureGossipEvent(CRYSTAL_KEEPER, GOSSIP_EVENT_ON_HELLO,  on_hello)
RegisterCreatureGossipEvent(CRYSTAL_KEEPER, GOSSIP_EVENT_ON_SELECT, on_select)
RegisterServerEvent(WORLD_EVENT_ON_STARTUP, on_startup)
-- the 30-minute timer is registered at load, so a Lua reload (which doesn't
-- fire the startup event again) keeps the pair wandering
CreateLuaEvent(swap, SWAP_EVERY_MS, 0)
