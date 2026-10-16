#!/usr/bin/env luajit
-- lessons-sql.lua - works out every lesson a character of its class, race
-- and level would have learned from its class trainers and class quests,
-- and writes the SQL that adds the ones it lacks.
--
-- For a general audience: this is the thinking half of
-- scripts/teach-character-lessons (which checks, backs up and applies). It
-- follows the server's own rules for whether a trainer may teach a lesson
-- (Trainer::GetSpellState): the level, the race and class the lesson's
-- skill line allows, any ability the lesson asks for first (a talent: no
-- talent, no lesson), the previous rank, and the world database's
-- spell_required pairs. A "teach" lesson (one the trainer casts, adding
-- another spell) adds the spell it teaches. Lessons open others (a
-- quest's Bear Form opens Maul), so it goes round until a round adds
-- nothing. Class quest spells (the first totems, Bear Form) come from the
-- buddy module's list (modules/mod-buddies/src/buddies_quest_spells.h), so
-- the two never disagree. Pure Lua with no server calls, so the server's
-- Lua scripts can use the same rules.
--
-- Usage: luajit lessons-sql.lua PROJECT_DIR STATE_TSV LESSONS_TSV REQUIRED_TSV OUT_SQL
--   STATE_TSV     "char<TAB>guid<TAB>race<TAB>class<TAB>level", then "spell<TAB>id" per known spell
--   LESSONS_TSV   the class trainers' lessons: spell, level, ability 1-3, skill line, skill rank
--   REQUIRED_TSV  spell_required: spell, the spell it needs
--   OUT_SQL       the plan (one transaction); prints a report to standard output

-- {{{ arguments
local DIR, STATE, LESSONS, REQUIRED, OUT = arg[1], arg[2], arg[3], arg[4], arg[5]
local function die(msg) io.stderr:write("lessons-sql: " .. msg .. "\n"); os.exit(1) end
if not OUT then die("usage: lessons-sql.lua PROJECT_DIR STATE_TSV LESSONS_TSV REQUIRED_TSV OUT_SQL") end
-- }}}

-- {{{ local function load_dbc
local function load_dbc(name)
    local f = io.open(DIR .. "/data-files/dbc/" .. name, "rb") or die("cannot open data-files/dbc/" .. name)
    local d = f:read("*a"); f:close()
    local function u32(o) local a, b, c, e = d:byte(o + 1, o + 4) return a + b * 256 + c * 65536 + e * 16777216 end
    return u32(4), u32(12), u32
end
-- }}}

-- {{{ the character
local ch, known = nil, {}
for line in (io.open(STATE) or die("cannot open " .. STATE)):lines() do
    local kind, a, b, c, d = line:match("^(%a+)\t(%d+)\t?(%d*)\t?(%d*)\t?(%d*)")
    if kind == "char" then ch = { guid = tonumber(a), race = tonumber(b), class = tonumber(c), level = tonumber(d) }
    elseif kind == "spell" then known[tonumber(a)] = true end
end
if not ch then die("state file has no 'char' line") end
local raceBit, classBit = 2 ^ (ch.race - 1), 2 ^ (ch.class - 1)
local function has(mask, bit) return mask % (2 * bit) >= bit end
local before = {}
for s in pairs(known) do before[s] = true end
-- }}}

-- {{{ the client's tables
-- Spell.dbc: effect 36 (learn spell) at fields 71-73, the spell it
-- teaches at 116-118
local teaches = {}
local n, rs, u = load_dbc("Spell.dbc")
for r = 0, n - 1 do
    local b = 20 + r * rs
    for i = 0, 2 do
        if u(b + (71 + i) * 4) == 36 then
            local id = u(b)
            teaches[id] = teaches[id] or {}
            table.insert(teaches[id], u(b + (116 + i) * 4))
        end
    end
end
-- SkillLineAbility.dbc: 2 spell, 3 race mask, 4 class mask, 8 the next rank
local fits_rows, prev = {}, {}
n, rs, u = load_dbc("SkillLineAbility.dbc")
for r = 0, n - 1 do
    local b = 20 + r * rs
    local spell, rmask, cmask, nextRank = u(b + 8), u(b + 12), u(b + 16), u(b + 32)
    fits_rows[spell] = fits_rows[spell] or {}
    table.insert(fits_rows[spell], { rmask, cmask })
    if nextRank ~= 0 then prev[nextRank] = spell end
end
-- the server's IsSpellFitByClassAndRace: no skill line row fits all; else
-- some row must allow both the race and the class
local function fits(spell)
    local rows = fits_rows[spell]
    if not rows then return true end
    for _, m in ipairs(rows) do
        if (m[1] == 0 or has(m[1], raceBit)) and (m[2] == 0 or has(m[2], classBit)) then return true end
    end
    return false
end
-- A quest spell counts only if it (or a spell it teaches) has a skill line
-- row that fits: the buddy module's ClassSkill rule, which passes over
-- quest-list rows for spells the game no longer gives the class (the
-- hunter's Taming Lesson, the shaman's Swift Wind and its Earthen Ring
-- totem item, all found by the first dry run, 2026-10-15).
local function class_skill(spell)
    local ids = { spell }
    for _, t in ipairs(teaches[spell] or {}) do ids[#ids + 1] = t end
    for _, id in ipairs(ids) do
        for _, m in ipairs(fits_rows[id] or {}) do
            if (m[1] == 0 or has(m[1], raceBit)) and (m[2] == 0 or has(m[2], classBit)) then return true end
        end
    end
    return false
end
-- }}}

-- {{{ the lessons and the rules
local lessons = {}
for line in (io.open(LESSONS) or die("cannot open " .. LESSONS)):lines() do
    local t = {}
    for v in line:gmatch("[^\t]+") do t[#t + 1] = tonumber(v) end
    if #t >= 7 then lessons[#lessons + 1] = { spell = t[1], level = t[2], abilities = { t[3], t[4], t[5] }, skill = t[6], rank = t[7] } end
end
local required = {}
for line in (io.open(REQUIRED) or die("cannot open " .. REQUIRED)):lines() do
    local s, req = line:match("^(%d+)\t(%d+)")
    if s then required[tonumber(s)] = required[tonumber(s)] or {}; table.insert(required[tonumber(s)], tonumber(req)) end
end
-- the class quest spells: { class, race mask, level, spell } rows of the
-- buddy module's header
local quests = {}
for line in (io.open(DIR .. "/modules/mod-buddies/src/buddies_quest_spells.h") or die("cannot open buddies_quest_spells.h")):lines() do
    local c, races, lvl, spell = line:match("^%s*{%s*(%d+),%s*(%d+),%s*(%d+),%s*(%d+)%s*}")
    if c then quests[#quests + 1] = { class = tonumber(c), races = tonumber(races), level = tonumber(lvl), spell = tonumber(spell) } end
end
-- }}}

-- {{{ teaching
-- The spells a lesson adds: what it teaches, or itself.
local function adds(spell) return teaches[spell] or { spell } end

local function may_learn(l)
    if l.level > ch.level or not fits(l.spell) then return false end
    for _, a in ipairs(l.abilities) do if a ~= 0 and not known[a] then return false end end
    if l.skill ~= 0 then return false end                  -- a lesson needing a skill rank: none for class trainers
    for _, s in ipairs(adds(l.spell)) do
        local p = prev[s]
        if p and not known[p] then return false end         -- the rank before first
    end
    for _, req in ipairs(required[l.spell] or {}) do if not known[req] then return false end end
    return true
end

local added, rounds = {}, 0
local function take(spells)
    local any = false
    for _, s in ipairs(spells) do
        if not known[s] then known[s] = true; added[#added + 1] = s; any = true end
    end
    return any
end
repeat
    rounds = rounds + 1
    local more = false
    for _, q in ipairs(quests) do                           -- quest spells first: trainer ranks ask for them
        if q.class == ch.class and q.level <= ch.level and (q.races == 0 or has(q.races, raceBit)) and class_skill(q.spell) then
            more = take(adds(q.spell)) or more
        end
    end
    for _, l in ipairs(lessons) do
        if may_learn(l) then more = take(adds(l.spell)) or more end
    end
until not more or rounds > 40
-- }}}

-- {{{ write the plan
local out = io.open(OUT, "w") or die("cannot write " .. OUT)
out:write(string.format("-- written by scripts/lib/lessons-sql.lua for character %d (race %d, class %d, level %d)\n",
    ch.guid, ch.race, ch.class, ch.level))
out:write("START TRANSACTION;\n")
table.sort(added)
for _, s in ipairs(added) do
    out:write(string.format("INSERT IGNORE INTO character_spell (guid, spell, specMask) VALUES (%d, %d, 255);\n", ch.guid, s))
end
out:write("COMMIT;\n")
out:close()
print(string.format("Lessons: %d known before, %d added (%d rounds)", (function() local c = 0 for _ in pairs(before) do c = c + 1 end return c end)(), #added, rounds))
if #added > 0 then print("Added: " .. table.concat(added, " ")) end
-- }}}
