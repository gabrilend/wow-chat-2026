--------------------------------------------------------------------------------
-- lib/blp.lua (issue 173d) - the game's texture files, decoded to pixels
--
-- For a general audience: every picture painted on a model (skin, hair,
-- armour, bark) is a BLP2 file. Inside is the picture at full size and at
-- smaller sizes, stored one of three ways: as colour numbers into a
-- 256-colour palette, as the graphics card's own compressed blocks (DXT1,
-- DXT3, DXT5: 4 x 4 pixels packed into 8 or 16 bytes), or as plain pixels.
-- This turns the full-size picture into plain red-green-blue-alpha bytes,
-- in LuaJIT, so the client and the offline tests can both use it.
--
-- Header (148 bytes, then a 1024-byte palette; little-endian):
--   0   "BLP2"
--   4   uint32  type (1)
--   8   uint8   encoding: 1 palette, 2 DXT, 3 plain BGRA
--   9   uint8   alpha bits: 0, 1, 4 or 8
--   10  uint8   alpha kind (DXT): 0 DXT1, 1 DXT3, 7 DXT5
--   11  uint8   has smaller sizes (mipmaps)
--   12  uint32  width
--   16  uint32  height
--   20  uint32[16] where each size starts
--   84  uint32[16] how long each size is
--   148 uint8[1024] palette, BGRA
--------------------------------------------------------------------------------

local ffi = require("ffi")
local bit = require("bit")

local Blp = {}

-- {{{ local function u32
local function u32(s, at)
    local a, b, c, d = s:byte(at + 1, at + 4)
    return a + b * 256 + c * 65536 + d * 16777216
end
-- }}}

-- {{{ local function rgb565
-- A DXT colour: 5 bits red, 6 green, 5 blue, widened to 0-255.
local function rgb565(v)
    local r, g, b = bit.rshift(v, 11), bit.band(bit.rshift(v, 5), 63), bit.band(v, 31)
    return bit.bor(bit.lshift(r, 3), bit.rshift(r, 2)), bit.bor(bit.lshift(g, 2), bit.rshift(g, 4)), bit.bor(bit.lshift(b, 3), bit.rshift(b, 2))
end
-- }}}

-- {{{ local function decode_dxt
-- Fills `out` (uint8 RGBA, w*h*4) from DXT blocks in `s` starting at
-- byte `at`. `kind` 0 DXT1 (8-byte blocks, 1-bit alpha), 1 DXT3 (16-byte,
-- 4 bits of alpha a pixel), 7 DXT5 (16-byte, alpha by interpolation).
local function decode_dxt(s, at, w, h, kind, out)
    local p = ffi.cast("const uint8_t *", s) + at
    local block = (kind == 0) and 8 or 16
    local cr, cg, cb, ca = {}, {}, {}, {}
    local alpha = {}
    for by = 0, math.max(1, h / 4) - 1 do
        for bx = 0, math.max(1, w / 4) - 1 do
            local q = p + (by * math.max(1, w / 4) + bx) * block
            local cq = q + ((kind == 0) and 0 or 8)               -- the colour half

            -- alpha, sixteen values (DXT3 and DXT5)
            if kind == 1 then
                for i = 0, 15 do
                    local byte = q[bit.rshift(i, 1)]
                    local nib  = (i % 2 == 0) and bit.band(byte, 15) or bit.rshift(byte, 4)
                    alpha[i] = nib * 17
                end
            elseif kind == 7 then
                local a0, a1 = q[0], q[1]
                local pal = { [0] = a0, a1 }
                if a0 > a1 then
                    for i = 1, 6 do pal[i + 1] = math.floor(((7 - i) * a0 + i * a1) / 7) end
                else
                    for i = 1, 4 do pal[i + 1] = math.floor(((5 - i) * a0 + i * a1) / 5) end
                    pal[6], pal[7] = 0, 255
                end
                -- 48 bits of 3-bit indices, little-endian, in two 24-bit halves
                for half = 0, 1 do
                    local v = q[2 + half * 3] + q[3 + half * 3] * 256 + q[4 + half * 3] * 65536
                    for i = 0, 7 do alpha[half * 8 + i] = pal[bit.band(bit.rshift(v, 3 * i), 7)] end
                end
            end

            -- colour: two endpoints and two (or one) between
            local c0 = cq[0] + cq[1] * 256
            local c1 = cq[2] + cq[3] * 256
            cr[0], cg[0], cb[0] = rgb565(c0)
            cr[1], cg[1], cb[1] = rgb565(c1)
            ca[0], ca[1], ca[2], ca[3] = 255, 255, 255, 255
            if c0 > c1 or kind ~= 0 then
                cr[2], cg[2], cb[2] = math.floor((2 * cr[0] + cr[1]) / 3), math.floor((2 * cg[0] + cg[1]) / 3), math.floor((2 * cb[0] + cb[1]) / 3)
                cr[3], cg[3], cb[3] = math.floor((cr[0] + 2 * cr[1]) / 3), math.floor((cg[0] + 2 * cg[1]) / 3), math.floor((cb[0] + 2 * cb[1]) / 3)
            else
                cr[2], cg[2], cb[2] = math.floor((cr[0] + cr[1]) / 2), math.floor((cg[0] + cg[1]) / 2), math.floor((cb[0] + cb[1]) / 2)
                cr[3], cg[3], cb[3], ca[3] = 0, 0, 0, 0               -- DXT1's see-through colour
            end
            local idx = cq[4] + cq[5] * 256 + cq[6] * 65536 + cq[7] * 16777216
            for py = 0, 3 do
                for px = 0, 3 do
                    local x, y = bx * 4 + px, by * 4 + py
                    if x < w and y < h then
                        local i = py * 4 + px
                        local k = bit.band(bit.rshift(idx, 2 * i), 3)
                        local o = (y * w + x) * 4
                        out[o], out[o + 1], out[o + 2] = cr[k], cg[k], cb[k]
                        out[o + 3] = (kind == 0) and ca[k] or alpha[i]
                    end
                end
            end
        end
    end
end
-- }}}

-- {{{ function Blp.decode
-- The full-size picture of BLP2 data `s` (string): { width, height
-- (integers), rgba (string of width*height*4 bytes, rows top to bottom) }.
-- Errors on anything that isn't a BLP2 file or uses an encoding not known.
function Blp.decode(s, name)
    name = name or "texture"
    if s:sub(1, 4) ~= "BLP2" then error(name .. " is not a BLP2 texture") end
    local enc, abits, akind = s:byte(9), s:byte(10), s:byte(11)
    local w, h = u32(s, 12), u32(s, 16)
    local at, len = u32(s, 20), u32(s, 84)
    local out = ffi.new("uint8_t[?]", w * h * 4)

    if enc == 2 then
        decode_dxt(s, at, w, h, akind, out)
    elseif enc == 1 then
        -- palette: one byte a pixel, then the alpha bits packed after
        local pal = 148
        for i = 0, w * h - 1 do
            local c = s:byte(at + i + 1)
            local o = i * 4
            out[o], out[o + 1], out[o + 2] = s:byte(pal + c * 4 + 3), s:byte(pal + c * 4 + 2), s:byte(pal + c * 4 + 1)
            local a = 255
            if abits == 8 then
                a = s:byte(at + w * h + i + 1)
            elseif abits == 4 then
                local byte = s:byte(at + w * h + math.floor(i / 2) + 1)
                a = ((i % 2 == 0) and bit.band(byte, 15) or bit.rshift(byte, 4)) * 17
            elseif abits == 1 then
                local byte = s:byte(at + w * h + math.floor(i / 8) + 1)
                a = (bit.band(bit.rshift(byte, i % 8), 1) == 1) and 255 or 0
            end
            out[o + 3] = a
        end
    elseif enc == 3 then
        for i = 0, w * h - 1 do
            local o = i * 4
            out[o], out[o + 1], out[o + 2], out[o + 3] = s:byte(at + o + 3), s:byte(at + o + 2), s:byte(at + o + 1), s:byte(at + o + 4)
        end
    else
        error(string.format("%s: encoding %d is not known", name, enc))
    end
    return { width = w, height = h, rgba = ffi.string(out, w * h * 4), bytes = len }
end
-- }}}

return Blp
