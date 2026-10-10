--------------------------------------------------------------------------------
-- navmesh-tiles.lua - reads the server's walking mesh, one tile file at a
-- time (issue 617e12: caves for the roaming-area cutter)
--
-- For a general audience: the server plans how creatures walk on a mesh of
-- flat polygons covering every walkable floor, built from the terrain and
-- from the buildings and caves set on it (data-files/mmaps/, made by the
-- core's mmaps generator). The map files' height grid has one ground height
-- per spot and so cannot show a cave under a hill; the mesh can, because a
-- cave's floor is a polygon lying below that ground. This reads a tile's
-- polygons: their corners in the game's coordinates, their neighbours, and
-- their area kind (ground, water, ...).
--
-- The file (data-files/mmaps/MMMXXYY.mmtile): the project's header
-- (MmapTileHeader in the core's MapDefines.h: magic "MMAP", versions, the
-- data size, liquids flag, the recast settings), then Detour's own tile
-- data (dtCreateNavMeshData's layout, each part padded to 4 bytes): its
-- header (dtMeshHeader, 100 bytes, magic "DNAV"), the corners (3 floats
-- each), the polygons (dtPoly, 32 bytes each), then links and detail parts
-- this reader doesn't need. Detour keeps points as (game y, game z, game
-- x), height in the middle: turned around here, and only here.
--
-- Usage: local Nav = dofile(DIR .. "/scripts/lib/navmesh-tiles.lua")
--        local tile = Nav.read(path)            -- nil, why on failure
-- See navmesh-tiles.info.md.
--------------------------------------------------------------------------------

local ffi = require("ffi")

local M = {}

local DNAV_MAGIC   = 0x444E4156                         -- 'D'<<24 | 'N'<<16 | 'A'<<8 | 'V'
local MESH_HEADER  = 100                                -- sizeof(dtMeshHeader)
local POLY_BYTES   = 32                                 -- sizeof(dtPoly), 6 corners
local VERTS_MAX    = 6                                  -- DT_VERTS_PER_POLYGON
local EXT_LINK     = 0x8000                             -- DT_EXT_LINK: a neighbour in another tile

-- {{{ local function align4
local function align4(n) return n + (4 - n % 4) % 4 end
-- }}}

-- {{{ M.read
-- One tile: { x, y (the tile's place in the mesh's grid), polys = { {
-- corners = { {x, y, z}, ... } in game coordinates, centre = {x, y, z},
-- neis = { n, ... } (0 none, 1.. a polygon of this tile, -1 another tile),
-- flags = number (the mesh builder's: ground, water, ...), area = number } },
-- bmin, bmax (game x, y, z) }.
function M.read(path)
    local f = io.open(path, "rb")
    if not f then return nil, "can't open " .. path end
    local data = f:read("*a")
    f:close()
    -- the bytes copied into memory LuaJIT owns: a pointer into a Lua string
    -- is unsafe once compiled code runs (the 2026-10-08 crash in
    -- generate-buddy-subareas)
    local n = #data
    local buf = ffi.new("uint8_t[?]", n)
    ffi.copy(buf, data, n)
    data = nil
    local u32 = function(o) return ffi.cast("const uint32_t*", buf + o)[0] end
    local i32 = function(o) return ffi.cast("const int32_t*", buf + o)[0] end
    local u16 = function(o) return ffi.cast("const uint16_t*", buf + o)[0] end
    local f32 = function(o) return ffi.cast("const float*", buf + o)[0] end

    -- Detour's header: found by its magic after the project's header, whose
    -- size has changed between versions (52 bytes once, 56 now)
    local base
    for o = 0, math.min(n - 4, 256), 4 do
        if u32(o) == DNAV_MAGIC then base = o; break end
    end
    if not base then return nil, path .. ": no Detour tile in it (no DNAV magic)" end
    local h = {
        x = i32(base + 8), y = i32(base + 12),
        polys = i32(base + 24), verts = i32(base + 28),
    }
    -- bmin/bmax at 72 and 84 (after 15 ints and the 3 agent floats), Detour's order
    local function point(o) return { f32(o + 8), f32(o), f32(o + 4) } end   -- (y, z, x) -> (x, y, z)
    local tile = { x = h.x, y = h.y, bmin = point(base + 72), bmax = point(base + 84), polys = {} }

    local verts = base + align4(MESH_HEADER)
    local polys = verts + align4(12 * h.verts)
    if polys + POLY_BYTES * h.polys > n then
        return nil, path .. ": shorter than its own counts (" .. h.polys .. " polygons, " .. h.verts .. " corners)"
    end
    for p = 0, h.polys - 1 do
        local o = polys + POLY_BYTES * p
        -- dtPoly: firstLink (4 bytes), corners (6 x 2), neighbours (6 x 2),
        -- flags (2), corner count (1), area and type (1)
        local count = buf[o + 30]
        local poly = { corners = {}, neis = {}, flags = u16(o + 28), area = bit.band(buf[o + 31], 0x3f) }
        local cx, cy, cz = 0, 0, 0
        for k = 0, math.min(count, VERTS_MAX) - 1 do
            local c = point(verts + 12 * u16(o + 4 + 2 * k))
            poly.corners[#poly.corners + 1] = c
            cx, cy, cz = cx + c[1], cy + c[2], cz + c[3]
            local nei = u16(o + 16 + 2 * k)
            poly.neis[#poly.neis + 1] = (nei == 0) and 0 or (bit.band(nei, EXT_LINK) ~= 0 and -1 or nei)
        end
        local k = #poly.corners
        poly.centre = k > 0 and { cx / k, cy / k, cz / k } or { 0, 0, 0 }
        tile.polys[p + 1] = poly
    end
    return tile
end
-- }}}

-- {{{ M.tile_path
-- The tile file of a map and tile number, as the core names them
-- (MMAP::MapMgr: "%03i%02i%02i.mmtile").
function M.tile_path(dir, map, a, b)
    return string.format("%s/data-files/mmaps/%03d%02d%02d.mmtile", dir, map, a, b)
end
-- }}}

return M
