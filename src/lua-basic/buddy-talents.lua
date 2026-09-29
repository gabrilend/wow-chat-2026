--------------------------------------------------------------------------------
-- buddy-talents.lua (issue 617g)
--
-- Buddies spend their own talent points. The bot module only does that for
-- its random bots, and basic has none; a buddy is an owned character logged
-- in as a bot, so without this script its points would sit unspent.
--
-- When it runs:
--   - a buddy levels up: its new point is spent;
--   - a buddy logs in: anything unspent is spent (and a re-roll owed from
--     while it was offline is done first);
--   - a player's talents are reset (a respec): if the player is a buddy, its
--     points are spent again; if the player owns buddies, every one of them
--     is reset for free and spent again ("re-rolled when the owner respecs",
--     Ritz 2026-09-25). Buddies offline at that moment are flagged in the
--     roster and re-rolled at their next login.
--
-- What to learn is decided by lib/buddy-talent-spender.lua (the same code
-- scripts/test-buddy-talents exercises); the class trees come from
-- data/buddy-talent-data.lua (scripts/generate-basic-talent-data).
--
-- Who is a buddy, and its shape: the characters-database roster of issue
-- 617a, `buddy_roster` (buddy = the buddy's character guid, profile = its
-- shape id 1-10, talents_reroll = 1 while a re-roll is owed). Until 617a
-- creates that table this script reports it once at startup and stays off.
--------------------------------------------------------------------------------

-- {{{ local function script_dir
-- The directory this file sits in, so the data file is found wherever the
-- lua_scripts tree is linked from (as in outland-flights.lua).
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
-- }}}

local DATA    = dofile(script_dir() .. "data/buddy-talent-data.lua")
local Spender = dofile(script_dir() .. "lib/buddy-talent-spender.lua")

local PLAYER_EVENT_ON_LOGIN          =  3
local PLAYER_EVENT_ON_LEVEL_CHANGE   = 13
local PLAYER_EVENT_ON_TALENTS_RESET  = 17

local TAG = "[buddy-talents] "

-- {{{ local function roster_ready
-- The roster table and the one column this script adds to it must exist.
-- Missing means 617a's install step has not run: an error, not a quiet
-- no-op, since every buddy would then keep its points unspent.
local function roster_ready()
    if not CharDBQuery("SHOW TABLES LIKE 'buddy_roster'") then
        print(TAG .. "ERROR: characters table buddy_roster is missing (issue 617a's install step not run?); buddy talents are OFF")
        return false
    end
    if not CharDBQuery("SHOW COLUMNS FROM buddy_roster LIKE 'talents_reroll'") then
        print(TAG .. "ERROR: buddy_roster has no talents_reroll column (617a's table predates 617g); buddy talents are OFF")
        return false
    end
    return true
end
-- }}}

-- {{{ local function buddy_row
-- The roster row of a character that is a buddy: shape id and whether a
-- re-roll is owed. nil when the character is not a buddy.
local function buddy_row(player)
    local q = CharDBQuery(string.format(
        "SELECT profile, talents_reroll FROM buddy_roster WHERE buddy = %d", player:GetGUIDLow()))
    if not q then return nil end
    return { shape = q:GetUInt32(0), reroll = q:GetUInt32(1) ~= 0 }
end
-- }}}

-- {{{ local function spend
-- Spend a buddy's free points by its shape, then read the talents back and
-- report any the server refused (the spender and the server's rules
-- disagreeing is a bug to fix, not something to paper over).
local function spend(player, shape)
    local free = player:GetFreeTalentPoints()
    if free == 0 then return end

    local cls = DATA.classes[player:GetClass()]
    if not cls then
        print(TAG .. "ERROR: " .. player:GetName() .. " has class " .. player:GetClass() .. ", which the talent data lacks"); return
    end
    if not cls.shapes[shape] then
        print(TAG .. "ERROR: " .. player:GetName() .. "'s roster shape " .. tostring(shape) .. " is not one of " .. cls.name .. "'s 1-" .. #cls.shapes .. "; nothing spent"); return
    end

    local spec  = player:GetActiveSpec()
    local has   = function(spell) return player:HasTalent(spell, spec) end
    local held  = Spender.read_held(cls, has)
    local steps, unspent = Spender.plan(cls, shape, held, free, math.random)

    for _, st in ipairs(steps) do player:LearnTalent(st.id, st.rank) end

    -- verify: every planned rank is now held
    local now = Spender.read_held(cls, has)
    for _, st in ipairs(steps) do
        if (now[st.id] or 0) < st.rank + 1 then
            print(string.format("%sERROR: %s: the server refused %s rank %d (shape %d, %s); the spender and the server's talent rules disagree",
                TAG, player:GetName(), st.name, st.rank + 1, shape, cls.shapes[shape].label))
            return
        end
    end
    if unspent > 0 then
        print(string.format("%sWARNING: %s: %d talent point(s) left unspent, no legal talent in shape %d (%s)",
            TAG, player:GetName(), unspent, shape, cls.shapes[shape].label))
    end
end
-- }}}

-- {{{ local function on_login
local function on_login(event, player)
    local row = buddy_row(player)
    if not row then return end
    if row.reroll then
        -- owed from an owner respec while this buddy was offline
        player:ResetTalents(true)
        CharDBExecute(string.format("UPDATE buddy_roster SET talents_reroll = 0 WHERE buddy = %d", player:GetGUIDLow()))
    end
    spend(player, row.shape)
end
-- }}}

-- {{{ local function on_level_change
local function on_level_change(event, player, old_level)
    local row = buddy_row(player)
    if row then spend(player, row.shape) end
end
-- }}}

-- {{{ local function after_reset
-- Runs one server tick after a talent reset was asked for. The reset hook
-- fires before the server decides (it can still refuse: not enough gold,
-- or no talents to reset), so the free points are compared: more than
-- before means the reset really happened.
local function after_reset(player, free_before)
    if player:GetFreeTalentPoints() <= free_before then return end   -- refused or nothing to reset

    local row = buddy_row(player)
    if row then spend(player, row.shape); return end                -- a buddy: spend again

    -- an owner: re-roll every buddy; flag them all, clear the flag for the
    -- ones online now as they are done
    local owner = player:GetGUIDLow()
    local q = CharDBQuery(string.format(
        "SELECT buddy FROM buddy_roster WHERE owner = %d AND buddy IS NOT NULL AND buddy <> 0", owner))
    if not q then return end
    CharDBExecute(string.format(
        "UPDATE buddy_roster SET talents_reroll = 1 WHERE owner = %d AND buddy IS NOT NULL AND buddy <> 0", owner))
    repeat
        local low   = q:GetUInt32(0)
        local buddy = GetPlayerByGUID(GetPlayerGUID(low))
        if buddy then
            buddy:ResetTalents(true)                                -- its own reset hook spends it again
            CharDBExecute(string.format("UPDATE buddy_roster SET talents_reroll = 0 WHERE buddy = %d", low))
        end
    until not q:NextRow()
end
-- }}}

-- {{{ local function on_talents_reset
local function on_talents_reset(event, player, no_cost)
    local free_before = player:GetFreeTalentPoints()
    player:RegisterEvent(function(_, _, _, p) after_reset(p, free_before) end, 1, 1)
end
-- }}}

if roster_ready() then
    RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,         on_login)
    RegisterPlayerEvent(PLAYER_EVENT_ON_LEVEL_CHANGE,  on_level_change)
    RegisterPlayerEvent(PLAYER_EVENT_ON_TALENTS_RESET, on_talents_reset)
end
