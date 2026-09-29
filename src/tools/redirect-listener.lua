#!/usr/bin/env luajit
-- redirect-listener.lua
-- The pretend "second server" for issue 913a (client redirect handoff).
-- It listens on a spare port, and when a game client that was redirected
-- here calls in, it greets the client the way a real worldserver does, then
-- writes down everything the client says back: who connected, the
-- account name, the proof the client offers, and every later packet. With
-- the session key supplied it also checks the proof and unscrambles the
-- packet headers that follow, so the log shows what the client is waiting
-- for after a redirect. It never logs anyone in; it only watches.
--
-- Usage:
--   luajit src/tools/redirect-listener.lua [DIR] [--port N] [--key HEX] [--answer auth-ok]
--     DIR       project root (defaults to the hard-coded one below)
--     --port    port to listen on (default 4463, one above the vanilla worldserver)
--     --key     the 80-hex-digit session key the probe prints on the server console
--     --answer  auth-ok: after a valid proof, reply with a scrambled "login accepted"
--               packet (0x1EE) to see whether the client then carries on
-- Log: DIR/tmp/shared-memory/redirect-listener.log (appended), and stdout.

local DIR = "/mnt/mtwo/games/azeroth-core/wow-chat-2026"
local LIBS = "/home/ritz/programming/ai-stuff/libs/lua/luasocket"

-- {{{ argument parsing
local options = { port = 4463, key = nil, answer = nil }
do
    local i = 1
    while arg[i] do
        local word = arg[i]
        if     word == "--port"   then options.port   = tonumber(arg[i + 1]); i = i + 2
        elseif word == "--key"    then options.key    = arg[i + 1];           i = i + 2
        elseif word == "--answer" then options.answer = arg[i + 1];           i = i + 2
        elseif word:sub(1, 2) ~= "--" then DIR = word;                       i = i + 1
        else error("redirect-listener: unknown option " .. word) end
    end
end
if not options.port then error("redirect-listener: --port needs a number") end
if options.key and (not options.key:match("^%x+$") or #options.key ~= 80) then
    error("redirect-listener: --key must be 80 hex digits (the 40-byte session key); got " .. #options.key .. " characters")
end
if options.answer and options.answer ~= "auth-ok" then
    error("redirect-listener: --answer only knows auth-ok; got " .. options.answer)
end
-- }}}

package.path  = LIBS .. "/share/lua/5.1/?.lua;"  .. package.path
package.cpath = LIBS .. "/lib/lua/5.1/?.so;"     .. package.cpath
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

-- values of connecting relevance align vertically
local OPCODE_AUTH_CHALLENGE = 0x1EC   -- server -> client, plaintext
local OPCODE_AUTH_RESPONSE  = 0x1EE   -- server -> client
local OPCODE_REDIRECT_PROOF = 0x512   -- client -> server, plaintext (first packet)
local OPCODE_REDIRECT_FAIL  = 0x50E   -- client -> server
local AUTH_OK               = 0x0C
local CHALLENGE_SEED        = "\239\190\173\222"                 -- 0xDEADBEEF little-endian: easy to spot
local CHALLENGE_BYTES       = string.char(unpack((function() local t = {} for i = 0, 31 do t[#t + 1] = i end return t end)()))
-- from AuthCrypt.cpp: the server decrypts what the client sends with the
-- first seed, and encrypts what it sends with the second
local SEED_CLIENT_TO_SERVER = string.char(0xC2, 0xB3, 0x72, 0x3C, 0xC6, 0xAE, 0xD9, 0xB5, 0x34, 0x3C, 0x53, 0xEE, 0x2F, 0x43, 0x67, 0xCE)
local SEED_SERVER_TO_CLIENT = string.char(0xCC, 0x98, 0xAE, 0x04, 0xE8, 0x97, 0xEA, 0xCA, 0x12, 0xDD, 0xC0, 0x93, 0x42, 0x91, 0x53, 0x57)

-- {{{ log
local log_path = DIR .. "/tmp/shared-memory/redirect-listener.log"
local log_file = io.open(log_path, "a")
if not log_file then
    error("redirect-listener: cannot open " .. log_path .. ". Is " .. DIR .. "/tmp/shared-memory"
       .. " present? It is the RAM scratch link (tmp -> /tmp/<project>, and inside it"
       .. " shared-memory -> /dev/shm/<project>). Nothing was started.")
end
local function log(text)
    local line = os.date("%H:%M:%S ") .. text
    print(line)
    log_file:write(line, "\n")
    log_file:flush()
end
-- }}}

-- {{{ local function hex
local function hex(bytes)
    return (bytes:gsub(".", function(c) return string.format("%02X", c:byte()) end))
end
-- }}}

-- {{{ local function hmac_sha1
local function hmac_sha1(key, message)
    local out = ffi.new("unsigned char[20]")
    crypto.HMAC(crypto.EVP_sha1(), key, #key, message, #message, out, nil)
    return ffi.string(out, 20)
end
-- }}}

-- {{{ local function sha1
local function sha1(message)
    local out = ffi.new("unsigned char[20]")
    crypto.SHA1(message, #message, out)
    return ffi.string(out, 20)
end
-- }}}

-- {{{ local function new_arc4
-- ARC4 with the first 1024 output bytes thrown away, as the 3.3.5 header
-- scrambler does. Returns a function that transforms a string of bytes;
-- the stream state carries over between calls, so every header must pass
-- through it in order, exactly once.
local function new_arc4(key)
    local s = ffi.new("uint8_t[256]")
    for i = 0, 255 do s[i] = i end
    local j = 0
    for i = 0, 255 do
        j = bit.band(j + s[i] + key:byte(i % #key + 1), 255)
        s[i], s[j] = s[j], s[i]
    end
    local x, y = 0, 0
    local function step(bytes)
        local out = {}
        for n = 1, #bytes do
            x = bit.band(x + 1, 255)
            y = bit.band(y + s[x], 255)
            s[x], s[y] = s[y], s[x]
            out[n] = string.char(bit.bxor(bytes:byte(n), s[bit.band(s[x] + s[y], 255)]))
        end
        return table.concat(out)
    end
    step(string.rep("\0", 1024))
    return step
end
-- }}}

-- {{{ local function read_exact
-- Blocking read of exactly n bytes; returns nil and the reason when the
-- client hangs up, along with whatever partial bytes arrived.
local function read_exact(client, n)
    local data, err, partial = client:receive(n)
    if data then return data end
    return nil, err, partial
end
-- }}}

-- {{{ local function send_challenge
-- Same layout AzerothCore's worldserver sends: size (2 bytes, big-endian,
-- counting the opcode), opcode (2 bytes, little-endian), then uint32 1,
-- uint32 seed, 32 bytes of challenge.
local function send_challenge(client)
    local body   = "\1\0\0\0" .. CHALLENGE_SEED .. CHALLENGE_BYTES
    local size   = #body + 2
    local header = string.char(math.floor(size / 256), size % 256,
                               OPCODE_AUTH_CHALLENGE % 256, math.floor(OPCODE_AUTH_CHALLENGE / 256))
    client:send(header .. body)
    log("sent auth challenge (0x1EC), seed " .. hex(CHALLENGE_SEED) .. ", 32 bytes 00..1F")
end
-- }}}

-- {{{ local function parse_redirect_proof
-- Layout read from Wow.exe 12340 at 0x63282E: zero-terminated account
-- name, uint64 anti-flood answer, 20-byte digest =
-- SHA1(account name .. session key .. server seed as it sat on the wire).
local function parse_redirect_proof(body, session_key)
    local name_end = body:find("\0", 1, true)
    if not name_end then
        log("0x512 body has no zero byte ending the account name; raw " .. hex(body))
        return false
    end
    local account = body:sub(1, name_end - 1)
    local dos     = body:sub(name_end + 1, name_end + 8)
    local digest  = body:sub(name_end + 9, name_end + 28)
    local extra   = body:sub(name_end + 29)
    log("redirect proof: account \"" .. account .. "\", anti-flood answer " .. hex(dos)
     .. ", digest " .. hex(digest) .. (#extra > 0 and (", " .. #extra .. " unexpected trailing bytes " .. hex(extra)) or ""))

    if not session_key then
        log("digest not checked: no --key given")
        return false
    end
    local expected = sha1(account .. session_key .. CHALLENGE_SEED)
    local matched  = (expected == digest)
    log("digest " .. (matched and "MATCHES" or "DOES NOT MATCH") .. " SHA1(account .. key .. seed) = " .. hex(expected))
    return matched
end
-- }}}

-- {{{ local function serve
local function serve(client)
    local peer_ip, peer_port = client:getpeername()
    log("connection from " .. tostring(peer_ip) .. ":" .. tostring(peer_port))
    client:settimeout(30)
    send_challenge(client)

    local session_key = options.key and (options.key:gsub("..", function(p) return string.char(tonumber(p, 16)) end))
    local decrypt, encrypt = nil, nil

    while true do
        local header, err, partial = read_exact(client, 6)
        if not header then
            log("connection ended while waiting for a packet header (" .. tostring(err) .. ")"
             .. ((partial and #partial > 0) and (", partial bytes " .. hex(partial)) or ""))
            return
        end

        -- after the proof the client scrambles headers; without the key the
        -- best we can do is dump the raw bytes in arrival order
        local raw_header = header
        if decrypt then header = decrypt(header) end

        local size   = header:byte(1) * 256 + header:byte(2)
        local opcode = header:byte(3) + header:byte(4) * 0x100 + header:byte(5) * 0x10000 + header:byte(6) * 0x1000000
        if size < 4 or size > 10240 then
            log("header does not parse (size " .. size .. "); raw " .. hex(raw_header)
             .. (decrypt and " (decrypted " .. hex(header) .. ")" or " (no key: headers are probably scrambled now)"))
            local rest, _, rest_partial = client:receive(4096)
            log("following bytes: " .. hex(rest or rest_partial or ""))
            return
        end

        local body = ""
        if size > 4 then body = read_exact(client, size - 4) end
        if not body then
            log("connection ended inside the body of opcode " .. string.format("0x%03X", opcode))
            return
        end
        log(string.format("client sent opcode 0x%03X, %d body bytes: %s", opcode, #body, hex(body)))

        if opcode == OPCODE_REDIRECT_PROOF then
            local matched = parse_redirect_proof(body, session_key)
            if session_key then
                decrypt = new_arc4(hmac_sha1(SEED_CLIENT_TO_SERVER, session_key))
                encrypt = new_arc4(hmac_sha1(SEED_SERVER_TO_CLIENT, session_key))
                log("header unscrambling switched on for the rest of this connection")
            end
            if matched and options.answer == "auth-ok" then
                -- AUTH_OK, then the fields AzerothCore sends with it:
                -- billing time left (uint32), billing flags (uint8),
                -- billing rested (uint32), expansion (uint8, 2 = WotLK)
                local reply  = string.char(AUTH_OK) .. "\0\0\0\0" .. "\0" .. "\0\0\0\0" .. "\2"
                local rsize  = #reply + 2
                local rhead  = string.char(math.floor(rsize / 256), rsize % 256,
                                           OPCODE_AUTH_RESPONSE % 256, math.floor(OPCODE_AUTH_RESPONSE / 256))
                client:send(encrypt(rhead) .. reply)
                log("sent scrambled auth response (0x1EE) AUTH_OK; watching what the client does next")
            end
        elseif opcode == OPCODE_REDIRECT_FAIL then
            log("client refused the redirect on this connection; token " .. hex(body))
        end
    end
end
-- }}}

-- {{{ main
local server = assert(socket.bind("0.0.0.0", options.port))
log("listening on 0.0.0.0:" .. options.port .. (options.key and " with session key" or " without session key")
 .. (options.answer and (", answering " .. options.answer) or ", observing only"))
while true do
    local client = server:accept()
    local ok, failure = pcall(serve, client)
    if not ok then log("listener error while serving a connection: " .. tostring(failure)) end
    client:close()
    log("connection closed; waiting for the next one")
end
-- }}}
