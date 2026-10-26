
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end

local OWN     = script_dir() .. "helpers/"
local RC      = dofile(OWN .. "data/sargobras-race-class-data.lua")
local TD      = dofile(OWN .. "data/sargobras-buddy-talent-data.lua")
local JOKES   = dofile(OWN .. "data/sargobras-jokes.lua")
local Spender = dofile(OWN .. "lib/sargobras-buddy-talent-spender.lua")
local Choice  = dofile(OWN .. "lib/sargobras-buddy-choice.lua")
local Valleys = dofile(OWN .. "data/sargobras-starting-valleys.lua")
local Deck    = dofile(OWN .. "lib/sargobras-valley-deck.lua")

local VALLEY, WANDERER                   = 6170001, 6170002
local WANDERER_HATTED, HAT_CHANCE        = 6170003, 0.10
local function is_wanderer(entry) return entry == WANDERER or entry == WANDERER_HATTED end
local TEXT_OWED, TEXT_NOT_YOURS, TEXT_NONE = 6170001, 6170002, 6170003
local CAMPFIRE                           = 1798

local PLAYER_EVENT_ON_LOGIN        = 3
local PLAYER_EVENT_ON_LOGOUT       = 4
local PLAYER_EVENT_ON_LEVEL_CHANGE = 13
local PLAYER_EVENT_ON_MAP_CHANGE   = 28
local CREATURE_EVENT_ON_REACH_WP   = 6
local GOSSIP_EVENT_ON_HELLO        = 1
local GOSSIP_EVENT_ON_SELECT       = 2
local GOSSIP_ICON_CHAT             = 0
local GOSSIP_ICON_FLIGHT           = 2
local TEMPSUMMON_MANUAL_DESPAWN    = 8
local STAND_STATE_SIT, STAND_STATE_STAND = 1, 0
local CLASS_DEATH_KNIGHT           = 6

local WANDER_FROM_LEVEL = 10
local CIRCLE_MIN        = 5
local CIRCLE_MAX        = 10
local MOVE_ON_AT        = 15
local PULL_STEP         = 1.5
local PULL_FLOOR        = 2
local SIDE_STEPS        = { 0, 0.5, -0.5, 1.0, -1.0 }
local DIRECT_FACTOR     = 1.25
local DIRECT_SLACK      = 1
local FAN_STEP          = 0.4
local WALK_GIVE_UP_MS   = 30000
local MOVE_ID_SPOT      = 6171
local LOST_AT           = 100
local MAP_CHANGE_SUMMON_MS = 3000
local FACE_SLACK        = 0.17
local TURN_STEP_MS      = 200
local TURN_SPEED        = math.pi / 2
local TURN_DONE         = 0.05
local CROWD_RANGE       = 30
local CROWD_MAX         = 2
local CROWD_RETRY_MS    = 30000
local SIGHT             = 100
local JOKE_EVERY_MS     = { 45000, 90000 }
local JOKE_RANGE        = 30
local FIRE_SECONDS      = 120
local FIRE_RADIUS       = 2.5
local FIRE_PCT_PER_TIER = 2
local SIT_RADIUS        = 3
local SIT_SWING         = 1.0
local SEAT_REACHED      = 0.75
local WALK_GIVE_UP_MS   = 15000
local DEAL_BUDDY_ANGLE  = math.pi * 3 / 4
local DEAL_BUDDY_DIST   = 3
local DEAL_BUDDY_STEP   = 2

local UNIT_FLAG_NOT_SELECTABLE = 0x02000000
local SCHOOL_FIRE              = 2

local CLASS_ICON = {
    [1]  = 9,
    [2]  = 8,
    [3]  = 2,
    [4]  = 6,
    [5]  = 10,
    [7]  = 4,
    [8]  = 3,
    [9]  = 5,
    [11] = 1,
}
local RACE_ICON = {
    [1]  = 8,
    [2]  = 9,
    [3]  = 6,
    [4]  = 2,
    [5]  = 5,
    [6]  = 1,
    [7]  = 4,
    [8]  = 3,
    [10] = 10,
    [11] = 7,
}

local INTID_CLASSES, INTID_RACES, INTID_CLASS, INTID_RACE = 1, 2, 100, 200
local INTID_NAME                                         = 3
local INTID_NAME_BOX                                     = 4
local INTID_ELSEWHERE                                    = 5
local INTID_FLEXIBLE                                     = 6

local CLAN_NAME_MIN, CLAN_NAME_MAX = 2, 24
local TAKEN_QUIPS = {
    "Taken! Even the good names have owners these days. Try another.",
    "Someone got there first. Probably someone with worse taste. Again?",
    "That one's spoken for. Be bolder.",
}

local TAG = "[sargobras] "

local wanderer_of, owner_of, slot_of, fire_of = {}, {}, {}, {}
local turning = {}
local circle_of, spot_of, walking = {}, {}, {}

local function roster_ready()
    if not CharDBQuery("SHOW TABLES LIKE 'buddy_roster'") then
        print(TAG .. "ERROR: characters table buddy_roster is missing (issue 617a1's install step E042 not run?); Sargobras is OFF")
        return false
    end
    return true
end

local function article(name) return name:match("^[AEIOUaeiou]") and "An" or "A" end

local function team_name(player) return player:GetTeam() == 0 and "alliance" or "horde" end

local function owed_slots(owner)
    local list = {}
    local q = CharDBQuery("SELECT slot FROM buddy_roster WHERE owner = " .. owner .. " AND class = 0 AND buddy = 0 ORDER BY slot")
    if q then repeat list[#list + 1] = q:GetUInt32(0) until not q:NextRow() end
    return list
end
local function owed_slot(owner) return owed_slots(owner)[1] end

local function clan_roster(owner)
    local list = {}
    local q = CharDBQuery("SELECT class, profile, role FROM buddy_roster WHERE owner = " .. owner .. " AND class <> 0")
    if q then
        repeat list[#list + 1] = { class = q:GetUInt32(0), profile = q:GetUInt32(1), role = q:GetUInt32(2) } until not q:NextRow()
    end
    return list
end

local function choose(player, slot, roster, pick)
    local owner = player:GetGUIDLow()
    local b, err = Choice.resolve({ RC = RC, TD = TD, Spender = Spender, rand = math.random,
        team = team_name(player), owner_is_dk = player:GetClass() == CLASS_DEATH_KNIGHT,
        slot = slot, roster = roster, pick = pick })
    if not b then
        print(string.format("%sERROR: owner %d slot %d: %s", TAG, owner, slot, err))
        return nil, err
    end
    CharDBExecute(string.format("UPDATE buddy_roster SET class = %d, race = %d, profile = %d, role = %d "
        .. "WHERE owner = %d AND slot = %d AND class = 0 AND buddy = 0", b.class, b.race, b.profile, b.role, owner, slot))
    roster[#roster + 1] = { class = b.class, profile = b.profile, role = b.role }
    return b
end

local DEATH_KNIGHT_SLOT_LEVEL = { 55, 57, 59, 60 }
local STAGE_REMAKE, STAGE_ASIDE = 3, 5
local function give_death_knight_buddies(player, traded_now)
    if player:GetClass() ~= CLASS_DEATH_KNIGHT then return end
    local owner, level = player:GetGUIDLow(), player:GetLevel()
    if not traded_now and not CharDBQuery("SELECT 1 FROM basic_718_souls WHERE dk = " .. owner .. " AND state = 1") then return end

    local rows, roster = {}, {}
    local q = CharDBQuery("SELECT slot, buddy, stage, class, profile, role FROM buddy_roster WHERE owner = " .. owner .. " ORDER BY slot")
    if q then
        repeat
            rows[q:GetUInt32(0)] = { buddy = q:GetUInt32(1), stage = q:GetUInt32(2) }
            if q:GetUInt32(3) ~= 0 then
                roster[#roster + 1] = { class = q:GetUInt32(3), profile = q:GetUInt32(4), role = q:GetUInt32(5) }
            end
        until not q:NextRow()
    end

    local came = 0
    for slot, at in ipairs(DEATH_KNIGHT_SLOT_LEVEL) do
        local row = rows[slot]
        if level >= at and not row then
            local b, err = Choice.resolve({ RC = RC, TD = TD, Spender = Spender, rand = math.random,
                team = team_name(player), owner_is_dk = false, slot = slot, roster = roster, pick = { kind = "any" } })
            if not b then
                print(string.format("%sERROR: death knight %d buddy %d (level %d): %s; done before it: %d buddies come this time",
                    TAG, owner, slot, at, err, came))
                break
            end
            CharDBExecute(string.format("INSERT IGNORE INTO buddy_roster (owner, slot, class, race, profile, role) "
                .. "VALUES (%d, %d, %d, %d, %d, %d)", owner, slot, b.class, b.race, b.profile, b.role))
            roster[#roster + 1] = { class = b.class, profile = b.profile, role = b.role }
            came = came + 1
        elseif level >= at and row.buddy ~= 0 and row.stage == STAGE_ASIDE then
            CharDBExecute(string.format("UPDATE buddy_roster SET stage = %d WHERE owner = %d AND slot = %d AND stage = %d",
                STAGE_REMAKE, owner, slot, STAGE_ASIDE))
            came = came + 1
        end
    end
    if came == 0 then return end

    local later = {}
    for slot, at in ipairs(DEATH_KNIGHT_SLOT_LEVEL) do if level < at then later[#later + 1] = tostring(at) end end
    player:SendBroadcastMessage((came == 1 and "One who fell beside you rises again." or (came .. " who fell beside you rise again."))
        .. " They will find you."
        .. (#later > 0 and (" More will come at level " .. table.concat(later, ", ") .. ".") or ""))
end
BuddiesGiveDeathKnightBuddies = function(player) give_death_knight_buddies(player, true) end

local join_clan_later

local function found_clan(player, creature, name)
    local owner = player:GetGUIDLow()
    RunCommand(string.format('.guild create %s "%s"', player:GetName(), name))
    player:RegisterEvent(function(_, _, _, p)
        local g = GetGuildByName(name)
        if not g or p:GetGuildId() ~= g:GetId() then
            print(string.format('%sERROR: owner %d: the guild "%s" was not created', TAG, owner, name))
            p:SendBroadcastMessage('Sargobras frowns: "The heralds refused that name. Try another."')
            return
        end
        CharDBExecute(string.format("UPDATE buddy_clan SET clan_guild = %d WHERE owner = %d", g:GetId(), owner))
        local q = CharDBQuery("SELECT buddy FROM buddy_roster WHERE owner = " .. owner .. " AND buddy <> 0")
        if q then repeat
            local b = GetPlayerByGUID(GetPlayerGUID(q:GetUInt32(0)))
            if b then join_clan_later(b) end
        until not q:NextRow() end
        p:SendBroadcastMessage(string.format('The clan "%s" is founded.', name))
    end, 2000, 1)
end

local CLAN_POPUP = "And what will your clan be called? (letters and spaces, 2 to 24)"
local function try_clan_name(player, speaker, code)
    if player:IsInGuild() then return end
    local name = (code or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    if name == "" then return end
    if #name < CLAN_NAME_MIN or #name > CLAN_NAME_MAX or name:find("[^%a ]") then
        return speaker:SendUnitSay("Letters and spaces, two to twenty-four of them. Humour me.", 0)
    end
    if GetGuildByName(name) then
        return speaker:SendUnitSay(TAKEN_QUIPS[math.random(#TAKEN_QUIPS)], 0)
    end
    found_clan(player, speaker, name)
end
BuddiesTryClanName  = function(player, speaker, code) try_clan_name(player, speaker, code) end
BuddiesClanPopup    = CLAN_POPUP

local NAME_LISTEN_MS        = 60000
local PLAYER_EVENT_ON_CHAT  = 18
local CHAT_MSG_SAY          = 1
local listening = {}

local function listen_for_name(player, creature)
    listening[player:GetGUIDLow()] = { npc = creature:GetGUID(), until_ms = GetCurrTime() + NAME_LISTEN_MS }
    creature:SendUnitSay("Every clan needs a name. Say it aloud, and I'll see it written. Letters and spaces, two to twenty-four.", 0)
end

local function on_chat(event, player, msg, msg_type, lang)
    local wait = listening[player:GetGUIDLow()]
    if not wait or msg_type ~= CHAT_MSG_SAY then return end
    listening[player:GetGUIDLow()] = nil
    if GetCurrTime() > wait.until_ms then return end
    local creature = player:GetMap():GetWorldObject(wait.npc)
    if not creature then
        print(string.format('%sERROR: owner %d said a clan name but Sargobras (%s) is gone; nothing founded',
            TAG, player:GetGUIDLow(), tostring(wait.npc)))
        player:SendBroadcastMessage("Sargobras isn't here to hear it. Ask him again.")
        return
    end
    try_clan_name(player, creature, msg)
end
BuddiesListenForClanName = function(player, creature) listen_for_name(player, creature) end

local function may_go_elsewhere(player, creature)
    return creature:GetEntry() == VALLEY and player:GetLevel() == 1
       and player:GetClass() ~= CLASS_DEATH_KNIGHT
end

local function go_elsewhere(player, creature)
    local team    = player:GetTeam()
    local valleys = Valleys[team]
    local x, y    = player:GetLocation()
    local here    = Deck.standing_in(valleys, player:GetMapId(), x, y)
    local index   = Deck.next(player:GetGUIDLow(), here)
    local v       = valleys[index]

    creature:SendUnitSay(string.format("%s, then. Hold still.", v.name), 0)
    player:SetBindPoint(v.x, v.y, v.z, v.map, v.zone)
    player:Teleport(v.map, v.x, v.y, v.z, v.o)

    local q = CharDBQuery("SELECT buddy FROM buddy_roster WHERE owner = " .. player:GetGUIDLow() .. " AND buddy <> 0 ORDER BY slot")
    if q then
        local i = 0
        repeat
            local b = GetPlayerByGUID(GetPlayerGUID(q:GetUInt32(0)))
            if b and b:IsInWorld() then
                i = i + 1
                local side  = (i % 2 == 1) and 1 or -1
                local angle = v.o + side * DEAL_BUDDY_ANGLE
                local dist  = DEAL_BUDDY_DIST + math.floor((i - 1) / 2) * DEAL_BUDDY_STEP
                b:Teleport(v.map, v.x + math.cos(angle) * dist, v.y + math.sin(angle) * dist, v.z + 1, v.o)
            end
        until not q:NextRow()
    end
    CharDBExecute(string.format(
        "UPDATE basic_starting_valley_rotation SET dealt_in_batch = dealt_in_batch + 1 WHERE team = %d AND current_valley = %d",
        team, index))
end

local function show_menu(player, creature, page)
    player:GossipClearMenu()
    if not player:IsInGuild() then
        player:GossipMenuAddItem(GOSSIP_ICON_CHAT, "First, our clan needs a name.", 0, INTID_NAME)
        player:GossipMenuAddItem(GOSSIP_ICON_CHAT, "(test) Type our clan's name in a box.", 0, INTID_NAME_BOX, true, CLAN_POPUP)
    elseif owed_slot(player:GetGUIDLow()) then
        local classes, races = Choice.menu(RC, team_name(player), false)
        for _, c in ipairs(classes) do
            local text = c.name
            player:GossipMenuAddItem(CLASS_ICON[c.id] or GOSSIP_ICON_CHAT, text, 0, INTID_CLASS + c.id)
        end
        for _, r in ipairs(races) do
            player:GossipMenuAddItem(RACE_ICON[r.id] or GOSSIP_ICON_CHAT, r.name, 0, INTID_RACE + r.id)
        end
        player:GossipMenuAddItem(GOSSIP_ICON_CHAT, "I'm flexible.", 0, INTID_FLEXIBLE)
    end
    if may_go_elsewhere(player, creature) then
        player:GossipMenuAddItem(GOSSIP_ICON_FLIGHT, "Actually, can I go somewhere else?", 0, INTID_ELSEWHERE)
    end
    player:GossipSendMenu(TEXT_OWED, creature)
end

local function remove_wanderer(creature)
    local low = creature:GetGUIDLow()
    local owner = owner_of[low]
    if owner and wanderer_of[owner] and slot_of[low] and wanderer_of[owner][slot_of[low]] == creature:GetGUID() then
        wanderer_of[owner][slot_of[low]] = nil
    end
    owner_of[low] = nil
    slot_of[low] = nil
    turning[low] = nil
    circle_of[low], spot_of[low], walking[low] = nil, nil, nil
    local fire = fire_of[low]
    fire_of[low] = nil
    if fire then
        local go = creature:GetMap():GetWorldObject(fire)
        if go then go:Despawn() end
    end
    creature:RemoveEvents()
    creature:DespawnOrUnsummon(0)
end

local function go_on_break(creature, player)
    local low = creature:GetGUIDLow()
    creature:RemoveEvents()
    turning[low]   = nil
    walking[low]   = nil
    creature:MoveIdle()
    creature:MoveStop()

    local fx, fy, fz = player:GetLocation()
    local fire = creature:SummonGameObject(CAMPFIRE, fx, fy, fz, player:GetO(), FIRE_SECONDS)
    if fire then fire_of[low] = fire:GetGUID() end

    local sx, sy  = creature:GetLocation()
    local a       = math.atan2(sy - fy, sx - fx) + SIT_SWING
    local seat_x  = fx + math.cos(a) * SIT_RADIUS
    local seat_y  = fy + math.sin(a) * SIT_RADIUS
    local seat_z  = creature:GetMap():GetHeight(seat_x, seat_y) or fz
    creature:SetWalk(true)
    creature:MoveTo(1, seat_x, seat_y, seat_z)

    local walked, step = 0, TURN_SPEED * TURN_STEP_MS / 1000
    creature:RegisterEvent(function(event_id, _, _, c)
        walked = walked + TURN_STEP_MS
        local x, y = c:GetLocation()
        local there = (x - seat_x) ^ 2 + (y - seat_y) ^ 2 <= SEAT_REACHED ^ 2
        if not there and walked < WALK_GIVE_UP_MS then return end
        local delta = (math.atan2(fy - y, fx - x) - c:GetO() + math.pi) % (2 * math.pi) - math.pi
        if math.abs(delta) > TURN_DONE then
            c:SetFacing((c:GetO() + math.min(math.abs(delta), step) * (delta > 0 and 1 or -1)) % (2 * math.pi))
            return
        end
        c:RemoveEventById(event_id)
        c:SetStandState(STAND_STATE_SIT)
        c:SetUnitFlags(bit.bor(c:GetUnitFlags(), UNIT_FLAG_NOT_SELECTABLE))
    end, TURN_STEP_MS, 0)

    local tier = slot_of[low] or 1
    creature:RegisterEvent(function(_, _, _, c)
        for _, p in ipairs(c:GetPlayersInRange(SIT_RADIUS + FIRE_RADIUS) or {}) do
            local px, py = p:GetLocation()
            if (px - fx) ^ 2 + (py - fy) ^ 2 <= FIRE_RADIUS ^ 2 and p:IsAlive() then
                p:DealDamage(p, math.ceil(p:GetMaxHealth() * FIRE_PCT_PER_TIER * tier / 100), false, SCHOOL_FIRE)
            end
        end
    end, 1000, 0)

    creature:RegisterEvent(function(_, _, _, c)
        local near = c:GetPlayersInRange(JOKE_RANGE)
        if near and #near > 0 then c:SendUnitSay(JOKES[math.random(#JOKES)], 0) end
    end, JOKE_EVERY_MS, 0)
    creature:RegisterEvent(function(_, _, _, c) remove_wanderer(c) end, FIRE_SECONDS * 1000, 1)
end

local function slot_level(slot) return slot == 1 and 1 or (slot - 1) * 10 end

local function turn_to(creature, want)
    local low = creature:GetGUIDLow()
    if turning[low] then return end
    turning[low] = true
    local step = TURN_SPEED * TURN_STEP_MS / 1000
    creature:RegisterEvent(function(event_id, _, _, c)
        local a = want(c)
        local delta = a and ((a - c:GetO() + math.pi) % (2 * math.pi) - math.pi)
        if not delta or not c:IsStopped() or math.abs(delta) <= TURN_DONE then
            turning[c:GetGUIDLow()] = nil
            return c:RemoveEventById(event_id)
        end
        local turn = math.min(math.abs(delta), step) * (delta > 0 and 1 or -1)
        c:SetFacing((c:GetO() + turn) % (2 * math.pi))
    end, TURN_STEP_MS, 0)
end

local path_call_missing_said = false
local function direct_route(player, x, y, z)
    local straight = math.sqrt((x - player:GetX()) ^ 2 + (y - player:GetY()) ^ 2)
    local ok, length = pcall(function() return player:GetWalkablePathLength(x, y, z) end)
    if ok then return length ~= nil and length <= straight * DIRECT_FACTOR + DIRECT_SLACK end
    if not path_call_missing_said then
        path_call_missing_said = true
        print(TAG .. "ERROR: the server has no GetWalkablePathLength (source patch B051 not built yet); Sargobras"
            .. " checks his spots by line of sight instead, which misses cliffs and bridges, until the next compile: " .. tostring(length))
    end
    return player:IsWithinLoS(x, y, z + 2)
end

local function new_circle(creature, player)
    local low        = creature:GetGUIDLow()
    local cx, cy, cz = player:GetX(), player:GetY(), player:GetZ()
    local sx, sy     = creature:GetX(), creature:GetY()
    local k          = (slot_of[low] or 1) - 1
    local base       = math.atan2(sy - cy, sx - cx) + math.ceil(k / 2) * (k % 2 == 1 and 1 or -1) * FAN_STEP
    local r          = CIRCLE_MIN + math.random() * (CIRCLE_MAX - CIRCLE_MIN)
    while true do
        for _, side in ipairs(SIDE_STEPS) do
            local a = base + side
            local x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
            if r <= PULL_FLOOR or direct_route(player, x, y, cz) then
                circle_of[low] = { cx = cx, cy = cy, cz = cz, r = r }
                spot_of[low]   = { x = x, y = y, z = cz }
                return
            end
            if r <= PULL_FLOOR then break end
        end
        r = math.max(PULL_FLOOR, r - PULL_STEP)
    end
end

local arrived
local function walk_to_spot(creature)
    local low = creature:GetGUIDLow()
    local s   = spot_of[low]
    if walking[low] then creature:RemoveEventById(walking[low]) end
    creature:SetWalk(true)
    creature:MoveTo(MOVE_ID_SPOT, s.x, s.y, s.z, true)
    walking[low] = creature:RegisterEvent(function(_, _, _, c)
        walking[c:GetGUIDLow()] = nil
        c:MoveIdle()
        arrived(c)
    end, WALK_GIVE_UP_MS, 1)
end

local summon_wanderer

local function follow_tick(_, _, _, creature)
    local low    = creature:GetGUIDLow()
    local owner  = owner_of[low]
    local player = owner and GetPlayerByGUID(GetPlayerGUID(owner))
    if not player or not player:IsInWorld() or player:GetMapId() ~= creature:GetMapId() then
        return remove_wanderer(creature)
    end
    if walking[low] then return end

    local d = creature:GetDistance(player)
    if d > MOVE_ON_AT and player:GetLevel() < slot_level(slot_of[low] or 1) then
        return remove_wanderer(creature)
    end
    if d > LOST_AT then
        remove_wanderer(creature)
        return summon_wanderer(player)
    end
    if d > MOVE_ON_AT then
        new_circle(creature, player)
        return walk_to_spot(creature)
    end

    local function want(c)
        local p = GetPlayerByGUID(GetPlayerGUID(owner))
        local ring = circle_of[c:GetGUIDLow()]
        if not p or not ring then return nil end
        local inside = (p:GetX() - ring.cx) ^ 2 + (p:GetY() - ring.cy) ^ 2 <= ring.r ^ 2
        if inside then return math.atan2(ring.cy - c:GetY(), ring.cx - c:GetX()) end
        return math.atan2(p:GetY() - c:GetY(), p:GetX() - c:GetX())
    end
    local a = want(creature)
    if a and math.abs((a - creature:GetO() + math.pi) % (2 * math.pi) - math.pi) > FACE_SLACK then
        turn_to(creature, want)
    end
end

arrived = function(creature) follow_tick(nil, nil, nil, creature) end
local function on_reach(event, creature, kind, id)
    if id ~= MOVE_ID_SPOT then return end
    local low = creature:GetGUIDLow()
    if not owner_of[low] or not walking[low] then return end
    creature:RemoveEventById(walking[low])
    walking[low] = nil
    creature:MoveIdle()
    arrived(creature)
end

summon_wanderer = function(player)
    local owner = player:GetGUIDLow()
    if player:GetClass() == CLASS_DEATH_KNIGHT or player:GetLevel() < WANDER_FROM_LEVEL then return end
    local map = player:GetMap()
    if map:IsDungeon() or map:IsRaid() or map:IsBattleground() or map:IsArena() then return end
    local slots = {}
    for _, slot in ipairs(owed_slots(owner)) do
        if slot_level(slot) <= player:GetLevel() then slots[#slots + 1] = slot end
    end
    if #slots == 0 then return end
    wanderer_of[owner] = wanderer_of[owner] or {}
    local mine = wanderer_of[owner]

    local near = #(player:GetCreaturesInRange(CROWD_RANGE, VALLEY) or {})
    for _, entry in ipairs({ WANDERER, WANDERER_HATTED }) do
        for _, c in ipairs(player:GetCreaturesInRange(CROWD_RANGE, entry) or {}) do
            if owner_of[c:GetGUIDLow()] ~= owner then near = near + 1 end
        end
    end
    if near > CROWD_MAX then
        player:RegisterEvent(function(_, _, _, p) summon_wanderer(p) end, CROWD_RETRY_MS, 1)
        return
    end

    local x, y, z = player:GetLocation()
    for _, slot in ipairs(slots) do
        if not mine[slot] then
            local a = (slot - 1) * 2 * math.pi / 7
            local c = player:SpawnCreature(math.random() < HAT_CHANCE and WANDERER_HATTED or WANDERER, x + math.cos(a) * CIRCLE_MAX, y + math.sin(a) * CIRCLE_MAX, z,
                math.atan2(-math.sin(a), -math.cos(a)), TEMPSUMMON_MANUAL_DESPAWN, 0)
            if not c then
                print(string.format("%sERROR: could not summon Sargobras for owner %d, slot %d", TAG, owner, slot))
            else
                local low  = c:GetGUIDLow()
                mine[slot]     = c:GetGUID()
                owner_of[low]  = owner
                slot_of[low]   = slot
                c:SetLevel(slot_level(slot) + 1)
                new_circle(c, player)
                walk_to_spot(c)
                c:RegisterEvent(follow_tick, 1000, 0)
            end
        end
    end
end

local function on_hello(event, player, creature)
    if is_wanderer(creature:GetEntry()) and owner_of[creature:GetGUIDLow()] ~= player:GetGUIDLow() then
        player:GossipClearMenu()
        return player:GossipSendMenu(TEXT_NOT_YOURS, creature)
    end
    if player:GetClass() == CLASS_DEATH_KNIGHT or (player:IsInGuild() and not owed_slot(player:GetGUIDLow())) then
        player:GossipClearMenu()
        if may_go_elsewhere(player, creature) then
            player:GossipMenuAddItem(GOSSIP_ICON_FLIGHT, "Actually, can I go somewhere else?", 0, INTID_ELSEWHERE)
        end
        return player:GossipSendMenu(TEXT_NONE, creature)
    end
    show_menu(player, creature, nil)
end

local function on_select(event, player, creature, sender, intid, code)
    if intid == INTID_CLASSES or intid == INTID_RACES then return show_menu(player, creature, intid) end
    if intid == INTID_ELSEWHERE then
        player:GossipComplete()
        if may_go_elsewhere(player, creature) then go_elsewhere(player, creature) end
        return
    end
    if intid == INTID_NAME_BOX then
        player:GossipComplete()
        return try_clan_name(player, creature, code)
    end
    if intid == INTID_NAME then
        player:GossipComplete()
        if player:IsInGuild() then return end
        return listen_for_name(player, creature)
    end

    local pick
    if intid > INTID_RACE then pick = { kind = "race", id = intid - INTID_RACE }
    elseif intid > INTID_CLASS then pick = { kind = "class", id = intid - INTID_CLASS }
    elseif intid == INTID_FLEXIBLE then pick = { kind = "flexible" } end
    player:GossipComplete()
    if not pick then return end
    if not player:IsInGuild() then return end

    local owner = player:GetGUIDLow()
    local owed  = owed_slots(owner)
    if #owed == 0 then return end
    local slot = owed[1]
    local mine = slot_of[creature:GetGUIDLow()]
    for _, s in ipairs(owed) do if s == mine then slot = mine end end
    local b = choose(player, slot, clan_roster(owner), pick)
    if not b then
        creature:SendUnitSay("Hm. The stars are cloudy tonight. Ask me again in a moment.", 0)
        return
    end
    local race_name = RC.races[b.race].name
    if pick.kind == "flexible" then
        creature:SendUnitSay("Good, you shall find others like you soon.", 0)
    else
        creature:SendUnitSay(string.format("%s %s %s. They'll find you soon.",
            article(race_name), race_name, RC.classes[b.class].name), 0)
    end

    if is_wanderer(creature:GetEntry()) then go_on_break(creature, player) end
end

local CLAN_JOIN_DELAY_MS = 5000
join_clan_later = function(buddy)
    if buddy:IsInGuild() then return end
    local q = CharDBQuery("SELECT owner FROM buddy_roster WHERE buddy = " .. buddy:GetGUIDLow())
    if not q then return end
    local owner = q:GetUInt32(0)
    buddy:RegisterEvent(function(_, _, _, b)
        if b:IsInGuild() then return end
        local guild = GetGuildByLeaderGUID(GetPlayerGUID(owner))
        if not guild then return end
        guild:AddMember(b)
    end, CLAN_JOIN_DELAY_MS, 1)
end

local function on_login(event, player)
    give_death_knight_buddies(player, false)
    join_clan_later(player)
    summon_wanderer(player)
end

local function on_level_change(event, player, old_level)
    give_death_knight_buddies(player, false)
    if math.floor(player:GetLevel() / 10) > math.floor(old_level / 10) then
        player:RegisterEvent(function(_, _, _, p) summon_wanderer(p) end, 2000, 1)
    end
end

local function on_map_change(event, player)
    wanderer_of[player:GetGUIDLow()] = {}
    player:RegisterEvent(function(_, _, _, p) summon_wanderer(p) end, MAP_CHANGE_SUMMON_MS, 1)
end

local function on_logout(event, player)
    local mine = wanderer_of[player:GetGUIDLow()]
    if not mine then return end
    for _, guid in pairs(mine) do
        local c = player:GetMap():GetWorldObject(guid)
        if c then remove_wanderer(c) end
    end
    wanderer_of[player:GetGUIDLow()] = nil
end

if roster_ready() then
    RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,        on_login)
    RegisterPlayerEvent(PLAYER_EVENT_ON_LEVEL_CHANGE, on_level_change)
    RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT,       on_logout)
    RegisterPlayerEvent(PLAYER_EVENT_ON_MAP_CHANGE,   on_map_change)
    for _, entry in ipairs({ WANDERER, WANDERER_HATTED }) do
        RegisterCreatureEvent(entry, CREATURE_EVENT_ON_REACH_WP, on_reach)
    end
    RegisterPlayerEvent(PLAYER_EVENT_ON_CHAT,         on_chat)
    for _, entry in ipairs({ VALLEY, WANDERER, WANDERER_HATTED }) do
        RegisterCreatureGossipEvent(entry, GOSSIP_EVENT_ON_HELLO,  on_hello)
        RegisterCreatureGossipEvent(entry, GOSSIP_EVENT_ON_SELECT, on_select)
    end

    local players = GetPlayersInWorld() or {}
    for _, p in ipairs(players) do
        for _, entry in ipairs({ WANDERER, WANDERER_HATTED }) do
            for _, c in ipairs(p:GetCreaturesInRange(SIGHT, entry) or {}) do
                if not owner_of[c:GetGUIDLow()] then c:DespawnOrUnsummon(0) end
            end
        end
    end
    for _, p in ipairs(players) do summon_wanderer(p) end
end
