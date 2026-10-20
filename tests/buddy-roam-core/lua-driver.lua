
local DIR  = arg[1] or "/mnt/kaun/wow-chat-2026"
local MODE = arg[2]
local Maps = dofile(DIR .. "/tests/buddy-roam-core/drawn-maps.lua")

local POS_TOL   = 0.01
local ANGLE_TOL = 1e-4
local REST_TOL  = 1e-5
local COST_TOL  = 1e-5

local function words(line)
    local t = {}
    for w in line:gmatch("%S+") do t[#t + 1] = w end
    return t
end

if MODE == "dump" then
    Maps.dump(arg[3])
    os.exit(0)
end

if MODE == "run" then
    local Roam = dofile(DIR .. "/src/lua-basic/lib/buddy-roam.lua")
    local by_name = {}
    for _, a in ipairs(Maps.list) do by_name[a.name] = a end
    local out = assert(io.open(arg[4], "w"))
    local TURN

    local function fmt_path(path)
        local cost = 0
        for k = 2, #path do
            local a, b = path[k - 1], path[k]
            local ds = math.sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2)
            local grade = ds > 0 and (b.h - a.h) / ds or 0
            cost = cost + ds * (1 + Roam.PLAN.SLOPE_W * grade * grade)
        end
        local t = { string.format("%.17g", cost), #path }
        for _, p in ipairs(path) do t[#t + 1] = string.format("%.17g %.17g", p.x, p.y) end
        return table.concat(t, " ")
    end

    local function recorded(list)
        local used = 0
        local r = {}
        function r.rand()
            used = used + 1
            if used > #list then error("recorded random numbers exhausted") end
            return list[used]
        end
        function r.used() return used end
        return r
    end

    local RUN = {
        settings = function(w) TURN = tonumber(w[3]) end,

        wp = function(w)
            local id, area = w[2], by_name[w[3]]
            local x, y, spin, angle = tonumber(w[4]), tonumber(w[5]), tonumber(w[6]), tonumber(w[7])
            local has_wp, pct, body = w[8] == "1", tonumber(w[9]), tonumber(w[10])
            local inward, pierce, use_mobs = tonumber(w[11]), tonumber(w[12]), w[13] == "1"
            local n_others, i = tonumber(w[14]), 15
            local others = {}
            for _ = 1, n_others do
                others[#others + 1] = { tonumber(w[i]), tonumber(w[i + 1]) }
                i = i + 2
            end
            local n_rand = tonumber(w[i]); i = i + 1
            local list = {}
            for k = 1, n_rand do list[k] = tonumber(w[i + k - 1]) end
            local rec = recorded(list)

            local b = { id = 1, x = x, y = y, spin = spin, body = body, inward = inward }
            if has_wp then b.share = pct / 100 end
            local mobs = {}
            if use_mobs then
                for _, m in ipairs(area.mobs) do mobs[#mobs + 1] = { x = m[1], y = m[2], r = m[3], alive = true } end
            end
            local s = Roam.new(area, { b }, {
                reading = "waypoints", turn = TURN, y_mode = "step", y_limit = 20, y_min = 1,
                near = 10, crowd = 5, openings = 20, clearance = 3, others = others,
                step = 0.001, body = body, pierce = pierce, mobs = mobs,
            }, rec.rand)
            b.angle = angle
            local ok = pcall(Roam.tick, s, rec.rand)
            if ok and not b.path then ok = false end
            if not ok then
                out:write(string.format("wp %s fail\n", id))
                return
            end
            local lured = b.via_kind == "lure"
            out:write(string.format("wp %s ok %.17g %.17g %.17g %d %d %d %d %d %d %d %.17g %.17g %s\n", id, b.wp.x, b.wp.y, b.angle,
                math.floor(b.share * 100 + 0.5), b.crowd_moves or 0, rec.used(),
                b.spin, b.inward or 0, b.pierced or 0, lured and 1 or 0, lured and b.via.x or 0, lured and b.via.y or 0,
                fmt_path(b.path)))
        end,

        plan = function(w)
            local id, area = w[2], by_name[w[3]]
            local ok, path = pcall(Roam.plan_path, area, tonumber(w[4]), tonumber(w[5]), tonumber(w[6]), tonumber(w[7]), tonumber(w[8]))
            if not ok then
                out:write(string.format("plan %s fail\n", id))
                return
            end
            out:write(string.format("plan %s ok %s\n", id, fmt_path(path)))
        end,

        begin = function(w)
            local id, area = w[2], by_name[w[3]]
            local rec = recorded({ tonumber(w[7]) })
            local b = { id = 1, x = tonumber(w[4]), y = tonumber(w[5]) }
            Roam.new(area, { b }, { reading = "waypoints", turn = TURN }, rec.rand)
            out:write(string.format("begin %s ok %d %.17g %d\n", id, b.spin, b.angle, rec.used()))
        end,

        rest = function(w)
            out:write(string.format("rest %s ok %.17g\n", w[2], Roam.rest_chance(tonumber(w[3]), tonumber(w[4]))))
        end,
    }

    for line in io.lines(arg[3]) do
        local w = words(line)
        RUN[w[1]](w)
    end
    out:close()
    os.exit(0)
end

if MODE == "compare" then
    local function load(path)
        local t, order = {}, {}
        for line in io.lines(path) do
            local w = words(line)
            local key = w[1] .. " " .. w[2]
            t[key] = w
            order[#order + 1] = key
        end
        return t, order
    end
    local cpp, order = load(arg[3])
    local lua = load(arg[4])

    local passed, failed, shown = 0, 0, 0
    local by_kind = {}
    local function fail(key, why)
        failed = failed + 1
        local kind = key:match("^(%S+)")
        by_kind[kind] = (by_kind[kind] or 0) + 1
        if shown < 12 then
            shown = shown + 1
            print("  FAIL " .. key .. ": " .. why)
        end
    end
    local function near(a, b, tol) return math.abs(tonumber(a) - tonumber(b)) <= tol end
    local ties = 0
    local function mirrored(c, l, i)
        if c[i + 1] ~= l[i + 1] then return false end
        local n = tonumber(l[i + 1])
        local ax = (tonumber(l[i + 2]) + tonumber(c[i + 2])) / 2
        local ay = (tonumber(l[i + 3]) + tonumber(c[i + 3])) / 2
        local bx = (tonumber(l[i + 2 * n]) + tonumber(c[i + 2 * n])) / 2
        local by = (tonumber(l[i + 2 * n + 1]) + tonumber(c[i + 2 * n + 1])) / 2
        local len = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
        if len < 1e-9 then return false end
        local ux, uy = (bx - ax) / len, (by - ay) / len
        for k = 1, n do
            local j = i + 2 * k
            local px, py = tonumber(l[j]) - ax, tonumber(l[j + 1]) - ay
            local along = px * ux + py * uy
            local rx, ry = ax + 2 * along * ux - px, ay + 2 * along * uy - py
            if not near(c[j], rx, POS_TOL) or not near(c[j + 1], ry, POS_TOL) then return false end
        end
        return true
    end
    local function same_path(c, l, i)
        local cc, lc = tonumber(c[i]), tonumber(l[i])
        local same_cost = math.abs(cc - lc) <= COST_TOL * math.max(1, lc)
        local why
        if c[i + 1] ~= l[i + 1] then
            why = "path lengths " .. c[i + 1] .. " (C++) and " .. l[i + 1] .. " (Lua)"
        else
            for k = 1, tonumber(c[i + 1]) do
                local j = i + 2 * k
                if not near(c[j], l[j], POS_TOL) or not near(c[j + 1], l[j + 1], POS_TOL) then
                    why = string.format("path point %d at (%s, %s) in C++, (%s, %s) in Lua", k, c[j], c[j + 1], l[j], l[j + 1])
                    break
                end
            end
        end
        if not why then return true end
        if same_cost and mirrored(c, l, i) then
            ties = ties + 1
            return true
        end
        return false, why .. string.format("; costs %.6f (C++) %.6f (Lua)", cc, lc)
    end

    local CHECK = {
        wp = function(c, l)
            if not near(c[4], l[4], POS_TOL) or not near(c[5], l[5], POS_TOL) then
                return false, string.format("waypoint (%s, %s) in C++, (%s, %s) in Lua", c[4], c[5], l[4], l[5])
            end
            if not near(c[6], l[6], ANGLE_TOL) then return false, "bearing " .. c[6] .. " (C++) " .. l[6] .. " (Lua)" end
            if c[7] ~= l[7] then return false, "Y percent " .. c[7] .. " (C++) " .. l[7] .. " (Lua)" end
            if c[8] ~= l[8] then return false, "crowding moves " .. c[8] .. " (C++) " .. l[8] .. " (Lua)" end
            if c[9] ~= l[9] then return false, "random numbers drawn " .. c[9] .. " (C++) " .. l[9] .. " (Lua)" end
            if c[10] ~= l[10] then return false, "direction after " .. c[10] .. " (C++) " .. l[10] .. " (Lua)" end
            if c[11] ~= l[11] then return false, "inward count after " .. c[11] .. " (C++) " .. l[11] .. " (Lua)" end
            if c[12] ~= l[12] then return false, "crossings " .. c[12] .. " (C++) " .. l[12] .. " (Lua)" end
            if c[13] ~= l[13] then return false, "lured " .. c[13] .. " (C++) " .. l[13] .. " (Lua)" end
            if not near(c[14], l[14], POS_TOL) or not near(c[15], l[15], POS_TOL) then
                return false, string.format("lure point (%s, %s) in C++, (%s, %s) in Lua", c[14], c[15], l[14], l[15])
            end
            return same_path(c, l, 16)
        end,
        plan = function(c, l) return same_path(c, l, 4) end,
        begin = function(c, l)
            if c[4] ~= l[4] then return false, "direction " .. c[4] .. " (C++) " .. l[4] .. " (Lua)" end
            if not near(c[5], l[5], ANGLE_TOL) then return false, "bearing " .. c[5] .. " (C++) " .. l[5] .. " (Lua)" end
            if c[6] ~= l[6] then return false, "random numbers drawn " .. c[6] .. " (C++) " .. l[6] .. " (Lua)" end
            return true
        end,
        rest = function(c, l)
            if not near(c[4], l[4], REST_TOL) then return false, "chance " .. c[4] .. " (C++) " .. l[4] .. " (Lua)" end
            return true
        end,
    }

    local outcomes = { ok = 0, fail = 0 }
    for _, key in ipairs(order) do
        local c, l = cpp[key], lua[key]
        if not l then
            fail(key, "no Lua answer")
        elseif c[3] == "exhausted" then
            fail(key, "the C++ side ran out of recorded random numbers (raise the list's length in cross-check.cpp)")
        elseif c[3] ~= l[3] then
            fail(key, "C++ says " .. c[3] .. ", Lua says " .. l[3])
        elseif c[3] == "fail" then
            passed = passed + 1
            outcomes.fail = outcomes.fail + 1
        else
            local ok, why = CHECK[c[1]](c, l)
            if ok then
                passed = passed + 1
                outcomes.ok = outcomes.ok + 1
            else
                fail(key, why)
            end
        end
    end
    print(string.format("  checks passed %d, failed %d (answered: %d situations with a result, %d where both gave up)",
        passed, failed, outcomes.ok, outcomes.fail))
    print(string.format("  of those passed, %d chose a different path of the same cost (a mirror-image tie)", ties))
    for kind, n in pairs(by_kind) do print(string.format("    failed %-6s %d", kind, n)) end
    os.exit(failed == 0 and 0 or 1)
end

io.stderr:write("lua-driver.lua: mode must be dump, run or compare (got " .. tostring(MODE) .. ")\n")
os.exit(2)
