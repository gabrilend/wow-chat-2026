
local ffi = require("ffi")

ffi.cdef[[
typedef struct evp_md_st EVP_MD;
const EVP_MD *EVP_sha1(void);
unsigned char *HMAC(const EVP_MD *evp_md, const void *key, int key_len,
                    const unsigned char *d, size_t n,
                    unsigned char *md, unsigned int *md_len);
]]

local REDIRECT_OPCODE      = 0x50D
local REDIRECT_TOKEN       = 0xC0FFEE13
local REDIRECT_PAYLOAD_LEN = 30
local SESSION_KEY_LEN      = 40
local PLAYER_EVENT_ON_COMMAND = 42

local function hex_to_bytes(hex)
    return (hex:gsub("..", function(pair) return string.char(tonumber(pair, 16)) end))
end

local function bytes_to_hex(bytes)
    return (bytes:gsub(".", function(c) return string.format("%02X", c:byte()) end))
end

local function hmac_sha1(key, message)
    local out = ffi.new("unsigned char[20]")
    ffi.C.HMAC(ffi.C.EVP_sha1(), key, #key, message, #message, out, nil)
    return ffi.string(out, 20)
end

local function send_redirect(player, a, b, c, d, port, address_order, port_order)
    local address_bytes = (address_order == "net") and string.char(a, b, c, d)
                                                    or string.char(d, c, b, a)
    local port_bytes    = (port_order    == "net") and string.char(math.floor(port / 256), port % 256)
                                                    or string.char(port % 256, math.floor(port / 256))

    local query = AuthDBQuery("SELECT HEX(session_key) FROM account WHERE id = " .. player:GetAccountId())
    if not query then
        error("redirect-probe: no account row for account id " .. player:GetAccountId()
           .. " (player " .. player:GetName() .. "). The session key comes from"
           .. " acore_auth.account; to debug: is this worldserver pointed at the same"
           .. " auth database the authserver writes to?")
    end
    local session_key = hex_to_bytes(query:GetString(0))
    if #session_key ~= SESSION_KEY_LEN then
        error("redirect-probe: session key for account " .. player:GetAccountId()
           .. " is " .. #session_key .. " bytes, expected " .. SESSION_KEY_LEN
           .. ". Address and port were parsed; the packet was not sent.")
    end

    local proof = hmac_sha1(session_key, address_bytes .. port_bytes)

    local a1, a2, a3, a4 = address_bytes:byte(1, 4)
    local p1, p2         = port_bytes:byte(1, 2)

    local packet = CreatePacket(REDIRECT_OPCODE, REDIRECT_PAYLOAD_LEN)
    packet:WriteULong(a1 + a2 * 0x100 + a3 * 0x10000 + a4 * 0x1000000)
    packet:WriteUShort(p1 + p2 * 0x100)
    packet:WriteULong(REDIRECT_TOKEN)
    for i = 1, 20 do packet:WriteUByte(proof:byte(i)) end

    player:SendPacket(packet)

    local summary = string.format("redirect sent: address bytes %s (%s order), port bytes %s (%s order), token %08X, proof %s",
                                  bytes_to_hex(address_bytes), address_order,
                                  bytes_to_hex(port_bytes),    port_order,
                                  REDIRECT_TOKEN, bytes_to_hex(proof))
    player:SendBroadcastMessage(summary)
    print("[redirect-probe] " .. player:GetName() .. ": " .. summary)
    print("[redirect-probe] session key for the listener's --key: " .. bytes_to_hex(session_key))
end

local function on_command(event, player, command)
    local words = {}
    for word in command:gmatch("%S+") do words[#words + 1] = word end
    if words[1] ~= "redirect" then return end

    if not player then
        print("[redirect-probe] .redirect needs an in-game administrator; the console has no client connection")
        return false
    end

    if player:GetGMRank() < 3 then return end

    if words[2] == "key" then
        local query = AuthDBQuery("SELECT HEX(session_key) FROM account WHERE id = " .. player:GetAccountId())
        if not query then
            error("redirect-probe: no account row for account id " .. player:GetAccountId() .. "; nothing printed")
        end
        print("[redirect-probe] session key for the listener's --key: " .. query:GetString(0))
        player:SendBroadcastMessage("session key printed on the worldserver console")
        return false
    end

    local a, b, c, d = (words[2] or ""):match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
    local port       = tonumber(words[3] or "")
    local address_order = words[4] or "net"
    local port_order    = words[5] or "host"

    if not a or not port or port < 1 or port > 65535
       or (address_order ~= "net" and address_order ~= "host")
       or (port_order    ~= "net" and port_order    ~= "host") then
        player:SendBroadcastMessage("usage: .redirect <a.b.c.d> <port> [net|host address order] [net|host port order]")
        return false
    end

    send_redirect(player, tonumber(a), tonumber(b), tonumber(c), tonumber(d), port, address_order, port_order)
    return false
end

RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, on_command)
