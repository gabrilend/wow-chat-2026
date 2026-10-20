
local ffi = require("ffi")

local M = {}

local DNAV_MAGIC   = 0x444E4156
local MESH_HEADER  = 100
local POLY_BYTES   = 32
local VERTS_MAX    = 6
local EXT_LINK     = 0x8000

local function align4(n) return n + (4 - n % 4) % 4 end

function M.read(path)
    local f = io.open(path, "rb")
    if not f then return nil, "can't open " .. path end
    local data = f:read("*a")
    f:close()
    local n = #data
    local buf = ffi.new("uint8_t[?]", n)
    ffi.copy(buf, data, n)
    data = nil
    local u32 = function(o) return ffi.cast("const uint32_t*", buf + o)[0] end
    local i32 = function(o) return ffi.cast("const int32_t*", buf + o)[0] end
    local u16 = function(o) return ffi.cast("const uint16_t*", buf + o)[0] end
    local f32 = function(o) return ffi.cast("const float*", buf + o)[0] end

    local base
    for o = 0, math.min(n - 4, 256), 4 do
        if u32(o) == DNAV_MAGIC then base = o; break end
    end
    if not base then return nil, path .. ": no Detour tile in it (no DNAV magic)" end
    local h = {
        x = i32(base + 8), y = i32(base + 12),
        polys = i32(base + 24), verts = i32(base + 28),
    }
    local function point(o) return { f32(o + 8), f32(o), f32(o + 4) } end
    local tile = { x = h.x, y = h.y, bmin = point(base + 72), bmax = point(base + 84), polys = {} }

    local verts = base + align4(MESH_HEADER)
    local polys = verts + align4(12 * h.verts)
    if polys + POLY_BYTES * h.polys > n then
        return nil, path .. ": shorter than its own counts (" .. h.polys .. " polygons, " .. h.verts .. " corners)"
    end
    for p = 0, h.polys - 1 do
        local o = polys + POLY_BYTES * p
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

function M.tile_path(dir, map, a, b)
    return string.format("%s/data-files/mmaps/%03d%02d%02d.mmtile", dir, map, a, b)
end

return M
