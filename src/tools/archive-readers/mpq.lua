
local ffi = require("ffi")
local bit = require("bit")

ffi.cdef[[
int uncompress(uint8_t *dest, unsigned long *destLen, const uint8_t *source, unsigned long sourceLen);
]]
local zlib = ffi.load("z")

local Mpq = {}

local FILE_IMPLODE     = 0x00000100
local FILE_COMPRESS    = 0x00000200
local FILE_ENCRYPTED   = 0x00010000
local FILE_FIX_KEY     = 0x00020000
local FILE_SINGLE_UNIT = 0x01000000
local FILE_EXISTS      = 0x80000000
local HASH_EMPTY       = 0xFFFFFFFF

local CRYPT = ffi.new("uint32_t[1280]")
do
    local seed = 0x00100001
    for i1 = 0, 255 do
        local i2 = i1
        for _ = 0, 4 do
            seed = (seed * 125 + 3) % 0x2AAAAB
            local hi = seed % 0x10000
            seed = (seed * 125 + 3) % 0x2AAAAB
            local lo = seed % 0x10000
            CRYPT[i2] = hi * 0x10000 + lo
            i2 = i2 + 256
        end
    end
end

function Mpq.hash(text, kind)
    local seed1, seed2 = ffi.new("uint32_t", 0x7FED7FED), ffi.new("uint32_t", 0xEEEEEEEE)
    for i = 1, #text do
        local ch = text:byte(i)
        if ch >= 97 and ch <= 122 then ch = ch - 32 end
        if ch == 47 then ch = 92 end
        seed1 = ffi.cast("uint32_t", bit.bxor(CRYPT[kind * 256 + ch], tonumber(ffi.cast("uint32_t", seed1 + seed2))))
        seed2 = ffi.cast("uint32_t", ch + seed1 + seed2 + bit.lshift(tonumber(seed2), 5) + 3)
    end
    return tonumber(seed1)
end

local function decrypt(words, count, key)
    local seed = ffi.new("uint32_t", 0xEEEEEEEE)
    key = ffi.new("uint32_t", key)
    for i = 0, count - 1 do
        seed = ffi.cast("uint32_t", seed + CRYPT[0x400 + tonumber(key) % 256])
        local ch = ffi.cast("uint32_t", bit.bxor(words[i], tonumber(ffi.cast("uint32_t", key + seed))))
        key  = ffi.cast("uint32_t", bit.bor(bit.lshift(bit.bnot(tonumber(key)), 0x15) + 0x11111111, bit.rshift(tonumber(key), 0x0B)))
        seed = ffi.cast("uint32_t", ch + seed + bit.lshift(tonumber(seed), 5) + 3)
        words[i] = ch
    end
end
Mpq.decrypt = decrypt

local function u32(s, at)
    local a, b, c, d = s:byte(at + 1, at + 4)
    return a + b * 256 + c * 65536 + d * 16777216
end

function Mpq.open(path)
    local f = assert(io.open(path, "rb"))
    local base, head
    for at = 0, 64 * 1024 * 1024, 512 do
        f:seek("set", at)
        head = f:read(44)
        if not head or #head < 32 then break end
        if head:sub(1, 4) == "MPQ\26" then base = at; break end
    end
    if not base then f:close(); error(path .. " is not an MPQ archive (no MPQ mark)") end

    local a = { path = path, file = f, base = base }
    a.sector = 512 * 2 ^ (head:byte(15) + head:byte(16) * 256)
    local hash_at, block_at = u32(head, 16), u32(head, 20)
    a.nhash, a.nblock       = u32(head, 24), u32(head, 28)
    local version = head:byte(13) + head:byte(14) * 256
    if version >= 1 and #head >= 44 then
        hash_at  = hash_at  + (head:byte(41) + head:byte(42) * 256) * 2 ^ 32
        block_at = block_at + (head:byte(43) + head:byte(44) * 256) * 2 ^ 32
    end

    local function table_of(at, n, name)
        f:seek("set", base + at)
        local raw = f:read(n * 16)
        local words = ffi.new("uint32_t[?]", n * 4)
        ffi.copy(words, raw, n * 16)
        decrypt(words, n * 4, Mpq.hash(name, 3))
        return words
    end
    a.hashes = table_of(hash_at,  a.nhash,  "(hash table)")
    a.blocks = table_of(block_at, a.nblock, "(block table)")
    return a
end

local function find_block(a, name)
    local slot = Mpq.hash(name, 0) % a.nhash
    local na, nb = Mpq.hash(name, 1), Mpq.hash(name, 2)
    for _ = 1, a.nhash do
        local h = a.hashes + slot * 4
        if h[3] == HASH_EMPTY then return nil end
        if h[0] == na and h[1] == nb and h[3] < a.nblock then return tonumber(h[3]) end
        slot = (slot + 1) % a.nhash
    end
    return nil
end

local function inflate(raw, size, name)
    local how = raw:byte(1)
    if how ~= 0x02 then
        error(string.format("%s: compression 0x%02x is not read by this reader (zlib only)", name, how))
    end
    local out = ffi.new("uint8_t[?]", size)
    local len = ffi.new("unsigned long[1]", size)
    local rc = zlib.uncompress(out, len, ffi.cast("const uint8_t *", raw) + 1, #raw - 1)
    if rc ~= 0 then error(string.format("%s: zlib failed (%d)", name, rc)) end
    return ffi.string(out, len[0])
end

local function unscramble(raw, key)
    local n = math.floor(#raw / 4)
    local words = ffi.new("uint32_t[?]", n + 1)
    ffi.copy(words, raw, #raw)
    decrypt(words, n, key)
    return ffi.string(words, n * 4) .. raw:sub(n * 4 + 1)
end

function Mpq.read(a, name)
    local bi = find_block(a, name)
    if not bi then return nil end
    local b = a.blocks + bi * 4
    local pos, csize, size, flags = tonumber(b[0]), tonumber(b[1]), tonumber(b[2]), tonumber(b[3])
    if bit.band(flags, FILE_EXISTS) == 0 then return nil end
    if bit.band(flags, FILE_IMPLODE) ~= 0 then error(name .. ": PKWARE implode is not read by this reader") end

    local key
    if bit.band(flags, FILE_ENCRYPTED) ~= 0 then
        key = Mpq.hash(name:match("[^\\/]+$"), 3)
        if bit.band(flags, FILE_FIX_KEY) ~= 0 then
            key = tonumber(ffi.cast("uint32_t", bit.bxor(tonumber(ffi.cast("uint32_t", key + pos)), size)))
        end
    end
    a.file:seek("set", a.base + pos)
    local compressed = bit.band(flags, FILE_COMPRESS) ~= 0

    if bit.band(flags, FILE_SINGLE_UNIT) ~= 0 then
        local raw = a.file:read(csize)
        if key then raw = unscramble(raw, key) end
        return (compressed and csize < size) and inflate(raw, size, name) or raw
    end
    if not compressed then
        local raw = a.file:read(size)
        if not key then return raw end
        local parts = {}
        for i = 0, math.ceil(size / a.sector) - 1 do
            parts[#parts + 1] = unscramble(raw:sub(i * a.sector + 1, (i + 1) * a.sector), key + i)
        end
        return table.concat(parts)
    end

    local n = math.ceil(size / a.sector)
    local offsets = ffi.new("uint32_t[?]", n + 1)
    ffi.copy(offsets, a.file:read((n + 1) * 4), (n + 1) * 4)
    if key then decrypt(offsets, n + 1, key - 1) end
    local parts = {}
    for i = 0, n - 1 do
        local from, to = tonumber(offsets[i]), tonumber(offsets[i + 1])
        a.file:seek("set", a.base + pos + from)
        local raw = a.file:read(to - from)
        if key then raw = unscramble(raw, key + i) end
        local want = math.min(a.sector, size - i * a.sector)
        parts[#parts + 1] = (#raw < want) and inflate(raw, want, name) or raw
    end
    return table.concat(parts)
end

local ORDER = {
    "%s/patch-3.MPQ", "%s/patch-2.MPQ", "%s/patch.MPQ",
    "%s/%s/patch-%s-3.MPQ", "%s/%s/patch-%s-2.MPQ", "%s/%s/patch-%s.MPQ",
    "%s/lichking.MPQ", "%s/expansion.MPQ", "%s/common-2.MPQ", "%s/common.MPQ",
    "%s/%s/lichking-locale-%s.MPQ", "%s/%s/expansion-locale-%s.MPQ", "%s/%s/locale-%s.MPQ",
}
function Mpq.chain(data, locale)
    local c = { archives = {} }
    for _, pattern in ipairs(ORDER) do
        local path = pattern:format(data, locale, locale)
        local f = io.open(path, "rb")
        if f then f:close(); c.archives[#c.archives + 1] = Mpq.open(path) end
    end
    if #c.archives == 0 then error("no MPQ archives found in " .. data) end
    function c:read(name)
        for _, a in ipairs(self.archives) do
            local s = Mpq.read(a, name)
            if s then return s, a.path end
        end
        return nil
    end
    return c
end

return Mpq
