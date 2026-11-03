-- journal-seal.lua - locks a player's journal so only their password opens it
-- (issue 1008a). Loaded with dofile() from LuaJIT; talks to libsodium through
-- the FFI, the same library the world server and the browser opener use, so
-- a journal locked by one opens in the others.
--
-- For a general audience: a password is turned into a pair of keys. The server keeps only the public half, which can lock but
-- not unlock. Each journal file gets its own random key for its lines; that
-- key is locked with the public half and stored at the top of the file. Only
-- someone who knows the password can remake the private half, unlock the
-- file's key, and read the lines. Any changed, reordered or missing line is
-- refused; a file that was cut short (a server crash) is read up to where it
-- stops and reported as cut short.
--
-- What protects a journal is the password alone. The Argon2id step that
-- turns it into keys is not counted as protection (the owner, 2026-10-26:
-- "they can always just apply more compute"); it is libsodium's way of
-- making a fixed-size seed from a password, run at the light "interactive"
-- settings to spare the server's memory. The settings are stored in each
-- file, so changing them later never breaks an old journal.
--
-- The file format, all numbers little-endian (the same table is in
-- issues/1008a-a-lock-made-from-the-password.md; change both together):
--
--   offset  size  field
--        0     8  magic "GSJRNL01"
--        8     4  account id            (uint32)
--       12    16  salt for the stretch
--       28     4  ops limit             (uint32, Argon2id passes)
--       32     8  mem limit             (uint64, bytes)
--       40    80  sealed file key       (crypto_box_seal of 32 bytes)
--      120    24  secretstream header
--      144     -  records: 4-byte length (uint32), then that many bytes
--
-- Bytes 0..119 are the "additional data" of every record, so a header edited
-- to point at another account or salt makes every record refuse to open.
-- Each record's plain text is  <unix time>\t<kind>\t<sender>\t<text>.
-- The last record of a properly closed file is empty and carries the stream's
-- "final" tag; its absence is how a cut-short file is told apart.

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

-- libsodium.so.26 is the soname on this machine (Void Linux); "sodium" lets
-- the loader find it by its plain name elsewhere. No third try: a missing
-- library is an error the reader should see, not something to paper over.
local ok_load, sodium = pcall(ffi.load, "sodium")
if not ok_load then
    ok_load, sodium = pcall(ffi.load, "libsodium.so.26")
end
if not ok_load then
    error("journal-seal: libsodium was not found (tried 'sodium' and 'libsodium.so.26'): " .. tostring(sodium))
end
if sodium.sodium_init() < 0 then error("journal-seal: libsodium failed to start (sodium_init < 0)") end

-- The header packs integers by copying their memory; that matches the
-- little-endian format only on a little-endian machine.
assert(ffi.abi("le"), "journal-seal: this machine is big-endian; the packing below assumes little-endian")

local MAGIC        = "GSJRNL01"
local SALT_BYTES   = 16
local KEY_BYTES    = 32     -- box public/secret keys, seed, stream key
local SEAL_BYTES   = 48     -- crypto_box_SEALBYTES
local STREAM_HDR   = 24     -- crypto_secretstream_xchacha20poly1305_HEADERBYTES
local STREAM_ABYTES= 17     -- crypto_secretstream_xchacha20poly1305_ABYTES
local TAG_MESSAGE  = 0
local TAG_FINAL    = 3
local AD_BYTES     = 8 + 4 + SALT_BYTES + 4 + 8 + KEY_BYTES + SEAL_BYTES   -- 120
local HEADER_BYTES = AD_BYTES + STREAM_HDR                                 -- 144
local MAX_RECORD   = 1048576  -- a line longer than 1 MiB is a corrupt length, not a line

local Seal = {
    MAGIC        = MAGIC,
    HEADER_BYTES = HEADER_BYTES,
    OPS_INTERACTIVE = tonumber(sodium.crypto_pwhash_opslimit_interactive()),
    MEM_INTERACTIVE = tonumber(sodium.crypto_pwhash_memlimit_interactive()),
}

-- {{{ local function u32 / u64 / read_u32 / read_u64
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
-- }}}

-- {{{ local function game_uppercase
-- The game uppercases passwords before using them (Utf8ToUpperOnlyLatin in
-- source-beta/src/common/Utilities/Util.cpp), which is why WoW passwords
-- ignore case. The key must be made from the same text, byte for byte.
-- What the game does, read from its source: it decodes the UTF-8, uppercases
-- only a-z (wcharToUpperOnlyLatin applies the upper-casing only when
-- isBasicLatinCharacter, which is a-z and A-Z), leaves every other
-- character exactly as typed (accented letters included), and encodes it
-- back. Text that is not valid UTF-8 makes the game's function fail, so the
-- game makes no account from it; this refuses it the same way. (The owner,
-- 2026-10-28, on accented letters: "it's just bits at the end of the day.")
-- a-z is matched by its byte range, not by the locale's idea of a letter.
local function valid_utf8(s)
    local i, n = 1, #s
    while i <= n do
        local c = s:byte(i)
        local need, lo, hi = 0, 0x80, 0xBF
        if c < 0x80 then need = 0
        elseif c >= 0xC2 and c <= 0xDF then need = 1
        elseif c == 0xE0 then need, lo = 2, 0xA0
        elseif (c >= 0xE1 and c <= 0xEC) or c == 0xEE or c == 0xEF then need = 2
        elseif c == 0xED then need, hi = 2, 0x9F           -- no UTF-16 surrogates
        elseif c == 0xF0 then need, lo = 3, 0x90
        elseif c >= 0xF1 and c <= 0xF3 then need = 3
        elseif c == 0xF4 then need, hi = 3, 0x8F           -- nothing past U+10FFFF
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
-- }}}

-- {{{ function Seal.make_key
-- Stretches a password into the account's key pair.
-- password: string, as typed. salt: 16-byte string, or nil for a new random
-- one. ops, mem: Argon2id limits (numbers), nil for libsodium's "interactive" (2 passes, 64 MiB).
-- Returns a table: salt (string 16), ops (number), mem (number),
-- public_key (string 32), secret_key (string 32).
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
-- }}}

-- {{{ function Seal.record / Seal.parse_record
-- One line of a journal as plain text, and back. Tabs and newlines inside a
-- field are replaced by spaces, so the four fields always split cleanly.
function Seal.record(time, kind, sender, text)
    local function clean(s) return (tostring(s):gsub("[\t\r\n]", " ")) end
    return string.format("%d\t%s\t%s\t%s", time, clean(kind), clean(sender), clean(text))
end
function Seal.parse_record(s)
    local time, kind, sender, text = s:match("^(%d+)\t([^\t]*)\t([^\t]*)\t(.*)$")
    if not time then error("journal-seal: a record that does not have four fields: " .. s) end
    return { time = tonumber(time), kind = kind, sender = sender, text = text }
end
-- }}}

-- {{{ function Seal.writer
-- Opens a new journal file for one account, locked to its public key.
-- path: string. account_id: number. key: a table with salt, ops, mem,
-- public_key (what acore_auth.account_journal_key holds; no secret needed).
-- Returns a writer with :line(record_string) and :close().
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
-- }}}

-- {{{ function Seal.open
-- Reads a journal file with one or more passwords (old journals are locked
-- to old passwords: issue 1008 question 2).
-- path: string. passwords: a string or a list of strings.
-- Returns a table: account_id (number), lines (list of record strings),
-- finished (boolean: false when the file was cut short).
-- Errors, saying which, when: the file is not a journal; no password fits;
-- a record was changed, reordered or removed.
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

    -- Try each password: the one whose key unlocks the sealed file key fits.
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
        if at + 3 > #data then break end   -- a length cut in half: cut short
        local n = read_u32(data, at)
        if n < STREAM_ABYTES or n > MAX_RECORD then
            error(string.format("journal-seal: %s record %d has an impossible length %d: the file was changed", path, #lines + 1, n))
        end
        if at + 4 + n - 1 > #data then break end  -- a record cut in half: cut short
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
-- }}}

-- {{{ function Seal.fingerprint
-- BLAKE2b (32 bytes, as hex) of a whole file: lets anyone check a locked
-- journal was not changed, without being able to read it (issue 1008b).
function Seal.fingerprint(path)
    local f = assert(io.open(path, "rb"))
    local data = f:read("*a")
    f:close()
    local out = ffi.new("unsigned char[32]")
    sodium.crypto_generichash(out, 32, data, #data, nil, 0)
    return (ffi.string(out, 32):gsub(".", function(c) return string.format("%02x", c:byte()) end))
end
-- }}}

return Seal
