
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end

local Countdown = dofile(script_dir() .. "lib/world-boss-countdown.lua")

local TAG     = "[world-boss-respawn] "
local PASS_MS = Countdown.PASS_SECONDS * 1000

local bosses = nil
local warned = {}

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

local function pass()
    if not bosses then
        bosses = load_bosses()
        if not bosses then return end
    end
    local dead = CharDBQuery("SELECT guid, elapsed, tokens FROM basic_world_boss_timer WHERE alive = 0")
    if not dead then return end
    local present = players_by_area()
    repeat
        local guid = dead:GetUInt32(0)
        local boss = bosses[guid]
        if boss then
            local players = present[boss.map .. ":" .. boss.area] or 0
            local elapsed, tokens = Countdown.pass(dead:GetUInt32(1), dead:GetUInt32(2), players)
            if Countdown.due(elapsed, tokens) then
                RunCommand(".basic worldboss respawn " .. guid)
                print(string.format("%sspawn %d due after %d s and %d moment tokens: brought back", TAG, guid, elapsed, tokens))
            else
                CharDBExecute(string.format(
                    "UPDATE basic_world_boss_timer SET elapsed = %d, tokens = %d WHERE guid = %d AND alive = 0",
                    elapsed, tokens, guid))
            end
        else
            if not warned[guid] then
                print(TAG .. "WARNING: countdown row for spawn " .. guid .. ", which basic_155j_world_bosses does not list; ignored")
                warned[guid] = true
            end
        end
    until not dead:NextRow()
end

CreateLuaEvent(pass, PASS_MS, 0)
