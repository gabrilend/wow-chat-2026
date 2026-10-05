--------------------------------------------------------------------------------
-- lib/ground-mesh.lua (issue 173a) - one tile of ground, ready to draw
--
-- For a general audience: turns one tile of the server's height data
-- (lib/maps.lua) into triangles the graphics card can draw: the 129 x 129
-- corner points and 128 x 128 cell centres as points, four triangles per
-- cell exactly as the server divides the cell (so what you see is what the
-- server stands you on), no triangles over holes. Each point gets a
-- direction the surface faces (for light) and a colour from how steep it
-- is: forest floor on the level, bare rock on the steep.
--
-- Positions are made relative to an origin near the player, so the
-- graphics card's single-precision numbers stay exact far from the
-- world's centre.
--------------------------------------------------------------------------------

local ffi  = require("ffi")
local Maps = require("lib.maps")

local Ground = {}

ffi.cdef[[
typedef struct { float x, y, z, nx, ny, nz; uint8_t r, g, b, a; } ground_vertex;
]]

Ground.FORMAT = {
    { "VertexPosition", "float", 3 },
    { "VertexNormal",   "float", 3 },
    { "VertexColor",    "byte",  4 },
}

local STEP = Maps.GRID_SIZE / Maps.RESOLUTION    -- yards between corner points (4.1667)
local FLOOR = { 0.20, 0.33, 0.24 }               -- Ashenvale's dark forest floor
local ROCK  = { 0.38, 0.36, 0.33 }               -- steep ground

-- {{{ local function colour
local function colour(nz)
    -- nz: how upward the surface faces (1 level, 0 a wall)
    local t = math.max(0, math.min(1, (0.92 - nz) / 0.25))
    return FLOOR[1] + (ROCK[1] - FLOOR[1]) * t, FLOOR[2] + (ROCK[2] - FLOOR[2]) * t, FLOOR[3] + (ROCK[3] - FLOOR[3]) * t
end
-- }}}

-- {{{ function Ground.build
-- A LÖVE mesh for tile `t` (from Maps.load_tile), positions relative to
-- (ox, oy). Returns the mesh, or nil for a tile with no height data.
function Ground.build(t, ox, oy)
    if t.flat then return nil end
    local v9, v8 = t.v9, t.v8
    local corner_count, centre_count = 129 * 129, 128 * 128
    local count = corner_count + centre_count
    local data = love.data.newByteData(count * ffi.sizeof("ground_vertex"))
    local vtx = ffi.cast("ground_vertex*", data:getFFIPointer())

    -- corner points: index ix * 129 + iy; their facing from the neighbours'
    -- heights (the slope across two steps each way)
    local function h9(ix, iy)
        ix = math.max(0, math.min(128, ix)); iy = math.max(0, math.min(128, iy))
        return v9[ix * 129 + iy]
    end
    for ix = 0, 128 do
        for iy = 0, 128 do
            local v = vtx[ix * 129 + iy]
            local wx, wy = Maps.corner_position(t.tx, t.ty, ix, iy)
            v.x, v.y, v.z = wx - ox, wy - oy, v9[ix * 129 + iy]
            -- world x falls as ix rises, so the x slope is (back - ahead)
            local sx = (h9(ix - 1, iy) - h9(ix + 1, iy)) / (2 * STEP)
            local sy = (h9(ix, iy - 1) - h9(ix, iy + 1)) / (2 * STEP)
            local nx, ny, nz = -sx, -sy, 1
            local l = math.sqrt(nx * nx + ny * ny + nz * nz)
            v.nx, v.ny, v.nz = nx / l, ny / l, nz / l
            local r, g, b = colour(v.nz)
            v.r, v.g, v.b, v.a = r * 255, g * 255, b * 255, 255
        end
    end
    -- cell centres: index corner_count + ix * 128 + iy; facing averaged from
    -- the cell's four corners
    for ix = 0, 127 do
        for iy = 0, 127 do
            local v = vtx[corner_count + ix * 128 + iy]
            local wx, wy = Maps.corner_position(t.tx, t.ty, ix + 0.5, iy + 0.5)
            v.x, v.y, v.z = wx - ox, wy - oy, v8[ix * 128 + iy]
            local nx, ny, nz = 0, 0, 0
            for _, c in ipairs({ ix * 129 + iy, (ix + 1) * 129 + iy, ix * 129 + iy + 1, (ix + 1) * 129 + iy + 1 }) do
                nx, ny, nz = nx + vtx[c].nx, ny + vtx[c].ny, nz + vtx[c].nz
            end
            local l = math.sqrt(nx * nx + ny * ny + nz * nz)
            v.nx, v.ny, v.nz = nx / l, ny / l, nz / l
            local r, g, b = colour(v.nz)
            v.r, v.g, v.b, v.a = r * 255, g * 255, b * 255, 255
        end
    end

    -- triangles: per cell, the server's four (h1 h2 h5, h1 h3 h5, h2 h4 h5,
    -- h3 h4 h5), none in a hole
    local tris = {}
    for ix = 0, 127 do
        for iy = 0, 127 do
            if not Maps.is_hole(t, ix, iy) then
                local h1, h2 = ix * 129 + iy, (ix + 1) * 129 + iy
                local h3, h4 = ix * 129 + iy + 1, (ix + 1) * 129 + iy + 1
                local h5 = corner_count + ix * 128 + iy
                local n = #tris
                tris[n + 1], tris[n + 2], tris[n + 3]    = h1 + 1, h2 + 1, h5 + 1
                tris[n + 4], tris[n + 5], tris[n + 6]    = h1 + 1, h5 + 1, h3 + 1
                tris[n + 7], tris[n + 8], tris[n + 9]    = h2 + 1, h4 + 1, h5 + 1
                tris[n + 10], tris[n + 11], tris[n + 12] = h3 + 1, h5 + 1, h4 + 1
            end
        end
    end
    local mesh = love.graphics.newMesh(Ground.FORMAT, count, "triangles", "static")
    mesh:setVertices(data)
    mesh:setVertexMap(tris)
    return mesh
end
-- }}}

return Ground
