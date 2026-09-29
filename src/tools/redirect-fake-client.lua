#!/usr/bin/env luajit
-- redirect-fake-client.lua
-- A stand-in for the real game client, used to test the redirect listener
-- without starting the game. It dials the listener, reads the greeting,
-- and answers the way Wow.exe 12340 answers a greeting that arrives on a
-- redirected connection (read from its code at 0x632730..0x632914): account
-- name, anti-flood answer, and a digest of name + session key + seed. Then
-- it switches on header scrambling, expects a scrambled "login accepted"
-- back, and sends one scrambled ping, so both scrambling directions are
-- exercised. Exits 0 when every step matched, non-zero with the step that
-- didn't.
--
-- Usage: luajit src/tools/redirect-fake-client.lua <port> <80-hex-digit key>

local LIBS = "/home/ritz/programming/ai-stuff/libs/lua/luasocket"
package.path  = LIBS .. "/share/lua/5.1/?.lua;" .. package.path
package.cpath = LIBS .. "/lib/lua/5.1/?.so;"    .. package.cpath
local socket = require("socket")
local ffi    = require("ffi")
local bit    = require("bit")

ffi.cdef[[
typedef struct evp_md_st EVP_MD;
const EVP_MD *EVP_sha1(void);
unsigned char *HMAC(const EVP_MD *evp_md, const void *key, int key_len,
                    const unsigned char *d, size_t n,
                    unsigned char *md, unsigned int *md_len);
unsigned char *SHA1(const unsigned char *d, size_t n, unsigned char *md);
]]
local crypto = ffi.load("libcrypto.so.3")

local port        = assert(tonumber(arg[1]), "first argument: listener port")
local session_key = assert(arg[2], "second argument: session key hex"):gsub("..", function(p) return string.char(tonumber(p, 16)) end)
local ACCOUNT     = "FAKECLIENT"

-- same seeds as AuthCrypt.cpp; the client uses them the other way round
-- from the server: it scrambles its sends with the client-to-server seed
local SEED_CLIENT_TO_SERVER = string.char(0xC2, 0xB3, 0x72, 0x3C, 0xC6, 0xAE, 0xD9, 0xB5, 0x34, 0x3C, 0x53, 0xEE, 0x2F, 0x43, 0x67, 0xCE)
local SEED_SERVER_TO_CLIENT = string.char(0xCC, 0x98, 0xAE, 0x04, 0xE8, 0x97, 0xEA, 0xCA, 0x12, 0xDD, 0xC0, 0x93, 0x42, 0x91, 0x53, 0x57)

-- {{{ local function fail
local function fail(step, detail)
    io.stderr:write("redirect-fake-client: FAILED at " .. step .. ": " .. detail .. "\n")
    os.exit(1)
end
-- }}}

-- {{{ local function digest_of
local function hmac_sha1(key, message)
    local out = ffi.new("unsigned char[20]")
    crypto.HMAC(crypto.EVP_sha1(), key, #key, message, #message, out, nil)
    return ffi.string(out, 20)
end
local function sha1(message)
    local out = ffi.new("unsigned char[20]")
    crypto.SHA1(message, #message, out)
    return ffi.string(out, 20)
end
-- }}}

-- {{{ local function new_arc4
-- written independently of the listener's copy on purpose: if both carried
-- the same mistake, a shared copy would hide it
local function new_arc4(key)
    local s = {}
    for i = 0, 255 do s[i] = i end
    local j = 0
    for i = 0, 255 do
        j = (j + s[i] + key:byte((i % #key) + 1)) % 256
        s[i], s[j] = s[j], s[i]
    end
    local x, y = 0, 0
    local function step(bytes)
        local out = {}
        for n = 1, #bytes do
            x = (x + 1) % 256
            y = (y + s[x]) % 256
            s[x], s[y] = s[y], s[x]
            out[n] = string.char(bit.bxor(bytes:byte(n), s[(s[x] + s[y]) % 256]))
        end
        return table.concat(out)
    end
    step(string.rep("\0", 1024))
    return step
end
-- }}}

local conn = socket.connect("127.0.0.1", port)
if not conn then fail("connect", "nothing listening on 127.0.0.1:" .. port) end
conn:settimeout(5)

-- greeting: 4-byte plaintext header, then uint32 1, uint32 seed, 32 bytes
local header = conn:receive(4)
if not header then fail("greeting header", "listener sent nothing") end
local opcode = header:byte(3) + header:byte(4) * 256
if opcode ~= 0x1EC then fail("greeting header", string.format("opcode 0x%03X, expected 0x1EC", opcode)) end
local body = conn:receive(40)
if not body then fail("greeting body", "fewer than 40 bytes") end
local seed = body:sub(5, 8)

-- proof: account\0, uint64 anti-flood answer (content unchecked by
-- the listener), 20-byte digest
local digest = sha1(ACCOUNT .. session_key .. seed)
local proof  = ACCOUNT .. "\0" .. string.rep("\0", 8) .. digest
local size   = #proof + 4
conn:send(string.char(math.floor(size / 256), size % 256, 0x12, 0x05, 0, 0) .. proof)

local send_scramble = new_arc4(hmac_sha1(SEED_CLIENT_TO_SERVER, session_key))
local recv_scramble = new_arc4(hmac_sha1(SEED_SERVER_TO_CLIENT, session_key))

-- scrambled "login accepted": 4-byte header, 11-byte body starting 0x0C
local reply_header = conn:receive(4)
if not reply_header then fail("auth response", "no reply after the proof (listener run without --answer auth-ok?)") end
reply_header = recv_scramble(reply_header)
local reply_opcode = reply_header:byte(3) + reply_header:byte(4) * 256
if reply_opcode ~= 0x1EE then fail("auth response", string.format("unscrambled opcode 0x%03X, expected 0x1EE", reply_opcode)) end
local reply_body = conn:receive(reply_header:byte(1) * 256 + reply_header:byte(2) - 2)
if not reply_body or reply_body:byte(1) ~= 0x0C then fail("auth response", "body does not start with AUTH_OK (0x0C)") end

-- scrambled CMSG_PING (0x1DC): uint32 serial, uint32 latency
local ping = string.char(0x2A, 0, 0, 0) .. string.char(0, 0, 0, 0)
local psize = #ping + 4
conn:send(send_scramble(string.char(0, psize, 0xDC, 0x01, 0, 0)) .. ping)
socket.sleep(0.3)
conn:close()
print("redirect-fake-client: greeting read, proof sent, scrambled AUTH_OK received, scrambled ping sent")
