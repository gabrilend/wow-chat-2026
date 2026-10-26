#!/usr/bin/env luajit
-- spell-data.lua - what a spell does, read from the game's own spell file
--
-- For a general audience: every spell in the game, from a boss's fireball
-- to the "+10 defence" a piece of armour gives, is a row in one data file
-- the server reads at start (data-files/dbc/Spell.dbc). A row says what the
-- spell does in up to three "effects" (deal damage, apply an aura such as
-- "raise defence", summon...), how much (a base amount plus a dice roll),
-- to whom, and in which school (fire, shadow...). The server also lets the
-- world database replace whole rows (its spell_dbc table), and basic does
-- that to rescale spells (the legendaries, issue 182); a replaced row wins
-- here as it does in the server. This reads both and answers by spell
-- number.
--
-- Spell.dbc fields used (3.3.5a, from the server's SpellEntry in
-- DBCStructure.h): 0 ID; 28 CastingTimeIndex; 29 RecoveryTime; 37
-- MaxLevel; 38 BaseLevel; 39 SpellLevel; 40 DurationIndex; 77-79
-- EffectRealPointsPerLevel; 116-118 EffectTriggerSpell; 71-73 Effect; 74-76 EffectDieSides; 80-82
-- EffectBasePoints (stored one less than the amount shown); 86-88
-- EffectImplicitTargetA; 92-94 EffectRadiusIndex; 95-97
-- EffectApplyAuraName; 98-100 EffectAmplitude (ms between ticks); 110-112
-- EffectMiscValue; 136 SpellName (enUS); 225 SchoolMask.
--
-- Returns its table (no globals): local Spells = dofile(".../spell-data.lua")

local ffi = require("ffi")
local SpellData = {}

-- {{{ local function read_dbc
-- The file's header: "WDBC", rows, fields, bytes per row, bytes of text;
-- then the rows, then the text block the string fields point into.
local function read_dbc(path)
    local f = io.open(path, "rb")
    if not f then error("spell-data: cannot open " .. path .. " (is the server's data folder there?)") end
    local d = f:read("*a"); f:close()
    if d:sub(1, 4) ~= "WDBC" then error("spell-data: " .. path .. " is not a WDBC file") end
    local function u32(o) local a, b, c, e = d:byte(o + 1, o + 4); return a + b * 256 + c * 65536 + e * 16777216 end
    local n, fields, size = u32(4), u32(8), u32(12)
    local strs = 20 + n * size
    local t = { n = n, fields = fields, by_id = {} }
    function t.u(row, i) return u32(20 + row * size + i * 4) end
    function t.i(row, i) local v = t.u(row, i); if v >= 2 ^ 31 then v = v - 2 ^ 32 end; return v end
    function t.f(row, i) local v = ffi.new("uint32_t[1]", t.u(row, i)); return ffi.cast("float*", v)[0] end
    function t.s(row, i) local o = t.u(row, i); local e = d:find("\0", strs + o + 1, true); return d:sub(strs + o + 1, e - 1) end
    for r = 0, n - 1 do t.by_id[t.u(r, 0)] = r end
    return t
end
-- }}}

-- {{{ function SpellData.open
-- dir: the project folder (text). mysql: a command line that runs one
-- query with -N -B (text), or false to read the file alone. Returns a
-- reader whose lookups give nil for a spell number that exists nowhere.
function SpellData.open(dir, mysql)
    local dbc = read_dbc(dir .. "/data-files/dbc/Spell.dbc")
    local over = {}                                       -- spell number -> its fields by index (0-based), text
    if mysql then
        local p = io.popen(mysql .. ' -e "SELECT * FROM spell_dbc" 2>&1')
        for l in p:lines() do
            if not l:match("^mysql: %[Warning%]") then
                local v, i = {}, 0
                for x in (l .. "\t"):gmatch("([^\t]*)\t") do v[i] = x; i = i + 1 end
                if i ~= dbc.fields then error("spell-data: spell_dbc has " .. i .. " columns, Spell.dbc " .. dbc.fields .. "; MySQL said: " .. l) end
                over[tonumber(v[0])] = v
            end
        end
        p:close()
    end

    -- durations (SpellDuration.dbc: id, ms; -1 is "until removed")
    local durs = read_dbc(dir .. "/data-files/dbc/SpellDuration.dbc")

    local R = {}
    -- one field of a spell: from its replacing row when it has one, else from the file
    local function field(id, i, kind)
        local o = over[id]
        if o then return kind == "s" and o[i] or tonumber(o[i]) end
        local row = dbc.by_id[id]
        if not row then return nil end
        return dbc[kind](row, i)
    end

    -- {{{ R.exists, R.name, R.school, R.replaced
    function R.exists(id) return over[id] ~= nil or dbc.by_id[id] ~= nil end
    function R.name(id) return field(id, 136, "s") end
    function R.school(id) return field(id, 225, "u") end      -- bit mask: 1 physical, 2 holy, 4 fire, 8 nature, 16 frost, 32 shadow, 64 arcane
    function R.replaced(id) return over[id] ~= nil end
    -- ms the spell's aura lasts (nil without one, -1 until removed)
    function R.duration(id)
        local idx = field(id, 40, "u")
        if not idx or idx == 0 then return nil end
        local row = durs.by_id[idx]
        return row and durs.i(row, 1) or nil
    end
    -- the levels its amounts grow between: { spell = SpellLevel, max = MaxLevel } (numbers)
    function R.levels(id) return { base = field(id, 38, "u") or 0, spell = field(id, 39, "u") or 0, max = field(id, 37, "u") or 0 } end
    -- }}}

    -- {{{ R.effects
    -- The spell's effects that exist (Effect not 0), each a table:
    --   effect (number, what it does: 2 school damage, 6 apply aura, ...),
    --   aura (number, for effect 6 and kin: 3 periodic damage, 30 skill,
    --   189 rating ...), base (number, the smallest amount, as shown),
    --   dice (number, added at most on top), misc (number, the aura's
    --   which-one: a skill number, a rating mask ...), target (number),
    --   radius (number, the radius index; 0 = single target), period
    --   (number, ms between ticks).
    function R.effects(id)
        if not R.exists(id) then return nil end
        local list = {}
        for k = 0, 2 do
            local e = field(id, 71 + k, "u")
            if e and e ~= 0 then
                local dice = field(id, 74 + k, "i")
                list[#list + 1] = {
                    effect = e,
                    aura   = field(id, 95 + k, "u"),
                    base   = field(id, 80 + k, "i") + 1,
                    dice   = dice > 1 and dice - 1 or 0,
                    misc   = field(id, 110 + k, "i"),
                    target = field(id, 86 + k, "u"),
                    radius = field(id, 92 + k, "u"),
                    period = field(id, 98 + k, "u"),
                    per_level = field(id, 77 + k, "f"),
                    trigger = field(id, 116 + k, "u"),
                }
            end
        end
        return list
    end
    -- }}}
    return R
end
-- }}}

return SpellData
