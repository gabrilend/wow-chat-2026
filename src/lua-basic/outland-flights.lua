
local GOSSIP_EVENT_ON_HELLO  = 1
local GOSSIP_EVENT_ON_SELECT = 2
local GOSSIP_ICON_TAXI       = 2
local TEAM_ALLIANCE          = 0

local MOUNT_GRYPHON    = 541
local MOUNT_WIND_RIDER = 2224

local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end

local WAYPOINTS = dofile(script_dir() .. "data/outland-flight-paths.lua")

local PATH = {}
for name, points in pairs(WAYPOINTS) do
    PATH[name] = AddTaxiPath(points, MOUNT_GRYPHON, MOUNT_WIND_RIDER, 0)
end

local MASTERS = {
    [18931] = { label = "Fly to Honor Hold.",                   route = "portal_to_honor_hold" },
    [16822] = { label = "Fly to the Dark Portal.",              route = "honor_hold_to_portal" },
    [18930] = { label = "Fly to Thrallmar.",                    route = "portal_to_thrallmar" },
    [16587] = { label = "Fly to the Dark Portal.",              route = "thrallmar_to_portal" },
    [12617] = { label = "Fly to the Isle of Quel'Danas.",       route = "lights_hope_to_isle_a" },
    [12636] = { label = "Fly to the Isle of Quel'Danas.",       route = "lights_hope_to_isle_h" },
    [26560] = { label = "Fly to Light's Hope Chapel.",          route = { "isle_to_lights_hope_a", "isle_to_lights_hope_h" } },
}

local function route_for(master, player)
    if type(master.route) == "table" then
        return (player:GetTeam() == TEAM_ALLIANCE) and master.route[1] or master.route[2]
    end
    return master.route
end

local HEADER = {}
local function header_text(entry)
    if HEADER[entry] == nil then
        HEADER[entry] = 100
        local q = WorldDBQuery("SELECT g.TextID FROM creature_template t JOIN gossip_menu g ON g.MenuID = t.gossip_menu_id WHERE t.entry = " .. entry .. " LIMIT 1")
        if q then HEADER[entry] = q:GetUInt32(0) end
    end
    return HEADER[entry]
end

local function on_hello(event, player, creature)
    local master = MASTERS[creature:GetEntry()]
    player:GossipClearMenu()
    player:GossipMenuAddItem(GOSSIP_ICON_TAXI, master.label, 0, 1)
    player:GossipSendMenu(header_text(creature:GetEntry()), creature)
    return true
end

local function on_select(event, player, creature, sender, intid)
    player:GossipComplete()
    local route = route_for(MASTERS[creature:GetEntry()], player)
    local path = PATH[route]
    if not path then
        player:SendBroadcastMessage("This flight is not available (route '" .. tostring(route) .. "' missing; re-run scripts/generate-basic-outland-flights).")
        return true
    end
    player:StartTaxi(path)
    return true
end

for entry in pairs(MASTERS) do
    RegisterCreatureGossipEvent(entry, GOSSIP_EVENT_ON_HELLO, on_hello)
    RegisterCreatureGossipEvent(entry, GOSSIP_EVENT_ON_SELECT, on_select)
end
