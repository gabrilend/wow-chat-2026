--------------------------------------------------------------------------------
-- outland-flights.lua (issue 155l)
--
-- Basic turns every flight master off (vanilla's flight-path removal, E008,
-- shared). This script brings back a few flights as fixed routes, offered
-- as a line in the flight master's dialogue, that need no discovered
-- destinations:
--
--   the Dark Portal  <-> Honor Hold  (Alliance)
--   the Dark Portal  <-> Thrallmar   (Horde)
--   Light's Hope Chapel <-> the Isle of Quel'Danas (both factions; the only
--   way onto the Isle once the Shattrath portal is removed)
--
-- Ritz, 2026-09-24: "let's make sure that the players can have the first
-- flight path to Thrallmar and Honor Hold, otherwise they'll be stuck by the
-- dark portal since right by the dark portal it's mostly elites." / "The Dark
-- Portal flights also go back." / "I still want to force players to fly
-- there because I'm evil >:)" / "That is the only flight path to them then.
-- I love how it's in the highest level zone on Azeroth, too."
--
-- The Horde's Light's Hope master stands at the chapel's Horde node, which
-- has no direct path to the Isle; its route is the client's two legs via
-- Zul'Aman joined into one (14,007 yards against the Alliance's direct
-- 13,772), so neither faction gets a quick flight.
--
-- The routes' waypoints are generated (scripts/generate-basic-outland-flights)
-- into data/outland-flight-paths.lua, loaded here with dofile. Paths are
-- built once at startup with AddTaxiPath, free of charge.
--------------------------------------------------------------------------------

local GOSSIP_EVENT_ON_HELLO  = 1
local GOSSIP_EVENT_ON_SELECT = 2
local GOSSIP_ICON_TAXI       = 2
local TEAM_ALLIANCE          = 0

local MOUNT_GRYPHON    = 541    -- Riding Gryphon (Alliance flight mount creature)
local MOUNT_WIND_RIDER = 2224   -- Wind Rider (Horde flight mount creature)

-- {{{ local function script_dir
-- The directory this file sits in, so the data file is found wherever the
-- lua_scripts tree is linked from.
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
-- }}}

local WAYPOINTS = dofile(script_dir() .. "data/outland-flight-paths.lua")

-- route name -> taxi path id, filled at startup
local PATH = {}
for name, points in pairs(WAYPOINTS) do
    PATH[name] = AddTaxiPath(points, MOUNT_GRYPHON, MOUNT_WIND_RIDER, 0)
end

-- flight master creature entry -> the route(s) it offers.
-- label: the dialogue line; route: fixed, or per team {alliance, horde}
local MASTERS = {
    [18931] = { label = "Fly to Honor Hold.",                   route = "portal_to_honor_hold" },   -- Amish Wildhammer, the Dark Portal
    [16822] = { label = "Fly to the Dark Portal.",              route = "honor_hold_to_portal" },   -- Flightmaster Krill Bitterhue, Honor Hold
    [18930] = { label = "Fly to Thrallmar.",                    route = "portal_to_thrallmar" },    -- Vlagga Freyfeather, the Dark Portal
    [16587] = { label = "Fly to the Dark Portal.",              route = "thrallmar_to_portal" },    -- Barley, Thrallmar
    [12617] = { label = "Fly to the Isle of Quel'Danas.",       route = "lights_hope_to_isle_a" },  -- Khaelyn Steelwing, Light's Hope (Alliance)
    [12636] = { label = "Fly to the Isle of Quel'Danas.",       route = "lights_hope_to_isle_h" },  -- Georgia, Light's Hope (Horde)
    [26560] = { label = "Fly to Light's Hope Chapel.",          route = { "isle_to_lights_hope_a", "isle_to_lights_hope_h" } },  -- Ohura, the Isle (neutral)
}

-- {{{ local function route_for
-- The route name a master offers this player.
local function route_for(master, player)
    if type(master.route) == "table" then
        return (player:GetTeam() == TEAM_ALLIANCE) and master.route[1] or master.route[2]
    end
    return master.route
end
-- }}}

-- {{{ local function header_text
-- The dialogue's header text: the master's own (E008 gave each former flight
-- master a flavor text explaining why the birds aren't flying), else the
-- stock greeting (100).
local HEADER = {}
local function header_text(entry)
    if HEADER[entry] == nil then
        HEADER[entry] = 100
        local q = WorldDBQuery("SELECT g.TextID FROM creature_template t JOIN gossip_menu g ON g.MenuID = t.gossip_menu_id WHERE t.entry = " .. entry .. " LIMIT 1")
        if q then HEADER[entry] = q:GetUInt32(0) end
    end
    return HEADER[entry]
end
-- }}}

-- {{{ local function on_hello
local function on_hello(event, player, creature)
    local master = MASTERS[creature:GetEntry()]
    player:GossipClearMenu()
    player:GossipMenuAddItem(GOSSIP_ICON_TAXI, master.label, 0, 1)
    player:GossipSendMenu(header_text(creature:GetEntry()), creature)
    return true
end
-- }}}

-- {{{ local function on_select
local function on_select(event, player, creature, sender, intid)
    player:GossipComplete()
    local route = route_for(MASTERS[creature:GetEntry()], player)
    local path = PATH[route]
    if not path then
        -- the data file lacks this route: say so rather than fly nowhere
        player:SendBroadcastMessage("This flight is not available (route '" .. tostring(route) .. "' missing; re-run scripts/generate-basic-outland-flights).")
        return true
    end
    player:StartTaxi(path)
    return true
end
-- }}}

for entry in pairs(MASTERS) do
    RegisterCreatureGossipEvent(entry, GOSSIP_EVENT_ON_HELLO, on_hello)
    RegisterCreatureGossipEvent(entry, GOSSIP_EVENT_ON_SELECT, on_select)
end
