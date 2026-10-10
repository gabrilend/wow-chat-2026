--------------------------------------------------------------------------------
-- map-heights.lua - the terrain's height anywhere on a map, from the
-- server's map files (issue 617e12)
--
-- For a general audience: each map file covers one grid (533 yards square)
-- of a map and holds the outdoor terrain's height at points 4.17 yards
-- apart (129 x 129 per grid). Caves and buildings are not in it: they are
-- separate models set on the terrain. That is why comparing it with the
-- walking mesh (navmesh-tiles.lua) finds caves: a walkable floor several
-- yards below the terrain is under the hill.
--
-- The file (as the server reads it, src/server/game/Grids/GridTerrainData):
-- header "MAPS", version 9, build, then offset and size of the area,
-- height, liquid and holes sections. Height: "MHGT", flags, gridHeight,
-- gridMaxHeight, then (unless flags & 1: flat at gridHeight) the 129 x 129
-- points (V9) as floats, or as uint16 (flags & 2) / uint8 (flags & 4)
-- scaled by (gridMaxHeight - gridHeight) / 65535 or / 255 above gridHeight.
-- Point (i, j) is index i * 129 + j, i along x, j along y, both growing as
-- the position falls: i = 128 * (32 - x / 533.3333) - 128 * grid x.
-- Files are named MMMXXYY.map: map, grid along x, grid along y.
--
-- Usage: local Heights = dofile(DIR .. "/scripts/lib/map-heights.lua")
--        local terrain = Heights.map(DIR, 1)       -- one map, grids read on use
--        local z = terrain:height(x, y)            -- nil where no map file
-- See map-heights.info.md.
--------------------------------------------------------------------------------

local ffi = require("ffi")

local M = {}

local GRID = 533.3333
ffi.cdef [[
typedef struct { uint32_t magic, version, build, areaOffset, areaSize, heightOffset, heightSize,
                 liquidOffset, liquidSize, holesOffset, holesSize; } mh_map_header;
typedef struct { uint32_t fourcc; uint32_t flags; float gridHeight; float gridMaxHeight; } mh_height_header;
]]

-- {{{ local function read_grid
-- One grid's heights: a function (i, j) -> height for its V9 points, or a
-- constant for a flat grid; nil, why when the file is missing or unreadable.
local function read_grid(path)
    local f = io.open(path, "rb")
    if not f then return nil, "no map file " .. path end
    local raw = f:read("*a")
    f:close()
    -- copied into memory LuaJIT owns (see generate-buddy-subareas: a pointer
    -- into a Lua string crashed compiled code, 2026-10-08)
    local data = ffi.new("uint8_t[?]", #raw)
    ffi.copy(data, raw, #raw)
    local h = ffi.cast("const mh_map_header*", data)
    if h.magic ~= 0x5350414D or h.version ~= 9 then return nil, path .. ": not a version-9 map file" end
    if h.heightOffset == 0 then return nil, path .. ": no height section" end
    local hh = ffi.cast("const mh_height_header*", data + h.heightOffset)
    local flat = hh.gridHeight
    if bit.band(hh.flags, 1) ~= 0 then return function() return flat end, data end
    local base = data + h.heightOffset + ffi.sizeof("mh_height_header")
    local lo, span = hh.gridHeight, hh.gridMaxHeight - hh.gridHeight
    if bit.band(hh.flags, 2) ~= 0 then
        local v = ffi.cast("const uint16_t*", base); local m = span / 65535
        return function(i, j) return lo + v[i * 129 + j] * m end, data
    elseif bit.band(hh.flags, 4) ~= 0 then
        local v = ffi.cast("const uint8_t*", base); local m = span / 255
        return function(i, j) return lo + v[i * 129 + j] * m end, data
    end
    local v = ffi.cast("const float*", base)
    return function(i, j) return v[i * 129 + j] end, data
end
-- }}}

-- {{{ M.map
-- A map's terrain, its grids read the first time a position asks for one.
-- terrain:height(x, y): the height at the nearest V9 point; nil where the
-- map has no file for that grid (open sea, or outside the map).
function M.map(dir, map)
    local grids, keep = {}, {}
    local terrain = {}
    function terrain:height(x, y)
        local fx, fy = 128 * (32 - x / GRID), 128 * (32 - y / GRID)
        local gx, gy = math.floor(fx / 128), math.floor(fy / 128)
        local k = gx * 64 + gy
        local grid = grids[k]
        if grid == nil then
            local fn, data = read_grid(string.format("%s/data-files/maps/%03d%02d%02d.map", dir, map, gx, gy))
            grid = fn or false
            grids[k] = grid
            keep[k] = data                              -- the buffer lives as long as its reader
        end
        if not grid then return nil end
        local i = math.floor(fx - 128 * gx + 0.5)
        local j = math.floor(fy - 128 * gy + 0.5)
        return grid(math.min(128, math.max(0, i)), math.min(128, math.max(0, j)))
    end
    return terrain
end
-- }}}

return M
