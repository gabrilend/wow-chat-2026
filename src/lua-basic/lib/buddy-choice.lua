--------------------------------------------------------------------------------
-- buddy-choice.lua (issue 617b)
--
-- Turns a player's pick at Sargobras ("a paladin", or "a dwarf") into a whole
-- buddy: class, race, talent shape and role, ready to be written into the
-- owed roster row for the buddy module to make (617a3). Pure decisions, no
-- server calls: the NPC script (sargobras.lua) and the offline test
-- (scripts/test-buddy-choice) run the same code.
--
-- The rules, all owner decisions recorded in 617b and 617g:
--   - pick a class: the race is drawn from the owner's faction's races that
--     can play it. Pick a race: the class is drawn from that race's classes.
--   - death knights are not offered to other owners; a death-knight owner
--     picks nothing: every buddy is a death knight of a random race.
--   - the talent shape is drawn from the class's ten, minus those held by
--     same-class clan-mates (617g's draw).
--   - the tank-and-healer guarantee acts only at the last two slots (the
--     buddies owed at levels 50 and 60), only while the clan lacks a tank
--     or a healer (tank first), and never refuses a pick: a picked class
--     keeps its class and has its shape steered to the missing role when
--     it can fill it; a picked race has its class drawn from those that can
--     fill the role, when any can. Death-knight clans skip it.
--
-- Loaded with dofile; ALE's own scan also runs it once, which only builds
-- and returns this table.
--------------------------------------------------------------------------------

local Choice = {}

local DEATH_KNIGHT      = 6
local GUARANTEE_SLOTS   = { [6] = true, [7] = true }   -- owed at levels 50 and 60
local ROLE_NUMBER       = { damage = 0, tank = 1, healer = 2 }
local ROLE_ORDER        = { "tank", "healer" }         -- the guarantee fills a tank first

-- {{{ local function races_of
-- The race ids of a faction ("alliance"/"horde"), sorted.
local function races_of(RC, team)
    local list = {}
    for id, race in pairs(RC.races) do
        if race.team == team then list[#list + 1] = id end
    end
    table.sort(list)
    return list
end
-- }}}

-- {{{ local function race_can
local function race_can(race, class)
    for _, c in ipairs(race.classes) do if c == class then return true end end
    return false
end
-- }}}

-- {{{ function Choice.menu
-- What Sargobras offers: the classes the faction can play (death knights
-- left out) and the faction's races. Each list is of { id, name }, sorted
-- by name. A death-knight owner gets empty lists (they pick nothing).
function Choice.menu(RC, team, owner_is_dk)
    if owner_is_dk then return {}, {} end
    local classes, seen, races = {}, {}, {}
    for _, rid in ipairs(races_of(RC, team)) do
        races[#races + 1] = { id = rid, name = RC.races[rid].name }
        for _, c in ipairs(RC.races[rid].classes) do
            if c ~= DEATH_KNIGHT and not seen[c] then
                seen[c] = true
                classes[#classes + 1] = { id = c, name = RC.classes[c].name }
            end
        end
    end
    table.sort(classes, function(a, b) return a.name < b.name end)
    table.sort(races,   function(a, b) return a.name < b.name end)
    return classes, races
end
-- }}}

-- {{{ function Choice.needed_role
-- The role the guarantee asks for at this slot, or nil. roster: the clan's
-- chosen or filled buddies, each { class, profile, role (number) }.
function Choice.needed_role(slot, roster, owner_is_dk)
    if owner_is_dk or not GUARANTEE_SLOTS[slot] then return nil end
    local have = {}
    for _, b in ipairs(roster) do have[b.role] = true end
    for _, role in ipairs(ROLE_ORDER) do
        if not have[ROLE_NUMBER[role]] then return role end
    end
    return nil
end
-- }}}

-- {{{ function Choice.resolve
-- The buddy a pick makes.
--   a.RC        race-class-data.lua        a.TD   buddy-talent-data.lua
--   a.Spender   buddy-talent-spender.lua   a.rand function(n) -> 1..n
--   a.team      "alliance"/"horde"         a.owner_is_dk  boolean
--   a.slot      1..7                       a.roster  (see needed_role)
--   a.pick      { kind = "class" | "race", id } (ignored for a DK owner)
-- Returns { class, race, profile, role (number), filled (bool) } or
-- nil, message (a pick the menu never offers: another faction's race, a
-- death knight for a non-DK owner, a class the faction can't play).
function Choice.resolve(a)
    local RC, rand   = a.RC, a.rand
    local team_races = races_of(RC, a.team)
    local need       = Choice.needed_role(a.slot, a.roster, a.owner_is_dk)
    local class, race

    if a.owner_is_dk then
        class = DEATH_KNIGHT
        local fits = {}
        for _, rid in ipairs(team_races) do
            if race_can(RC.races[rid], DEATH_KNIGHT) then fits[#fits + 1] = rid end
        end
        if #fits == 0 then return nil, "no " .. a.team .. " race can be a death knight" end
        race = fits[rand(#fits)]

    elseif a.pick and a.pick.kind == "class" then
        class = a.pick.id
        if class == DEATH_KNIGHT then return nil, "death knights are only for death-knight owners" end
        local fits = {}
        for _, rid in ipairs(team_races) do
            if race_can(RC.races[rid], class) then fits[#fits + 1] = rid end
        end
        if #fits == 0 then return nil, "no " .. a.team .. " race can be class " .. tostring(class) end
        race = fits[rand(#fits)]

    elseif a.pick and a.pick.kind == "race" then
        race = a.pick.id
        local r = RC.races[race]
        if not r or r.team ~= a.team then return nil, "race " .. tostring(race) .. " is not of the " .. a.team end
        local all, able = {}, {}
        for _, c in ipairs(r.classes) do
            if c ~= DEATH_KNIGHT then
                all[#all + 1] = c
                if need and a.Spender.can_fill(a.TD.classes[c], need) then able[#able + 1] = c end
            end
        end
        local pool = (#able > 0) and able or all
        class = pool[rand(#pool)]

    else
        return nil, "no pick"
    end

    local cls = a.TD.classes[class]
    if not cls then return nil, "the talent data lacks class " .. tostring(class) end
    local taken = {}
    for _, b in ipairs(a.roster) do
        if b.class == class and b.profile and b.profile > 0 then taken[b.profile] = true end
    end
    local shape, filled = a.Spender.draw_shape(cls, taken, need, rand)
    if not shape then return nil, filled end
    return { class = class, race = race, profile = shape,
             role = ROLE_NUMBER[cls.shapes[shape].role], filled = filled }
end
-- }}}

return Choice
