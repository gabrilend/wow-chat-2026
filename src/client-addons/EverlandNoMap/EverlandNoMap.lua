
local MAP_PLACES = {
    ["Blasted Lands"]       = { ["The Dark Portal"] = true },
    ["Hellfire Peninsula"]  = { ["The Stair of Destiny"] = true },
    ["Stormwind City"]      = { ["Stormwind Keep"] = true },
    ["Ironforge"]           = { ["The High Seat"] = true },
    ["Darnassus"]           = { ["The Temple of the Moon"] = true },
    ["The Exodar"]          = { ["The Vault of Lights"] = true },
    ["Orgrimmar"]           = { ["Grommash Hold"] = true },
    ["Thunder Bluff"]       = { ["The High Rise"] = true },
    ["Undercity"]           = { ["The Royal Quarter"] = true },
    ["Silvermoon City"]     = { ["Sunfury Spire"] = true },
}

local function map_kept_here()
    local subs = MAP_PLACES[GetRealZoneText() or ""]
    if not subs then return false end
    return subs["*"] or subs[GetSubZoneText() or ""] or false
end

local function say(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffc8a060Everland:|r " .. text)
end

local told = false
local function close_unless_kept(frame)
    if map_kept_here() then return end
    if frame == WorldMapFrame then HideUIPanel(WorldMapFrame) else frame:Hide() end
    if not told then
        say("there is no map here. Maps are kept at planning tables: the throne rooms, the Dark Portal.")
        told = true
    end
end

local function hide_minimap()
    MinimapCluster:Hide()
    MinimapCluster:SetScript("OnShow", MinimapCluster.Hide)
end

local frame = CreateFrame("Frame")

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

SLASH_EVERLANDNOMAP1 = "/nomap"
SlashCmdList.EVERLANDNOMAP = function(msg)
    if msg == "where" then
        say(string.format('zone "%s", sub-zone "%s": %s', GetRealZoneText() or "", GetSubZoneText() or "",
            map_kept_here() and "a map is kept here" or "no map here"))
    else
        say("/nomap where - the zone and sub-zone you stand in, and whether a map is kept there")
    end
end
