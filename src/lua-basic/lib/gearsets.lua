--------------------------------------------------------------------------------
-- lib/gearsets.lua (issue 617r) - finding a character's record in a gearset
--
-- For a general audience: a gearset profile is one named list of gear
-- (data/gearsets/<name>.lua): "elite", the bannermen's Tier 1 outfits;
-- "vanilla-starter", the level-20 starter kit; more later. Inside, records
-- are found by spec and then race (owner, 2026-10-05: "it has to be *spec*
-- profile and race. Not class, though that is self-apparent"), or by
-- class and then race for a profile worn before talents exist (the starter
-- kit). Nothing in a profile knows who will wear it: the same record
-- dresses a buddy, a player character or a stand-in.
--
-- A character's spec is the talent tree holding most of its points, read
-- from the talents it actually has (a buddy's plan is only a plan until
-- its points are spent). Pure: the talent check is passed in, so the
-- offline tests run it without a server.
--------------------------------------------------------------------------------

local Gearsets = {}

-- {{{ function Gearsets.load
-- The profile called `name` (text: letters, digits, dashes) from folder
-- `dir`. Errors naming the file when there is none, or when it lacks the
-- shape every profile has (name, keyed_by "spec" or "class", records).
function Gearsets.load(dir, name)
    if not name:match("^[%w%-]+$") then error("a gearset name is letters, digits and dashes: " .. tostring(name)) end
    local path = dir .. name .. ".lua"
    local chunk = loadfile(path)
    if not chunk then error("no gearset profile " .. name .. " (" .. path .. ")") end
    local p = chunk()
    if p.name ~= name or (p.keyed_by ~= "spec" and p.keyed_by ~= "class") or type(p.records) ~= "table" then
        error(path .. ": not a gearset profile (needs name, keyed_by = \"spec\" or \"class\", records)")
    end
    return p
end
-- }}}

-- {{{ function Gearsets.spec_of
-- The talent tree id (integer, TalentTab) holding most of a character's
-- points, and that count; nil, 0 when it has spent none. `class_trees` is
-- the class's three trees from data/buddy-talent-data.lua; `knows(spell)`
-- answers whether the character has a spell. A talent's points are its
-- highest rank known. A tie goes to the tree further left (the game's
-- own order), so the answer never depends on table order.
function Gearsets.spec_of(class_trees, knows)
    local best, best_points = nil, 0
    for _, tree in ipairs(class_trees) do
        local points = 0
        for _, t in ipairs(tree.talents) do
            for rank = #t.spells, 1, -1 do
                if knows(t.spells[rank]) then points = points + rank; break end
            end
        end
        if points > best_points then best, best_points = tree.tab, points end
    end
    return best, best_points
end
-- }}}

-- {{{ function Gearsets.record
-- The record (items, bags, ammo) for a character of `class`, `spec` (tree
-- id or nil) and `race` (integers), or nil and the reason (text) when the
-- profile has none: no near match is ever given.
function Gearsets.record(profile, class, spec, race)
    local key = (profile.keyed_by == "spec") and spec or class
    if key == nil then return nil, "no talents spent yet, so no spec to look up" end
    local by_race = profile.records[key]
    if not by_race then return nil, string.format("no record for %s %d", profile.keyed_by, key) end
    local rec = by_race[race]
    if not rec then return nil, string.format("no record for race %d under %s %d", race, profile.keyed_by, key) end
    return rec
end
-- }}}

return Gearsets
