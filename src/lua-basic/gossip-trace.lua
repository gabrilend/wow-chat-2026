
local DIR      = "/mnt/kaun/wow-chat-2026"
local LOG_PATH = DIR .. "/tmp/shared-memory/gossip-trace.log"

local function trace(fmt, ...)
    local f = assert(io.open(LOG_PATH, "a"), "gossip-trace: cannot open " .. LOG_PATH)
    f:write(os.date("%H:%M:%S "), string.format(fmt, ...), "\n")
    f:close()
end

local CMSG_GOSSIP_SELECT_OPTION    = 0x17C
local SMSG_GOSSIP_MESSAGE          = 0x17D
local PACKET_EVENT_ON_RECEIVE      = 5
local PACKET_EVENT_ON_SEND         = 7
local GOSSIP_EVENT_ON_SELECT       = 2

local VALLEY, WANDERER             = 6170001, 6170002

local function on_menu_sent(event, packet, player)
    local guid   = packet:ReadGUID()
    local menu   = packet:ReadULong()
    local text   = packet:ReadULong()
    local count  = packet:ReadULong()
    local coded  = {}
    for _ = 1, count do
        local index = packet:ReadULong()
        packet:ReadUByte()
        local box   = packet:ReadUByte()
        packet:ReadULong()
        packet:ReadString()
        packet:ReadString()
        if box ~= 0 then coded[#coded + 1] = index end
    end
    trace("menu sent to %s: npc %s, menu %d, text %d, %d options, coded options [%s]",
        player and player:GetName() or "?", tostring(guid), menu, text, count, table.concat(coded, ","))
end

local function on_answer_received(event, packet, player)
    local guid  = packet:ReadGUID()
    local menu  = packet:ReadULong()
    local index = packet:ReadULong()
    local rest  = tonumber(tostring(packet:GetSize())) - 8 - 4 - 4
    local code  = rest > 0 and packet:ReadString() or "(none)"

    local npc   = player and player:GetMap():GetWorldObject(guid)
    local where = "npc not found on the player's map"
    if npc then
        where = string.format("npc entry %d, %.1f yards away, alive %s",
            npc:GetEntry(), player:GetDistance(npc), tostring(npc:IsAlive()))
    end
    trace("answer received from %s: npc %s, menu %d, option %d, code \"%s\"; %s",
        player and player:GetName() or "?", tostring(guid), menu, index, code, where)
end

local function on_handler_reached(event, player, creature, sender, intid, code)
    trace("handler reached for %s: npc entry %d, intid %d, code \"%s\"",
        player:GetName(), creature:GetEntry(), intid, tostring(code))
end

RegisterPacketEvent(SMSG_GOSSIP_MESSAGE,       PACKET_EVENT_ON_SEND,    on_menu_sent)
RegisterPacketEvent(CMSG_GOSSIP_SELECT_OPTION, PACKET_EVENT_ON_RECEIVE, on_answer_received)
RegisterCreatureGossipEvent(VALLEY,   GOSSIP_EVENT_ON_SELECT, on_handler_reached)
RegisterCreatureGossipEvent(WANDERER, GOSSIP_EVENT_ON_SELECT, on_handler_reached)
