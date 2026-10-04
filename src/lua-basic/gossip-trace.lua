--------------------------------------------------------------------------------
-- gossip-trace.lua (TEMPORARY - remove once the Sargobras clan-name bug is found)
--
-- A listening post on Sargobras's conversation window. It writes one log line
-- for each menu the server sends a player, one for each answer the client
-- sends back, and one when the Sargobras script's own answer handler is
-- actually reached. Nothing is changed or blocked; it only reads copies.
--
-- Why it exists: picking a class with a clan name typed in the pop-up box did
-- nothing and left the window open (2026-10-03). The server drops an answer
-- silently in three places before any script sees it:
--   1. the option number the client names is not in the server's stored menu
--   2. the menu's NPC is not the NPC the client answered
--   3. the player "can't interact" with that NPC (distance, alive, hostile)
-- Comparing a "menu sent" line with the "answer received" line after it shows
-- which one: matching NPC and option number but no "handler reached" line
-- points at 3; a different NPC at 2; an option number past the count at 1.
--
-- Lines go to tmp/shared-memory/gossip-trace.log (RAM; the Lua engine's own
-- print() only reaches the worldserver console, not a log file).
--------------------------------------------------------------------------------

local DIR      = "/mnt/mtwo/games/azeroth-core/wow-chat-2026"
local LOG_PATH = DIR .. "/tmp/shared-memory/gossip-trace.log"

-- {{{ local function trace
-- One line, appended and flushed at once so it survives a crash.
local function trace(fmt, ...)
    local f = assert(io.open(LOG_PATH, "a"), "gossip-trace: cannot open " .. LOG_PATH)
    f:write(os.date("%H:%M:%S "), string.format(fmt, ...), "\n")
    f:close()
end
-- }}}

-- opcodes (source-beta Opcodes.h) and packet hook ids (mod-ale Hooks.h)
local CMSG_GOSSIP_SELECT_OPTION    = 0x17C
local SMSG_GOSSIP_MESSAGE          = 0x17D
local PACKET_EVENT_ON_RECEIVE      = 5
local PACKET_EVENT_ON_SEND         = 7
local GOSSIP_EVENT_ON_SELECT       = 2

-- the Sargobras entries, as in sargobras.lua
local VALLEY, WANDERER             = 6170001, 6170002

-- {{{ local function on_menu_sent
-- SMSG_GOSSIP_MESSAGE, 3.3.5a layout: npc guid (u64), menu id (u32), text id
-- (u32), item count (u32), then per item: index (u32), icon (u8), coded (u8),
-- box money (u32), text (string), box text (string). Quests follow; unread.
local function on_menu_sent(event, packet, player)
    local guid   = packet:ReadGUID()
    local menu   = packet:ReadULong()
    local text   = packet:ReadULong()
    local count  = packet:ReadULong()
    local coded  = {}
    for _ = 1, count do
        local index = packet:ReadULong()
        packet:ReadUByte()                          -- icon
        local box   = packet:ReadUByte()
        packet:ReadULong()                          -- box money
        packet:ReadString()                         -- option text
        packet:ReadString()                         -- box text
        if box ~= 0 then coded[#coded + 1] = index end
    end
    trace("menu sent to %s: npc %s, menu %d, text %d, %d options, coded options [%s]",
        player and player:GetName() or "?", tostring(guid), menu, text, count, table.concat(coded, ","))
end
-- }}}

-- {{{ local function on_answer_received
-- CMSG_GOSSIP_SELECT_OPTION: npc guid (u64), menu id (u32), option index
-- (u32), then the typed code (string) only when that option is coded.
local function on_answer_received(event, packet, player)
    local guid  = packet:ReadGUID()
    local menu  = packet:ReadULong()
    local index = packet:ReadULong()
    -- the size comes back as a 64-bit userdata, not a Lua number
    local rest  = tonumber(tostring(packet:GetSize())) - 8 - 4 - 4
    local code  = rest > 0 and packet:ReadString() or "(none)"

    -- part of how the server judges "can interact" (drop 3), seen from here.
    -- The pinned engine has no hostility check; greeting him already passed
    -- the same one, so it is left out.
    local npc   = player and player:GetMap():GetWorldObject(guid)
    local where = "npc not found on the player's map"
    if npc then
        where = string.format("npc entry %d, %.1f yards away, alive %s",
            npc:GetEntry(), player:GetDistance(npc), tostring(npc:IsAlive()))
    end
    trace("answer received from %s: npc %s, menu %d, option %d, code \"%s\"; %s",
        player and player:GetName() or "?", tostring(guid), menu, index, code, where)
end
-- }}}

-- {{{ local function on_handler_reached
-- A second listener on Sargobras's select event: firing at all means the
-- server passed every check and handed the answer to the scripts.
local function on_handler_reached(event, player, creature, sender, intid, code)
    trace("handler reached for %s: npc entry %d, intid %d, code \"%s\"",
        player:GetName(), creature:GetEntry(), intid, tostring(code))
end
-- }}}

RegisterPacketEvent(SMSG_GOSSIP_MESSAGE,       PACKET_EVENT_ON_SEND,    on_menu_sent)
RegisterPacketEvent(CMSG_GOSSIP_SELECT_OPTION, PACKET_EVENT_ON_RECEIVE, on_answer_received)
RegisterCreatureGossipEvent(VALLEY,   GOSSIP_EVENT_ON_SELECT, on_handler_reached)
RegisterCreatureGossipEvent(WANDERER, GOSSIP_EVENT_ON_SELECT, on_handler_reached)
