
local ffi = require("ffi")

ffi.cdef[[
int    sodium_init(void);
void   sodium_memzero(void *pnt, size_t len);
void   randombytes_buf(void *buf, size_t size);
size_t crypto_pwhash_opslimit_interactive(void);
size_t crypto_pwhash_memlimit_interactive(void);
int    crypto_pwhash_alg_argon2id13(void);
int    crypto_pwhash(unsigned char *out, unsigned long long outlen,
                     const char *passwd, unsigned long long passwdlen,
                     const unsigned char *salt,
                     unsigned long long opslimit, size_t memlimit, int alg);
int    crypto_box_seed_keypair(unsigned char *pk, unsigned char *sk, const unsigned char *seed);
int    crypto_box_seal(unsigned char *c, const unsigned char *m,
                       unsigned long long mlen, const unsigned char *pk);
int    crypto_box_seal_open(unsigned char *m, const unsigned char *c,
                            unsigned long long clen,
                            const unsigned char *pk, const unsigned char *sk);
size_t crypto_secretstream_xchacha20poly1305_statebytes(void);
void   crypto_secretstream_xchacha20poly1305_keygen(unsigned char *k);
int    crypto_secretstream_xchacha20poly1305_init_push(void *state, unsigned char *header, const unsigned char *k);
int    crypto_secretstream_xchacha20poly1305_push(void *state,
           unsigned char *c, unsigned long long *clen_p,
           const unsigned char *m, unsigned long long mlen,
           const unsigned char *ad, unsigned long long adlen, unsigned char tag);
int    crypto_secretstream_xchacha20poly1305_init_pull(void *state, const unsigned char *header, const unsigned char *k);
int    crypto_secretstream_xchacha20poly1305_pull(void *state,
           unsigned char *m, unsigned long long *mlen_p, unsigned char *tag_p,
           const unsigned char *c, unsigned long long clen,
           const unsigned char *ad, unsigned long long adlen);
int    crypto_generichash(unsigned char *out, size_t outlen,
                          const unsigned char *in, unsigned long long inlen,
                          const unsigned char *key, size_t keylen);
]]

local ok_load, sodium = pcall(ffi.load, "sodium")
if not ok_load then
    ok_load, sodium = pcall(ffi.load, "libsodium.so.26")
end
if not ok_load then
    error("journal-seal: libsodium was not found (tried 'sodium' and 'libsodium.so.26'): " .. tostring(sodium))
end
if sodium.sodium_init() < 0 then error("journal-seal: libsodium failed to start (sodium_init < 0)") end

assert(ffi.abi("le"), "journal-seal: this machine is big-endian; the packing below assumes little-endian")

local MAGIC        = "GSJRNL01"
local SALT_BYTES   = 16
local KEY_BYTES    = 32
local SEAL_BYTES   = 48
local STREAM_HDR   = 24
local STREAM_ABYTES= 17
local TAG_MESSAGE  = 0
local TAG_FINAL    = 3
local AD_BYTES     = 8 + 4 + SALT_BYTES + 4 + 8 + KEY_BYTES + SEAL_BYTES
local HEADER_BYTES = AD_BYTES + STREAM_HDR
local MAX_RECORD   = 1048576

local Seal = {
    MAGIC        = MAGIC,
    HEADER_BYTES = HEADER_BYTES,
    OPS_INTERACTIVE = tonumber(sodium.crypto_pwhash_opslimit_interactive()),
    MEM_INTERACTIVE = tonumber(sodium.crypto_pwhash_memlimit_interactive()),
}

local function u32(n)
    local b = ffi.new("uint32_t[1]", n)
    return ffi.string(b, 4)
end
local function u64(n)
    local b = ffi.new("uint64_t[1]", n)
    return ffi.string(b, 8)
end
local function read_u32(s, at)
    local b = ffi.new("uint32_t[1]")
    ffi.copy(b, s:sub(at, at + 3), 4)
    return tonumber(b[0])
end
local function read_u64(s, at)
    local b = ffi.new("uint64_t[1]")
    ffi.copy(b, s:sub(at, at + 7), 8)
    return tonumber(b[0])
end

local function valid_utf8(s)
    local i, n = 1, #s
    while i <= n do
        local c = s:byte(i)
        local need, lo, hi = 0, 0x80, 0xBF
        if c < 0x80 then need = 0
        elseif c >= 0xC2 and c <= 0xDF then need = 1
        elseif c == 0xE0 then need, lo = 2, 0xA0
        elseif (c >= 0xE1 and c <= 0xEC) or c == 0xEE or c == 0xEF then need = 2
        elseif c == 0xED then need, hi = 2, 0x9F
        elseif c == 0xF0 then need, lo = 3, 0x90
        elseif c >= 0xF1 and c <= 0xF3 then need = 3
        elseif c == 0xF4 then need, hi = 3, 0x8F
        else return false end
        for k = 1, need do
            local b = s:byte(i + k)
            if not b then return false end
            if k == 1 then if b < lo or b > hi then return false end
            elseif b < 0x80 or b > 0xBF then return false end
        end
        i = i + need + 1
    end
    return true
end
local function game_uppercase(password)
    if not valid_utf8(password) then
        error("journal-seal: the password is not valid UTF-8; the game makes no account from such a password "
           .. "(its uppercasing fails), so no key is made from it either")
    end
    return (password:gsub("[a-z]", function(c) return string.char(c:byte() - 32) end))
end
Seal.game_uppercase = game_uppercase

function Seal.make_key(password, salt, ops, mem)
    ops = ops or Seal.OPS_INTERACTIVE
    mem = mem or Seal.MEM_INTERACTIVE
    if salt == nil then
        local b = ffi.new("unsigned char[?]", SALT_BYTES)
        sodium.randombytes_buf(b, SALT_BYTES)
        salt = ffi.string(b, SALT_BYTES)
    end
    assert(#salt == SALT_BYTES, "journal-seal: a salt is 16 bytes, this one is " .. #salt)

    local upper = game_uppercase(password)
    local seed  = ffi.new("unsigned char[?]", KEY_BYTES)
    if sodium.crypto_pwhash(seed, KEY_BYTES, upper, #upper, salt, ops, mem,
                            sodium.crypto_pwhash_alg_argon2id13()) ~= 0 then
        error(string.format("journal-seal: stretching the password failed (ops %d, mem %d bytes): usually out of memory", ops, mem))
    end
    local pk = ffi.new("unsigned char[?]", KEY_BYTES)
    local sk = ffi.new("unsigned char[?]", KEY_BYTES)
    sodium.crypto_box_seed_keypair(pk, sk, seed)
    local key = { salt = salt, ops = ops, mem = mem,
                  public_key = ffi.string(pk, KEY_BYTES), secret_key = ffi.string(sk, KEY_BYTES) }
    sodium.sodium_memzero(seed, KEY_BYTES)
    sodium.sodium_memzero(sk, KEY_BYTES)
    return key
end

function Seal.record(time, kind, sender, text)
    local function clean(s) return (tostring(s):gsub("[\t\r\n]", " ")) end
    return string.format("%d\t%s\t%s\t%s", time, clean(kind), clean(sender), clean(text))
end
function Seal.parse_record(s)
    local time, kind, sender, text = s:match("^(%d+)\t([^\t]*)\t([^\t]*)\t(.*)$")
    if not time then error("journal-seal: a record that does not have four fields: " .. s) end
    return { time = tonumber(time), kind = kind, sender = sender, text = text }
end

function Seal.writer(path, account_id, key)
    local file_key = ffi.new("unsigned char[?]", KEY_BYTES)
    sodium.crypto_secretstream_xchacha20poly1305_keygen(file_key)

    local sealed = ffi.new("unsigned char[?]", KEY_BYTES + SEAL_BYTES)
    sodium.crypto_box_seal(sealed, file_key, KEY_BYTES, key.public_key)

    local ad = MAGIC .. u32(account_id) .. key.salt .. u32(key.ops) .. u64(key.mem)
            .. ffi.string(sealed, KEY_BYTES + SEAL_BYTES)
    assert(#ad == AD_BYTES)

    local state  = ffi.new("unsigned char[?]", sodium.crypto_secretstream_xchacha20poly1305_statebytes())
    local header = ffi.new("unsigned char[?]", STREAM_HDR)
    sodium.crypto_secretstream_xchacha20poly1305_init_push(state, header, file_key)
    sodium.sodium_memzero(file_key, KEY_BYTES)

    local f = assert(io.open(path, "wb"))
    f:write(ad, ffi.string(header, STREAM_HDR))

    local w = {}
    local clen = ffi.new("unsigned long long[1]")
    local function push(m, tag)
        local c = ffi.new("unsigned char[?]", #m + STREAM_ABYTES)
        sodium.crypto_secretstream_xchacha20poly1305_push(state, c, clen, m, #m, ad, #ad, tag)
        local n = tonumber(clen[0])
        f:write(u32(n), ffi.string(c, n))
    end
    function w:line(m) push(m, TAG_MESSAGE) end
    function w:close()
        push("", TAG_FINAL)
        f:close()
        sodium.sodium_memzero(state, ffi.sizeof(state))
    end
    return w
end

function Seal.open(path, passwords)
    if type(passwords) == "string" then passwords = { passwords } end
    local f = io.open(path, "rb")
    if not f then error("journal-seal: cannot read " .. path) end
    local data = f:read("*a")
    f:close()

    if #data < HEADER_BYTES or data:sub(1, 8) ~= MAGIC then
        error(string.format("journal-seal: %s is not a journal (%d bytes, starts %q, expected %q)",
              path, #data, data:sub(1, 8), MAGIC))
    end
    local ad      = data:sub(1, AD_BYTES)
    local account = read_u32(data, 9)
    local salt    = data:sub(13, 28)
    local ops     = read_u32(data, 29)
    local mem     = read_u64(data, 33)
    local sealed  = data:sub(41, 120)
    local header  = data:sub(121, 144)

    local file_key = ffi.new("unsigned char[?]", KEY_BYTES)
    local fitted = false
    for _, pw in ipairs(passwords) do
        local key = Seal.make_key(pw, salt, ops, mem)
        if sodium.crypto_box_seal_open(file_key, sealed, #sealed, key.public_key, key.secret_key) == 0 then
            fitted = true
            break
        end
    end
    if not fitted then
        error(string.format("journal-seal: none of the %d password(s) given opens %s (account %d)", #passwords, path, account))
    end

    local state = ffi.new("unsigned char[?]", sodium.crypto_secretstream_xchacha20poly1305_statebytes())
    sodium.crypto_secretstream_xchacha20poly1305_init_pull(state, header, file_key)
    sodium.sodium_memzero(file_key, KEY_BYTES)

    local lines, finished, at = {}, false, HEADER_BYTES + 1
    local mlen, tag = ffi.new("unsigned long long[1]"), ffi.new("unsigned char[1]")
    while at <= #data do
        if finished then
            error(string.format("journal-seal: %s has %d bytes after its final line: something was added", path, #data - at + 1))
        end
        if at + 3 > #data then break end
        local n = read_u32(data, at)
        if n < STREAM_ABYTES or n > MAX_RECORD then
            error(string.format("journal-seal: %s record %d has an impossible length %d: the file was changed", path, #lines + 1, n))
        end
        if at + 4 + n - 1 > #data then break end
        local c = data:sub(at + 4, at + 3 + n)
        local m = ffi.new("unsigned char[?]", n)
        if sodium.crypto_secretstream_xchacha20poly1305_pull(state, m, mlen, tag, c, n, ad, #ad) ~= 0 then
            error(string.format("journal-seal: %s record %d does not open: it, the header, or the order of records was changed "
                             .. "(%d records read before it)", path, #lines + 1, #lines))
        end
        if tag[0] == TAG_FINAL then
            finished = true
        else
            lines[#lines + 1] = ffi.string(m, tonumber(mlen[0]))
        end
        at = at + 4 + n
    end
    return { account_id = account, lines = lines, finished = finished }
end

function Seal.fingerprint(path)
    local f = assert(io.open(path, "rb"))
    local data = f:read("*a")
    f:close()
    local out = ffi.new("unsigned char[32]")
    sodium.crypto_generichash(out, 32, data, #data, nil, 0)
    return (ffi.string(out, 32):gsub(".", function(c) return string.format("%02x", c:byte()) end))
end

return Seal
