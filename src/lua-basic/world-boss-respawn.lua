--------------------------------------------------------------------------------
-- world-boss-respawn.lua (issue 155j)
--
-- The world bosses (Doom Lord Kazzak, Doomwalker, Azuregos, the Emerald
-- Dragons) come back when this script says so, not on the server's timer
-- (install step E046 sets that to a year). Owner, 2026-09-27: "Can we change
-- their respawn time to 2.5 hours? [...] slower if players are in the area"
-- / "manual spawning through lua".
--
-- Every 5 seconds, for each boss that is dead, one pass of its countdown
-- (lib/world-boss-countdown.lua): the time moves on and every player (not
-- bot) standing in the boss's area deposits a moment token; when the
-- countdown is due, the script asks the server's own code to bring the boss
-- back (".basic worldboss respawn <spawn>", src/cpp-basic/basic_rules.cpp),
-- which also marks it alive and, for Kazzak, summons his demon swarm.
--
-- Who does what: the server's code notices deaths (a Lua death event on a
-- boss would replace the boss's scripted fight with the Lua engine's own)
-- and keeps the alive flag; this script keeps the countdown. Both live in
-- the characters table basic_world_boss_timer (E047), so a restart picks up
-- where it stopped (a dead boss's countdown is saved every pass).
--------------------------------------------------------------------------------

-- {{{ local function script_dir
-- The directory this file sits in (as buddy-talents.lua).
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
-- }}}

local Countdown = dofile(script_dir() .. "lib/world-boss-countdown.lua")

local TAG     = "[world-boss-respawn] "
local PASS_MS = Countdown.PASS_SECONDS * 1000

-- The bosses: spawn id -> { map, area } (their area, where players count),
-- read on the first pass from the world table basic_155j_world_bosses (the
-- one place a world boss is named) and the creature table.
local bosses = nil
local warned = {}        -- countdown rows for unlisted spawns, warned about once each

-- {{{ local function load_bosses
-- Returns the table, or nil (an error, printed once) when an install step
-- is missing: then nothing is counted down.
local reported = false
local function load_bosses()
    local list = WorldDBQuery("SELECT b.guid, c.map, c.position_x, c.position_y, c.position_z "
        .. "FROM basic_155j_world_bosses b JOIN creature c ON c.guid = b.guid")
    if not list then
        if not reported then
            print(TAG .. "ERROR: no world bosses listed (world table basic_155j_world_bosses missing or empty: install step E046 not run?); no countdowns")
            reported = true
        end
        return nil
    end
    if not CharDBQuery("SHOW TABLES LIKE 'basic_world_boss_timer'") then
        if not reported then
            print(TAG .. "ERROR: characters table basic_world_boss_timer is missing (install step E047 not run?); no countdowns")
            reported = true
        end
        return nil
    end
    local out, count = {}, 0
    repeat
        local guid, map_id = list:GetUInt32(0), list:GetUInt32(1)
        local x, y, z = list:GetFloat(2), list:GetFloat(3), list:GetFloat(4)
        local map = GetMapById(map_id)
        -- a continent map always exists; no map means a broken row
        if map then
            out[guid] = { map = map_id, area = map:GetAreaId(x, y, z) }
            count = count + 1
        else
            print(TAG .. "ERROR: world boss spawn " .. guid .. " is on map " .. map_id .. ", which the server has not got; skipped")
        end
    until not list:NextRow()
    print(TAG .. count .. " world bosses under countdown")
    return out
end
-- }}}

-- {{{ local function players_by_area
-- Players (not bots) in each map and area, counted once per pass:
-- key "map:area" -> count.
local function players_by_area()
    local counts = {}
    for _, player in ipairs(GetPlayersInWorld()) do
        if not player:IsBot() then
            local key = player:GetMapId() .. ":" .. player:GetAreaId()
            counts[key] = (counts[key] or 0) + 1
        end
    end
    return counts
end
-- }}}

-- {{{ local function pass
-- Every PASS_MS: each dead boss's countdown moves on one pass; a boss that
-- is due is sent back. Dead bosses are the rows with alive = 0 (written by
-- the server's code at the death).
local function pass()
    if not bosses then
        bosses = load_bosses()
        if not bosses then return end
    end
    local dead = CharDBQuery("SELECT guid, elapsed, tokens FROM basic_world_boss_timer WHERE alive = 0")
    if not dead then return end                        -- every boss alive
    local present = players_by_area()
    repeat
        local guid = dead:GetUInt32(0)
        local boss = bosses[guid]
        if boss then
            local players = present[boss.map .. ":" .. boss.area] or 0
            local elapsed, tokens = Countdown.pass(dead:GetUInt32(1), dead:GetUInt32(2), players)
            if Countdown.due(elapsed, tokens) then
                -- the server's code marks it alive (and zeroes the counters)
                RunCommand(".basic worldboss respawn " .. guid)
                print(string.format("%sspawn %d due after %d s and %d moment tokens: brought back", TAG, guid, elapsed, tokens))
            else
                CharDBExecute(string.format(
                    "UPDATE basic_world_boss_timer SET elapsed = %d, tokens = %d WHERE guid = %d AND alive = 0",
                    elapsed, tokens, guid))
            end
        else
            -- a row for a spawn no longer listed: left alone, said once
            if not warned[guid] then
                print(TAG .. "WARNING: countdown row for spawn " .. guid .. ", which basic_155j_world_bosses does not list; ignored")
                warned[guid] = true
            end
        end
    until not dead:NextRow()
end
-- }}}

-- Runs from the world's first update on, and again after a Lua reload.
CreateLuaEvent(pass, PASS_MS, 0)
