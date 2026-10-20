
local PLAYER_EVENT_ON_COMMAND = 42
local GM_RANK = 2
local TAG     = "[buddies] "
local TEAM_ALLIANCE = 0
local GRAVEYARD_FACTION = { [TEAM_ALLIANCE] = 469, [1] = 67 }

local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end

local Arc = dofile(script_dir() .. "lib/buddy-arc.lua")

local function roster_of(partner_low)
    local list = {}
    local q = CharDBQuery("SELECT buddy FROM buddy_roster WHERE owner = " .. partner_low .. " AND buddy <> 0 ORDER BY slot")
    if q then repeat list[#list + 1] = q:GetUInt32(0) until not q:NextRow() end
    return list
end

local function partner_of_buddy(low)
    local q = CharDBQuery("SELECT owner FROM buddy_roster WHERE buddy = " .. low)
    return q and q:GetUInt32(0) or nil
end

local function nearest_graveyard(partner)
    local px, py = partner:GetLocation()
    local q = WorldDBQuery(string.format(
        "SELECT g.x, g.y, g.z FROM game_graveyard g JOIN graveyard_zone z ON z.ID = g.ID " ..
        "WHERE g.Map = %d AND z.Faction IN (0, %d) GROUP BY g.ID, g.x, g.y, g.z " ..
        "ORDER BY POW(g.x - (%f), 2) + POW(g.y - (%f), 2) LIMIT 1",
        partner:GetMapId(), GRAVEYARD_FACTION[partner:GetTeam()] or 0, px, py))
    if not q then return nil end
    return q:GetFloat(0), q:GetFloat(1), q:GetFloat(2)
end

local function place(roster, buddies, map, map_id, ax, ay, az, ao, shape, revive)
    local spots = Arc.places(ax, ay, ao, #roster, shape)
    local moved, notes = 0, {}
    for i, guid in ipairs(roster) do
        local b = buddies[guid]
        if not b then
            notes[#notes + 1] = string.format("character %d: not in the world", guid)
        elseif revive and not b:IsDead() then
        elseif not revive and b:IsDead() then
            notes[#notes + 1] = b:GetName() .. ": dead, left where it lies (use .buddies revive)"
        else
            if revive then b:ResurrectPlayer(100, false) end
            local s = spots[i]
            local z = map:GetHeight(s.x, s.y)
            if not z or math.abs(z - az) > 5 then z = az end
            b:Teleport(map_id, s.x, s.y, z, s.o)
            moved = moved + 1
        end
    end
    return moved, notes
end

local function run(gm, words, say)
    local verb, rest = words:match("^(%a+)%s*(.*)$")
    local dest, name, shape
    if verb == "to" then
        dest, rest = rest:match("^(%a+)%s*(.*)$")
    elseif verb == "revive" then
        local before, at = rest:match("^(.-)%s*at%s+(%a+).*$")
        if not at then return say(TAG .. "revive needs where: .buddies revive [name] at me|partner|graveyard [ring|centre]") end
        dest, rest = at, before .. " " .. (rest:match("at%s+%a+%s*(.*)$") or "")
    else
        return say(TAG .. "commands: .buddies to partner [name] | .buddies to me [name] | .buddies revive [name] at me|partner|graveyard; each may end in ring or centre")
    end
    for word in (rest or ""):gmatch("%a+") do
        if word == "ring" or word == "centre" or word == "center" then shape = (word == "ring") and "ring" or "centre"
        elseif not name then name = word end
    end
    if dest ~= "me" and dest ~= "partner" and not (verb == "revive" and dest == "graveyard") then
        return say(TAG .. "where to? me or partner" .. (verb == "revive" and " or graveyard" or ""))
    end
    if dest == "me" and not gm then return say(TAG .. "\"me\" needs a game master in the world (not the console)") end

    local partner
    if name then
        partner = GetPlayerByName(name:sub(1, 1):upper() .. name:sub(2):lower())
    elseif gm then
        local sel = gm:GetSelection()
        if sel and sel:GetTypeId() == 4 then
            local low = sel:GetGUIDLow()
            local owner = partner_of_buddy(low)
            partner = owner and GetPlayerByGUID(GetPlayerGUID(owner)) or sel
        end
    end
    if not partner or not partner:IsInWorld() then
        return say(TAG .. "no partner: give a name, or select the partner (or one of their buddies); they must be in the world")
    end
    local roster = roster_of(partner:GetGUIDLow())
    if #roster == 0 then return say(TAG .. partner:GetName() .. " has no buddies in the roster") end
    local buddies = {}
    for _, guid in ipairs(roster) do
        local b = GetPlayerByGUID(GetPlayerGUID(guid))
        if b and b:IsInWorld() then buddies[guid] = b end
    end

    local anchor, map, map_id, ax, ay, az, ao
    if dest == "graveyard" then
        ax, ay, az = nearest_graveyard(partner)
        if not ax then return say(TAG .. "no graveyard " .. partner:GetName() .. "'s side may use on map " .. partner:GetMapId()) end
        map, map_id = partner:GetMap(), partner:GetMapId()
        local px, py = partner:GetLocation()
        ao = math.atan2(py - ay, px - ax) % (2 * math.pi)
    else
        anchor = dest == "me" and gm or partner
        map, map_id = anchor:GetMap(), anchor:GetMapId()
        ax, ay, az, ao = anchor:GetLocation()
    end
    shape = Arc.pick_shape(shape, math.random())
    local moved, notes = place(roster, buddies, map, map_id, ax, ay, az, ao, shape, verb == "revive")
    for _, line in ipairs(notes) do say(TAG .. line) end
    say(string.format("%s%d of %s's %d buddies %s %s (%s)", TAG, moved, partner:GetName(), #roster,
        verb == "revive" and "revived at" or "moved to",
        dest == "me" and "you" or dest == "partner" and partner:GetName() or "the nearest graveyard", shape))
end

local function on_command(event, player, command, handler)
    local words = command:match("^buddies%s+(.+)$")
    if not words then return end
    if player and player:GetGMRank() < GM_RANK then return end
    local say = player and function(text) player:SendBroadcastMessage(text) end
                        or function(text) handler:SendSysMessage(text) end
    run(player, words:lower(), say)
    return false
end

RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, on_command)
