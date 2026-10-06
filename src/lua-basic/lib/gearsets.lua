--------------------------------------------------------------------------------
-- lib/gearsets.lua (issues 617r, 617r1) - finding a character's record in a gearset
--
-- For a general audience: a gearset profile is one named list of gear
-- (data/gearsets/<name>.lua): "elite", the bannermen's Tier 1 outfits;
-- "vanilla-starter", the level-20 starter kit; "buddy-white", what buddies
-- are made wearing; more later. Each profile says which facts about a
-- character its records are filed under, in order (its `keys`):
--
--   shape  class id x 100 + talent shape id: the class and how its points
--          are split between its three trees, in thirds (the ten shapes of
--          data/buddy-talent-data.lua). A Retribution paladin leaning Holy
--          (paladin shape 5, "1/3 Holy, 2/3 Retribution": key 205) and one
--          leaning Protection (shape 6: key 206) are
--          different keys (owner, 2026-10-05: "a ret paladin who has half a
--          tree of holy would want spellpower, while a ret paladin who has
--          half a tree of prot would want dodge and parry").
--   class  class id, for gear worn before talents exist (the starter kit)
--   race   race id
--   level  the lowest level a record is for: the highest at or below the
--          character's level is used
--
-- Nothing in a profile knows who will wear it: the same record dresses a
-- buddy, a player character or a stand-in. Pure: the talent check is
-- passed in, so the offline tests run it without a server.
--------------------------------------------------------------------------------

local Gearsets = {}

local KNOWN_KEYS = { shape = true, class = true, race = true, level = true }
Gearsets.EVEN_SHAPE = 7      -- one-third in each tree: everyone before level 10 or with no points (owner, 2026-10-05)

-- {{{ function Gearsets.load
-- The profile called `name` (text: letters, digits, dashes) from folder
-- `dir`. Errors naming the file when there is none, or when it lacks the
-- shape every profile has (name, keys, records).
function Gearsets.load(dir, name)
    if not name:match("^[%w%-]+$") then error("a gearset name is letters, digits and dashes: " .. tostring(name)) end
    local path = dir .. name .. ".lua"
    local chunk = loadfile(path)
    if not chunk then error("no gearset profile " .. name .. " (" .. path .. ")") end
    local p = chunk()
    local ok = p.name == name and type(p.keys) == "table" and #p.keys > 0 and type(p.records) == "table"
    for _, k in ipairs(type(p.keys) == "table" and p.keys or {}) do ok = ok and KNOWN_KEYS[k] end
    if not ok then error(path .. ": not a gearset profile (needs name, keys from shape/class/race/level, records)") end
    return p
end
-- }}}

-- {{{ function Gearsets.points_of
-- Points spent per tree (a list of three integers) for a class's three
-- trees `class_trees` (data/buddy-talent-data.lua), given `knows(spell)`.
-- A talent's points are its highest rank known.
function Gearsets.points_of(class_trees, knows)
    local per = {}
    for i, tree in ipairs(class_trees) do
        local points = 0
        for _, t in ipairs(tree.talents) do
            for rank = #t.spells, 1, -1 do
                if knows(t.spells[rank]) then points = points + rank; break end
            end
        end
        per[i] = points
    end
    return per
end
-- }}}

-- {{{ function Gearsets.nearest_shape
-- The shape id (integer) whose thirds lie nearest a spread of points
-- (three integers): each compared as fractions of the whole, summed
-- squared differences, ties to the lower id. No points: EVEN_SHAPE.
function Gearsets.nearest_shape(shapes, per)
    local total = per[1] + per[2] + per[3]
    if total == 0 then return Gearsets.EVEN_SHAPE end
    local best, best_d
    for id, s in ipairs(shapes) do
        local d = 0
        for i = 1, 3 do d = d + (per[i] / total - s.thirds[i] / 3) ^ 2 end
        if not best_d or d < best_d - 1e-12 then best, best_d = id, d end
    end
    return best
end
-- }}}

-- {{{ function Gearsets.record
-- The record (items, bags, ammo) for `who` = { class, shape (1-10), race,
-- level } (integers), or nil and the reason (text) when the profile has
-- none: no near match is ever given (a level key takes the highest record
-- at or below, which is the key's meaning, not a near match).
function Gearsets.record(profile, who)
    local node = profile.records
    for _, k in ipairs(profile.keys) do
        local want
        if k == "shape" then
            if not who.shape then return nil, "no talent shape known" end
            want = who.class * 100 + who.shape
        elseif k == "level" then
            local best
            for lvl in pairs(node) do
                if lvl <= who.level and (not best or lvl > best) then best = lvl end
            end
            if not best then return nil, string.format("no record at or below level %d", who.level) end
            want = best
        else
            want = who[k]
        end
        if not node[want] then return nil, string.format("no record for %s %s", k, tostring(want)) end
        node = node[want]
    end
    return node
end
-- }}}

return Gearsets
