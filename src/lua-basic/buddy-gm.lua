--------------------------------------------------------------------------------
-- buddy-gm.lua (issue 617e; game masters' tools for a partner's buddies)
--
-- For a general audience: three commands for game masters, typed in game
-- or (with a name) on the server console:
--
--   .buddies to partner [name] [ring|centre]
--        every one of the partner's buddies in the world is brought to the
--        partner;
--   .buddies to me [name] [ring|centre]
--        ... brought to the game master instead;
--   .buddies revive [name] at me|partner|graveyard [ring|centre]
--        every dead one is brought back to life at the game master, the
--        partner, or the graveyard nearest the partner (one their side may
--        use).
--
-- No name: the game master's selected target (the partner, or one of their
-- buddies). They are placed round the anchor by lib/buddy-arc.lua: on a
-- ring the anchor is part of, or on an arc with the anchor in the middle
-- (ring three times in four unless asked). The owner, 2026-10-04: "can we
-- add a command for gms that teleport all of a target player's buddy-bots
-- to them, and also, another one that teleports all of the target
-- player's buddy-bots to them, the GM? also another gm command that
-- revives all of a target player's buddy-bots, both with options to revive
-- them at the GM's location, the player-partner's location, and the
-- nearest graveyard." (Replaces the one-off ".buddies here" of the same day.)
--------------------------------------------------------------------------------

local PLAYER_EVENT_ON_COMMAND = 42
local GM_RANK = 2                    -- game masters only
local TAG     = "[buddies] "
local TEAM_ALLIANCE = 0
-- graveyard_zone.Faction: who may use a graveyard (0: everyone)
local GRAVEYARD_FACTION = { [TEAM_ALLIANCE] = 469, [1] = 67 }

-- {{{ local function script_dir
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
-- }}}

local Arc = dofile(script_dir() .. "lib/buddy-arc.lua")

-- {{{ local function roster_of
-- The partner's registered buddies, by slot: a list of character guids
-- (low part, integers). Its length is the n the placing counts.
local function roster_of(partner_low)
    local list = {}
    local q = CharDBQuery("SELECT buddy FROM buddy_roster WHERE owner = " .. partner_low .. " AND buddy <> 0 ORDER BY slot")
    if q then repeat list[#list + 1] = q:GetUInt32(0) until not q:NextRow() end
    return list
end
-- }}}

-- {{{ local function partner_of_buddy
-- A selected buddy stands for its partner: the partner's guid, or nil.
local function partner_of_buddy(low)
    local q = CharDBQuery("SELECT owner FROM buddy_roster WHERE buddy = " .. low)
    return q and q:GetUInt32(0) or nil
end
-- }}}

-- {{{ local function nearest_graveyard
-- The graveyard on the partner's map nearest them that their side may use:
-- x, y, z, or nil. (game_graveyard: where; graveyard_zone: who may use it.)
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
-- }}}

-- {{{ local function place
-- Puts the listed buddies (players in the world) round an anchor on map
-- `map_id`, each at its roster index's place. `revive`: bring the dead to
-- life first (and only them); otherwise the dead are left where they lie.
-- Returns how many were placed and lines about the rest.
local function place(roster, buddies, map, map_id, ax, ay, az, ao, shape, revive)
    local spots = Arc.places(ax, ay, ao, #roster, shape)
    local moved, notes = 0, {}
    for i, guid in ipairs(roster) do
        local b = buddies[guid]
        if not b then
            notes[#notes + 1] = string.format("character %d: not in the world", guid)
        elseif revive and not b:IsDead() then
            -- revive moves only the dead; the living stay where they are
        elseif not revive and b:IsDead() then
            notes[#notes + 1] = b:GetName() .. ": dead, left where it lies (use .buddies revive)"
        else
            if revive then b:ResurrectPlayer(100, false) end
            local s = spots[i]
            local z = map:GetHeight(s.x, s.y)
            if not z or math.abs(z - az) > 5 then z = az end   -- no ground found, or a ledge: the anchor's height
            b:Teleport(map_id, s.x, s.y, z, s.o)
            moved = moved + 1
        end
    end
    return moved, notes
end
-- }}}

-- {{{ local function run
-- `gm`: the game master (nil on the console); `words`: the command after
-- "buddies"; `say`: prints a line back.
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

    -- the partner: by name, or the selected target (a buddy stands for its partner)
    local partner
    if name then
        partner = GetPlayerByName(name:sub(1, 1):upper() .. name:sub(2):lower())
    elseif gm then
        local sel = gm:GetSelection()
        if sel and sel:GetTypeId() == 4 then                      -- a player (TYPEID_PLAYER)
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

    -- the anchor
    local anchor, map, map_id, ax, ay, az, ao
    if dest == "graveyard" then
        ax, ay, az = nearest_graveyard(partner)
        if not ax then return say(TAG .. "no graveyard " .. partner:GetName() .. "'s side may use on map " .. partner:GetMapId()) end
        map, map_id = partner:GetMap(), partner:GetMapId()
        local px, py = partner:GetLocation()
        ao = math.atan2(py - ay, px - ax) % (2 * math.pi)        -- the arc faces the partner
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
-- }}}

-- {{{ local function on_command
local function on_command(event, player, command, handler)
    local words = command:match("^buddies%s+(.+)$")
    if not words then return end
    if player and player:GetGMRank() < GM_RANK then return end
    local say = player and function(text) player:SendBroadcastMessage(text) end
                        or function(text) handler:SendSysMessage(text) end
    run(player, words:lower(), say)
    return false
end
-- }}}

RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, on_command)
