--------------------------------------------------------------------------------
-- sargobras.lua (issue 617b)
--
-- Sargobras lets a player choose a buddy. He is in two places:
--
--   the valley Sargobras (creature 6170001): one in each starting valley,
--     standing where newcomers arrive (install step E043). Anyone owed a
--     buddy may ask him.
--   the wandering Sargobras (creature 6170002): summoned beside an owner who
--     is owed a buddy, at each tenth level (where they levelled) and at
--     login (where they logged in), once they are level 10 or more. Only
--     that owner may ask him. He follows at about 7 yards, sets off again
--     when they are 15 yards away, and turns to face them now and then.
--     Once every owed buddy is chosen he lights a campfire, sits, tells
--     jokes, and goes when no player is within sight.
--
-- A choice (a class, or a race) becomes a whole buddy through
-- lib/buddy-choice.lua (tested offline by scripts/test-buddy-choice) and is
-- written into the owner's lowest owed roster row. The buddy module (617a3)
-- makes the character from that row; nothing here calls it.
--
-- The clan's name (617l): an owner with no guild picks its first buddy
-- through options worded "I want a Paladin as my first buddy, and I'd like
-- to name our clan", which open the client's own pop-up box; the name typed
-- there founds the clan (owner, 2026-09-26). A name that fails is simply
-- asked again with the next pick. A death knight names its clan in the
-- soul trade's pop-up in Acherus (death-knight-souls.lua).
--
-- A buddy joins the clan 5 seconds after it appears in the world, not when
-- it is made: one step, then the other (owner, 2026-09-26). It says
-- nothing; belonging is assumed. The guild is made with the server's guild command (so its
-- own name rules apply) and checked a moment later; a taken name gets a joke
-- and another try. Buddies already made are invited; the buddy module adds
-- each later one as it makes it (617a3).
--
-- Death-knight owners never meet him (owner, 2026-09-25). They get exactly
-- four buddies, death knights of random races, when they accept the soul
-- trade with the Sargobras at the gate of Acherus (owner, 2026-09-26:
-- "4 buddy-bots per Death Knight [...] never any more [...] when they
-- accept a soul-trade with Sargobras in Acherus"). death-knight-souls.lua
-- calls BuddiesGiveDeathKnightBuddies on the trade; login catches up a
-- death knight who traded before this was installed.
--
-- Needs the roster table (617a1, install step E042); without it the script
-- says so at startup and does nothing.
--------------------------------------------------------------------------------

-- {{{ local function script_dir
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
-- }}}

local RC      = dofile(script_dir() .. "data/race-class-data.lua")
local TD      = dofile(script_dir() .. "data/buddy-talent-data.lua")
local JOKES   = dofile(script_dir() .. "data/sargobras-jokes.lua")
local Spender = dofile(script_dir() .. "lib/buddy-talent-spender.lua")
local Choice  = dofile(script_dir() .. "lib/buddy-choice.lua")

local VALLEY, WANDERER                   = 6170001, 6170002
local TEXT_OWED, TEXT_NOT_YOURS, TEXT_NONE = 6170001, 6170002, 6170003
local CAMPFIRE                           = 1798           -- a stock "Campfire" object

local PLAYER_EVENT_ON_LOGIN        = 3
local PLAYER_EVENT_ON_LOGOUT       = 4
local PLAYER_EVENT_ON_LEVEL_CHANGE = 13
local GOSSIP_EVENT_ON_HELLO        = 1
local GOSSIP_EVENT_ON_SELECT       = 2
local GOSSIP_ICON_CHAT             = 0
local TEMPSUMMON_MANUAL_DESPAWN    = 8
local STAND_STATE_SIT, STAND_STATE_STAND = 1, 0
local CLASS_DEATH_KNIGHT           = 6

-- {{{ tuning (owner decisions, 617b)
local WANDER_FROM_LEVEL = 10        -- below this only the valley Sargobras
local STOP_AT           = 7         -- yards: he stops this close
local FOLLOW_AGAIN_AT   = 15        -- yards: he sets off again past this
local TURN_EVERY_MS     = 5000      -- he starts a turn toward the owner at most this often
-- The server can only set a facing, not animate one, so a turn is played as
-- small steps (a linear interpolation sampled every TURN_STEP_MS). Owner,
-- 2026-09-26: step as rarely as still "feels fine", to spare the server.
-- Both are guesses until seen in game; tune them in docs/balance-updates.md.
local TURN_STEP_MS      = 200       -- one step every this many ms (5 a second)
local TURN_SPEED        = math.pi / 2  -- radians a second (90 degrees): 18 degrees a step
local TURN_DONE         = 0.05      -- radians: close enough to stop turning
local CROWD_RANGE       = 30        -- yards
local CROWD_MAX         = 2         -- he doesn't come if more than this many are already near
local CROWD_RETRY_MS    = 30000     -- a crowded owner is tried again this often
local SIGHT             = 100       -- yards: the server's outdoor visibility, roughly
local JOKE_EVERY_MS     = { 45000, 90000 }
local JOKE_RANGE        = 30
-- }}}

-- intids: 1 ask for a class, 2 ask for a people, 100+class, 200+race
local INTID_CLASSES, INTID_RACES, INTID_CLASS, INTID_RACE = 1, 2, 100, 200

-- {{{ clan names
-- The server's own rule for guild names is checked by its guild command;
-- this is only the quick check before asking it (letters and spaces, 2-24).
local CLAN_NAME_MIN, CLAN_NAME_MAX = 2, 24
local TAKEN_QUIPS = {
    "Taken! Even the good names have owners these days. Try another.",
    "Someone got there first. Probably someone with worse taste. Again?",
    "That one's spoken for. Be bolder.",
}
-- }}}

local TAG = "[sargobras] "

-- Owner guid (low) -> the wandering Sargobras's guid; wanderer guid (low) ->
-- owner guid (low); the campfire each wanderer lit. Summoned creatures are
-- never saved, so this only has to live as long as the server runs.
local wanderer_of, owner_of, fire_of = {}, {}, {}
-- Wanderer guid (low) -> when he last started a turn (ms, GetCurrTime), and
-- whether a turn is under way.
local turned_at, turning = {}, {}

-- {{{ local function roster_ready
local function roster_ready()
    if not CharDBQuery("SHOW TABLES LIKE 'buddy_roster'") then
        print(TAG .. "ERROR: characters table buddy_roster is missing (issue 617a1's install step E042 not run?); Sargobras is OFF")
        return false
    end
    return true
end
-- }}}

-- {{{ local function article
-- "a" or "an" before a name ("an Undead Mage", "an Orc", "a Paladin").
local function article(name) return name:match("^[AEIOUaeiou]") and "An" or "A" end
-- }}}

-- {{{ local function team_name
local function team_name(player) return player:GetTeam() == 0 and "alliance" or "horde" end
-- }}}

-- {{{ local function owed_slots
-- The owner's slots still waiting for a choice, lowest first.
-- (Writes go through the database's queue, so a slot chosen a moment ago
-- may still read as owed; callers that write several in a row keep their
-- own list rather than asking again.)
local function owed_slots(owner)
    local list = {}
    local q = CharDBQuery("SELECT slot FROM buddy_roster WHERE owner = " .. owner .. " AND class = 0 AND buddy = 0 ORDER BY slot")
    if q then repeat list[#list + 1] = q:GetUInt32(0) until not q:NextRow() end
    return list
end
local function owed_slot(owner) return owed_slots(owner)[1] end
-- }}}

-- {{{ local function clan_roster
-- The owner's chosen or made buddies: { class, profile, role }.
local function clan_roster(owner)
    local list = {}
    local q = CharDBQuery("SELECT class, profile, role FROM buddy_roster WHERE owner = " .. owner .. " AND class <> 0")
    if q then
        repeat list[#list + 1] = { class = q:GetUInt32(0), profile = q:GetUInt32(1), role = q:GetUInt32(2) } until not q:NextRow()
    end
    return list
end
-- }}}

-- {{{ local function choose
-- Resolve a pick for one slot and write it. roster: the clan as the caller
-- knows it (the chosen buddy is appended, so a caller filling several slots
-- in a row passes the same table). Returns the buddy, or nil and why.
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
-- }}}

-- {{{ local function give_death_knight_buddies
-- A death-knight owner's four buddies, chosen at once (death knights of
-- random races) and written as chosen rows in one statement each, so they
-- don't depend on owed rows landing first. Only for a death knight whose
-- soul is given (traded_now: the trade just happened and its ledger write
-- is still queued), and only if it has no buddies yet: never more than four.
local DEATH_KNIGHT_BUDDIES = 4
local function give_death_knight_buddies(player, traded_now)
    if player:GetClass() ~= CLASS_DEATH_KNIGHT then return end
    local owner = player:GetGUIDLow()
    if not traded_now and not CharDBQuery("SELECT 1 FROM basic_718_souls WHERE dk = " .. owner .. " AND state = 1") then return end
    if CharDBQuery("SELECT 1 FROM buddy_roster WHERE owner = " .. owner .. " LIMIT 1") then return end
    local roster = {}
    for slot = 1, DEATH_KNIGHT_BUDDIES do
        local b, err = Choice.resolve({ RC = RC, TD = TD, Spender = Spender, rand = math.random,
            team = team_name(player), owner_is_dk = true, slot = slot, roster = roster })
        if not b then
            print(string.format("%sERROR: death knight %d buddy %d: %s", TAG, owner, slot, err))
            return
        end
        CharDBExecute(string.format("INSERT IGNORE INTO buddy_roster (owner, slot, class, race, profile, role) "
            .. "VALUES (%d, %d, %d, %d, %d, %d)", owner, slot, b.class, b.race, b.profile, b.role))
        roster[#roster + 1] = { class = b.class, profile = b.profile, role = b.role }
    end
    player:SendBroadcastMessage("Four who fell beside you rise again. They will find you.")
end
-- The soul trade (death-knight-souls.lua) calls this; a plain global, since
-- the two scripts are loaded separately.
BuddiesGiveDeathKnightBuddies = function(player) give_death_knight_buddies(player, true) end
-- }}}

local join_clan_later       -- defined below, with the player events

-- {{{ local function found_clan
-- Ask the server to make the guild, then look a moment later: it runs the
-- command on its next tick. Success: record it and invite the buddies made
-- so far. Otherwise say so (a name the server's rules refuse).
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
        -- buddies in the world now join 5 seconds later; the rest when they appear
        local q = CharDBQuery("SELECT buddy FROM buddy_roster WHERE owner = " .. owner .. " AND buddy <> 0")
        if q then repeat
            local b = GetPlayerByGUID(GetPlayerGUID(q:GetUInt32(0)))
            if b then join_clan_later(b) end
        until not q:NextRow() end
        p:SendBroadcastMessage(string.format('The clan "%s" is founded.', name))
    end, 2000, 1)
end
-- }}}

-- {{{ local function try_clan_name
-- A typed name: check it, then found the clan, or say why not (a joke for
-- a taken one). Empty text does nothing.
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
-- The soul trade in Acherus uses the same; plain globals, since the two
-- scripts are loaded separately.
BuddiesTryClanName  = function(player, speaker, code) try_clan_name(player, speaker, code) end
BuddiesClanPopup    = CLAN_POPUP
-- }}}

-- {{{ local function show_menu
local function show_menu(player, creature, page)
    player:GossipClearMenu()
    local classes, races = Choice.menu(RC, team_name(player), false)
    -- no clan yet: each pick also names the clan, typed in its pop-up box
    local ask_name = not player:IsInGuild()
    local popup    = ask_name and CLAN_POPUP or nil
    local first    = ask_name and " as my first buddy, and I'd like to name our clan." or ", please."
    if page == INTID_CLASSES then
        for _, c in ipairs(classes) do
            local text = ask_name and ("I want " .. article(c.name):lower() .. " " .. c.name .. first) or (article(c.name) .. " " .. c.name .. first)
            player:GossipMenuAddItem(GOSSIP_ICON_CHAT, text, 0, INTID_CLASS + c.id, ask_name, popup)
        end
    elseif page == INTID_RACES then
        for _, r in ipairs(races) do
            local text = ask_name and ("I want someone of the " .. r.name .. " people" .. first) or ("Someone of the " .. r.name .. " people.")
            player:GossipMenuAddItem(GOSSIP_ICON_CHAT, text, 0, INTID_RACE + r.id, ask_name, popup)
        end
    else
        if owed_slot(player:GetGUIDLow()) then
            player:GossipMenuAddItem(GOSSIP_ICON_CHAT, "I know what kind of fighter I want.", 0, INTID_CLASSES)
            player:GossipMenuAddItem(GOSSIP_ICON_CHAT, "I know which people I want them from.", 0, INTID_RACES)
        end
    end
    player:GossipSendMenu(TEXT_OWED, creature)
end
-- }}}

-- {{{ local function remove_wanderer
local function remove_wanderer(creature)
    local low = creature:GetGUIDLow()
    local owner = owner_of[low]
    if owner then wanderer_of[owner] = nil end
    owner_of[low] = nil
    turned_at[low] = nil
    turning[low] = nil
    local fire = fire_of[low]
    fire_of[low] = nil
    if fire then
        local go = creature:GetMap():GetWorldObject(fire)
        if go then go:Despawn() end
    end
    creature:RemoveEvents()
    creature:DespawnOrUnsummon(0)
end
-- }}}

-- {{{ local function go_on_break
-- Every owed buddy is chosen: a campfire, a seat, jokes, and gone once no
-- player is in sight.
local function go_on_break(creature)
    creature:RemoveEvents()
    turning[creature:GetGUIDLow()] = nil        -- any turn in progress was among those events
    creature:MoveStop()
    local x, y, z, o = creature:GetLocation()
    local fire = creature:SummonGameObject(CAMPFIRE, x + math.cos(o) * 2, y + math.sin(o) * 2, z, o, 3600)
    if fire then fire_of[creature:GetGUIDLow()] = fire:GetGUID() end
    creature:SetStandState(STAND_STATE_SIT)
    creature:RegisterEvent(function(_, _, _, c)
        local near = c:GetPlayersInRange(JOKE_RANGE)
        if near and #near > 0 then c:SendUnitSay(JOKES[math.random(#JOKES)], 0) end
    end, JOKE_EVERY_MS, 0)
    creature:RegisterEvent(function(_, _, _, c)
        local seen = c:GetPlayersInRange(SIGHT)
        if not seen or #seen == 0 then remove_wanderer(c) end
    end, 5000, 0)
end
-- }}}

-- {{{ local function start_turn
-- Turn toward the owner a step at a time; stops when facing them, when he
-- starts walking, or when the owner is gone.
local function start_turn(creature, player)
    local low = creature:GetGUIDLow()
    if turning[low] then return end
    turning[low] = true
    local step = TURN_SPEED * TURN_STEP_MS / 1000
    creature:RegisterEvent(function(event_id, _, _, c)
        local owner = owner_of[c:GetGUIDLow()]
        local p = owner and GetPlayerByGUID(GetPlayerGUID(owner))
        local delta = p and ((c:GetAngle(p) - c:GetO() + math.pi) % (2 * math.pi) - math.pi)
        if not delta or c:IsMoving() or math.abs(delta) <= TURN_DONE then
            turning[c:GetGUIDLow()] = nil
            return c:RemoveEventById(event_id)
        end
        local turn = math.min(math.abs(delta), step) * (delta > 0 and 1 or -1)
        c:SetFacing((c:GetO() + turn) % (2 * math.pi))
    end, TURN_STEP_MS, 0)
end
-- }}}

-- {{{ local function follow_tick
-- Once a second: keep near the owner (stop at 7 yards, set off again past
-- 15), turn toward them at most every 5 seconds, and leave if they are gone.
local function follow_tick(_, _, _, creature)
    local owner = owner_of[creature:GetGUIDLow()]
    local player = owner and GetPlayerByGUID(GetPlayerGUID(owner))
    if not player or not player:IsInWorld() or player:GetMapId() ~= creature:GetMapId() then
        return remove_wanderer(creature)
    end
    local d = creature:GetDistance(player)
    if d > FOLLOW_AGAIN_AT then
        local px, py, pz = player:GetLocation()
        local cx, cy     = creature:GetLocation()
        local k = STOP_AT / d
        creature:MoveTo(1, px + (cx - px) * k, py + (cy - py) * k, pz)
    elseif not creature:IsMoving() then
        local now, low = GetCurrTime(), creature:GetGUIDLow()
        if not turned_at[low] or now - turned_at[low] >= TURN_EVERY_MS then
            turned_at[low] = now
            start_turn(creature, player)
        end
    end
end
-- }}}

-- {{{ local function summon_wanderer
-- Beside the owner, unless one is already theirs or the spot is crowded.
local function summon_wanderer(player)
    local owner = player:GetGUIDLow()
    if player:GetClass() == CLASS_DEATH_KNIGHT or player:GetLevel() < WANDER_FROM_LEVEL then return end
    if not owed_slot(owner) then return end
    if wanderer_of[owner] then return end

    local near = #(player:GetCreaturesInRange(CROWD_RANGE, VALLEY) or {}) + #(player:GetCreaturesInRange(CROWD_RANGE, WANDERER) or {})
    if near > CROWD_MAX then
        -- crowded: try again shortly, until he fits or nothing is owed
        player:RegisterEvent(function(_, _, _, p) summon_wanderer(p) end, CROWD_RETRY_MS, 1)
        return
    end

    local x, y, z, o = player:GetLocation()
    local c = player:SpawnCreature(WANDERER, x, y, z, o, TEMPSUMMON_MANUAL_DESPAWN, 0)
    if not c then
        print(string.format("%sERROR: could not summon Sargobras for owner %d", TAG, owner))
        return
    end
    wanderer_of[owner]      = c:GetGUID()
    owner_of[c:GetGUIDLow()] = owner
    c:RegisterEvent(follow_tick, 1000, 0)
end
-- }}}

-- {{{ local function on_hello
local function on_hello(event, player, creature)
    if creature:GetEntry() == WANDERER and owner_of[creature:GetGUIDLow()] ~= player:GetGUIDLow() then
        player:GossipClearMenu()
        return player:GossipSendMenu(TEXT_NOT_YOURS, creature)
    end
    if player:GetClass() == CLASS_DEATH_KNIGHT or not owed_slot(player:GetGUIDLow()) then
        player:GossipClearMenu()
        return player:GossipSendMenu(TEXT_NONE, creature)
    end
    show_menu(player, creature, nil)
end
-- }}}

-- {{{ local function on_select
local function on_select(event, player, creature, sender, intid, code)
    if intid == INTID_CLASSES or intid == INTID_RACES then return show_menu(player, creature, intid) end

    local pick
    if intid > INTID_RACE then pick = { kind = "race", id = intid - INTID_RACE }
    elseif intid > INTID_CLASS then pick = { kind = "class", id = intid - INTID_CLASS } end
    player:GossipComplete()
    if not pick then return end

    local owner = player:GetGUIDLow()
    local owed  = owed_slots(owner)
    if #owed == 0 then return end
    local b = choose(player, owed[1], clan_roster(owner), pick)
    if not b then
        creature:SendUnitSay("Hm. The stars are cloudy tonight. Ask me again in a moment.", 0)
        return
    end
    local race_name = RC.races[b.race].name
    creature:SendUnitSay(string.format("%s %s %s. They'll find you soon.",
        article(race_name), race_name, RC.classes[b.class].name), 0)

    -- the name typed in the pick's pop-up, when there was no clan yet
    try_clan_name(player, creature, code)

    -- that was the last owed buddy: a wanderer goes on break (he still
    -- answers, so an unnamed clan can be named at the fire)
    if #owed == 1 and creature:GetEntry() == WANDERER then go_on_break(creature) end
end
-- }}}

-- {{{ player events
-- {{{ local function join_clan_later
-- A buddy that appears without being in its owner's clan joins it 5
-- seconds later, quietly. The owner leads the clan guild, so
-- the guild is found by its leader even when the owner is offline.
local CLAN_JOIN_DELAY_MS = 5000
join_clan_later = function(buddy)
    if buddy:IsInGuild() then return end
    local q = CharDBQuery("SELECT owner FROM buddy_roster WHERE buddy = " .. buddy:GetGUIDLow())
    if not q then return end
    local owner = q:GetUInt32(0)
    buddy:RegisterEvent(function(_, _, _, b)
        if b:IsInGuild() then return end
        local guild = GetGuildByLeaderGUID(GetPlayerGUID(owner))
        if not guild then return end                            -- no clan yet: joins at a later appearance
        guild:AddMember(b)
    end, CLAN_JOIN_DELAY_MS, 1)
end
-- }}}

local function on_login(event, player)
    give_death_knight_buddies(player, false)
    join_clan_later(player)
    summon_wanderer(player)
end

local function on_level_change(event, player, old_level)
    -- a tenth level owes a new slot, written by the buddy module on the same
    -- level-up through the database queue: act a moment later
    if math.floor(player:GetLevel() / 10) > math.floor(old_level / 10) then
        player:RegisterEvent(function(_, _, _, p) summon_wanderer(p) end, 2000, 1)
    end
end

local function on_logout(event, player)
    local guid = wanderer_of[player:GetGUIDLow()]
    if not guid then return end
    local c = player:GetMap():GetWorldObject(guid)
    if c then remove_wanderer(c) else wanderer_of[player:GetGUIDLow()] = nil end
end
-- }}}

if roster_ready() then
    RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,        on_login)
    RegisterPlayerEvent(PLAYER_EVENT_ON_LEVEL_CHANGE, on_level_change)
    RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT,       on_logout)
    for _, entry in ipairs({ VALLEY, WANDERER }) do
        RegisterCreatureGossipEvent(entry, GOSSIP_EVENT_ON_HELLO,  on_hello)
        RegisterCreatureGossipEvent(entry, GOSSIP_EVENT_ON_SELECT, on_select)
    end
end
