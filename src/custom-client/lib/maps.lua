--------------------------------------------------------------------------------
-- lib/maps.lua (issue 173a) - the server's ground, read the server's way
--
-- For a general audience: the game server knows how high the ground is
-- everywhere from files it extracts from the game (data-files/maps). Each
-- file is one tile of the world 533 1/3 yards square, holding heights at
-- 129 x 129 corner points and 128 x 128 cell centres; between them the
-- ground is four flat triangles per cell. This reads those files and
-- answers "how high is the ground here?" with the very same arithmetic
-- the server uses (GridTerrainData.cpp, getHeightFrom*), so the custom
-- client's character stands where the server thinks it stands.
--
-- World axes are the game's: x runs north, y runs west, z up. A tile's
-- file name is map id (3 digits), tile x, tile y (2 digits each), the tile
-- indices counted from the north-west corner of the world:
--     tile x = floor(32 - x / 533.333...)    tile y = floor(32 - y / 533.333...)
--------------------------------------------------------------------------------

local ffi = require("ffi")
local bit = require("bit")

local Maps = {}

local GRID_SIZE      = 533.33333              -- yards per tile (SIZE_OF_GRIDS)
local RESOLUTION     = 128                    -- cells per tile side (MAP_RESOLUTION)
local INVALID_HEIGHT = -100000.0              -- the server's "no ground here"

-- height block flags (GridTerrainData.h)
local HEIGHT_NONE, HEIGHT_INT16, HEIGHT_INT8 = 0x0001, 0x0002, 0x0004
-- holes: a cell of 8 x 8 squares carries 16 bits, one per 2 x 2 squares
local HOLE_H = { [0] = 0x1111, 0x2222, 0x4444, 0x8888 }
local HOLE_V = { [0] = 0x000F, 0x00F0, 0x0F00, 0xF000 }

Maps.GRID_SIZE, Maps.RESOLUTION, Maps.INVALID_HEIGHT = GRID_SIZE, RESOLUTION, INVALID_HEIGHT

-- {{{ local function read_u32, read_f32
local function read_u32(s, at)
    local a, b, c, d = s:byte(at + 1, at + 4)
    return a + b * 256 + c * 65536 + d * 16777216
end
local f32box = ffi.new("float[1]")
local u32box = ffi.cast("uint32_t*", f32box)
local function read_f32(s, at)
    u32box[0] = read_u32(s, at)
    return f32box[0]
end
-- }}}

-- {{{ function Maps.tile_of
-- Which tile (x index, y index) holds the world point (x, y).
function Maps.tile_of(x, y)
    return math.floor(32 - x / GRID_SIZE), math.floor(32 - y / GRID_SIZE)
end
-- }}}

-- {{{ function Maps.load_tile
-- Reads one tile. Returns a table:
--   tx, ty      integers   the tile's indices
--   v9          float[129*129]  corner heights, index ix * 129 + iy
--   v8          float[128*128]  cell-centre heights, index ix * 128 + iy
--   flat        number or nil   one height for the whole tile (no height data)
--   holes       table of 256 integers or nil
-- or nil and a message when the file is missing or not a map file.
-- Heights stored as whole numbers (int16 / int8) are turned into yards
-- here (raw x step + base), which gives the server's own numbers: its
-- triangle sums are linear, so decoding first changes nothing but rounding.
function Maps.load_tile(dir, map_id, tx, ty)
    local path = string.format("%s/%03d%02d%02d.map", dir, map_id, tx, ty)
    local f = io.open(path, "rb")
    if not f then return nil, "no tile file " .. path end
    local s = f:read("*a")
    f:close()
    if s:sub(1, 4) ~= "MAPS" then return nil, path .. " is not a map file (no MAPS mark)" end
    local height_at = read_u32(s, 20)                  -- heightMapOffset (6th field)
    local holes_at, holes_size = read_u32(s, 36), read_u32(s, 40)
    local t = { tx = tx, ty = ty }

    if s:sub(height_at + 1, height_at + 4) ~= "MHGT" then return nil, path .. ": height block missing" end
    local flags  = read_u32(s, height_at + 4)
    local base   = read_f32(s, height_at + 8)
    local top    = read_f32(s, height_at + 12)
    local at     = height_at + 16
    if bit.band(flags, HEIGHT_NONE) ~= 0 then
        t.flat = base
    else
        t.v9 = ffi.new("float[?]", 129 * 129)
        t.v8 = ffi.new("float[?]", 128 * 128)
        if bit.band(flags, HEIGHT_INT16) ~= 0 then
            local step = (top - base) / 65535
            local raw = ffi.cast("const uint16_t*", ffi.cast("const char*", s) + at)
            for i = 0, 129 * 129 - 1 do t.v9[i] = raw[i] * step + base end
            for i = 0, 128 * 128 - 1 do t.v8[i] = raw[129 * 129 + i] * step + base end
        elseif bit.band(flags, HEIGHT_INT8) ~= 0 then
            local step = (top - base) / 255
            local raw = ffi.cast("const uint8_t*", ffi.cast("const char*", s) + at)
            for i = 0, 129 * 129 - 1 do t.v9[i] = raw[i] * step + base end
            for i = 0, 128 * 128 - 1 do t.v8[i] = raw[129 * 129 + i] * step + base end
        else
            local raw = ffi.cast("const float*", ffi.cast("const char*", s) + at)
            for i = 0, 129 * 129 - 1 do t.v9[i] = raw[i] end
            for i = 0, 128 * 128 - 1 do t.v8[i] = raw[129 * 129 + i] end
        end
    end
    if holes_size > 0 then
        t.holes = {}
        local raw = ffi.cast("const uint16_t*", ffi.cast("const char*", s) + holes_at)
        for i = 0, 255 do t.holes[i] = raw[i] end
    end
    return t
end
-- }}}

-- {{{ function Maps.is_hole
-- The server's isHole: cell (row, col) of the tile's 128 x 128.
function Maps.is_hole(t, row, col)
    if not t.holes then return false end
    local cell_row, cell_col = math.floor(row / 8), math.floor(col / 8)
    local hole_row = math.floor((row % 8) / 2)
    local hole_col = math.floor((col - cell_col * 8) / 2)
    local hole = t.holes[cell_row * 16 + cell_col]
    return bit.band(hole, HOLE_H[hole_col], HOLE_V[hole_row]) ~= 0
end
-- }}}

-- {{{ function Maps.height_in_tile
-- The ground height at world (x, y) inside tile t, exactly as the server
-- works it out: which of the cell's four triangles the point is in, then
-- the plane through that triangle. INVALID_HEIGHT in a hole.
function Maps.height_in_tile(t, x, y)
    if t.flat then return t.flat end
    local fx = RESOLUTION * (32 - x / GRID_SIZE)
    local fy = RESOLUTION * (32 - y / GRID_SIZE)
    local xi, yi = math.floor(fx), math.floor(fy)
    fx, fy = fx - xi, fy - yi
    xi, yi = bit.band(xi, RESOLUTION - 1), bit.band(yi, RESOLUTION - 1)
    if Maps.is_hole(t, xi, yi) then return INVALID_HEIGHT end

    local v9, v8 = t.v9, t.v8
    local h5 = 2 * v8[xi * 128 + yi]
    local a, b, c
    if fx + fy < 1 then
        if fx > fy then                                  -- triangle 1: h1, h2, h5
            local h1, h2 = v9[xi * 129 + yi], v9[(xi + 1) * 129 + yi]
            a, b, c = h2 - h1, h5 - h1 - h2, h1
        else                                             -- triangle 2: h1, h3, h5
            local h1, h3 = v9[xi * 129 + yi], v9[xi * 129 + yi + 1]
            a, b, c = h5 - h1 - h3, h3 - h1, h1
        end
    else
        if fx > fy then                                  -- triangle 3: h2, h4, h5
            local h2, h4 = v9[(xi + 1) * 129 + yi], v9[(xi + 1) * 129 + yi + 1]
            a, b, c = h2 + h4 - h5, h4 - h2, h5 - h4
        else                                             -- triangle 4: h3, h4, h5
            local h3, h4 = v9[xi * 129 + yi + 1], v9[(xi + 1) * 129 + yi + 1]
            a, b, c = h4 - h3, h3 + h4 - h5, h5 - h4
        end
    end
    return a * fx + b * fy + c
end
-- }}}

-- {{{ function Maps.world
-- A world on one map: tiles loaded as they are needed and kept.
--   world:height(x, y)   ground height, or INVALID_HEIGHT (no tile, a hole)
--   world:tile(tx, ty)   the tile, loaded on first use (false if none)
function Maps.world(dir, map_id)
    local w = { dir = dir, map_id = map_id, tiles = {} }
    function w:tile(tx, ty)
        local key = tx * 64 + ty
        if self.tiles[key] == nil then
            self.tiles[key] = Maps.load_tile(self.dir, self.map_id, tx, ty) or false
        end
        return self.tiles[key]
    end
    function w:height(x, y)
        local t = self:tile(Maps.tile_of(x, y))
        if not t then return INVALID_HEIGHT end
        return Maps.height_in_tile(t, x, y)
    end
    return w
end
-- }}}

-- {{{ function Maps.corner_position
-- World (x, y) of corner point (ix, iy) of tile (tx, ty): the inverse of
-- the index arithmetic above, for building the drawn ground.
function Maps.corner_position(tx, ty, ix, iy)
    return (32 - tx - ix / RESOLUTION) * GRID_SIZE, (32 - ty - iy / RESOLUTION) * GRID_SIZE
end
-- }}}

return Maps
