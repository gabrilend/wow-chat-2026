-- lua-side.lua - the Lua half of the roaming-pattern check
-- (scripts/test-roam-pattern). Reads the JavaScript half's lines (the
-- situations and the JavaScript answers), answers each again with the Lua
-- model (src/lua-basic/lib/buddy-roam.lua), and compares what
-- docs/roaming-pattern.md fixes: the dungeon's map and open cells, every
-- sector's kind and reach, and every waypoint's place, Y, direction and
-- inward count. Prints counts and each disagreement; exits 1 on any.
-- Usage: luajit lua-side.lua DIR JS_OUTPUT_FILE
local DIR, JSOUT = arg[1] or "/mnt/mtwo/games/azeroth-core/wow-chat-2026", arg[2]
local Roam = dofile(DIR .. "/src/lua-basic/lib/buddy-roam.lua")
local TOL = 1e-6

local passed, failed, notes = 0, 0, {}
local function check(ok, what)
    if ok then passed = passed + 1 else failed = failed + 1; if #notes < 25 then notes[#notes + 1] = what end end
end
local function near(a, b) return math.abs(a - b) <= TOL end
local function words(s) local t = {}; for w in s:gmatch("%S+") do t[#t + 1] = w end; return t end

-- {{{ the dungeon as the Lua model takes it (the gallery generator's DUNGEON)
local DUNGEON = {
    rects = {
        { 20, 190, 110, 340 }, { 190, 140, 310, 240 }, { 20, 20, 120, 100 }, { 370, 20, 480, 110 }, { 380, 170, 480, 330 },
        { 110, 215, 190, 225 }, { 245, 60, 255, 140 }, { 120, 55, 370, 65 }, { 60, 165, 190, 175 }, { 60, 100, 70, 175 },
        { 310, 180, 380, 190 }, { 280, 240, 290, 300 }, { 280, 290, 380, 300 }, { 440, 110, 450, 150 },
    },
    walls   = { { 250, 190, 6 }, { 60, 280, 5 }, { 470, 30, 4 }, { 440, 250, 6 } },
    outline = { { 10, 10 }, { 490, 10 }, { 490, 350 }, { 10, 350 } },
    centre  = { 250, 180 },
}
-- }}}
local g = Roam.paint_grid(DUNGEON, 3)
local AREA = {
    outline = { { 6, 14 }, { 40, 4 }, { 88, 8 }, { 122, 24 }, { 124, 60 }, { 104, 88 }, { 60, 94 }, { 22, 84 }, { 2, 52 } },
    walls = { { 42, 34, 6 }, { 80, 30, 5 }, { 64, 60, 7 }, { 30, 64, 4 }, { 100, 58, 4 }, { 88, 76, 3 } },
}
local function seeded(seed)
    local s = seed
    return function() s = (s * 1103515245 + 12345) % 2147483648; return s / 2147483648 end
end

local rect_i, rock_i, counts = 0, 0, { rect = 0, rock = 0, grid = 0, sector = 0, waypoint = 0 }
for line in io.lines(JSOUT) do
    local w = words(line)
    local kind = w[1]
    if kind == "rect" then
        rect_i = rect_i + 1; counts.rect = counts.rect + 1
        local r = DUNGEON.rects[rect_i]
        check(r and tonumber(w[2]) == r[1] and tonumber(w[3]) == r[2] and tonumber(w[4]) == r[3] and tonumber(w[5]) == r[4], "map rectangle " .. rect_i .. " differs: " .. line)
    elseif kind == "rock" then
        rock_i = rock_i + 1; counts.rock = counts.rock + 1
        local k = DUNGEON.walls[rock_i]
        check(k and tonumber(w[2]) == k[1] and tonumber(w[3]) == k[2] and tonumber(w[4]) == k[3], "map rock " .. rock_i .. " differs: " .. line)
    elseif kind == "grid" then
        counts.grid = counts.grid + 1
        local open, sum = 0, 0
        for i = 0, g.n - 1 do if g.open[i] then open = open + 1; sum = sum + i end end
        check(tonumber(w[2]) == g.nx and tonumber(w[3]) == g.ny and near(tonumber(w[4]), g.x0) and near(tonumber(w[5]), g.y0)
              and tonumber(w[6]) == open and tonumber(w[7]) == sum,
              string.format("grid differs: js %s | lua %d %d %.3f %.3f %d %d", table.concat(w, " ", 2), g.nx, g.ny, g.x0, g.y0, open, sum))
    elseif kind == "sector" then
        counts.sector = counts.sector + 1
        local x, y = tonumber(w[2]), tonumber(w[3])
        local secs = Roam.sense_sectors(g, x, y, 40)
        for k = 1, 8 do
            local jk, jr = w[2 + 2 * k], tonumber(w[3 + 2 * k])
            check(secs[k].kind == jk and near(secs[k].reach, jr),
                  string.format("sector %d at (%.2f, %.2f): js %s %.3f, lua %s %.3f", k, x, y, jk, jr, secs[k].kind, secs[k].reach))
        end
    elseif kind == "waypoint" then
        counts.waypoint = counts.waypoint + 1
        local k = tonumber(w[2])
        local angle, spin, y100, inward, n = tonumber(w[3]), tonumber(w[4]), tonumber(w[5]), tonumber(w[6]), tonumber(w[7])
        local others = {}
        for m = 1, n do others[m] = { tonumber(w[6 + 2 * m]), tonumber(w[7 + 2 * m]) } end
        local ans = {}
        for m = 9 + 2 * n, #w do ans[#ans + 1] = w[m] end   -- after the "=>" at 8 + 2n
        local b = { id = 1, x = 60, y = 50, spin = spin, share = y100 / 100, inward = inward }
        local rand = seeded(1000 + k)
        local s = Roam.new(AREA, { b }, { reading = "waypoints", turn = 2 * math.pi / 10, y_mode = "step", y_limit = 20, y_min = 1,
                                          near = 10, crowd = 5, pierce = 25, others = others, headings = 16 }, rand)
        b.angle = angle
        local ok_pick = pcall(Roam.tick, s, rand)
        if ans[1] == "none" then
            check(not ok_pick or not b.wp, "waypoint " .. k .. ": js found none, lua found one")
        else
            local wx, wy, jy, js, ji = tonumber(ans[1]), tonumber(ans[2]), tonumber(ans[3]), tonumber(ans[4]), tonumber(ans[5])
            local ly = b.share and math.floor(b.share * 100 + 0.5)
            check(ok_pick and b.wp and near(b.wp.x, wx) and near(b.wp.y, wy) and ly == jy and b.spin == js and (b.inward or 0) == ji,
                  string.format("waypoint %d: js (%.4f, %.4f) Y %d spin %d inward %d | lua (%s, %s) Y %s spin %s inward %s", k, wx, wy, jy, js, ji,
                      b.wp and string.format("%.4f", b.wp.x) or "-", b.wp and string.format("%.4f", b.wp.y) or "-", tostring(ly), tostring(b.spin), tostring(b.inward)))
        end
    end
end
check(rect_i == #DUNGEON.rects and rock_i == #DUNGEON.walls, string.format("map sizes differ: js %d rectangles %d rocks, lua %d %d", rect_i, rock_i, #DUNGEON.rects, #DUNGEON.walls))
print(string.format("  situations: %d rectangles, %d rocks, %d grid, %d sector points (x8 sectors), %d waypoints",
    counts.rect, counts.rock, counts.grid, counts.sector, counts.waypoint))
print(string.format("  checks passed %d, failed %d", passed, failed))
for _, n in ipairs(notes) do print("  DIFFER: " .. n) end
os.exit(failed == 0 and 0 or 1)
