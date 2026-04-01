-- {{{ Everland Ghostsong - Gesture Command System
-- Players command NPCs through body language: kneeling, sitting, beckoning
-- NPCs respond with reverence, following, waiting, and directed movement
--
-- Issue: 133-gesture-command-system-kneel-convoy.md
-- Concept Catalog: 101-139
-- }}}

require("movement")

Gestures = {}

-- {{{ Configuration
KNEEL_RADIUS           = 10    -- yards to trigger NPC kneeling
BECKON_RADIUS          = 15    -- yards for beckoning to work
KNEEL_DIRECTION_DIST   = 50    -- yards to project facing direction
REVERENCE_CHECK_RATE   = 1000  -- ms between proximity checks
DIRECTION_UPDATE_RATE  = 500   -- ms between facing direction updates
-- }}}

-- {{{ Emote ID mappings (WotLK 3.3.5a)
-- These may need verification against actual emote IDs
EMOTE_ONESHOT_KNEEL = 68
EMOTE_STATE_KNEEL   = 68
EMOTE_ONESHOT_WAVE  = 3
EMOTE_ONESHOT_POINT = 25
EMOTE_STATE_SIT     = 1
EMOTE_ONESHOT_SALUTE = 66

GESTURE_ACTIONS = {
    [EMOTE_ONESHOT_KNEEL] = "kneel_start",
    [EMOTE_STATE_KNEEL]   = "kneel_hold",
    [EMOTE_ONESHOT_WAVE]  = "beckon",
    [EMOTE_ONESHOT_POINT] = "direct",
    [EMOTE_STATE_SIT]     = "wait_command",
    [EMOTE_ONESHOT_SALUTE]= "dismiss_convoy",
}
-- }}}

-- {{{ State storage
-- Tracked per-player: NPCs who have shown reverence
local reverence_targets = {}  -- [npc_guid] = player_guid
local player_convoys = {}     -- [player_guid] = {npc_guids...}
local kneel_directions = {}   -- [player_guid] = {facing, active}
-- }}}

-- {{{ Gestures.getPlayersInRange
-- Find all players within range of a position
function Gestures.getPlayersInRange(x, y, z, range, map)
    local players = {}
    local all_players = GetPlayersInWorld()

    if not all_players then return players end

    for _, player in pairs(all_players) do
        if player and player:IsAlive() then
            local px, py, pz = player:GetPosition()
            local dist = Movement.squaredDistance(x, y, px, py)
            if dist <= range * range then
                table.insert(players, player)
            end
        end
    end

    return players
end
-- }}}

-- {{{ Gestures.getNPCsInRange
-- Find all friendly NPCs within range of player
function Gestures.getNPCsInRange(player, range)
    local npcs = {}
    local px, py, pz = player:GetPosition()

    -- Get creatures in range that are friendly
    local nearby = player:GetCreaturesInRange(range, 1, 0)  -- friendly

    if not nearby then return npcs end

    for _, npc in pairs(nearby) do
        if npc and npc:IsAlive() and not npc:IsInCombat() then
            table.insert(npcs, npc)
        end
    end

    return npcs
end
-- }}}

-- {{{ Gestures.npcKneel
-- Make an NPC kneel before a player
function Gestures.npcKneel(npc, player)
    if not npc or not player then return end

    local npc_guid = npc:GetGUID()
    local player_guid = player:GetGUID()

    -- Already kneeling to someone?
    if reverence_targets[npc_guid] then return end

    -- Face the player
    local px, py = player:GetPosition()
    local nx, ny = npc:GetPosition()
    local angle = math.atan2(py - ny, px - nx)
    npc:SetFacing(angle)

    -- Kneel (set stand state)
    npc:SetStandState(8)  -- UNIT_STAND_STATE_KNEEL = 8

    -- Track reverence
    reverence_targets[npc_guid] = player_guid

    print("[Gestures] " .. npc:GetName() .. " kneels before " .. player:GetName())
end
-- }}}

-- {{{ Gestures.npcRise
-- Make an NPC rise from kneeling
function Gestures.npcRise(npc)
    if not npc then return end

    npc:SetStandState(0)  -- UNIT_STAND_STATE_STAND = 0

    local npc_guid = npc:GetGUID()
    reverence_targets[npc_guid] = nil

    print("[Gestures] " .. npc:GetName() .. " rises")
end
-- }}}

-- {{{ Gestures.addToConvoy
-- Add an NPC to a player's convoy
function Gestures.addToConvoy(player, npc)
    if not player or not npc then return end

    local player_guid = player:GetGUID()
    local npc_guid = npc:GetGUID()

    -- Initialize convoy if needed
    if not player_convoys[player_guid] then
        player_convoys[player_guid] = {}
    end

    -- Check if already in convoy
    for _, guid in ipairs(player_convoys[player_guid]) do
        if guid == npc_guid then return end
    end

    table.insert(player_convoys[player_guid], npc_guid)

    -- Set NPC to follow player
    npc:MoveFollow(player, 3, 0)  -- 3 yard distance, 0 angle offset

    print("[Gestures] " .. npc:GetName() .. " joins " .. player:GetName() .. "'s convoy")
end
-- }}}

-- {{{ Gestures.removeFromConvoy
-- Remove an NPC from a player's convoy
function Gestures.removeFromConvoy(player, npc)
    if not player or not npc then return end

    local player_guid = player:GetGUID()
    local npc_guid = npc:GetGUID()

    if not player_convoys[player_guid] then return end

    for i, guid in ipairs(player_convoys[player_guid]) do
        if guid == npc_guid then
            table.remove(player_convoys[player_guid], i)
            npc:MovementExpired()
            print("[Gestures] " .. npc:GetName() .. " leaves convoy")
            return
        end
    end
end
-- }}}

-- {{{ Gestures.getConvoy
-- Get all NPCs in a player's convoy
function Gestures.getConvoy(player)
    if not player then return {} end

    local player_guid = player:GetGUID()
    local convoy = player_convoys[player_guid] or {}
    local npcs = {}

    for _, npc_guid in ipairs(convoy) do
        local npc = GetCreatureByGUID(npc_guid)
        if npc and npc:IsAlive() then
            table.insert(npcs, npc)
        end
    end

    return npcs
end
-- }}}

-- {{{ Gestures.onPlayerApproach
-- Check for NPCs that should kneel when player approaches
function Gestures.onPlayerApproach(player)
    if not player or not player:IsAlive() then return end
    if not player:IsStandState() then return end  -- Player must be standing

    local npcs = Gestures.getNPCsInRange(player, KNEEL_RADIUS)

    for _, npc in ipairs(npcs) do
        if not npc:IsInCombat() then
            Gestures.npcKneel(npc, player)
        end
    end
end
-- }}}

-- {{{ Gestures.onPlayerBeckon
-- Player beckons - kneeling NPCs rise and follow
function Gestures.onPlayerBeckon(player)
    if not player then return end

    local player_guid = player:GetGUID()
    local npcs = Gestures.getNPCsInRange(player, BECKON_RADIUS)

    for _, npc in ipairs(npcs) do
        local npc_guid = npc:GetGUID()

        -- Only respond if kneeling to this player
        if reverence_targets[npc_guid] == player_guid then
            Gestures.npcRise(npc)
            Gestures.addToConvoy(player, npc)
        end
    end

    print("[Gestures] " .. player:GetName() .. " beckons followers")
end
-- }}}

-- {{{ Gestures.onPlayerSit
-- Player sits - convoy members wait nearby
function Gestures.onPlayerSit(player)
    if not player then return end

    local convoy = Gestures.getConvoy(player)
    local px, py, pz = player:GetPosition()

    for _, npc in ipairs(convoy) do
        -- Stop following
        npc:MovementExpired()

        -- Move to player's position
        npc:MoveTo(0, px, py, pz, true)

        -- Kneel and wait
        npc:RegisterEvent(function()
            npc:SetStandState(8)  -- Kneel
        end, 2000, 1)
    end

    print("[Gestures] " .. player:GetName() .. " sits - convoy waits")
end
-- }}}

-- {{{ Gestures.onPlayerKneel
-- Player kneels facing a direction - convoy moves that way
function Gestures.onPlayerKneel(player)
    if not player then return end

    local player_guid = player:GetGUID()
    local convoy = Gestures.getConvoy(player)

    if #convoy == 0 then return end

    local px, py, pz = player:GetPosition()
    local facing = player:GetFacing()

    -- Calculate target position in facing direction
    local target_x = px + math.cos(facing) * KNEEL_DIRECTION_DIST
    local target_y = py + math.sin(facing) * KNEEL_DIRECTION_DIST
    local target_z = player:GetMap():GetHeight(player:GetPhase(), target_x, target_y, pz)

    -- Store active direction for updates
    kneel_directions[player_guid] = {
        facing = facing,
        active = true
    }

    -- Direct convoy to target
    for _, npc in ipairs(convoy) do
        npc:MovementExpired()
        npc:MoveTo(0, target_x, target_y, target_z, true)
        npc:SetStandState(0)  -- Stand up to move
    end

    print("[Gestures] " .. player:GetName() .. " directs convoy " ..
          string.format("(%.0f, %.0f)", target_x, target_y))
end
-- }}}

-- {{{ Gestures.onPlayerStand
-- Player stands up - resume normal convoy behavior
function Gestures.onPlayerStand(player)
    if not player then return end

    local player_guid = player:GetGUID()
    local convoy = Gestures.getConvoy(player)

    -- Clear kneeling direction
    kneel_directions[player_guid] = nil

    -- Resume following
    for _, npc in ipairs(convoy) do
        npc:SetStandState(0)  -- Stand
        npc:MoveFollow(player, 3, 0)
    end

    print("[Gestures] " .. player:GetName() .. " stands - convoy follows")
end
-- }}}

-- {{{ Gestures.onPlayerDismiss
-- Player salutes - dismiss convoy
function Gestures.onPlayerDismiss(player)
    if not player then return end

    local convoy = Gestures.getConvoy(player)

    for _, npc in ipairs(convoy) do
        Gestures.removeFromConvoy(player, npc)
        npc:MoveRandom(30)  -- Wander off
    end

    player_convoys[player:GetGUID()] = nil

    print("[Gestures] " .. player:GetName() .. " dismisses convoy")
end
-- }}}

-- {{{ Gestures.onEmote
-- Handle player emote events
function Gestures.onEmote(event, player, emote)
    local action = GESTURE_ACTIONS[emote]

    if not action then return end

    if action == "beckon" then
        Gestures.onPlayerBeckon(player)
    elseif action == "kneel_start" or action == "kneel_hold" then
        Gestures.onPlayerKneel(player)
    elseif action == "direct" then
        Gestures.onPlayerKneel(player)  -- Point also directs
    elseif action == "dismiss_convoy" then
        Gestures.onPlayerDismiss(player)
    end
end
-- }}}

-- {{{ Gestures.onStandStateChange
-- Handle player stand state changes
function Gestures.onStandStateChange(event, player, state)
    if state == 1 then  -- Sitting
        Gestures.onPlayerSit(player)
    elseif state == 8 then  -- Kneeling
        Gestures.onPlayerKneel(player)
    elseif state == 0 then  -- Standing
        Gestures.onPlayerStand(player)
    end
end
-- }}}

-- {{{ Gestures.proximityCheck
-- Periodic check for player-NPC proximity (reverence trigger)
function Gestures.proximityCheck()
    local all_players = GetPlayersInWorld()

    if not all_players then return end

    for _, player in pairs(all_players) do
        if player and player:IsAlive() and player:IsStandState() then
            Gestures.onPlayerApproach(player)
        end
    end
end
-- }}}

-- {{{ Gestures.initialize
-- Set up periodic checks and event handlers
function Gestures.initialize()
    -- Periodic proximity check for reverence
    CreateLuaEvent(Gestures.proximityCheck, REVERENCE_CHECK_RATE, 0)

    print("[Gestures] System initialized")
end
-- }}}

-- {{{ Event Registration
PLAYER_EVENT_ON_EMOTE = 28  -- May need verification
PLAYER_EVENT_ON_UPDATE = 30  -- May need verification

-- Note: These event registrations may need adjustment based on actual ALE API
-- RegisterPlayerEvent(PLAYER_EVENT_ON_EMOTE, Gestures.onEmote)

-- Initialize on load
Gestures.initialize()

print("[Gestures] Behavior loaded - Issue 133")
-- }}}
