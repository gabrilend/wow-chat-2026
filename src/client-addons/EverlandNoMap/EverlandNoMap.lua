--------------------------------------------------------------------------------
-- EverlandNoMap.lua (issue 155y) - a client addon for the 3.3.5a game client
--
-- For a general audience: Everland Ghostsong is meant to be played without
-- a map. Players find their way by the land, the sky and what people say.
-- The server can't switch maps off (the client draws them from its own
-- files), so this addon does it on the player's machine. It is offered on
-- the project's website as the intended way to play (owner, 2026-10-04),
-- not installed by any script.
--
--   the minimap  (top right, with its tracking dots) is hidden, always;
--   the world map (M, the quest log's map button) and the zone map
--                (shift-M) close as soon as anything opens them, unless the
--                player stands where a map is kept: "unless you're at a
--                planning table or a map, like outside the Dark Portal or
--                in the throne rooms" (owner, 2026-10-04).
--
-- Where a map is kept is MAP_PLACES below: zone name -> sub-zone names, as
-- the client shows them (the text above the minimap, which is gone, so
-- "/nomap where" prints them). A place listed with sub-zone "*" counts
-- everywhere in that zone. If a map is open when the player walks out of
-- such a place, it closes.
--
-- Commands: "/nomap where" prints the zone and sub-zone you stand in and
-- whether a map is kept there.
--------------------------------------------------------------------------------

-- {{{ where a map is kept
-- Names are as the enUS client shows them. Several are not yet confirmed
-- in game (the owner checks with /nomap where and corrects them; issue
-- 155y, open questions).
local MAP_PLACES = {
    ["Blasted Lands"]       = { ["The Dark Portal"] = true },                -- outside the Dark Portal
    ["Hellfire Peninsula"]  = { ["The Stair of Destiny"] = true },           -- its other side
    ["Stormwind City"]      = { ["Stormwind Keep"] = true },
    ["Ironforge"]           = { ["The High Seat"] = true },
    ["Darnassus"]           = { ["The Temple of the Moon"] = true },
    ["The Exodar"]          = { ["The Vault of Lights"] = true },
    ["Orgrimmar"]           = { ["Grommash Hold"] = true },
    ["Thunder Bluff"]       = { ["The High Rise"] = true },
    ["Undercity"]           = { ["The Royal Quarter"] = true },
    ["Silvermoon City"]     = { ["Sunfury Spire"] = true },
}
-- }}}

-- {{{ local function map_kept_here
-- True when the player stands where a map is kept.
local function map_kept_here()
    local subs = MAP_PLACES[GetRealZoneText() or ""]
    if not subs then return false end
    return subs["*"] or subs[GetSubZoneText() or ""] or false
end
-- }}}

-- {{{ local function say
local function say(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffc8a060Everland:|r " .. text)
end
-- }}}

-- {{{ local function close_unless_kept
-- A map frame's show handler: closes it again unless a map is kept here.
-- The first close in a place says why; later ones are quiet.
local told = false
local function close_unless_kept(frame)
    if map_kept_here() then return end
    if frame == WorldMapFrame then HideUIPanel(WorldMapFrame) else frame:Hide() end
    if not told then
        say("there is no map here. Maps are kept at planning tables: the throne rooms, the Dark Portal.")
        told = true
    end
end
-- }}}

-- {{{ local function hide_minimap
-- The minimap and everything clustered round it (zone name, clock, mail and
-- tracking buttons) go together; the cluster is shown again by the default
-- interface on some events, so its show handler hides it each time.
local function hide_minimap()
    MinimapCluster:Hide()
    MinimapCluster:SetScript("OnShow", MinimapCluster.Hide)
end
-- }}}

local frame = CreateFrame("Frame")

-- {{{ events
-- PLAYER_LOGIN      hide the minimap, watch the world map
-- ADDON_LOADED      the zone map (shift-M) is its own addon, loaded the
--                   first time it's used: watch it then
-- ZONE_CHANGED*     walking out of a map place closes an open map
local handlers = {}

handlers.PLAYER_LOGIN = function()
    hide_minimap()
    WorldMapFrame:HookScript("OnShow", close_unless_kept)
    if BattlefieldMinimap then BattlefieldMinimap:HookScript("OnShow", close_unless_kept) end
end

handlers.ADDON_LOADED = function(name)
    if name == "Blizzard_BattlefieldMinimap" then
        BattlefieldMinimap:HookScript("OnShow", close_unless_kept)
    end
end

local function left_place()
    told = false
    if WorldMapFrame:IsShown() then close_unless_kept(WorldMapFrame) end
    if BattlefieldMinimap and BattlefieldMinimap:IsShown() then close_unless_kept(BattlefieldMinimap) end
end
handlers.ZONE_CHANGED          = left_place
handlers.ZONE_CHANGED_INDOORS  = left_place
handlers.ZONE_CHANGED_NEW_AREA = left_place

for event in pairs(handlers) do frame:RegisterEvent(event) end
frame:SetScript("OnEvent", function(_, event, ...) handlers[event](...) end)
-- }}}

-- {{{ /nomap
SLASH_EVERLANDNOMAP1 = "/nomap"
SlashCmdList.EVERLANDNOMAP = function(msg)
    if msg == "where" then
        say(string.format('zone "%s", sub-zone "%s": %s', GetRealZoneText() or "", GetSubZoneText() or "",
            map_kept_here() and "a map is kept here" or "no map here"))
    else
        say("/nomap where - the zone and sub-zone you stand in, and whether a map is kept there")
    end
end
-- }}}
