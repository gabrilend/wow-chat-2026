--------------------------------------------------------------------------------
-- lib/m2.lua (issue 173d) - the game's models (characters, creatures, trees)
--
-- For a general audience: a model comes as two files. The .m2 holds every
-- corner point of the model (where it is, which way its surface faces,
-- where on the texture it sits) and the list of textures; the .skin file
-- holds how those points join into triangles, grouped into pieces
-- ("geosets": the body, each hair style, bare hands or gloves...), and
-- which texture each piece is painted with. A character's model holds
-- every hair style and every clothing shape at once; the game shows only
-- the pieces chosen for that character (lib/character.lua chooses). This
-- reads both files into plain Lua tables. The model stands in its resting
-- pose (bones and animation are a later step).
--
-- Layouts are the 3.3.5a client's (model version 264), little-endian.
-- An "array" in the header is a count (uint32) then an offset (uint32).
--   .m2: "MD20"; version at 4; textures array at 80; vertices array at 60;
--        texture lookup array at 128.
--     vertex, 48 bytes: position float[3]; bone weights uint8[4]; bone
--        indices uint8[4]; normal float[3]; texture position float[2];
--        second texture position float[2].
--     texture, 16 bytes: kind uint32 (0 a named file; 1 body skin;
--        2 object skin, a cape; 6 hair; 8 fur; 11-13 creature skins),
--        flags uint32, file name array (chars).
--   .skin: "SKIN"; index array at 4 (uint16: skin point -> model point);
--        triangle array at 12 (uint16: 3 skin points a triangle); piece
--        array at 28 (48 bytes each); texture unit array at 36 (24 bytes).
--     piece: id uint16 (group * 100 + variant), level uint16 (the
--        triangle start's high part), first point uint16, point count
--        uint16, first triangle index uint16, triangle index count uint16,
--        then bones and bounds (not read).
--     texture unit: flags uint8, priority int8, shader uint16, piece
--        uint16, piece again uint16, colour int16, render flags uint16,
--        layer uint16, texture count uint16, texture lookup uint16, ...
--------------------------------------------------------------------------------

local ffi = require("ffi")

local M2 = {}

-- {{{ readers
local function u16(s, at) local a, b = s:byte(at + 1, at + 2); return a + b * 256 end
local function u32(s, at)
    local a, b, c, d = s:byte(at + 1, at + 4)
    return a + b * 256 + c * 65536 + d * 16777216
end
local f32box = ffi.new("float[1]")
local function f32(s, at) ffi.copy(f32box, s:sub(at + 1, at + 4), 4); return f32box[0] end
-- }}}

-- {{{ function M2.read
-- A model from .m2 data `m2` and its first .skin data `skin` (strings):
--   vertices  list of { x, y, z, nx, ny, nz, u, v } (numbers), model space:
--             +x the model's front, +y its left, +z up, in yards
--   textures  list of { kind (integer), file (text, "" unless kind 0) }
--   pieces    list of { id (integer), first, count (triangle indices) }
--   indices   list of model vertex numbers (1-based), three a triangle
--   units     list of { piece (1-based), texture (1-based into textures) }
function M2.read(m2, skin, name)
    name = name or "model"
    if m2:sub(1, 4) ~= "MD20" then error(name .. " is not an M2 model (no MD20 mark)") end
    if u32(m2, 4) ~= 264 then error(string.format("%s is model version %d; this reader knows 264 (3.3.5a)", name, u32(m2, 4))) end
    if skin:sub(1, 4) ~= "SKIN" then error(name .. ": the .skin file has no SKIN mark") end
    local model = { vertices = {}, textures = {}, pieces = {}, indices = {}, units = {} }

    local nv, ov = u32(m2, 60), u32(m2, 64)
    for i = 0, nv - 1 do
        local at = ov + i * 48
        model.vertices[i + 1] = {
            f32(m2, at), f32(m2, at + 4), f32(m2, at + 8),
            f32(m2, at + 20), f32(m2, at + 24), f32(m2, at + 28),
            f32(m2, at + 32), f32(m2, at + 36),
        }
    end

    local nt, ot = u32(m2, 80), u32(m2, 84)
    for i = 0, nt - 1 do
        local at = ot + i * 16
        local len, off = u32(m2, at + 8), u32(m2, at + 12)
        model.textures[i + 1] = { kind = u32(m2, at), file = len > 1 and m2:sub(off + 1, off + len - 1) or "" }
    end
    local nl, ol = u32(m2, 128), u32(m2, 132)
    local lookup = {}
    for i = 0, nl - 1 do lookup[i] = u16(m2, ol + i * 2) end

    -- the skin: which model point each skin point is, then the triangles
    local ni, oi = u32(skin, 4), u32(skin, 8)
    local remap = {}
    for i = 0, ni - 1 do remap[i] = u16(skin, oi + i * 2) end
    local ntri, otri = u32(skin, 12), u32(skin, 16)
    for i = 0, ntri - 1 do model.indices[i + 1] = remap[u16(skin, otri + i * 2)] + 1 end

    local np, op = u32(skin, 28), u32(skin, 32)
    for i = 0, np - 1 do
        local at = op + i * 48
        model.pieces[i + 1] = {
            id    = u16(skin, at),
            first = u16(skin, at + 8) + u16(skin, at + 2) * 65536,   -- the "level" field carries the high part
            count = u16(skin, at + 10),
        }
    end
    local nu, ou = u32(skin, 36), u32(skin, 40)
    for i = 0, nu - 1 do
        local at = ou + i * 24
        model.units[i + 1] = { piece = u16(skin, at + 4) + 1, texture = lookup[u16(skin, at + 16)] + 1 }
    end
    return model
end
-- }}}

return M2
