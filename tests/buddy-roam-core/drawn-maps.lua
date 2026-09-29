--------------------------------------------------------------------------------
-- drawn-maps.lua (issue 617e2) - the drawn maps the roaming core is checked on
--
-- For a general audience: the animations of buddy roaming were drawn on two
-- made-up places (scripts/generate-buddy-roaming-gifs): a mine-sized area
-- cluttered with rocks, crates, raised ground and hills, and a chamber with
-- a side tunnel. The cross-check of the C++ roaming core against the Lua
-- model runs both on these same places. This file is the one description
-- of them for the test: the Lua driver builds its areas from it, and writes
-- it out as plain numbers (maps.txt) for the C++ driver to read, so the two
-- can never be given different maps.
--
-- Copied from the generator (2026-09-27); the generator keeps its own copy.
-- If the generator's maps change, change these too (open question in 617e2:
-- have the generator read this file).
--
-- Every number that is handed to the C++ side as a float is rounded to a
-- float here first (to_float), so both sides compute from the very same
-- values; the C++ core takes positions as floats.
--------------------------------------------------------------------------------

local ffi = require("ffi")

local Maps = {}

-- {{{ local function to_float
-- The nearest single-precision value, as a Lua number.
local f1 = ffi.new("float[1]")
local function to_float(v)
    f1[0] = v
    return tonumber(f1[0])
end
Maps.to_float = to_float
-- }}}

-- {{{ the two places
-- walls: { x, y, radius, kind }; kind nil = a rock. Heights standing up
-- from the ground: big rocks (radius over 2) 5 yards, small rocks 1.2,
-- crates 1, raised ground 1.5 (as in the generator).
-- hills: { x, y, height, spread }, bell-shaped.
local TALL = { crate = 1.0, mound = 1.5 }
local function wall_tall(w) return TALL[w[4]] or (w[3] > 2 and 5 or 1.2) end

local CLUTTERED_OUTLINE = { { 6, 14 }, { 40, 4 }, { 88, 8 }, { 122, 24 }, { 124, 60 }, { 104, 88 }, { 60, 94 }, { 22, 84 }, { 2, 52 } }
local CLUTTERED_WALLS = {
    { 42, 34, 6 }, { 80, 30, 5 }, { 64, 60, 7 }, { 30, 64, 4 }, { 100, 58, 4 }, { 88, 76, 3 },
    { 22, 30, 1.5, "crate" }, { 56, 22, 1.2, "crate" }, { 96, 44, 1.5, "crate" }, { 50, 80, 1.2, "crate" }, { 112, 36, 1.2, "crate" },
    { 16, 46, 2.0 }, { 70, 14, 1.5 }, { 46, 50, 2.0 }, { 84, 88, 1.5 }, { 108, 72, 2.0 },
    { 26, 76, 4.0, "mound" }, { 64, 38, 3.5, "mound" }, { 100, 20, 3.0, "mound" },
}
local CLUTTERED_HILLS = { { 30, 42, 6, 13 }, { 98, 68, 7, 11 }, { 72, 24, -3, 9 } }
-- monsters: { x, y, aggro radius }, the generator's scene 18 (MOBS), all
-- living (the monster nudge, 2026-09-27)
local CLUTTERED_MOBS = {
    { 20, 20, 12 }, { 50, 12, 10 }, { 82, 16, 11 }, { 112, 48, 12 }, { 90, 62, 9 }, { 72, 86, 10 },
    { 40, 60, 11 }, { 12, 62, 10 }, { 56, 44, 9 }, { 106, 30, 10 }, { 30, 84, 12 },
}

local CHAMBER = { { 6, 20 }, { 30, 6 }, { 62, 6 }, { 80, 18 }, { 84, 40 }, { 84, 48 }, { 82, 72 }, { 60, 88 }, { 26, 86 }, { 4, 60 } }
local TUNNEL_OUTLINE = { { 6, 20 }, { 30, 6 }, { 62, 6 }, { 80, 18 }, { 84, 40 }, { 104, 39 }, { 104, 26 }, { 122, 24 }, { 124, 60 },
                        { 104, 60 }, { 104, 48 }, { 84, 48 }, { 82, 72 }, { 60, 88 }, { 26, 86 }, { 4, 60 } }
local TUNNEL_WALLS = { { 30, 36, 5 }, { 56, 66, 4 }, { 48, 20, 1.2, "crate" }, { 114, 52, 1.2, "crate" }, { 20, 70, 3, "mound" }, { 66, 30, 1.5 } }
-- }}}

-- {{{ local function centroid
-- The chamber's centre of area (the tunnel map's centre, as the generator
-- takes it).
local function centroid(poly)
    local a, cx, cy = 0, 0, 0
    for i = 1, #poly do
        local j = i % #poly + 1
        local k = poly[i][1] * poly[j][2] - poly[j][1] * poly[i][2]
        a, cx, cy = a + k, cx + (poly[i][1] + poly[j][1]) * k, cy + (poly[i][2] + poly[j][2]) * k
    end
    return cx / (3 * a), cy / (3 * a)
end
-- }}}

-- {{{ local function corner_average
-- The cluttered map's centre: the average of its corners (the model's
-- Roam.centre without a named centre).
local function corner_average(poly)
    local sx, sy = 0, 0
    for _, p in ipairs(poly) do sx, sy = sx + p[1], sy + p[2] end
    return sx / #poly, sy / #poly
end
-- }}}

-- {{{ local function build
-- An area table the Lua model takes: outline, walls, a named centre (as
-- floats, so the C++ side gets the same one), and the height function.
local function build(name, outline, walls, hills, mobs, cx, cy)
    local area = { name = name, outline = outline, walls = walls, hills = hills, mobs = mobs,
                   centre = { to_float(cx), to_float(cy) } }
    function area.height(x, y)
        local h = 0
        for _, k in ipairs(hills) do h = h + k[3] * math.exp(-((x - k[1]) ^ 2 + (y - k[2]) ^ 2) / (2 * k[4] ^ 2)) end
        local top = 0
        for _, w in ipairs(walls) do
            if (x - w[1]) ^ 2 + (y - w[2]) ^ 2 < w[3] ^ 2 then top = math.max(top, wall_tall(w)) end
        end
        return h + top
    end
    return area
end
-- }}}

Maps.list = {
    build("cluttered", CLUTTERED_OUTLINE, CLUTTERED_WALLS, CLUTTERED_HILLS, CLUTTERED_MOBS, corner_average(CLUTTERED_OUTLINE)),
    build("tunnel", TUNNEL_OUTLINE, TUNNEL_WALLS, {}, {}, centroid(CHAMBER)),
}

-- {{{ function Maps.dump
-- Write the maps as plain numbers for the C++ driver:
--   map <name> <centre x> <centre y>
--   outline <n> x y x y ...
--   walls <n> x y radius tall ...
--   hills <n> x y height spread ...
--   mobs <n> x y radius ...
function Maps.dump(path)
    local f = assert(io.open(path, "w"))
    for _, a in ipairs(Maps.list) do
        f:write(string.format("map %s %.17g %.17g\n", a.name, a.centre[1], a.centre[2]))
        local o = { "outline", #a.outline }
        for _, p in ipairs(a.outline) do o[#o + 1] = p[1]; o[#o + 1] = p[2] end
        f:write(table.concat(o, " "), "\n")
        local w = { "walls", #a.walls }
        for _, p in ipairs(a.walls) do w[#w + 1] = p[1]; w[#w + 1] = p[2]; w[#w + 1] = p[3]; w[#w + 1] = wall_tall(p) end
        f:write(table.concat(w, " "), "\n")
        local h = { "hills", #a.hills }
        for _, p in ipairs(a.hills) do for i = 1, 4 do h[#h + 1] = p[i] end end
        f:write(table.concat(h, " "), "\n")
        local m = { "mobs", #a.mobs }
        for _, p in ipairs(a.mobs) do for i = 1, 3 do m[#m + 1] = p[i] end end
        f:write(table.concat(m, " "), "\n")
    end
    f:close()
end
-- }}}

return Maps
