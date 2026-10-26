#!/usr/bin/env luajit

local Sched = {}

local function read_text(path)
    local f = io.open(path)
    if not f then return nil end
    local t = f:read("*a"); f:close()
    t = t:gsub("/%*.-%*/", " "):gsub("//[^\n]*", "")
    return t
end

local function seconds(expr)
    if not expr then return nil end
    expr = expr:gsub("IsHeroic%(%)%s*%?%s*[^:]+:%s*", "")
    local a, b = expr:match("randtime%(%s*([^,]+),%s*([^%)]+)%)")
    if a then local x, y = seconds(a), seconds(b); return x and y and (x + y) / 2 end
    local n, unit = expr:match("([%d%.]+)%s*(%a*)")
    if not n then return nil end
    n = tonumber(n)
    if unit == "ms" then return n / 1000 end
    if unit == "s" then return n end
    if unit == "min" then return n * 60 end
    if unit == "" or unit == "u" then return n / 1000 end
    return nil
end

local function match_close(t, i)
    local open = t:sub(i, i)
    local close = ({ ["("] = ")", ["{"] = "}", ["["] = "]" })[open]
    local depth = 0
    for j = i, #t do
        local c = t:sub(j, j)
        if c == open then depth = depth + 1 elseif c == close then depth = depth - 1; if depth == 0 then return j end end
    end
    return nil
end

local function spells_named(t)
    local ids = {}
    for name, value in t:gmatch("([A-Z][A-Z0-9_]*)%s*=%s*([%w_%(%), ]-)%s*[,;\n}]") do
        local n = tonumber(value) or tonumber((value:match("DUNGEON_MODE%(%s*(%d+)") or value:match("RAID_MODE%(%s*(%d+)") or ""))
        if n then ids[name] = n elseif value:match("^[A-Z][A-Z0-9_]*$") then ids[name] = value end
    end
    for name, v in pairs(ids) do if type(v) == "string" then ids[name] = type(ids[v]) == "number" and ids[v] or nil end end
    return ids
end

local CALL_TARGET = { DoCastVictim = "tank", DoCastAOE = "area", DoCastSelf = "self", DoCastRandomTarget = "random",
                      DoCastMaxThreat = "tank", DoCastToAllHostilePlayers = "area" }
local function casts_in(body, ids)
    local list = {}
    for call, args in body:gmatch("([%w_]*Cast[%w_]*)%s*(%b())") do
        local name = args:match("([A-Z][A-Z0-9_]+)")
        local spell = name and ids[name] or tonumber(args:match("^%(%s*(%d+)"))
        if spell then
            local target = CALL_TARGET[call]
            if not target then
                if body:find("SelectTargetMethod::Random") or body:find("SELECT_TARGET_RANDOM") then target = "random"
                elseif args:find("GetVictim") or body:find("SelectTargetMethod::MaxThreat") then target = "tank"
                elseif args:find("me%s*,") or args:find("%(%s*me%s*%)") then target = "self"
                else target = "other" end
            end
            list[#list + 1] = { spell = spell, target = target }
        end
    end
    return list
end

local source_cache
function Sched.find_file(dir, name)
    if not source_cache then
        source_cache = {}
        local p = io.popen('find "' .. dir .. '" -name "*.cpp"')
        for path in p:lines() do
            local f = io.open(path)
            if f then source_cache[#source_cache + 1] = { path = path, text = f:read("*a") }; f:close() end
        end
        p:close()
    end
    local plain = { "(" .. name .. ")", '"' .. name .. '"' }
    for _, s in ipairs(source_cache) do
        for _, needle in ipairs(plain) do
            if s.text:find(needle, 1, true) then return s.path end
        end
        if s.text:find("struct%s+" .. name .. "[%s:{]") or s.text:find("class%s+" .. name .. "[%s:{]") then return s.path end
    end
    return nil
end

function Sched.read(path, name)
    local t = read_text(path)
    local out = { casts = {}, notes = {} }
    if not t then out.notes[#out.notes + 1] = "cannot read " .. path; return out end
    local ids = spells_named(t)
    if name then
        local s = t:find("struct%s+" .. name .. "[%s:{]") or t:find("class%s+" .. name .. "[%s:{]")
        local open = s and t:find("{", s, true)
        local close = open and match_close(t, open)
        if close then t = t:sub(s, close)
        else out.notes[#out.notes + 1] = "its own block not found: the whole file read" end
    end

    local late = {}
    for _, pat in ipairs({ "ScheduleHealthCheckEvent%s*%(", "DamageTaken%s*%b()%s*[%w%s]*{", "HealthBelowPct%s*%b()[^{;]*{" }) do
        local p0 = 1
        while true do
            local s, e = t:find(pat, p0)
            if not s then break end
            local open = t:sub(e, e) == "{" and e or e
            local close = match_close(t, open)
            if close then late[#late + 1] = { s, close } end
            p0 = e + 1
        end
    end
    local function is_late(at)
        for _, r in ipairs(late) do if at >= r[1] and at <= r[2] then return true end end
        return false
    end

    local pos = 1
    while true do
        local s, e = t:find("[%.%s]Schedule%s*%(", pos)
        if not s then break end
        local open = e
        local close = match_close(t, open)
        if not close then break end
        local call = t:sub(open + 1, close - 1)
        local lam = call:find("%[[^%]]*%]%s*%(")
        if lam then
            local times = call:sub(1, lam - 1)
            local first = seconds(times:match("^%s*([^,]+)"))
            local second = times:match("^%s*[^,]+,%s*([^,]+),")
            if second and seconds(second) and first then first = (first + seconds(second)) / 2 end
            local bstart = call:find("{", lam)
            local bend = bstart and match_close(call, bstart)
            local body = bstart and bend and call:sub(bstart, bend) or ""
            local own = body:gsub("[%.%s]Schedule%s*%b()", " ")
            local rep = own:match("context%.Repeat%s*(%b())")
            local every
            if rep then
                local inner = rep:sub(2, -2)
                if inner:match("^%s*$") then every = first
                else
                    local a, b = inner:match("^%s*([^,]+),%s*([^%)]+)%s*$")
                    every = a and (seconds(a) and seconds(b) and (seconds(a) + seconds(b)) / 2) or seconds(inner)
                end
            end
            for _, c in ipairs(casts_in(own, ids)) do
                c.first, c.every, c.late = first, every, is_late(s)
                out.casts[#out.casts + 1] = c
            end
        end
        pos = open + 1
    end

    local first_of = {}
    for ev, times in t:gmatch("ScheduleEvent%s*%(%s*([A-Z][A-Z0-9_]*)%s*,%s*([^;]-)%)%s*;") do
        local a, b = times:match("^%s*([^,]+),%s*([^,]+)")
        local s1 = seconds(a or times)
        if b and seconds(b) and s1 then s1 = (s1 + seconds(b)) / 2 end
        if s1 and not first_of[ev] then first_of[ev] = s1 end
    end
    for ev, body in t:gmatch("case%s+([A-Z][A-Z0-9_]*)%s*:(.-)break%s*;") do
        local rep = body:match("events%.Repeat%s*(%b())") or body:match("events%.RescheduleEvent%s*%(%s*" .. ev .. "%s*,%s*([^;]-)%)%s*;")
            or body:match("events%.ScheduleEvent%s*%(%s*" .. ev .. "%s*,%s*([^;]-)%)%s*;")
        local every
        if rep then
            rep = rep:gsub("^%(", ""):gsub("%)$", "")
            local a, b = rep:match("^%s*([^,]+),%s*([^,%)]+)")
            every = a and seconds(a) and seconds(b) and (seconds(a) + seconds(b)) / 2 or seconds(rep)
        end
        for _, c in ipairs(casts_in(body, ids)) do
            c.first, c.every = first_of[ev], every
            out.casts[#out.casts + 1] = c
        end
    end

    if #out.casts == 0 then
        out.notes[#out.notes + 1] = (t:find("_Timer") or t:find("Timer%s*<=")) and "timers kept in variables: not read" or "no timed casts found"
    end
    return out
end

return Sched
