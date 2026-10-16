#!/usr/bin/env luajit
-- class-change-sql.lua - work out the database changes that turn one
-- character's class into another, and write them as SQL.
--
-- For a general audience: a character's class lives in many places, not
-- one: the class's skill lines (a warlock's Affliction, Demonology and
-- Destruction), every spell learned under them, the buttons on the action
-- bars that cast those spells, weapon skills the new class may not hold,
-- talents, glyphs, pets. This tool reads what the character has now (a
-- small file the caller fills from the database) and the game client's own
-- tables of which skill belongs to which class and which spell belongs to
-- which skill, and writes the SQL that removes exactly what the old class
-- owned and adds the new class's skill lines. Everything else (race, look,
-- position, gear, riding, professions, languages, money) is left alone.
-- It only writes the SQL; scripts/change-character-class backs up, checks
-- and applies it. Data generation here, application there.
--
-- Idempotent by construction: run against a character already of the
-- target class, nothing is disallowed and every needed skill is present,
-- so the SQL removes nothing, adds nothing, and leaves talents alone.
--
-- Usage: class-change-sql.lua PROJECT_DIR STATE_FILE NEW_CLASS SQL_OUT
--   STATE_FILE lines, tab separated (written by scripts/change-character-class):
--     char    <guid> <race> <class> <level>
--     skill   <skill id> <value> <max>
--     spell   <spell id>
--   Prints a plain-English report of the plan on standard output.

local DIR       = arg[1] or "/mnt/mtwo/games/azeroth-core/wow-chat-2026"
local STATE     = arg[2]
local NEW_CLASS = tonumber(arg[3] or "")
local SQL_OUT   = arg[4]
local DBC       = DIR .. "/data-files/dbc/"

-- {{{ configuration
local CLASS_NAMES = {
    [1] = "Warrior", [2] = "Paladin", [3] = "Hunter",  [4] = "Rogue",   [5] = "Priest",
    [6] = "Death Knight", [7] = "Shaman", [8] = "Mage", [9] = "Warlock", [11] = "Druid",
}
-- SkillLine.dbc categories (field 1) that decide a new skill's starting
-- value, the same rule the server uses when it first gives a skill:
-- weapon skills start at 1 of level x 5, class skill lines are full
-- (level x 5 of level x 5), anything else (armor) 1 of 1. One change to
-- that rule (owner, 2026-10-15, after Felicity arrived a priest with her
-- staff at 7 and her wand at 11 of 220: "There are some things she needs
-- to be fully enabled"): every weapon skill the character keeps or gains
-- (defense included, a weapon-category line) is full, as if practised.
local CATEGORY_WEAPON, CATEGORY_CLASS = 6, 7
-- the skills a class change may touch at all: weapons, class lines, armor.
-- Languages (10), racials (12), professions (11), secondary skills (9) and
-- riding are never removed, even if the table would say so.
local CATEGORY_ARMOR = 8
local TOUCHABLE = { [CATEGORY_WEAPON] = true, [CATEGORY_CLASS] = true, [CATEGORY_ARMOR] = true }
-- }}}

-- {{{ local function die
local function die(msg)
    io.stderr:write("class-change-sql: ", msg, "\n")
    os.exit(1)
end
-- }}}

-- {{{ local function load_dbc
-- Returns the record count, record size and a uint32 reader over the file
-- (same reader as scripts/generate-basic-death-knight-soul-data).
local function load_dbc(name)
    local f = io.open(DBC .. name, "rb") or die("cannot open " .. DBC .. name)
    local d = f:read("*a")
    f:close()
    if d:sub(1, 4) ~= "WDBC" then die(name .. " is not a WDBC file") end
    local function u32(o) local a, b, c, e = d:byte(o + 1, o + 4); return a + b * 256 + c * 65536 + e * 16777216 end
    return u32(4), u32(12), u32
end
-- }}}

-- {{{ local function read_state
-- The character as the database has it now.
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
-- }}}

-- {{{ main
if not STATE or not SQL_OUT then die("usage: class-change-sql.lua PROJECT_DIR STATE_FILE NEW_CLASS SQL_OUT") end
if not CLASS_NAMES[NEW_CLASS or -1] then die("no such class number: " .. tostring(arg[3])) end

local ch, have_skills, have_spells = read_state(STATE)
local race_bit, old_bit, new_bit = 2 ^ (ch.race - 1), 2 ^ (ch.class - 1), 2 ^ (NEW_CLASS - 1)
local function has(mask, bit) return mask == 0 or math.floor(mask / bit) % 2 == 1 end
local changing = ch.class ~= NEW_CLASS

-- SkillLine.dbc: 0 id, 1 category
local category = {}
local n, rs, u = load_dbc("SkillLine.dbc")
for r = 0, n - 1 do
    local b = 20 + r * rs
    category[u(b)] = u(b + 4)
end

-- SkillRaceClassInfo.dbc: 1 skill, 2 race mask, 3 class mask. A skill is
-- allowed for a race and class when any of its rows covers both (a zero
-- mask covers everyone). A skill with no rows at all is not ours to judge.
-- A class line belongs to a class only when a row names exactly that
-- class (its single bit: priest's Holy carries 16); rows covering every
-- class exist for hidden and death knight lines (769; 771 with 1535) and
-- make no line anyone's own (first dry run, 2026-10-14). The Mounts and
-- Companion Pets lines are filed as class lines too, with only such
-- "every class" rows: a class-category line with no single-class row is
-- nobody's class line and is never touched (second dry run).
local allowed_new, own_line, class_line, listed = {}, {}, {}, {}
local function single_bit(m) return m > 0 and m < 4096 and bit.band(m, m - 1) == 0 end   -- exactly one class
n, rs, u = load_dbc("SkillRaceClassInfo.dbc")
for r = 0, n - 1 do
    local b = 20 + r * rs
    local skill, rmask, cmask = u(b + 4), u(b + 8), u(b + 12)
    listed[skill] = true
    if has(rmask, race_bit) and has(cmask, new_bit) then allowed_new[skill] = true end
    if has(rmask, race_bit) and cmask == new_bit then own_line[skill] = true end
    -- both tests: weapon skills and riding also have rows naming one class
    -- (a death knight's riding row), and are nobody's class line (caught
    -- by scripts/test-change-character-class)
    if single_bit(cmask) and category[skill] == CATEGORY_CLASS then class_line[skill] = true end
end
-- {{{ local function new_class_may_hold
-- class lines: only the new class's own; weapons and armor: any row allows
local function new_class_may_hold(skill)
    if class_line[skill] then return own_line[skill] == true end
    return allowed_new[skill] == true
end
-- }}}

-- the skills to remove: held now, of a touchable category, listed, and not
-- for the new class (a warlock's Destruction; a sword skill for a priest).
-- The new class's own class lines are what get added.
local remove_skills = {}
for skill in pairs(have_skills) do
    if TOUCHABLE[category[skill] or -1] and listed[skill] and not new_class_may_hold(skill) then
        remove_skills[skill] = true
    end
end

-- SkillLineAbility.dbc: 1 skill line, 2 spell, 4 class mask. A held spell
-- goes when any skill line it sits under is a class line the new class may
-- not hold (the warlock's Felsteed sits under Demonology and under the
-- generic Mounts line, and must go: found on the first dry run, 2026-10-14),
-- or when every line it sits under is being removed (a sword skill's
-- spells); a spell also under a kept, non-class line otherwise stays.
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
                foreign = true                          -- another class's line: the spell is that class's
            elseif not remove_skills[skill] then
                keep = true                             -- also under a line the character keeps
            end
        end
        if foreign or not keep then remove_spells[spell] = true end
    end
end

-- the skills to add: the new class's own class lines (a priest's Holy,
-- Shadow Magic and Discipline), which are the class-category skills whose
-- SkillRaceClassInfo rows name the new class. Weapon skills are not added:
-- the new class learns those at a weapon master, as a new character would.
-- At the next login the server teaches each added line's automatic spells
-- (a priest's first Smite and Lesser Heal); the rest come from a trainer.
local add_skills = {}
n, rs, u = load_dbc("SkillRaceClassInfo.dbc")
for r = 0, n - 1 do
    local b = 20 + r * rs
    local skill, rmask, cmask = u(b + 4), u(b + 8), u(b + 12)
    -- only rows naming exactly this class (own_line's rule, above)
    if category[skill] == CATEGORY_CLASS and cmask == new_bit
       and has(rmask, race_bit) and not have_skills[skill] then
        add_skills[skill] = true
    end
end

-- {{{ write the SQL
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
    -- action-bar buttons of type 0 are spells; macros and items stay
    emit(string.format("DELETE FROM character_action WHERE guid = %d AND type = 0 AND action IN (%s);", ch.guid, l))
end
for _, skill in ipairs(add_list) do
    local value, max = 1, 1
    if category[skill] == CATEGORY_CLASS then value, max = full, full
    elseif category[skill] == CATEGORY_WEAPON then value, max = full, full end
    emit(string.format("INSERT IGNORE INTO character_skills (guid, skill, value, max) VALUES (%d, %d, %d, %d);", ch.guid, skill, value, max))
end
-- weapon skills it keeps, raised to full (the rule above); only those not
-- full already, so a second run writes nothing
for _, skill in ipairs(keys(have_skills)) do
    local h = have_skills[skill]
    if category[skill] == CATEGORY_WEAPON and not remove_skills[skill] and (h.value < full or h.max < full) then
        emit(string.format("UPDATE character_skills SET value = %d, max = %d WHERE guid = %d AND skill = %d;", full, full, ch.guid, skill))
    end
end
-- the class itself, and what belongs to a class as a whole. Only on a real
-- change: a second run must not wipe talents picked after the first.
if changing then
    emit(string.format("DELETE FROM character_talent WHERE guid = %d;", ch.guid))
    emit(string.format("DELETE FROM character_glyphs WHERE guid = %d;", ch.guid))
    emit(string.format("DELETE FROM character_aura WHERE guid = %d;", ch.guid))
    emit(string.format("DELETE FROM pet_aura WHERE guid IN (SELECT id FROM character_pet WHERE owner = %d);", ch.guid))
    emit(string.format("DELETE FROM pet_spell WHERE guid IN (SELECT id FROM character_pet WHERE owner = %d);", ch.guid))
    emit(string.format("DELETE FROM pet_spell_cooldown WHERE guid IN (SELECT id FROM character_pet WHERE owner = %d);", ch.guid))
    emit(string.format("DELETE FROM character_pet WHERE owner = %d;", ch.guid))
    -- at_login 4 = reset talents: the server gives the new class its full
    -- talent points at the next login
    emit(string.format("UPDATE characters SET class = %d, at_login = at_login | 4 WHERE guid = %d;", NEW_CLASS, ch.guid))
end
emit("COMMIT;")
local f = io.open(SQL_OUT, "w") or die("cannot write " .. SQL_OUT)
f:write(table.concat(out, "\n"), "\n")
f:close()
-- }}}

-- {{{ report
print(string.format("Class: %s -> %s%s", CLASS_NAMES[ch.class] or ch.class, CLASS_NAMES[NEW_CLASS],
    changing and "" or " (already; only leftovers are tidied)"))
print(string.format("Skills removed: %d (%s)", #rs_list, table.concat(rs_list, ", ")))
print(string.format("Skills added:   %d (%s)", #add_list, table.concat(add_list, ", ")))
print(string.format("Spells removed: %d of %d held, with their action-bar buttons", #sp_list, (function() local c = 0 for _ in pairs(have_spells) do c = c + 1 end return c end)()))
print(changing and "Talents, glyphs, auras and pets cleared; talents reset at next login."
               or  "Talents, glyphs and pets untouched.")
-- }}}
-- }}}
