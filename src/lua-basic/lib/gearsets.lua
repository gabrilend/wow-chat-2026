
local Gearsets = {}

local KNOWN_KEYS = { shape = true, class = true, race = true, level = true }
Gearsets.EVEN_SHAPE = 7

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

return Gearsets
