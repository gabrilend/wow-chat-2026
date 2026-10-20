
local PLAYER_EVENT_ON_COMMAND = 42
local TEMPSUMMON_CORPSE_TIMED_DESPAWN = 6
local CORPSE_MS        = 15000

local RING_PLACES      = 6
local RING_RADIUS      = 28
local GROUPS           = 3
local PER_GROUP        = 3
local CANDIDATES       = 3
local GROUP_SPREAD     = 3
local LEVEL_SPREAD     = 1
local CHECK_MS         = 2000
local GM_RANK          = 2

local trials = {}

local function party_of(player)
    local list = { player }
    local group = player:GetGroup()
    if group then
        for _, m in ipairs(group:GetMembers()) do
            if m ~= player and m:GetMapId() == player:GetMapId() then list[#list + 1] = m end
        end
    end
    return list
end

local function farthest_places(t, player)
    local party, scored = party_of(player), {}
    for i, p in ipairs(t.places) do
        local nearest = math.huge
        for _, m in ipairs(party) do
            local dx, dy = m:GetX() - p.x, m:GetY() - p.y
            nearest = math.min(nearest, math.sqrt(dx * dx + dy * dy))
        end
        scored[#scored + 1] = { i = i, d = nearest }
    end
    table.sort(scored, function(a, b) return a.d > b.d end)
    local out = {}
    for k = 1, math.min(CANDIDATES, #scored) do out[k] = t.places[scored[k].i] end
    return out
end

local function monster_entries(level)
    local q = WorldDBQuery(string.format(
        "SELECT DISTINCT t.entry FROM creature_template t JOIN creature c ON c.id = t.entry " ..
        "WHERE c.map = 0 AND c.position_x BETWEEN -14700 AND -11200 AND c.position_y BETWEEN -1000 AND 1500 " ..
        "AND t.`rank` = 0 AND t.npcflag = 0 AND t.type IN (1, 7) AND t.faction IN (14, 16, 18, 28, 30, 45, 48, 49, 72) " ..
        "AND t.minlevel BETWEEN %d AND %d", level - LEVEL_SPREAD, level + LEVEL_SPREAD))
    local list = {}
    if q then repeat list[#list + 1] = q:GetUInt32(0) until not q:NextRow() end
    return list
end

local function spawn_at(t, player, place, k)
    local a  = (k or math.random(0, 5)) * math.pi / 3
    local x  = place.x + math.cos(a) * GROUP_SPREAD
    local y  = place.y + math.sin(a) * GROUP_SPREAD
    local o  = math.atan2(t.cy - y, t.cx - x)
    local entry = t.entries[math.random(#t.entries)]
    local c = player:SpawnCreature(entry, x, y, t.cz, o, TEMPSUMMON_CORPSE_TIMED_DESPAWN, CORPSE_MS)
    if not c then
        print(string.format("[arena-trial] ERROR: monster %d could not be spawned at (%.1f, %.1f, %.1f)", entry, x, y, t.cz))
        return
    end
    t.alive[#t.alive + 1] = c:GetGUID()
end

local function start(player)
    local guid = player:GetGUIDLow()
    if trials[guid] then return player:SendBroadcastMessage("Arena trial already running; .arena stop first.") end
    local entries = monster_entries(player:GetLevel())
    if #entries == 0 then
        return player:SendBroadcastMessage(string.format(
            "No Stranglethorn monster of level %d (+/- %d) found; the Vale's monsters are about 30-50.", player:GetLevel(), LEVEL_SPREAD))
    end
    local t = { cx = player:GetX(), cy = player:GetY(), cz = player:GetZ(), map = player:GetMapId(),
                places = {}, entries = entries, alive = {} }
    for i = 1, RING_PLACES do
        local a = (i - 1) * 2 * math.pi / RING_PLACES
        t.places[i] = { x = t.cx + math.cos(a) * RING_RADIUS, y = t.cy + math.sin(a) * RING_RADIUS }
    end
    trials[guid] = t
    for g, place in ipairs(farthest_places(t, player)) do
        if g > GROUPS then break end
        for k = 1, PER_GROUP do spawn_at(t, player, place, k * 2) end
    end
    t.event = player:RegisterEvent(function(_, _, _, p)
        local tr = trials[p:GetGUIDLow()]
        if not tr then return end
        local still = {}
        for _, g in ipairs(tr.alive) do
            local c = p:GetMap():GetWorldObject(g)
            if c and c:IsAlive() then still[#still + 1] = g end
        end
        local missing = GROUPS * PER_GROUP - #still
        tr.alive = still
        for _ = 1, missing do
            local candidates = farthest_places(tr, p)
            spawn_at(tr, p, candidates[math.random(#candidates)])
        end
    end, CHECK_MS, 0)
    player:SendBroadcastMessage(string.format("Arena trial: %d monsters in %d groups, %d places round the ring (%d kinds of level %d +/- %d).",
        GROUPS * PER_GROUP, GROUPS, RING_PLACES, #entries, player:GetLevel(), LEVEL_SPREAD))
end

local function stop(player)
    local t = trials[player:GetGUIDLow()]
    if not t then return player:SendBroadcastMessage("No arena trial running.") end
    if t.event then player:RemoveEventById(t.event) end
    for _, g in ipairs(t.alive) do
        local c = player:GetMap():GetWorldObject(g)
        if c then c:DespawnOrUnsummon(0) end
    end
    trials[player:GetGUIDLow()] = nil
    player:SendBroadcastMessage("Arena trial stopped.")
end

local function on_command(event, player, command)
    if not player then return end
    local word = command:match("^arena%s+(%a+)$")
    if not word then return end
    if player:GetGMRank() < GM_RANK then return end
    if word == "start" then start(player) elseif word == "stop" then stop(player)
    else player:SendBroadcastMessage("Arena trial: .arena start (standing in the ring's middle) or .arena stop") end
    return false
end

local function on_logout(event, player)
    if trials[player:GetGUIDLow()] then stop(player) end
end

RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, on_command)
RegisterPlayerEvent(4, on_logout)
