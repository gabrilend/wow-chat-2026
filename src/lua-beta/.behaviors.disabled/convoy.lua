
require("movement")

Convoy = {}

package.loaded["behaviors/convoy"] = Convoy

CONVOY_SPACING        = 3
REFORM_DELAY          = 500
OUROBOROS_ENABLED     = true
CHAIN_UPDATE_RATE     = 1000
MAX_STRAY_DISTANCE    = 30

local convoys = {}
local npc_convoy_map = {}


function Convoy.create(leader_player)
    local convoy_id = "convoy_" .. tostring(math.random(100000, 999999))

    local convoy = {
        id = convoy_id,
        leader = leader_player and leader_player:GetGUID() or nil,
        head = nil,
        members = {},
        chain = {}
    }

    convoys[convoy_id] = convoy

    print("[Convoy] Created convoy: " .. convoy_id)
    return convoy_id
end

function Convoy.destroy(convoy_id)
    local convoy = convoys[convoy_id]
    if not convoy then return end

    for _, npc_guid in ipairs(convoy.members) do
        npc_convoy_map[npc_guid] = nil
        local npc = GetCreatureByGUID(npc_guid)
        if npc then
            npc:MoveExpire()
            npc:MoveRandom(30)
        end
    end

    convoys[convoy_id] = nil
    print("[Convoy] Destroyed convoy: " .. convoy_id)
end

function Convoy.addMember(convoy_id, npc)
    local convoy = convoys[convoy_id]
    if not convoy or not npc then return false end

    local npc_guid = npc:GetGUID()

    if npc_convoy_map[npc_guid] then
        Convoy.removeMember(npc_convoy_map[npc_guid], npc)
    end

    table.insert(convoy.members, npc_guid)
    npc_convoy_map[npc_guid] = convoy_id

    if #convoy.members == 1 then
        convoy.head = npc_guid
    end

    Convoy.rebuildChain(convoy_id)

    print("[Convoy] Added " .. npc:GetName() .. " to " .. convoy_id)
    return true
end

function Convoy.removeMember(convoy_id, npc)
    local convoy = convoys[convoy_id]
    if not convoy or not npc then return end

    local npc_guid = npc:GetGUID()

    for i, guid in ipairs(convoy.members) do
        if guid == npc_guid then
            table.remove(convoy.members, i)
            break
        end
    end

    npc_convoy_map[npc_guid] = nil

    npc:MoveExpire()

    if #convoy.members > 0 then
        Convoy.rebuildChain(convoy_id)
    else
        Convoy.destroy(convoy_id)
    end

    print("[Convoy] Removed " .. npc:GetName() .. " from " .. convoy_id)
end

function Convoy.findNearest(x, y, candidates)
    local nearest = nil
    local nearest_dist = math.huge

    for i, npc_guid in ipairs(candidates) do
        local npc = GetCreatureByGUID(npc_guid)
        if npc then
            local nx, ny = npc:GetLocation()
            local dist = Movement.squaredDistance(x, y, nx, ny)
            if dist < nearest_dist then
                nearest = i
                nearest_dist = dist
            end
        end
    end

    return nearest
end

function Convoy.rebuildChain(convoy_id)
    local convoy = convoys[convoy_id]
    if not convoy or #convoy.members == 0 then return end

    local start_x, start_y
    if convoy.leader then
        local leader = GetPlayerByGUID(convoy.leader)
        if leader then
            start_x, start_y = leader:GetLocation()
        end
    end

    if not start_x then
        local first_npc = GetCreatureByGUID(convoy.members[1])
        if first_npc then
            start_x, start_y = first_npc:GetLocation()
        else
            return
        end
    end

    local remaining = {}
    for _, guid in ipairs(convoy.members) do
        table.insert(remaining, guid)
    end

    local new_order = {}
    local current_x, current_y = start_x, start_y

    while #remaining > 0 do
        local nearest_idx = Convoy.findNearest(current_x, current_y, remaining)
        if nearest_idx then
            local npc_guid = table.remove(remaining, nearest_idx)
            table.insert(new_order, npc_guid)

            local npc = GetCreatureByGUID(npc_guid)
            if npc then
                current_x, current_y = npc:GetLocation()
            end
        else
            break
        end
    end

    convoy.members = new_order
    convoy.head = new_order[1]

    convoy.chain = {}
    for i, npc_guid in ipairs(new_order) do
        convoy.chain[npc_guid] = {
            following = new_order[i - 1] or nil,
            follower = new_order[i + 1] or nil
        }
    end

    if OUROBOROS_ENABLED and #new_order > 1 then
        local tail_guid = new_order[#new_order]
        convoy.chain[tail_guid].following_next = new_order[1]
    end

    Convoy.applyFollowBehavior(convoy_id)

    print("[Convoy] Rebuilt chain for " .. convoy_id .. " (" .. #new_order .. " members)")
end

function Convoy.applyFollowBehavior(convoy_id)
    local convoy = convoys[convoy_id]
    if not convoy then return end

    for i, npc_guid in ipairs(convoy.members) do
        local npc = GetCreatureByGUID(npc_guid)
        if not npc then goto continue end

        local chain_link = convoy.chain[npc_guid]

        if i == 1 then
            if convoy.leader then
                local leader = GetPlayerByGUID(convoy.leader)
                if leader then
                    npc:MoveFollow(leader, CONVOY_SPACING, 0)
                end
            end
        else
            local follow_guid = chain_link.following
            local follow_target = GetCreatureByGUID(follow_guid)
            if follow_target then
                npc:MoveFollow(follow_target, CONVOY_SPACING, 0)
            end
        end

        ::continue::
    end
end

function Convoy.onMemberDeath(npc)
    local npc_guid = npc:GetGUID()
    local convoy_id = npc_convoy_map[npc_guid]

    if not convoy_id then return end

    local convoy = convoys[convoy_id]
    if not convoy then return end

    local chain_link = convoy.chain[npc_guid]
    if not chain_link then return end

    local prev_guid = chain_link.follower
    local next_guid = chain_link.following

    if prev_guid and next_guid then
        local prev_npc = GetCreatureByGUID(prev_guid)
        local next_npc = GetCreatureByGUID(next_guid)

        if prev_npc and next_npc then
            prev_npc:MoveFollow(next_npc, CONVOY_SPACING, 0)
        end
    end

    if convoy.head == npc_guid and next_guid then
        convoy.head = next_guid

        if convoy.leader then
            local new_head = GetCreatureByGUID(next_guid)
            local leader = GetPlayerByGUID(convoy.leader)
            if new_head and leader then
                new_head:MoveFollow(leader, CONVOY_SPACING, 0)
            end
        end
    end

    Convoy.removeMember(convoy_id, npc)

    print("[Convoy] Member died, chain reformed: " .. #convoy.members .. " remain")
end

function Convoy.onLeaderLeave(player)
    local player_guid = player:GetGUID()

    for convoy_id, convoy in pairs(convoys) do
        if convoy.leader == player_guid then
            convoy.leader = nil

            if OUROBOROS_ENABLED and #convoy.members > 1 then
                local tail_guid = convoy.members[#convoy.members]
                local head_guid = convoy.head

                local tail_npc = GetCreatureByGUID(tail_guid)
                local head_npc = GetCreatureByGUID(head_guid)

                if tail_npc and head_npc then
                    head_npc:MoveFollow(tail_npc, CONVOY_SPACING, 0)
                end

                print("[Convoy] Ouroboros activated - tail becomes head")
            else
                Convoy.destroy(convoy_id)
            end
        end
    end
end

function Convoy.getConvoyByNPC(npc)
    local convoy_id = npc_convoy_map[npc:GetGUID()]
    return convoy_id and convoys[convoy_id] or nil
end

function Convoy.getConvoyByPlayer(player)
    local player_guid = player:GetGUID()

    for convoy_id, convoy in pairs(convoys) do
        if convoy.leader == player_guid then
            return convoy
        end
    end

    return nil
end

function Convoy.directToPosition(convoy_id, x, y, z)
    local convoy = convoys[convoy_id]
    if not convoy then return end

    local had_leader = convoy.leader
    convoy.leader = nil

    local head_npc = GetCreatureByGUID(convoy.head)
    if head_npc then
        head_npc:MoveTo(0, x, y, z, true)
    end

    Convoy.applyFollowBehavior(convoy_id)

    convoy.leader = had_leader

    print("[Convoy] Directed to position: " .. string.format("(%.0f, %.0f)", x, y))
end

function Convoy.lostMemberCheck()
    print("[DEBUG Convoy.lostMemberCheck] CALLBACK FIRED")
    for convoy_id, convoy in pairs(convoys) do
        if not convoy.leader then goto next_convoy end

        local leader = GetPlayerByGUID(convoy.leader)
        if not leader then goto next_convoy end

        local lx, ly = leader:GetLocation()

        for _, npc_guid in ipairs(convoy.members) do
            local npc = GetCreatureByGUID(npc_guid)
            if npc then
                local nx, ny = npc:GetLocation()
                local dist = math.sqrt(Movement.squaredDistance(lx, ly, nx, ny))

                if dist > MAX_STRAY_DISTANCE then
                    npc:NearTeleport(lx, ly, leader:GetZ(), leader:GetO())
                    print("[Convoy] " .. npc:GetName() .. " was lost, teleported back")
                end
            end
        end

        ::next_convoy::
    end
end

function Convoy.initialize()
    print("[Convoy] System initialized (per-player events via periodic_events.lua)")
end

function Convoy.periodicLostMemberCheck(player)
    local guid = player:GetGUID()
    local convoy = convoys[guid]
    if not convoy or not convoy.leader then return end

    local lx, ly = player:GetLocation()

    for _, npc_guid in ipairs(convoy.members) do
        local npc = GetCreatureByGUID(npc_guid)
        if npc then
            local nx, ny = npc:GetLocation()
            local dist = math.sqrt(Movement.squaredDistance(lx, ly, nx, ny))

            if dist > MAX_STRAY_DISTANCE then
                npc:NearTeleport(lx, ly, player:GetZ(), player:GetO())
                print("[Convoy] " .. npc:GetName() .. " was lost, teleported back")
            end
        end
    end
end

CREATURE_EVENT_ON_DIED = 4


Convoy.initialize()

print("[Convoy] Ouroboros behavior loaded - Issue 133")
