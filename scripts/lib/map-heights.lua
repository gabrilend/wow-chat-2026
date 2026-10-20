
local ffi = require("ffi")

local M = {}

local GRID = 533.3333
ffi.cdef [[
typedef struct { uint32_t magic, version, build, areaOffset, areaSize, heightOffset, heightSize,
                 liquidOffset, liquidSize, holesOffset, holesSize; } mh_map_header;
typedef struct { uint32_t fourcc; uint32_t flags; float gridHeight; float gridMaxHeight; } mh_height_header;
]]

local function read_grid(path)
    local f = io.open(path, "rb")
    if not f then return nil, "no map file " .. path end
    local raw = f:read("*a")
    f:close()
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
            keep[k] = data
        end
        if not grid then return nil end
        local i = math.floor(fx - 128 * gx + 0.5)
        local j = math.floor(fy - 128 * gy + 0.5)
        return grid(math.min(128, math.max(0, i)), math.min(128, math.max(0, j)))
    end
    function terrain:smooth_height(x, y)
        local fx, fy = 128 * (32 - x / GRID), 128 * (32 - y / GRID)
        local gx, gy = math.floor(fx / 128), math.floor(fy / 128)
        if not self:height(x, y) then return nil end
        local grid = grids[gx * 64 + gy]
        local u, v = fx - 128 * gx, fy - 128 * gy
        local i, j = math.min(127, math.floor(u)), math.min(127, math.floor(v))
        local du, dv = u - i, v - j
        return grid(i, j) * (1 - du) * (1 - dv) + grid(i + 1, j) * du * (1 - dv)
             + grid(i, j + 1) * (1 - du) * dv  + grid(i + 1, j + 1) * du * dv
    end
    return terrain
end

return M
