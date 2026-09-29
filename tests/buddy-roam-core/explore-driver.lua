--------------------------------------------------------------------------------
-- explore-driver.lua (issue 617e6) - the Lua model's side of the exploring
-- cross-check
--
-- For a general audience: the three new ways a buddy explores (least paint,
-- the room orbit, the squished circle) were designed in the Lua model
-- (src/lua-basic/lib/buddy-roam.lua, "painting") and drawn in the gallery's
-- animations 19 and 21 on a hall with an L-shaped leg, tunnels, a side room,
-- a far room and a dead end. The server runs them written again in C++
-- (modules/mod-buddies/src/roam/buddy_explore_core.*). This driver writes
-- the model's grid of that hall (which cells are floor, how far each is
-- from the edge and the walls, its rooms and tunnels, its squished circle)
-- and runs the model's clan of four for a while with each chooser, writing
-- down every choice and path; explore-check.cpp rebuilds the same from the
-- C++ core and compares.
--
-- Usage (scripts/test-buddy-roam-core runs these):
--   luajit explore-driver.lua <project dir> grid  <grid.txt>
--   luajit explore-driver.lua <project dir> trace <mode> <seed> <ticks> <trace.txt>
--   (mode: least | rooms | disc)
--------------------------------------------------------------------------------

local DIR  = arg[1] or "/mnt/mtwo/games/azeroth-core/wow-chat-2026"
local MODE = arg[2]
local Roam = dofile(DIR .. "/src/lua-basic/lib/buddy-roam.lua")

-- {{{ the hall
-- A copy of the gallery's hall (scripts/generate-buddy-roaming-gifs,
-- "exploring as painting: the hall"), so this test doesn't run the
-- generator. If the gallery's hall changes, change it here too; the test
-- holds the core to the model on this shape, whatever it is.
local function centroid(poly)
    local a, cx, cy = 0, 0, 0
    for i = 1, #poly do
        local j = i % #poly + 1
        local k = poly[i][1] * poly[j][2] - poly[j][1] * poly[i][2]
        a, cx, cy = a + k, cx + (poly[i][1] + poly[j][1]) * k, cy + (poly[i][2] + poly[j][2]) * k
    end
    return { cx / (3 * a), cy / (3 * a) }
end
local HALL_OUTLINE = {
    { 10, 10 }, { 150, 10 }, { 150, 40 }, { 200, 40 }, { 200, 20 }, { 250, 20 }, { 250, 80 }, { 228, 80 }, { 228, 140 }, { 250, 140 },
    { 250, 180 }, { 200, 180 }, { 200, 140 }, { 220, 140 }, { 220, 80 }, { 200, 80 }, { 200, 50 }, { 150, 50 }, { 150, 90 }, { 80, 90 },
    { 80, 140 }, { 150, 140 }, { 150, 150 }, { 80, 150 }, { 80, 180 }, { 10, 180 },
}
local HALL = {
    outline = HALL_OUTLINE,
    walls   = { { 50, 40, 6 }, { 110, 65, 5 }, { 40, 130, 5 }, { 230, 50, 4 }, { 225, 162, 3 } },
    centre  = centroid(HALL_OUTLINE),
}
local HALL_ENTRANCE = { 45, 176 }
local HALL_CELL     = 2
local DISC_SWEEPS   = 4000
-- }}}

-- {{{ local function g17
local function g17(v) return string.format("%.17g", v) end
-- }}}

-- {{{ local function make_grid
local function make_grid()
    local g = Roam.paint_grid(HALL, HALL_CELL)
    Roam.paint_disc_map(g, DISC_SWEEPS)
    return g
end
-- }}}

-- {{{ grid
-- One header line, then one line per cell:
--   i inside open edge wall rim du dv room tunnel
-- (edge -1 where not inside, wall -1 where not open, du dv 0 where the cell
-- has no place on the disc), then the wall pulse's cells, the places, and
-- the disc's waypoint cells.
if MODE == "grid" then
    local g = make_grid()
    local out = assert(io.open(arg[3], "w"))
    out:write(string.format("grid %d %d %s %s %s %s %s %d\n", g.nx, g.ny, g17(g.x0), g17(g.y0), g17(g.cell),
        g17(HALL_ENTRANCE[1]), g17(HALL_ENTRANCE[2]), DISC_SWEEPS))
    for i = 0, g.n - 1 do
        out:write(string.format("c %d %d %d %s %s %d %s %s %d %d\n", i,
            g.inside[i] and 1 or 0, g.open[i] and 1 or 0,
            g17(g.edge[i] or -1), g17(g.wall[i] or -1),
            g.rim[i] and 1 or 0, g17(g.du[i] or 0), g17(g.dv[i] or 0),
            g.room[i] or 0, g.tunnel[i] or 0))
    end
    for _, c in ipairs(g.wall_cells) do out:write(string.format("w %d %d\n", c[1], c[2])) end
    for _, p in ipairs(g.places) do
        out:write(string.format("p %s %d %d %s %s\n", p.kind, p.id, #p.cells, g17(p.cx), g17(p.cy)))
    end
    for _, i in ipairs(g.disc_clear) do out:write(string.format("d %d\n", i)) end
    out:close()
    os.exit(0)
end
-- }}}

-- {{{ trace
-- The model's clan of four on the hall, as the gallery's paint_sim: they
-- start by the entrance, each with a random circling direction; each tick
-- the walls pulse (every 48 ticks), buddies paint (every 4 ticks, turn by
-- turn), and a buddy at the end of its path chooses and plans again. Every
-- choice is written: "P tick id goal_x goal_y points x1 y1 ...", and every
-- 250 ticks the paint's totals: "C tick buddy_paint wall_paint explored".
if MODE == "trace" then
    local mode, seed, ticks = arg[3], tonumber(arg[4]), tonumber(arg[5])
    local g = make_grid()
    -- the gallery's seeded random numbers (its lcg)
    local s = seed
    local rand = function()
        s = (s * 1103515245 + 12345) % 2147483648
        return s / 2147483648
    end
    local bs = {}
    for k = 1, 4 do bs[k] = { id = k, x = HALL_ENTRANCE[1] - 10 + k * 4, y = HALL_ENTRANCE[2] - 4 } end
    local sim = Roam.new(HALL, bs, { reading = "paint", paint_mode = mode, grid = g, entrance = HALL_ENTRANCE, wall_paint = true,
        turn = 2 * math.pi / 10, y_mode = "step", y_limit = 20, near = 10, crowd = 5, openings = 20 }, rand)
    local out = assert(io.open(arg[6], "w"))
    for _, b in ipairs(bs) do out:write(string.format("S %d %d\n", b.id, b.spin)) end
    local seen = {}
    for t = 1, ticks do
        Roam.tick(sim, rand)
        for _, b in ipairs(bs) do
            if b.path ~= seen[b.id] then
                seen[b.id] = b.path
                local w = { "P", t, b.id, g17(b.goal.x), g17(b.goal.y), #b.path }
                for _, p in ipairs(b.path) do w[#w + 1] = g17(p.x); w[#w + 1] = g17(p.y) end
                out:write(table.concat(w, " "), "\n")
            end
        end
        if t % 250 == 0 then
            local sb, sw, sc = 0, 0, 0
            for i = 0, g.n - 1 do sb = sb + g.buddy[i]; sw = sw + g.wallp[i]; if g.close[i] then sc = sc + 1 end end
            out:write(string.format("C %d %d %d %d\n", t, sb, sw, sc))
        end
    end
    out:close()
    os.exit(0)
end
-- }}}

io.stderr:write("explore-driver.lua: unknown mode '" .. tostring(MODE) .. "' (grid | trace)\n")
os.exit(2)
