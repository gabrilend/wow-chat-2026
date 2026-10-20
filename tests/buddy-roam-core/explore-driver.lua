
local DIR  = arg[1] or "/mnt/kaun/wow-chat-2026"
local MODE = arg[2]
local Roam = dofile(DIR .. "/src/lua-basic/lib/buddy-roam.lua")

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

local function g17(v) return string.format("%.17g", v) end

local function make_grid()
    local g = Roam.paint_grid(HALL, HALL_CELL)
    Roam.paint_disc_map(g, DISC_SWEEPS)
    return g
end

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

if MODE == "trace" then
    local mode, seed, ticks = arg[3], tonumber(arg[4]), tonumber(arg[5])
    local g = make_grid()
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

io.stderr:write("explore-driver.lua: unknown mode '" .. tostring(MODE) .. "' (grid | trace)\n")
os.exit(2)
