--------------------------------------------------------------------------------
-- buddies-here.lua (issue 617e, hearthstones; a game master's mending tool)
--
-- For a general audience: until buddies hearth the way 617e designs, a
-- partner who hearths can leave their buddies behind (or the buddies use
-- their own hearthstones, still bound to the starting valley). A game
-- master types
--
--     .buddies here <partner name>
--
-- (or "buddies here <partner name>" on the server console) and each of
-- that partner's buddies in the world is moved to the partner: placed on a
-- small ring round them, evenly spread by roster slot, each facing the
-- partner. Owner, 2026-10-04: "Can you also manually teleport them to me
-- because I used my hearthstone already".
--------------------------------------------------------------------------------

local PLAYER_EVENT_ON_COMMAND = 42
local GM_RANK   = 2                  -- game masters only
local RING      = 3                  -- yards from the partner
local RING_SPOTS = 7                 -- one place per roster slot (seven slots)
local TAG       = "[buddies here] "

-- {{{ local function bring
-- Moves every buddy of `partner` (a player in the world) to a ring round
-- them; `say` prints a line back to whoever asked.
local function bring(partner, say)
    local q = CharDBQuery("SELECT slot, buddy FROM buddy_roster WHERE owner = " .. partner:GetGUIDLow() .. " AND buddy <> 0 ORDER BY slot")
    if not q then return say(TAG .. partner:GetName() .. " has no buddies in the roster") end
    local px, py, pz = partner:GetLocation()
    local map        = partner:GetMap()
    local moved, total = 0, 0
    repeat
        total = total + 1
        local slot, guid = q:GetUInt32(0), q:GetUInt32(1)
        local b = GetPlayerByGUID(GetPlayerGUID(guid))
        if not b or not b:IsInWorld() then
            say(string.format("%sslot %d (character %d): not in the world, left where it is", TAG, slot, guid))
        else
            -- slot k stands at angle (k - 1) * 2 pi / 7 round the partner,
            -- facing back toward them (the opposite angle)
            local a = (slot - 1) * 2 * math.pi / RING_SPOTS
            local x = px + math.cos(a) * RING
            local y = py + math.sin(a) * RING
            local z = map:GetHeight(x, y) or pz
            if math.abs(z - pz) > 5 then z = pz end   -- a ledge or a floor below: stand at the partner's height
            b:Teleport(partner:GetMapId(), x, y, z, (a + math.pi) % (2 * math.pi))
            moved = moved + 1
        end
    until not q:NextRow()
    say(string.format("%s%d of %d of %s's buddies moved to them", TAG, moved, total, partner:GetName()))
end
-- }}}

-- {{{ local function on_command
local function on_command(event, player, command, handler)
    local name = command:match("^buddies%s+here%s+(%a+)%s*$")
    if not name then return end
    if player and player:GetGMRank() < GM_RANK then return end
    local say = player and function(text) player:SendBroadcastMessage(text) end
                        or function(text) handler:SendSysMessage(text) end
    local partner = GetPlayerByName(name:sub(1, 1):upper() .. name:sub(2):lower())
    if not partner or not partner:IsInWorld() then
        say(TAG .. name .. " is not in the world; their buddies can only be moved to them while they are")
    else
        bring(partner, say)
    end
    return false
end
-- }}}

RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, on_command)
