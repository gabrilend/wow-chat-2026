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
--     that owner may ask him. He trails about 10 yards behind them at their
--     own pace (walking when they walk), lets go when they stop, sets off
--     again once they are 25 yards away, and turns to face them now and then.
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
-- four buddies, death knights of random races, from the soul trade with
-- the Sargobras at the gate of Acherus on (owner, 2026-09-26: "4
-- buddy-bots per Death Knight [...] never any more [...] when they accept
-- a soul-trade with Sargobras in Acherus"), by level since 2026-10-12: one
-- at 55, 57, 59 and 60. death-knight-souls.lua calls
-- BuddiesGiveDeathKnightBuddies on the trade (after the rise, for a
-- skipper); login and each level catch up the rest.
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
local Valleys = dofile(script_dir() .. "data/starting-valleys.lua")
local Deck    = dofile(script_dir() .. "lib/valley-deck.lua")

local VALLEY, WANDERER                   = 6170001, 6170002
-- the wanderer in Don Rigoberto's Lost Hat, one time in ten (owner,
-- 2026-10-12: "a 10% chance to spawn with a hat"); his own creature, so the
-- hat is in his outfit (buddies_outfits.cpp). Everything said of WANDERER
-- holds for him too (is_wanderer).
local WANDERER_HATTED, HAT_CHANCE        = 6170003, 0.10
local function is_wanderer(entry) return entry == WANDERER or entry == WANDERER_HATTED end
local TEXT_OWED, TEXT_NOT_YOURS, TEXT_NONE = 6170001, 6170002, 6170003
local CAMPFIRE                           = 1798           -- a stock "Campfire" object

local PLAYER_EVENT_ON_LOGIN        = 3
local PLAYER_EVENT_ON_LOGOUT       = 4
local PLAYER_EVENT_ON_LEVEL_CHANGE = 13
local GOSSIP_EVENT_ON_HELLO        = 1
local GOSSIP_EVENT_ON_SELECT       = 2
local GOSSIP_ICON_CHAT             = 0
local GOSSIP_ICON_FLIGHT           = 2    -- the wings: a journey
local TEMPSUMMON_MANUAL_DESPAWN    = 8
local STAND_STATE_SIT, STAND_STATE_STAND = 1, 0
local CLASS_DEATH_KNIGHT           = 6

-- {{{ tuning (owner decisions, 617b)
local WANDER_FROM_LEVEL = 10        -- below this only the valley Sargobras
-- his circle (owner, 2026-10-12: "he should stand 5-10 yards away from
-- you", "As soon as you're more than 15 yards away, he starts walking
-- toward a new waypoint that's created on a new circle near you")
local CIRCLE_MIN        = 5         -- yards: the circle's radius is drawn from here ...
local CIRCLE_MAX        = 10        -- ... to here
local MOVE_ON_AT        = 15        -- yards from him: past this the owner gets a new circle
local PULL_STEP         = 1.5       -- yards: a spot with no direct route is pulled in this much at a time ...
local PULL_FLOOR        = 2         -- ... down to this
local SIDE_STEPS        = { 0, 0.5, -0.5, 1.0, -1.0 }  -- radians tried either side of his line in, at each radius
local DIRECT_FACTOR     = 1.25      -- a walk at most this many times the straight line (plus DIRECT_SLACK) is "direct"
local DIRECT_SLACK      = 1         -- yards
local FAN_STEP          = 0.4       -- radians (~23 degrees) between neighbouring tiers' spots on one circle
local ARRIVED_AT        = 2         -- yards from his spot: arrived
local WALK_GIVE_UP_TICKS = 30       -- ticks (seconds) walking without arriving: he stands where he got to
local FACE_SLACK        = 0.17      -- radians (~10 degrees) off before he turns again
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
-- his break (owner, 2026-10-04: fire under the player, harder per tier;
-- walk off at an angle, face the fire, sit untargetable, go with the fire)
local FIRE_SECONDS      = 120       -- the fire burns this long; he goes with it
local FIRE_RADIUS       = 2.5       -- yards from the fire's centre that burn
local FIRE_PCT_PER_TIER = 2         -- percent of max health a second, per tier he serves
local SIT_RADIUS        = 3         -- yards from the fire to his seat
local SIT_SWING         = 1.0       -- radians (~57 degrees) he swings round the fire, off the line back
local SEAT_REACHED      = 0.75      -- yards: close enough to the seat
local WALK_GIVE_UP_MS   = 15000     -- a seat he can't reach: sit where he is after this long
-- buddies following a "somewhere else" deal (155d1, owner 2026-10-05:
-- "back and to the left 45 degrees, or to the right 45 degrees")
local DEAL_BUDDY_ANGLE  = math.pi * 3 / 4   -- radians from the partner's facing: 45 degrees off straight back
local DEAL_BUDDY_DIST   = 3         -- yards behind the partner, the first pair
local DEAL_BUDDY_STEP   = 2         -- yards further out for each later pair
-- }}}

-- {{{ game constants (3.3.5a)
local UNIT_FLAG_NOT_SELECTABLE = 0x02000000
local SCHOOL_FIRE              = 2
-- }}}

-- {{{ menu icons
-- The 3.3.5a client draws eleven gossip icons: 0 chat bubble, 1 bag,
-- 2 wings, 3 book, 4 cogwheel, 5 cogwheel (alt), 6 coin bag, 7 talk
-- bubble with dots, 8 tabard, 9 crossed swords, 10 yellow dot. One per
-- class and per people (owner, 2026-09-29: "can we pick one for each race
-- / class?"); eleven icons for nineteen rows, so peoples reuse some. A
-- first pass, by feel; retune freely. A missing id falls back to the chat
-- bubble. Class and race ids are the client's (ChrClasses, ChrRaces).
local CLASS_ICON = {
    [1]  = 9,   -- Warrior       crossed swords
    [2]  = 8,   -- Paladin       tabard (an order's colours)
    [3]  = 2,   -- Hunter        wings
    [4]  = 6,   -- Rogue         coin bag
    [5]  = 10,  -- Priest        yellow dot (a light)
    [7]  = 4,   -- Shaman        cogwheel (the turning of the elements)
    [8]  = 3,   -- Mage          book
    [9]  = 5,   -- Warlock       cogwheel (alt)
    [11] = 1,   -- Druid         bag (the forager's)
}
local RACE_ICON = {
    [1]  = 8,   -- Human         tabard
    [2]  = 9,   -- Orc           crossed swords
    [3]  = 6,   -- Dwarf         coin bag
    [4]  = 2,   -- Night Elf     wings
    [5]  = 5,   -- Undead        cogwheel (alt)
    [6]  = 1,   -- Tauren        bag
    [7]  = 4,   -- Gnome         cogwheel
    [8]  = 3,   -- Troll         book
    [10] = 10,  -- Blood Elf     yellow dot
    [11] = 7,   -- Draenei       talk bubble with dots
}
-- }}}

-- intids: 1 ask for a class, 2 ask for a people, 3 name the clan,
-- 100+class, 200+race
local INTID_CLASSES, INTID_RACES, INTID_CLASS, INTID_RACE = 1, 2, 100, 200
local INTID_NAME                                         = 3
-- [FIXME 2026-10-03, Claude]: TEMPORARY, a test. The old name box, offered
-- beside the spoken naming. It worked once per side on account 101
-- (Constine, Alliance; Growth, Horde; 2026-09-29) and never since (Karson,
-- Alliance). The owner's test: a new Horde character on the same account.
-- If its box answer arrives (gossip-trace.log: "answer received ... code"),
-- the box works once per side per account. Remove with gossip-trace.lua.
local INTID_NAME_BOX                                     = 4
local INTID_ELSEWHERE                                    = 5   -- "Actually, can I go somewhere else?" (155d1)

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

-- Owner guid (low) -> { slot -> the wandering Sargobras's guid }: one per
-- owed slot, a Sargobras per tier (owner, 2026-09-30: "Remember, one
-- sargobras per tier! Eventually they're gonna have different outfits.");
-- wanderer guid (low) -> owner guid (low), and -> the slot he serves; the
-- campfire each wanderer lit. Summoned creatures are never saved, so this
-- only has to live as long as the server runs.
local wanderer_of, owner_of, slot_of, fire_of = {}, {}, {}, {}
-- Wanderer guid (low) -> whether a turn is under way.
local turning = {}
-- Wanderer guid (low) -> his circle { cx, cy, cz, r } (the owner's feet
-- when it was made, and its radius) and his spot on its rim { x, y, z };
-- walking[low] = ticks spent walking to the spot, nil once standing there.
local circle_of, spot_of, walking = {}, {}, {}

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
-- A death-knight owner's buddies: four in all, never more, death knights
-- of random races (owner, 2026-09-26), and since 2026-10-12 by level: "one
-- buddy-bot every other level, so: 55 = 1 buddy-bot, 57 = 2, 59 = 3, 60 =
-- 4". Only for a death knight whose soul is given (traded_now: the trade
-- just happened and its ledger write is still queued). Called at the
-- trade (or after the rise, for a skipper), at login and at every level.
-- For each slot whose level the owner has reached:
--   no row yet        chosen now and written as a chosen row (one
--                     statement, so it doesn't wait on an owed row); the
--                     buddy module makes it at the owner's level
--   set aside (5)     back (3, remake): the module logs it in and makes it
--                     again at the owner's level ("placed to the side for
--                     Gabrubre to recollect when she hits level 60 again")
--   anything else     already with the owner, or on its way: left alone
-- A slot not reached yet is left as it is: chosen when reached, or, if
-- set aside by scripts/reset-dk-soul-trade, waiting. Rows are written
-- through the database queue, so two calls in one moment could both see a
-- slot empty; INSERT IGNORE keeps the first (owner and slot are the key).
local DEATH_KNIGHT_SLOT_LEVEL = { 55, 57, 59, 60 }
local STAGE_REMAKE, STAGE_ASIDE = 3, 5               -- buddy_roster.stage (04-buddy-roster: 3 made again at login, 5 set aside)
local function give_death_knight_buddies(player, traded_now)
    if player:GetClass() ~= CLASS_DEATH_KNIGHT then return end
    local owner, level = player:GetGUIDLow(), player:GetLevel()
    if not traded_now and not CharDBQuery("SELECT 1 FROM basic_718_souls WHERE dk = " .. owner .. " AND state = 1") then return end

    -- the rows as they are, and the clan so far (the chooser balances against it)
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
                team = team_name(player), owner_is_dk = true, slot = slot, roster = roster })
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

    -- what's still to come, in levels
    local later = {}
    for slot, at in ipairs(DEATH_KNIGHT_SLOT_LEVEL) do if level < at then later[#later + 1] = tostring(at) end end
    player:SendBroadcastMessage((came == 1 and "One who fell beside you rises again." or (came .. " who fell beside you rise again."))
        .. " They will find you."
        .. (#later > 0 and (" More will come at level " .. table.concat(later, ", ") .. ".") or ""))
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
-- A spoken (or typed) name: check it, then found the clan, or say why not
-- (a joke for a taken one). Empty text does nothing.
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

-- {{{ the clan name, spoken aloud
-- The client's own name box doesn't work here: on 2026-10-03 the server
-- sent menus with boxed options (first page, second page, plain icons and
-- fancy ones) and not one boxed answer ever came back, while plain clicks
-- on the same menus did (gossip-trace.lua's packet log). So Sargobras asks,
-- the window closes, and the owner says the name aloud in /say within
-- NAME_LISTEN_MS. The words still reach everyone nearby: naming a clan is
-- said, not whispered.
local NAME_LISTEN_MS        = 60000
local PLAYER_EVENT_ON_CHAT  = 18
local CHAT_MSG_SAY          = 1
local listening = {}            -- owner guid (low) -> { npc = creature guid, map = map id, until_ms = game time }

local function listen_for_name(player, creature)
    listening[player:GetGUIDLow()] = { npc = creature:GetGUID(), until_ms = GetCurrTime() + NAME_LISTEN_MS }
    creature:SendUnitSay("Every clan needs a name. Say it aloud, and I'll see it written. Letters and spaces, two to twenty-four.", 0)
end

-- what was said in /say by an owner he is listening to is the name;
-- anything else, and anyone else, passes untouched
local function on_chat(event, player, msg, msg_type, lang)
    local wait = listening[player:GetGUIDLow()]
    if not wait or msg_type ~= CHAT_MSG_SAY then return end
    listening[player:GetGUIDLow()] = nil
    if GetCurrTime() > wait.until_ms then return end                 -- too late: he stopped listening
    local creature = player:GetMap():GetWorldObject(wait.npc)
    if not creature then
        -- a wandering Sargobras can leave between the asking and the
        -- saying: tell the owner plainly, the clan isn't named
        print(string.format('%sERROR: owner %d said a clan name but Sargobras (%s) is gone; nothing founded',
            TAG, player:GetGUIDLow(), tostring(wait.npc)))
        player:SendBroadcastMessage("Sargobras isn't here to hear it. Ask him again.")
        return
    end
    try_clan_name(player, creature, msg)
end
-- The soul trade in Acherus names its clan the same way (a plain global,
-- since the two scripts are loaded separately).
BuddiesListenForClanName = function(player, creature) listen_for_name(player, creature) end
-- }}}

-- {{{ local function may_go_elsewhere
-- The valley Sargobras offers "somewhere else" to level-1 characters only
-- (155d1). Nothing is stored: at level 2 the option is simply not offered,
-- and a character returned to level 1 gets it back, with the same order.
-- Death knights never meet him (they start in Acherus).
local function may_go_elsewhere(player, creature)
    return creature:GetEntry() == VALLEY and player:GetLevel() == 1
       and player:GetClass() ~= CLASS_DEATH_KNIGHT
end
-- }}}

-- {{{ local function go_elsewhere
-- Deal the character's next valley from its own deck (lib/valley-deck.lua),
-- send it there, bind its hearthstone there (the same position and area the
-- creation step binds a new character to), and count the arrival toward the
-- rotation's batch of 30 when the dealt valley is the faction's current one
-- (owner, 2026-10-04: "let's say yes"). The count is a +1 in the database
-- (dealt_in_batch), which the creation patch B028 reads fresh; a dealt
-- valley that is not the current one has no batch to join, and the WHERE
-- leaves the row untouched.
local function go_elsewhere(player, creature)
    local team    = player:GetTeam()                         -- 0 Alliance, 1 Horde
    local valleys = Valleys[team]
    local x, y    = player:GetLocation()
    local here    = Deck.standing_in(valleys, player:GetMapId(), x, y)
    local index   = Deck.next(player:GetGUIDLow(), here)
    local v       = valleys[index]

    creature:SendUnitSay(string.format("%s, then. Hold still.", v.name), 0)
    player:SetBindPoint(v.x, v.y, v.z, v.map, v.zone)
    player:Teleport(v.map, v.x, v.y, v.z, v.o)

    -- buddies already chosen come along (owner, 2026-10-05): each lands
    -- behind the partner at a 45-degree angle off straight back, the first
    -- to the left, the second to the right, further ones a step further
    -- out on the same two lines; all facing the way the partner faces.
    -- Dropped a yard above the arrival point's height so uneven ground
    -- never puts one underneath it. Buddies not in the world stay put
    -- (their partner's hearthstone fetches them later, buddy-hearth.lua).
    local q = CharDBQuery("SELECT buddy FROM buddy_roster WHERE owner = " .. player:GetGUIDLow() .. " AND buddy <> 0 ORDER BY slot")
    if q then
        local i = 0
        repeat
            local b = GetPlayerByGUID(GetPlayerGUID(q:GetUInt32(0)))
            if b and b:IsInWorld() then
                i = i + 1
                local side  = (i % 2 == 1) and 1 or -1                       -- 1 back-left, -1 back-right
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
-- }}}

-- {{{ local function show_menu
-- No clan yet: one option, to name it (owner, 2026-10-03: "we should make
-- Sargobras have ONE option, which lets you pick a clan name. Once you've
-- done that, then he presents the [...] options"), so a name that fails
-- never costs a pick, and an owner whose buddies are all chosen can still
-- name the clan. With a clan: every class, then every people, each with
-- its own icon (owner, 2026-09-29: "can we put them all on the first menu
-- instead of having a sub-menu?"). `page` is no longer used; kept so an
-- old menu still open in a client, whose options ask for a page, lands here.
local function show_menu(player, creature, page)
    player:GossipClearMenu()
    if not player:IsInGuild() then
        player:GossipMenuAddItem(GOSSIP_ICON_CHAT, "First, our clan needs a name.", 0, INTID_NAME)
        player:GossipMenuAddItem(GOSSIP_ICON_CHAT, "(test) Type our clan's name in a box.", 0, INTID_NAME_BOX, true, CLAN_POPUP)
    elseif owed_slot(player:GetGUIDLow()) then
        local classes, races = Choice.menu(RC, team_name(player), false)
        for _, c in ipairs(classes) do
            local text = c.name                 -- just the name (owner, 2026-09-29: "\"paladin\" or \"druid\" [...] and that's it")
            player:GossipMenuAddItem(CLASS_ICON[c.id] or GOSSIP_ICON_CHAT, text, 0, INTID_CLASS + c.id)
        end
        for _, r in ipairs(races) do
            player:GossipMenuAddItem(RACE_ICON[r.id] or GOSSIP_ICON_CHAT, r.name, 0, INTID_RACE + r.id)
        end
    end
    if may_go_elsewhere(player, creature) then
        player:GossipMenuAddItem(GOSSIP_ICON_FLIGHT, "Actually, can I go somewhere else?", 0, INTID_ELSEWHERE)
    end
    player:GossipSendMenu(TEXT_OWED, creature)
end
-- }}}

-- {{{ local function remove_wanderer
local function remove_wanderer(creature)
    local low = creature:GetGUIDLow()
    local owner = owner_of[low]
    if owner and wanderer_of[owner] and slot_of[low] then wanderer_of[owner][slot_of[low]] = nil end
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
-- }}}

-- {{{ local function go_on_break
-- His tier is chosen (owner, 2026-10-04): the campfire is lit right under
-- the player who chose; he turns and walks off at an angle round it, faces
-- it, sits, and can't be targeted by anyone while he sits; he tells jokes;
-- he goes when the fire does (FIRE_SECONDS). The fire burns whoever stands
-- in it, harder for each tier he serves.
--
-- The geometry, with F the fire (the player's feet) and S where he stands:
--   a0   = the direction from F to S            atan2(Sy - Fy, Sx - Fx)
--   a    = a0 swung round by SIT_SWING           so he walks off at an angle,
--                                               not straight back from you
--   seat = F + SIT_RADIUS * (cos a, sin a)      on a circle round the fire
--   face = the direction from seat to F         atan2(Fy - y, Fx - x)
-- He turns toward `face` in small steps (as turn_to does), then sits.
local function go_on_break(creature, player)
    local low = creature:GetGUIDLow()
    creature:RemoveEvents()
    turning[low]   = nil                         -- any turn in progress was among those events
    walking[low]   = nil
    creature:MoveIdle()                          -- drop any walk to his spot
    creature:MoveStop()

    -- the fire, under the player
    local fx, fy, fz = player:GetLocation()
    local fire = creature:SummonGameObject(CAMPFIRE, fx, fy, fz, player:GetO(), FIRE_SECONDS)
    if fire then fire_of[low] = fire:GetGUID() end

    -- the seat, on a circle round the fire, swung off to one side
    local sx, sy  = creature:GetLocation()
    local a       = math.atan2(sy - fy, sx - fx) + SIT_SWING
    local seat_x  = fx + math.cos(a) * SIT_RADIUS
    local seat_y  = fy + math.sin(a) * SIT_RADIUS
    local seat_z  = creature:GetMap():GetHeight(seat_x, seat_y) or fz
    creature:SetWalk(true)
    creature:MoveTo(1, seat_x, seat_y, seat_z)

    -- arrived (or given up walking): turn to the fire a step at a time, then sit
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

    -- the fire burns: each second, whoever stands in it loses FIRE_PCT_PER_TIER
    -- percent of their health per tier he serves (tier = his slot: 1 for
    -- the level-1 buddy, 2 for level 10, ...). The player burns themself,
    -- so Sargobras is never in a fight with anyone.
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
-- }}}

-- {{{ local function slot_level
-- The level a slot is owed from, as the buddy module counts it
-- (buddies_clan.cpp, BuddySlotLevel): 1 for the first, then every tenth.
local function slot_level(slot) return slot == 1 and 1 or (slot - 1) * 10 end
-- }}}

-- {{{ local function turn_to
-- Turn toward the angle `want()` gives (radians; nil ends the turn) a step
-- at a time; stops when facing it or when he starts walking.
local function turn_to(creature, want)
    local low = creature:GetGUIDLow()
    if turning[low] then return end
    turning[low] = true
    local step = TURN_SPEED * TURN_STEP_MS / 1000
    creature:RegisterEvent(function(event_id, _, _, c)
        local a = want(c)
        local delta = a and ((a - c:GetO() + math.pi) % (2 * math.pi) - math.pi)
        -- "moving" is asked as "not stopped": the pinned Lua engine (July
        -- 2026) gives IsMoving to players only; IsStopped is on every unit
        if not delta or not c:IsStopped() or math.abs(delta) <= TURN_DONE then
            turning[c:GetGUIDLow()] = nil
            return c:RemoveEventById(event_id)
        end
        local turn = math.min(math.abs(delta), step) * (delta > 0 and 1 or -1)
        c:SetFacing((c:GetO() + turn) % (2 * math.pi))
    end, TURN_STEP_MS, 0)
end
-- }}}

-- {{{ local function direct_route
-- Whether the owner could walk straight to (x, y, z): the walk along the
-- navigation mesh is at most DIRECT_FACTOR times the straight line plus
-- DIRECT_SLACK yards (owner, 2026-10-12: "use the navmesh and if there
-- isn't a direct route to the player for the place he picks, then pull him
-- in closer until there is"). The mesh is asked through B051's
-- GetWalkablePathLength; a server built without it can't be asked, so
-- line of sight stands in, and that is an error, logged once per run.
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
-- }}}

-- {{{ local function new_circle
-- A new circle round the owner's feet, and his spot on its rim: radius
-- drawn from CIRCLE_MIN to CIRCLE_MAX, on the side he is coming from,
-- fanned by tier so several don't share a spot. A spot with no direct
-- route is tried a little to either side (SIDE_STEPS), then pulled in by
-- PULL_STEP, down to PULL_FLOOR; at the floor he takes the line in as it
-- is. The spot's height is the owner's: his walk along the mesh settles it
-- onto the ground (a height asked of the map from the sky would find a
-- roof or a bridge above).
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
-- }}}

-- {{{ local function walk_to_spot
-- Always a walk, never a run (owner, 2026-10-12: "when he paths to a new
-- location near you, he always walks, and also that he uses the navmesh
-- instead of walking straight towards it"): MoveTo with its path made
-- along the mesh.
local function walk_to_spot(creature)
    local s = spot_of[creature:GetGUIDLow()]
    creature:SetWalk(true)
    creature:MoveTo(0, s.x, s.y, s.z, true)
    walking[creature:GetGUIDLow()] = 0
end
-- }}}

-- {{{ local function follow_tick
-- Once a second, one of two states (owner, 2026-10-12; see 617b, "circles,
-- not a leash"):
--
--   walking (walking[low] set): on his way to his spot. Arrived (stopped
--     within ARRIVED_AT of it), or WALK_GIVE_UP_TICKS gone by: standing.
--   standing: he doesn't move. While the owner is within MOVE_ON_AT of him
--     he faces the circle's centre if the owner is inside the circle, the
--     owner if not. Past MOVE_ON_AT: if the owner's level is now below his
--     tier's he goes ("if your level isn't above the level that particular
--     Sargobras spawned for, he should disappear"), else a new circle is
--     made round the owner and he walks to it.
--
-- (2026-10-04 to 10-12 he was handed to the server's own follow, which
-- kept him 10 yards behind the owner; walking up to talk to him moved that
-- spot, and he walked away: "Sargobras running away when I try to talk to
-- him".)
--
-- Leaves if the owner is gone.
local function follow_tick(_, _, _, creature)
    local low    = creature:GetGUIDLow()
    local owner  = owner_of[low]
    local player = owner and GetPlayerByGUID(GetPlayerGUID(owner))
    if not player or not player:IsInWorld() or player:GetMapId() ~= creature:GetMapId() then
        return remove_wanderer(creature)
    end

    local s = spot_of[low]
    if walking[low] then
        walking[low] = walking[low] + 1
        local there = (creature:GetX() - s.x) ^ 2 + (creature:GetY() - s.y) ^ 2 <= ARRIVED_AT ^ 2
        if (there and creature:IsStopped()) or walking[low] >= WALK_GIVE_UP_TICKS then
            walking[low] = nil
            creature:MoveIdle()
        end
        return
    end

    if creature:GetDistance(player) > MOVE_ON_AT then
        if player:GetLevel() < slot_level(slot_of[low] or 1) then
            return remove_wanderer(creature)
        end
        new_circle(creature, player)
        return walk_to_spot(creature)
    end

    -- standing: face the centre while the owner is in the circle, else the owner
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
-- }}}

-- {{{ local function summon_wanderer
-- One near the owner for each owed slot the owner's level has reached that
-- has none yet, unless the spot is crowded with others' Sargobras (the
-- owner's own don't count toward the crowd). Each is his tier's level plus
-- one (owner, 2026-10-12: "if you hit level 30 then he should be level 31
-- [...] He wants you to know that he's always stronger than you"), appears
-- on his first circle's rim, and stands there.
local function summon_wanderer(player)
    local owner = player:GetGUIDLow()
    if player:GetClass() == CLASS_DEATH_KNIGHT or player:GetLevel() < WANDER_FROM_LEVEL then return end
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
        -- crowded: try again shortly, until they fit or nothing is owed
        player:RegisterEvent(function(_, _, _, p) summon_wanderer(p) end, CROWD_RETRY_MS, 1)
        return
    end

    local x, y, z = player:GetLocation()
    for _, slot in ipairs(slots) do
        if not mine[slot] then
            -- appear a little way out, in his tier's direction; his first
            -- circle is made from there and he is put straight on its rim
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
-- }}}

-- {{{ local function on_hello
local function on_hello(event, player, creature)
    if is_wanderer(creature:GetEntry()) and owner_of[creature:GetGUIDLow()] ~= player:GetGUIDLow() then
        player:GossipClearMenu()
        return player:GossipSendMenu(TEXT_NOT_YOURS, creature)
    end
    -- nothing for him to do: a death knight (named in Acherus), or an
    -- owner with a clan and every buddy chosen; a clanless owner always
    -- gets the naming option, buddies owed or not
    if player:GetClass() == CLASS_DEATH_KNIGHT or (player:IsInGuild() and not owed_slot(player:GetGUIDLow())) then
        player:GossipClearMenu()
        -- nothing owed, but a level-1 character may still ask to move on
        if may_go_elsewhere(player, creature) then
            player:GossipMenuAddItem(GOSSIP_ICON_FLIGHT, "Actually, can I go somewhere else?", 0, INTID_ELSEWHERE)
        end
        return player:GossipSendMenu(TEXT_NONE, creature)
    end
    show_menu(player, creature, nil)
end
-- }}}

-- {{{ local function on_select
local function on_select(event, player, creature, sender, intid, code)
    if intid == INTID_CLASSES or intid == INTID_RACES then return show_menu(player, creature, intid) end
    -- another valley (155d1); checked again here, as a menu can stay open past level 1
    if intid == INTID_ELSEWHERE then
        player:GossipComplete()
        if may_go_elsewhere(player, creature) then go_elsewhere(player, creature) end
        return
    end
    -- the box test (see INTID_NAME_BOX): the typed name, if it ever arrives
    if intid == INTID_NAME_BOX then
        player:GossipComplete()
        return try_clan_name(player, creature, code)
    end
    -- the clan's name: the window closes and he listens for it in /say
    if intid == INTID_NAME then
        player:GossipComplete()
        if player:IsInGuild() then return end       -- named meanwhile (another Sargobras, or Acherus)
        return listen_for_name(player, creature)
    end

    local pick
    if intid > INTID_RACE then pick = { kind = "race", id = intid - INTID_RACE }
    elseif intid > INTID_CLASS then pick = { kind = "class", id = intid - INTID_CLASS } end
    player:GossipComplete()
    if not pick then return end
    if not player:IsInGuild() then return end       -- an old menu still open from before the clan rule: name first

    local owner = player:GetGUIDLow()
    local owed  = owed_slots(owner)
    if #owed == 0 then return end
    -- a tier's own Sargobras serves his slot (while it is still owed);
    -- a valley Sargobras, the first owed
    local slot = owed[1]
    local mine = slot_of[creature:GetGUIDLow()]
    for _, s in ipairs(owed) do if s == mine then slot = mine end end
    local b = choose(player, slot, clan_roster(owner), pick)
    if not b then
        creature:SendUnitSay("Hm. The stars are cloudy tonight. Ask me again in a moment.", 0)
        return
    end
    local race_name = RC.races[b.race].name
    creature:SendUnitSay(string.format("%s %s %s. They'll find you soon.",
        article(race_name), race_name, RC.classes[b.class].name), 0)

    -- his tier is chosen: a wanderer goes on break (he still answers)
    if is_wanderer(creature:GetEntry()) then go_on_break(creature, player) end
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
    -- a death knight's buddies come by level (55, 57, 59, 60)
    give_death_knight_buddies(player, false)
    -- a tenth level owes a new slot, written by the buddy module on the same
    -- level-up through the database queue: act a moment later
    if math.floor(player:GetLevel() / 10) > math.floor(old_level / 10) then
        player:RegisterEvent(function(_, _, _, p) summon_wanderer(p) end, 2000, 1)
    end
end

local function on_logout(event, player)
    -- every tier's Sargobras leaves with the owner
    local mine = wanderer_of[player:GetGUIDLow()]
    if not mine then return end
    for _, guid in pairs(mine) do
        local c = player:GetMap():GetWorldObject(guid)
        if c then remove_wanderer(c) end
    end
    wanderer_of[player:GetGUIDLow()] = nil
end
-- }}}

if roster_ready() then
    RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,        on_login)
    RegisterPlayerEvent(PLAYER_EVENT_ON_LEVEL_CHANGE, on_level_change)
    RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT,       on_logout)
    RegisterPlayerEvent(PLAYER_EVENT_ON_CHAT,         on_chat)
    for _, entry in ipairs({ VALLEY, WANDERER, WANDERER_HATTED }) do
        RegisterCreatureGossipEvent(entry, GOSSIP_EVENT_ON_HELLO,  on_hello)
        RegisterCreatureGossipEvent(entry, GOSSIP_EVENT_ON_SELECT, on_select)
    end

    -- A reload of the Lua engine (".reload ale") forgets every wandering
    -- Sargobras's owner and stops his timers, but leaves him standing in
    -- the world, owned by no one, forever (2026-10-04). So on load, every
    -- wandering Sargobras near a player in the world goes, and each player
    -- gets theirs again as at login.
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
