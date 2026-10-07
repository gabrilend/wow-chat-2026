--------------------------------------------------------------------------------
-- lib/navmesh-slope.lua (issue 173a) - the steepest ground the server walks
--
-- For a general audience: the server plans every creature's path on its
-- navigation mesh, and that mesh was built with one rule for how steep a
-- slope can be and still count as ground you walk on. The rule is written
-- into the header of every navigation tile file the server loads
-- (data-files/mmaps/*.mmtile). Reading it from there, rather than typing
-- the number into the client, means the client and the server can never
-- disagree about it (owner, 2026-10-05: "when they're too steep, you
-- should start falling, using the same rules that the server uses").
--
-- Tile header layout (the server's MmapTileHeader, MapDefines.h; 56 bytes,
-- little-endian):
--   0  uint32  magic, 0x4d4d4150 ("MMAP")
--   4  uint32  Detour version
--   8  uint32  mmap version (19 when this was written)
--   12 uint32  size of the tile data that follows
--   16 char    uses liquids, then 3 padding bytes
--   20 float   walkable slope angle, degrees   <- the rule read here
--   24 ...     the rest of the build settings (radius, height, climb, ...)
--------------------------------------------------------------------------------

local NavmeshSlope = {}

local MMAP_MAGIC   = 0x4d4d4150
local MMAP_VERSION = 19

-- {{{ local function f32
-- An IEEE single-precision float from four little-endian bytes, by
-- arithmetic (no FFI), so this also runs under plain LuaJIT in the tests.
local function f32(s, at)
    local a, b, c, d = s:byte(at + 1, at + 4)
    local sign = d >= 128 and -1 or 1
    local e    = (d % 128) * 2 + math.floor(c / 128)
    local m    = (c % 128) * 65536 + b * 256 + a
    if e == 0 then return sign * m * 2 ^ -149 end
    return sign * (1 + m / 2 ^ 23) * 2 ^ (e - 127)
end
-- }}}

-- {{{ function NavmeshSlope.read
-- The walkable slope angle, in degrees (number), from the first tile file
-- of `map_id` (integer) in the server's mmaps folder `dir` (text). Errors,
-- naming the file and what was wrong, when there is no tile, the header is
-- not a navigation tile, or its version is one this layout wasn't read
-- from: a wrong slope rule is worse than none.
function NavmeshSlope.read(dir, map_id)
    local prefix = string.format("%03d", map_id)
    local listing = io.popen('ls "' .. dir .. '"')
    local name
    for line in listing:lines() do
        if line:sub(1, 3) == prefix and line:match("%.mmtile$") then name = line; break end
    end
    listing:close()
    if not name then error(string.format("no navigation tile for map %d in %s (scripts/extract-maps makes them)", map_id, dir)) end

    local path = dir .. "/" .. name
    local f = assert(io.open(path, "rb"))
    local s = f:read(24)
    f:close()
    local function u32(at) local a, b, c, d = s:byte(at + 1, at + 4); return a + b * 256 + c * 65536 + d * 16777216 end
    if not s or #s < 24 or u32(0) ~= MMAP_MAGIC then error(path .. " is not a navigation tile (no MMAP mark)") end
    if u32(8) ~= MMAP_VERSION then
        error(string.format("%s is navigation tile version %d; this reader knows version %d's header", path, u32(8), MMAP_VERSION))
    end
    return f32(s, 20)
end
-- }}}

return NavmeshSlope
