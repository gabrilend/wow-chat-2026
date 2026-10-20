#!/usr/bin/env luajit

local DIR, STATE, LESSONS, REQUIRED, OUT, TRADE = arg[1], arg[2], arg[3], arg[4], arg[5], arg[6]
local function die(msg) io.stderr:write("lessons-sql: " .. msg .. "\n"); os.exit(1) end
if not OUT then die("usage: lessons-sql.lua PROJECT_DIR STATE_TSV LESSONS_TSV REQUIRED_TSV OUT_SQL") end

local function load_dbc(name)
    local f = io.open(DIR .. "/data-files/dbc/" .. name, "rb") or die("cannot open data-files/dbc/" .. name)
    local d = f:read("*a"); f:close()
    local function u32(o) local a, b, c, e = d:byte(o + 1, o + 4) return a + b * 256 + c * 65536 + e * 16777216 end
    return u32(4), u32(12), u32
end

local ch, known, skills = nil, {}, {}
for line in (io.open(STATE) or die("cannot open " .. STATE)):lines() do
    local kind, a, b, c, d = line:match("^(%a+)\t(%d+)\t?(%d*)\t?(%d*)\t?(%d*)")
    if kind == "char" then ch = { guid = tonumber(a), race = tonumber(b), class = tonumber(c), level = tonumber(d) }
    elseif kind == "spell" then known[tonumber(a)] = true
    elseif kind == "skill" then skills[tonumber(a)] = { value = tonumber(b), max = tonumber(c) } end
end
if not ch then die("state file has no 'char' line") end
local raceBit, classBit = 2 ^ (ch.race - 1), 2 ^ (ch.class - 1)
local function has(mask, bit) return mask % (2 * bit) >= bit end
local before = {}
for s in pairs(known) do before[s] = true end

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
local fits_rows, prev = {}, {}
n, rs, u = load_dbc("SkillLineAbility.dbc")
for r = 0, n - 1 do
    local b = 20 + r * rs
    local spell, rmask, cmask, nextRank = u(b + 8), u(b + 12), u(b + 16), u(b + 32)
    fits_rows[spell] = fits_rows[spell] or {}
    table.insert(fits_rows[spell], { rmask, cmask })
    if nextRank ~= 0 then prev[nextRank] = spell end
end
local function fits(spell)
    local rows = fits_rows[spell]
    if not rows then return true end
    for _, m in ipairs(rows) do
        if (m[1] == 0 or has(m[1], raceBit)) and (m[2] == 0 or has(m[2], classBit)) then return true end
    end
    return false
end
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
local quests = {}
for line in (io.open(DIR .. "/modules/mod-buddies/src/buddies_quest_spells.h") or die("cannot open buddies_quest_spells.h")):lines() do
    local c, races, lvl, spell = line:match("^%s*{%s*(%d+),%s*(%d+),%s*(%d+),%s*(%d+)%s*}")
    if c then quests[#quests + 1] = { class = tonumber(c), races = tonumber(races), level = tonumber(lvl), spell = tonumber(spell) } end
end

local function adds(spell) return teaches[spell] or { spell } end

local function may_learn(l)
    if l.level > ch.level or not fits(l.spell) then return false end
    for _, a in ipairs(l.abilities) do if a ~= 0 and not known[a] then return false end end
    if l.skill ~= 0 then return false end
    for _, s in ipairs(adds(l.spell)) do
        local p = prev[s]
        if p and not known[p] then return false end
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
    for _, q in ipairs(quests) do
        if q.class == ch.class and q.level <= ch.level and (q.races == 0 or has(q.races, raceBit)) and class_skill(q.spell) then
            more = take(adds(q.spell)) or more
        end
    end
    for _, l in ipairs(lessons) do
        if may_learn(l) then more = take(adds(l.spell)) or more end
    end
until not more or rounds > 40

local RANKS = {
    [171] = { 2259, 3101, 3464, 11611 }, [164] = { 2018, 3100, 3538, 9785 }, [333] = { 7411, 7412, 7413, 13920 },
    [202] = { 4036, 4037, 4038, 12656 }, [773] = { 45357, 45358, 45359, 45360 }, [755] = { 25229, 25230, 28894, 28895 },
    [165] = { 2108, 3104, 3811, 10662 }, [197] = { 3908, 3909, 3910, 12180 }, [182] = { 2366, 2368, 3570, 11993 },
    [186] = { 2575, 2576, 3564, 10248 }, [393] = { 8613, 8617, 8618, 10768 }, [185] = { 2550, 3102, 3413, 18260 },
    [129] = { 3273, 3274, 7924, 10846 }, [356] = { 7620, 7731, 7732, 18248 },
}
local RANK_FROM_LEVEL, RANK_MAX = { 1, 10, 20, 35 }, { 75, 150, 225, 300 }
local skill_sql = {}
if TRADE then
    local target = math.min(ch.level * 5, 300)
    local isRank = {}
    for _, r in pairs(RANKS) do for _, sp in ipairs(r) do isRank[sp] = true end end
    for skill, ranks in pairs(RANKS) do
        local have = skills[skill]
        if have then
            local rank = 1
            for r = 2, 4 do if target > RANK_MAX[r - 1] and ch.level >= RANK_FROM_LEVEL[r] then rank = r end end
            for r = 1, rank do take({ ranks[r] }) end
            local max = math.max(RANK_MAX[rank], have.max)
            local value = math.max(math.min(target, RANK_MAX[rank]), have.value)
            if value ~= have.value or max ~= have.max then
                skill_sql[#skill_sql + 1] = string.format("UPDATE character_skills SET value = %d, max = %d WHERE guid = %d AND skill = %d;",
                    value, max, ch.guid, skill)
                have.value, have.max = value, max
            end
        end
    end
    for line in (io.open(TRADE) or die("cannot open " .. TRADE)):lines() do
        local spell, lvl, skill, srank = line:match("^(%d+)\t(%d+)\t(%d+)\t(%d+)")
        spell, lvl, skill, srank = tonumber(spell), tonumber(lvl), tonumber(skill), tonumber(srank)
        if spell and skill ~= 0 and skills[skill] and skills[skill].value >= srank and lvl <= ch.level and fits(spell) then
            local rankLesson = isRank[spell]
            for _, t in ipairs(teaches[spell] or {}) do if isRank[t] then rankLesson = true end end
            if not rankLesson then take(adds(spell)) end
        end
    end
end

local out = io.open(OUT, "w") or die("cannot write " .. OUT)
out:write(string.format("-- written by scripts/lib/lessons-sql.lua for character %d (race %d, class %d, level %d)\n",
    ch.guid, ch.race, ch.class, ch.level))
out:write("START TRANSACTION;\n")
table.sort(added)
for _, s in ipairs(added) do
    out:write(string.format("INSERT IGNORE INTO character_spell (guid, spell, specMask) VALUES (%d, %d, 255);\n", ch.guid, s))
end
for _, line in ipairs(skill_sql) do out:write(line .. "\n") end
out:write("COMMIT;\n")
out:close()
print(string.format("Lessons: %d known before, %d added (%d rounds)", (function() local c = 0 for _ in pairs(before) do c = c + 1 end return c end)(), #added, rounds))
if #added > 0 then print("Added: " .. table.concat(added, " ")) end
if #skill_sql > 0 then print(string.format("Professions raised: %d skills", #skill_sql)) end
