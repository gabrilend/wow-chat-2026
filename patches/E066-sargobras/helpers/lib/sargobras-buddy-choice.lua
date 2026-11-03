
local Choice = {}

local DEATH_KNIGHT      = 6
local GUARANTEE_SLOTS   = { [6] = true, [7] = true }
local ROLE_NUMBER       = { damage = 0, tank = 1, healer = 2 }
local EVEN_SHAPE        = 7
local ROLE_ORDER        = { "tank", "healer" }

local function races_of(RC, team)
    local list = {}
    for id, race in pairs(RC.races) do
        if race.team == team then list[#list + 1] = id end
    end
    table.sort(list)
    return list
end

local function race_can(race, class)
    for _, c in ipairs(race.classes) do if c == class then return true end end
    return false
end

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

function Choice.needed_role(slot, roster, owner_is_dk)
    if owner_is_dk or not GUARANTEE_SLOTS[slot] then return nil end
    local have = {}
    for _, b in ipairs(roster) do have[b.role] = true end
    for _, role in ipairs(ROLE_ORDER) do
        if not have[ROLE_NUMBER[role]] then return role end
    end
    return nil
end

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

function Choice.resolve(a)
    local RC, rand   = a.RC, a.rand
    local team_races = races_of(RC, a.team)
    local need       = Choice.needed_role(a.slot, a.roster, a.owner_is_dk)
    local class, race

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

return Choice
