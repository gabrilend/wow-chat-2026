--------------------------------------------------------------------------------
-- ale-test.lua - Simple ALE test script
-- Sends a message to all players every 5 seconds to verify ALE is working
-- Delete this file once ALE is confirmed working
--------------------------------------------------------------------------------

-- {{{ SendTestMessage
-- Sends a system message to all players
local function SendTestMessage()
    local players = GetPlayersInWorld()
    local count   = 0

    for _, player in ipairs(players) do
        if player and player:IsInWorld() then
            player:SendBroadcastMessage("[ALE Test] Server time: " .. os.date("%H:%M:%S"))
            count = count + 1
        end
    end

    print("[ALE Test] Sent message to " .. count .. " players")
end
-- }}}

-- {{{ PeriodicTest
-- Periodic callback that re-registers itself
local function PeriodicTest()
    SendTestMessage()
    -- Re-register for next tick (5 seconds, 1 repeat)
    CreateLuaEvent(PeriodicTest, 5000, 1)
end
-- }}}

-- {{{ Initialize
-- Start the periodic test after a short delay
print("[ALE Test] Script loaded - will send messages every 5 seconds")
CreateLuaEvent(PeriodicTest, 5000, 1)
-- }}}
