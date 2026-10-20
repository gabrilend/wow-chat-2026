#!/usr/bin/env luajit

local DIR = "/mnt/kaun/wow-chat-2026"
if arg[1] and arg[1] ~= "" then DIR = arg[1] end
local MYSQL = DIR .. "/mysql/installed-files/bin/mysql"
local WORLD = "acore_world_basic"

local passed, failed = 0, 0
local function check(ok, what)
    if ok then passed = passed + 1 else failed = failed + 1; print("  FAIL: " .. what) end
end

local names = {}
local profiles = {}
for _, tier in ipairs({ 1, 10, 20, 30, 40, 50, 60 }) do
    local path = string.format("%s/src/lua-basic/data/gearsets/buddy-white-%d.lua", DIR, tier)
    local p = assert(dofile(path), "could not read " .. path)
    profiles[#profiles + 1] = p
    for key, levels in pairs(p.records) do
        for level, rec in pairs(levels) do
            check(rec.items[15] ~= nil, string.format("%s shape %d level %d has a main hand", p.name, key, level))
            for _, item in pairs(rec.items) do
                names[item] = names[item] or {}
                table.insert(names[item], { profile = p.name, key = key, level = level })
            end
        end
    end
end

local ids = {}
for id in pairs(names) do ids[#ids + 1] = tostring(id) end
local cmd = string.format("MYSQL_PWD=menardi '%s' -h127.0.0.1 -P3307 -uritz -N -B %s -e 'SELECT entry, RequiredLevel FROM item_template WHERE entry IN (%s)'",
    MYSQL, WORLD, table.concat(ids, ","))
local pipe = assert(io.popen(cmd .. " 2>&1"))
local req = {}
for line in pipe:lines() do
    local e, r = line:match("^(%d+)\t(%d+)$")
    if not e then error("MySQL said: " .. line .. " (is it running? scripts/start-mysql)") end
    req[tonumber(e)] = tonumber(r)
end
pipe:close()
for id, uses in pairs(names) do
    check(req[id] ~= nil, "item " .. id .. " exists in " .. WORLD)
    for _, u in ipairs(uses) do
        if req[id] and req[id] > u.level then
            check(false, string.format("%s shape %d level %d names item %d, which needs level %d (re-run scripts/translate-buddy-kit-to-gearset)",
                u.profile, u.key, u.level, id, req[id]))
        end
    end
end

print(string.format("gearsets-hold-weapons: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
