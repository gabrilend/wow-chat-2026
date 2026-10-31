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
local EVEN_SHAPE        = 7         -- one-third in each tree, every class (buddy-talent-data.lua; gearsets.lua's EVEN_SHAPE)
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

-- {{{ function Choice.menu_for_race
-- What Sargobras offers for a reset slot (617a7), whose race is kept: only
-- the classes that race can play, death knights left out, { id, name },
-- sorted by name. No races (the race is the slot's).
function Choice.menu_for_race(RC, race)
    local classes = {}
    local r = RC.races[race]
    if not r then return classes end
    for _, c in ipairs(r.classes) do
        if c ~= DEATH_KNIGHT then classes[#classes + 1] = { id = c, name = RC.classes[c].name } end
    end
    table.sort(classes, function(a, b) return a.name < b.name end)
    return classes
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

-- {{{ function Choice.lacking_role
-- The role a group lacks most, for a bot choosing its own buddy (620c,
-- 2026-10-14: "the role its group lacks most, counted the same way the
-- dungeon draw counts tank and healer"). A five-player group wants one
-- tank, one healer and three damage (617c3); each role's shortfall is what
-- it wants minus what the group has, and the largest shortfall wins. Each
-- path:
--   one role short the most       - that role
--   several equally short         - one of them at random (rand(n) -> 1..n)
--   none short (the group full)   - the least over-supplied, the same way
-- have: { tank = n, healer = n, damage = n } (numbers, may be fractions;
-- missing keys count as 0).
local WANTED_ROLES = { { "tank", 1 }, { "healer", 1 }, { "damage", 3 } }
function Choice.lacking_role(have, rand)
    local best, top = nil, {}
    for _, w in ipairs(WANTED_ROLES) do
        local short = w[2] - (have[w[1]] or 0)
        if not best or short > best then
            best, top = short, { w[1] }
        elseif short == best then
            top[#top + 1] = w[1]
        end
    end
    return top[rand(#top)]
end
-- }}}

-- {{{ function Choice.resolve
-- The buddy a pick makes.
--   a.RC        race-class-data.lua        a.TD   buddy-talent-data.lua
--   a.Spender   buddy-talent-spender.lua   a.rand function(n) -> 1..n
--   a.team      "alliance"/"horde"         a.owner_is_dk  boolean
--   a.slot      1..7                       a.roster  (see needed_role)
--   a.pick      { kind = "class" | "race", id }, { kind = "flexible" },
--               { kind = "role", role = "tank" | "healer" | "damage" }
--               (a bot's own pick, 620c), or { kind = "any" } (ignored
--               for a DK owner)
--   a.kept_race a reset slot's race (617a7), or nil: the class must be one
--               the race plays (no death knight), the race stays; a
--               flexible pick draws among the race's classes
-- Returns { class, race, profile, role (number), filled (bool) } or
-- nil, message (a pick the menu never offers: another faction's race, a
-- death knight for a non-DK owner, a class the faction can't play).
function Choice.resolve(a)
    local RC, rand   = a.RC, a.rand
    local team_races = races_of(RC, a.team)
    local need       = Choice.needed_role(a.slot, a.roster, a.owner_is_dk)
    local class, race

    -- a reset slot (617a7): its race is kept; the class one it plays
    if a.kept_race and a.kept_race ~= 0 then
        local r = RC.races[a.kept_race]
        if not r or r.team ~= a.team then return nil, "the kept race " .. tostring(a.kept_race) .. " is not of the " .. a.team end
        local playable = {}
        for _, c in ipairs(Choice.menu_for_race(RC, a.kept_race)) do
            if a.TD.classes[c.id] then playable[#playable + 1] = c.id end
        end
        if a.pick and a.pick.kind == "class" then
            if not race_can(r, a.pick.id) or a.pick.id == DEATH_KNIGHT then
                return nil, "a " .. r.name .. " can't be class " .. tostring(a.pick.id) .. " (or a death knight)"
            end
            class = a.pick.id
        elseif a.pick and a.pick.kind == "flexible" then
            local pool = {}
            for _, c in ipairs(playable) do
                local taken = false
                for _, b in ipairs(a.roster) do if b.class == c and b.profile == EVEN_SHAPE then taken = true end end
                if not taken then pool[#pool + 1] = c end
            end
            if #pool == 0 then return nil, "every class this race plays already has a clan-mate in the even shape" end
            class = pool[rand(#pool)]
            local cls = a.TD.classes[class]
            return { class = class, race = a.kept_race, profile = EVEN_SHAPE,
                     role = ROLE_NUMBER[cls.shapes[EVEN_SHAPE].role], filled = false }
        else
            return nil, "a reset slot takes a class or \"I'm flexible\", not " .. tostring(a.pick and a.pick.kind)
        end
        race = a.kept_race
    end

    if class then
        -- the kept race's class, chosen above

    elseif a.owner_is_dk then
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

    elseif a.pick and a.pick.kind == "any" then
        -- a death knight player's buddies since 2026-10-12 (owner: "They
        -- should get a completely random race/class"): any class of the
        -- faction but the death knight, any race of it that plays the
        -- class; the shape is drawn as for every buddy (below)
        local classes = {}
        for _, rid in ipairs(team_races) do
            for _, c in ipairs(RC.races[rid].classes) do
                if c ~= DEATH_KNIGHT and a.TD.classes[c] then classes[c] = true end
            end
        end
        local pool = {}
        for c in pairs(classes) do pool[#pool + 1] = c end
        table.sort(pool)
        class = pool[rand(#pool)]
        local fits = {}
        for _, rid in ipairs(team_races) do
            if race_can(RC.races[rid], class) then fits[#fits + 1] = rid end
        end
        race = fits[rand(#fits)]

    elseif a.pick and a.pick.kind == "role" then
        -- a bot's own pick (620c): a role its group lacks. Any class of the
        -- faction but the death knight that has a shape of that role, any
        -- race of it that plays the class; the shape is then drawn with the
        -- role asked for (below), so a role pick always gets a shape of it
        local classes = {}
        for _, rid in ipairs(team_races) do
            for _, c in ipairs(RC.races[rid].classes) do
                if c ~= DEATH_KNIGHT and a.TD.classes[c] and a.Spender.can_fill(a.TD.classes[c], a.pick.role) then
                    classes[c] = true
                end
            end
        end
        local pool = {}
        for c in pairs(classes) do pool[#pool + 1] = c end
        table.sort(pool)
        if #pool == 0 then return nil, "no " .. a.team .. " class has a shape of role " .. tostring(a.pick.role) end
        class = pool[rand(#pool)]
        local fits = {}
        for _, rid in ipairs(team_races) do
            if race_can(RC.races[rid], class) then fits[#fits + 1] = rid end
        end
        race = fits[rand(#fits)]
        need = a.pick.role

    elseif a.pick and a.pick.kind == "flexible" then
        -- "I'm flexible." (owner, 2026-10-12: "it creates a totally random
        -- buddy-bot... but the spec is the one that's 1/3rd in all three
        -- talent trees. Of any class."): any class the faction can play,
        -- save the death knight, whose even shape no same-class clan-mate
        -- already holds; then any race of the faction that can play it
        local classes = {}
        for _, rid in ipairs(team_races) do
            for _, c in ipairs(RC.races[rid].classes) do
                if c ~= DEATH_KNIGHT and a.TD.classes[c] then classes[c] = true end
            end
        end
        for _, b in ipairs(a.roster) do
            if b.profile == EVEN_SHAPE then classes[b.class] = nil end
        end
        local pool = {}
        for c in pairs(classes) do pool[#pool + 1] = c end
        table.sort(pool)
        if #pool == 0 then return nil, "every class already has a clan-mate in the even shape" end
        class = pool[rand(#pool)]
        local fits = {}
        for _, rid in ipairs(team_races) do
            if race_can(RC.races[rid], class) then fits[#fits + 1] = rid end
        end
        race = fits[rand(#fits)]
        local cls = a.TD.classes[class]
        return { class = class, race = race, profile = EVEN_SHAPE,
                 role = ROLE_NUMBER[cls.shapes[EVEN_SHAPE].role], filled = false }

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
