#!/usr/bin/env luajit

local DIR       = arg[1] or "/mnt/kaun/wow-chat-2026"
local STATE     = arg[2]
local NEW_CLASS = tonumber(arg[3] or "")
local SQL_OUT   = arg[4]
local DBC       = DIR .. "/data-files/dbc/"

local CLASS_NAMES = {
    [1] = "Warrior", [2] = "Paladin", [3] = "Hunter",  [4] = "Rogue",   [5] = "Priest",
    [6] = "Death Knight", [7] = "Shaman", [8] = "Mage", [9] = "Warlock", [11] = "Druid",
}
local CATEGORY_WEAPON, CATEGORY_CLASS = 6, 7
local CATEGORY_ARMOR = 8
local TOUCHABLE = { [CATEGORY_WEAPON] = true, [CATEGORY_CLASS] = true, [CATEGORY_ARMOR] = true }

local function die(msg)
    io.stderr:write("class-change-sql: ", msg, "\n")
    os.exit(1)
end

local function load_dbc(name)
    local f = io.open(DBC .. name, "rb") or die("cannot open " .. DBC .. name)
    local d = f:read("*a")
    f:close()
    if d:sub(1, 4) ~= "WDBC" then die(name .. " is not a WDBC file") end
    local function u32(o) local a, b, c, e = d:byte(o + 1, o + 4); return a + b * 256 + c * 65536 + e * 16777216 end
    return u32(4), u32(12), u32
end

local function read_state(path)
    local f = io.open(path, "r") or die("cannot open state file " .. tostring(path))
    local ch, skills, spells = nil, {}, {}
    for line in f:lines() do
        local kind, a, b, c, d = line:match("^(%a+)\t(%d+)\t?(%d*)\t?(%d*)\t?(%d*)")
        if kind == "char" then
            ch = { guid = tonumber(a), race = tonumber(b), class = tonumber(c), level = tonumber(d) }
        elseif kind == "skill" then
            skills[tonumber(a)] = { value = tonumber(b), max = tonumber(c) }
        elseif kind == "spell" then
            spells[tonumber(a)] = true
        end
    end
    f:close()
    if not ch then die("state file has no 'char' line: " .. path) end
    return ch, skills, spells
end

if not STATE or not SQL_OUT then die("usage: class-change-sql.lua PROJECT_DIR STATE_FILE NEW_CLASS SQL_OUT") end
if not CLASS_NAMES[NEW_CLASS or -1] then die("no such class number: " .. tostring(arg[3])) end

local ch, have_skills, have_spells = read_state(STATE)
local race_bit, old_bit, new_bit = 2 ^ (ch.race - 1), 2 ^ (ch.class - 1), 2 ^ (NEW_CLASS - 1)
local function has(mask, bit) return mask == 0 or math.floor(mask / bit) % 2 == 1 end
local changing = ch.class ~= NEW_CLASS

local category = {}
local n, rs, u = load_dbc("SkillLine.dbc")
for r = 0, n - 1 do
    local b = 20 + r * rs
    category[u(b)] = u(b + 4)
end

local allowed_new, own_line, class_line, listed = {}, {}, {}, {}
local function single_bit(m) return m > 0 and m < 4096 and bit.band(m, m - 1) == 0 end
n, rs, u = load_dbc("SkillRaceClassInfo.dbc")
for r = 0, n - 1 do
    local b = 20 + r * rs
    local skill, rmask, cmask = u(b + 4), u(b + 8), u(b + 12)
    listed[skill] = true
    if has(rmask, race_bit) and has(cmask, new_bit) then allowed_new[skill] = true end
    if has(rmask, race_bit) and cmask == new_bit then own_line[skill] = true end
    if single_bit(cmask) and category[skill] == CATEGORY_CLASS then class_line[skill] = true end
end
local function new_class_may_hold(skill)
    if class_line[skill] then return own_line[skill] == true end
    return allowed_new[skill] == true
end

local remove_skills = {}
for skill in pairs(have_skills) do
    if TOUCHABLE[category[skill] or -1] and listed[skill] and not new_class_may_hold(skill) then
        remove_skills[skill] = true
    end
end

local lines_of = {}
n, rs, u = load_dbc("SkillLineAbility.dbc")
for r = 0, n - 1 do
    local b = 20 + r * rs
    local skill, spell = u(b + 4), u(b + 8)
    if have_spells[spell] then
        lines_of[spell] = lines_of[spell] or {}
        lines_of[spell][skill] = true
    end
end
local remove_spells = {}
for spell in pairs(have_spells) do
    local lines = lines_of[spell]
    if lines then
        local keep, foreign = false, false
        for skill in pairs(lines) do
            if class_line[skill] and not own_line[skill] then
                foreign = true
            elseif not remove_skills[skill] then
                keep = true
            end
        end
        if foreign or not keep then remove_spells[spell] = true end
    end
end

local add_skills = {}
n, rs, u = load_dbc("SkillRaceClassInfo.dbc")
for r = 0, n - 1 do
    local b = 20 + r * rs
    local skill, rmask, cmask = u(b + 4), u(b + 8), u(b + 12)
    if category[skill] == CATEGORY_CLASS and cmask == new_bit
       and has(rmask, race_bit) and not have_skills[skill] then
        add_skills[skill] = true
    end
end

local function keys(t) local k = {} for x in pairs(t) do k[#k + 1] = x end table.sort(k) return k end
local full = ch.level * 5
local out = {}
local function emit(s) out[#out + 1] = s end
emit(string.format("-- written by scripts/lib/class-change-sql.lua for character %d: class %d -> %d", ch.guid, ch.class, NEW_CLASS))
emit("START TRANSACTION;")
local rs_list, sp_list, add_list = keys(remove_skills), keys(remove_spells), keys(add_skills)
if #rs_list > 0 then
    emit(string.format("DELETE FROM character_skills WHERE guid = %d AND skill IN (%s);", ch.guid, table.concat(rs_list, ",")))
end
if #sp_list > 0 then
    local l = table.concat(sp_list, ",")
    emit(string.format("DELETE FROM character_spell WHERE guid = %d AND spell IN (%s);", ch.guid, l))
    emit(string.format("DELETE FROM character_spell_cooldown WHERE guid = %d AND spell IN (%s);", ch.guid, l))
    emit(string.format("DELETE FROM character_action WHERE guid = %d AND type = 0 AND action IN (%s);", ch.guid, l))
end
for _, skill in ipairs(add_list) do
    local value, max = 1, 1
    if category[skill] == CATEGORY_CLASS then value, max = full, full
    elseif category[skill] == CATEGORY_WEAPON then value, max = full, full end
    emit(string.format("INSERT IGNORE INTO character_skills (guid, skill, value, max) VALUES (%d, %d, %d, %d);", ch.guid, skill, value, max))
end
for _, skill in ipairs(keys(have_skills)) do
    local h = have_skills[skill]
    if category[skill] == CATEGORY_WEAPON and not remove_skills[skill] and (h.value < full or h.max < full) then
        emit(string.format("UPDATE character_skills SET value = %d, max = %d WHERE guid = %d AND skill = %d;", full, full, ch.guid, skill))
    end
end
if changing then
    emit(string.format("DELETE FROM character_talent WHERE guid = %d;", ch.guid))
    emit(string.format("DELETE FROM character_glyphs WHERE guid = %d;", ch.guid))
    emit(string.format("DELETE FROM character_aura WHERE guid = %d;", ch.guid))
    emit(string.format("DELETE FROM pet_aura WHERE guid IN (SELECT id FROM character_pet WHERE owner = %d);", ch.guid))
    emit(string.format("DELETE FROM pet_spell WHERE guid IN (SELECT id FROM character_pet WHERE owner = %d);", ch.guid))
    emit(string.format("DELETE FROM pet_spell_cooldown WHERE guid IN (SELECT id FROM character_pet WHERE owner = %d);", ch.guid))
    emit(string.format("DELETE FROM character_pet WHERE owner = %d;", ch.guid))
    emit(string.format("UPDATE characters SET class = %d, at_login = at_login | 4 WHERE guid = %d;", NEW_CLASS, ch.guid))
end
emit("COMMIT;")
local f = io.open(SQL_OUT, "w") or die("cannot write " .. SQL_OUT)
f:write(table.concat(out, "\n"), "\n")
f:close()

print(string.format("Class: %s -> %s%s", CLASS_NAMES[ch.class] or ch.class, CLASS_NAMES[NEW_CLASS],
    changing and "" or " (already; only leftovers are tidied)"))
print(string.format("Skills removed: %d (%s)", #rs_list, table.concat(rs_list, ", ")))
print(string.format("Skills added:   %d (%s)", #add_list, table.concat(add_list, ", ")))
print(string.format("Spells removed: %d of %d held, with their action-bar buttons", #sp_list, (function() local c = 0 for _ in pairs(have_spells) do c = c + 1 end return c end)()))
print(changing and "Talents, glyphs, auras and pets cleared; talents reset at next login."
               or  "Talents, glyphs and pets untouched.")
