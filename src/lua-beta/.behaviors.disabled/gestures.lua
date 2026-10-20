
require("movement")

Gestures = {}

package.loaded["behaviors/gestures"] = Gestures

KNEEL_RADIUS           = 10
BECKON_RADIUS          = 15
KNEEL_DIRECTION_DIST   = 50
REVERENCE_CHECK_RATE   = 1000
DIRECTION_UPDATE_RATE  = 500

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

local reverence_targets = {}
local player_convoys = {}
local kneel_directions = {}

function Gestures.getPlayersInRange(x, y, z, range, map)
    local players = {}
    local all_players = GetPlayersInWorld()

    if not all_players then return players end

    for _, player in pairs(all_players) do
        if player and player:IsAlive() then
            local px, py, pz = player:GetLocation()
            local dist = Movement.squaredDistance(x, y, px, py)
            if dist <= range * range then
                table.insert(players, player)
            end
        end
    end

    return players
end

function Gestures.getNPCsInRange(player, range)
    local npcs = {}
    local px, py, pz = player:GetLocation()

    local nearby = player:GetCreaturesInRange(range, 1, 0)

    if not nearby then return npcs end

    for _, npc in pairs(nearby) do
        if npc and npc:IsAlive() and not npc:IsInCombat() then
            table.insert(npcs, npc)
        end
    end

    return npcs
end

function Gestures.npcKneel(npc, player)
    if not npc or not player then return end

    local npc_guid = npc:GetGUID()
    local player_guid = player:GetGUID()

    if reverence_targets[npc_guid] then return end

    local px, py = player:GetLocation()
    local nx, ny = npc:GetLocation()
    local angle = math.atan2(py - ny, px - nx)
    npc:SetFacing(angle)

    npc:SetStandState(8)

    reverence_targets[npc_guid] = player_guid

    print("[Gestures] " .. npc:GetName() .. " kneels before " .. player:GetName())
end

function Gestures.npcRise(npc)
    if not npc then return end

    npc:SetStandState(0)

    local npc_guid = npc:GetGUID()
    reverence_targets[npc_guid] = nil

    print("[Gestures] " .. npc:GetName() .. " rises")
end

function Gestures.addToConvoy(player, npc)
    if not player or not npc then return end

    local player_guid = player:GetGUID()
    local npc_guid = npc:GetGUID()

    if not player_convoys[player_guid] then
        player_convoys[player_guid] = {}
    end

    for _, guid in ipairs(player_convoys[player_guid]) do
        if guid == npc_guid then return end
    end

    table.insert(player_convoys[player_guid], npc_guid)

    npc:MoveFollow(player, 3, 0)

    print("[Gestures] " .. npc:GetName() .. " joins " .. player:GetName() .. "'s convoy")
end

function Gestures.removeFromConvoy(player, npc)
    if not player or not npc then return end

    local player_guid = player:GetGUID()
    local npc_guid = npc:GetGUID()

    if not player_convoys[player_guid] then return end

    for i, guid in ipairs(player_convoys[player_guid]) do
        if guid == npc_guid then
            table.remove(player_convoys[player_guid], i)
            npc:MoveExpire()
            print("[Gestures] " .. npc:GetName() .. " leaves convoy")
            return
        end
    end
end

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

function Gestures.onPlayerApproach(player)
    if not player or not player:IsAlive() then return end
    if not player:IsStandState() then return end

    local npcs = Gestures.getNPCsInRange(player, KNEEL_RADIUS)

    for _, npc in ipairs(npcs) do
        if not npc:IsInCombat() then
            Gestures.npcKneel(npc, player)
        end
    end
end

function Gestures.onPlayerBeckon(player)
    if not player then return end

    local player_guid = player:GetGUID()
    local npcs = Gestures.getNPCsInRange(player, BECKON_RADIUS)

    for _, npc in ipairs(npcs) do
        local npc_guid = npc:GetGUID()

        if reverence_targets[npc_guid] == player_guid then
            Gestures.npcRise(npc)
            Gestures.addToConvoy(player, npc)
        end
    end

    print("[Gestures] " .. player:GetName() .. " beckons followers")
end

function Gestures.onPlayerSit(player)
    if not player then return end

    local convoy = Gestures.getConvoy(player)
    local px, py, pz = player:GetLocation()

    for _, npc in ipairs(convoy) do
        npc:MoveExpire()

        npc:MoveTo(0, px, py, pz, true)

        npc:RegisterEvent(function()
            npc:SetStandState(8)
        end, 2000, 1)
    end

    print("[Gestures] " .. player:GetName() .. " sits - convoy waits")
end

function Gestures.onPlayerKneel(player)
    if not player then return end

    local player_guid = player:GetGUID()
    local convoy = Gestures.getConvoy(player)

    if #convoy == 0 then return end

    local px, py, pz = player:GetLocation()
    local facing = player:GetO()

    local target_x = px + math.cos(facing) * KNEEL_DIRECTION_DIST
    local target_y = py + math.sin(facing) * KNEEL_DIRECTION_DIST
    local target_z = player:GetMap():GetHeight(target_x, target_y, player:GetPhaseMask())
    if not target_z then return end

    kneel_directions[player_guid] = {
        facing = facing,
        active = true
    }

    for _, npc in ipairs(convoy) do
        npc:MoveExpire()
        npc:MoveTo(0, target_x, target_y, target_z, true)
        npc:SetStandState(0)
    end

    print("[Gestures] " .. player:GetName() .. " directs convoy " ..
          string.format("(%.0f, %.0f)", target_x, target_y))
end

function Gestures.onPlayerStand(player)
    if not player then return end

    local player_guid = player:GetGUID()
    local convoy = Gestures.getConvoy(player)

    kneel_directions[player_guid] = nil

    for _, npc in ipairs(convoy) do
        npc:SetStandState(0)
        npc:MoveFollow(player, 3, 0)
    end

    print("[Gestures] " .. player:GetName() .. " stands - convoy follows")
end

function Gestures.onPlayerDismiss(player)
    if not player then return end

    local convoy = Gestures.getConvoy(player)

    for _, npc in ipairs(convoy) do
        Gestures.removeFromConvoy(player, npc)
        npc:MoveRandom(30)
    end

    player_convoys[player:GetGUID()] = nil

    print("[Gestures] " .. player:GetName() .. " dismisses convoy")
end

function Gestures.onEmote(event, player, emote)
    local action = GESTURE_ACTIONS[emote]

    if not action then return end

    if action == "beckon" then
        Gestures.onPlayerBeckon(player)
    elseif action == "kneel_start" or action == "kneel_hold" then
        Gestures.onPlayerKneel(player)
    elseif action == "direct" then
        Gestures.onPlayerKneel(player)
    elseif action == "dismiss_convoy" then
        Gestures.onPlayerDismiss(player)
    end
end

function Gestures.onStandStateChange(event, player, state)
    if state == 1 then
        Gestures.onPlayerSit(player)
    elseif state == 8 then
        Gestures.onPlayerKneel(player)
    elseif state == 0 then
        Gestures.onPlayerStand(player)
    end
end

function Gestures.proximityCheck()
    print("[DEBUG Gestures.proximityCheck] CALLBACK FIRED")
    local ready_players = ReadyPlayers.getAll()

    for _, player in pairs(ready_players) do
        if player and player:IsAlive() and player:IsStandState() then
            Gestures.onPlayerApproach(player)
        end
    end
end

function Gestures.initialize()
    print("[Gestures] System initialized (per-player events via periodic_events.lua)")
end

function Gestures.periodicProximityCheck(player)
    if not player or not player:IsAlive() or not player:IsStandState() then
        return
    end
    Gestures.onPlayerApproach(player)
end

PLAYER_EVENT_ON_EMOTE = 28
PLAYER_EVENT_ON_UPDATE = 30


Gestures.initialize()

print("[Gestures] Behavior loaded - Issue 133")
