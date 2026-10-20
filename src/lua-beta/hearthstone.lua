
local HEARTH_SPELLS     = { [8690] = true,
                            [556]  = true }
local FOLLOW_MS         = 1500
local RING_SPACING      = 2.5
local RING_MIN_RADIUS   = 3
local MENU_ID           = 211000
local INTID_COME, INTID_STAY = 1, 2
local NPC_TEXT          = 100
local GOSSIP_ICON_TAXI  = 2
local GOSSIP_ICON_CHAT  = 0
local PLAYER_EVENT_ON_LOGOUT     = 4
local PLAYER_EVENT_ON_SPELL_CAST = 5
local SPELL_EVENT_ON_PREPARE     = 1
local SPELL_EVENT_ON_CAST_CANCEL = 3
local GOSSIP_EVENT_ON_SELECT     = 2

local HEARTH_KIND = { question = "%s is hearthing to %s. Come along?",
                      confirm  = "Travel with %s to %s when their hearthstone finishes?" }

GroupHearth = {}

GroupHearth.pending = {}
local nextHearth = 0

function GroupHearth.circle(cx, cy, n)
    local out = {}
    if n < 1 then return out end
    local radius = math.max(RING_MIN_RADIUS, RING_SPACING * n / (2 * math.pi))
    for k = 1, n do
        local a = 2 * math.pi * k / n
        out[k] = { x = cx + math.cos(a) * radius, y = cy + math.sin(a) * radius }
    end
    return out
end

local function members_of(player)
    local map = player:GetMap()
    local group
    if map:IsBattleground() or map:IsArena() then group = player:GetOriginalGroup()
                                            else group = player:GetGroup() end
    if not group then return nil end
    local list = {}
    for _, m in ipairs(group:GetMembers()) do list[#list + 1] = m:GetGUID() end
    return list
end

local function ask(member, hearth)
    member:GossipClearMenu()
    member:GossipMenuAddItem(GOSSIP_ICON_TAXI, string.format(hearth.kind.question, hearth.name, hearth.place), hearth.id, INTID_COME,
                             false, string.format(hearth.kind.confirm, hearth.name, hearth.place))
    member:GossipMenuAddItem(GOSSIP_ICON_CHAT, "Stay here.", hearth.id, INTID_STAY)
    member:GossipSendMenu(NPC_TEXT, member, MENU_ID)
end

function GroupHearth.open(player, kind, place)
    local members = members_of(player)
    if not members or #members < 2 then return nil end
    nextHearth = nextHearth + 1
    local hearth = { id = nextHearth, hearther = player:GetGUID(), name = player:GetName(), kind = kind, place = place,
                     members = members, accepted = {}, asked = {}, done = false }
    GroupHearth.pending[hearth.hearther] = hearth
    for _, guid in ipairs(members) do
        if guid ~= hearth.hearther then
            local m = GetPlayerByGUID(guid)
            if m and (kind.withDead or not m:IsDead()) then
                if m:IsBot() then
                    hearth.accepted[guid] = true
                else
                    hearth.asked[guid] = true
                    ask(m, hearth)
                end
            end
        end
    end
    return hearth
end

function GroupHearth.homeName(player)
    local q = CharDBQuery("SELECT zoneId FROM character_homebind WHERE guid = " .. player:GetGUIDLow())
    if not q then
        print("[GroupHearth] ERROR: " .. player:GetName() .. " has no character_homebind row; no invitation sent")
        return nil
    end
    return GetAreaName(q:GetUInt32(0))
end

function GroupHearth.onPrepare(event, caster, spell)
    if not caster:IsPlayer() or not members_of(caster) then return end
    local place = GroupHearth.homeName(caster)
    if place then GroupHearth.open(caster, HEARTH_KIND, place) end
end

function GroupHearth.onCancel(event, caster, spell, bySelf)
    if not caster:IsPlayer() then return end
    local h = GroupHearth.pending[caster:GetGUID()]
    if h and not h.done then GroupHearth.withdraw(h) end
end

function GroupHearth.onLogout(event, player)
    local h = GroupHearth.pending[player:GetGUID()]
    if h then GroupHearth.withdraw(h) end
end

function GroupHearth.take(guid)
    local h = GroupHearth.pending[guid]
    if not h or h.done then return {}, 0 end
    GroupHearth.pending[guid] = nil
    local out = {}
    for k, g in ipairs(h.members) do
        if g ~= h.hearther and h.accepted[g] then
            local m = GetPlayerByGUID(g)
            if m and (h.kind.withDead or not m:IsDead()) then
                m:GossipComplete()
                out[#out + 1] = { guid = g, place = k }
            end
        end
    end
    return out, #h.members
end

function GroupHearth.onAnswer(event, player, object, sender, intid, code, menuId)
    player:GossipComplete()
    for _, h in pairs(GroupHearth.pending) do
        if h.id == sender and h.asked[player:GetGUID()] then
            h.accepted[player:GetGUID()] = (intid == INTID_COME) or nil
            if intid == INTID_COME then
                player:SendBroadcastMessage("You will travel with " .. h.name .. " when their hearthstone finishes.")
            end
        end
    end
end

function GroupHearth.withdraw(h)
    for guid in pairs(h.asked) do
        local m = GetPlayerByGUID(guid)
        if m then
            m:GossipComplete()
            m:SendBroadcastMessage(h.name .. "'s hearth was called off; you stay where you are.")
        end
    end
    GroupHearth.pending[h.hearther] = nil
end

function GroupHearth.onCast(event, player, spell)
    if not HEARTH_SPELLS[spell:GetEntry()] then return end
    local h = GroupHearth.pending[player:GetGUID()]
    if not h or h.done then return end
    h.done = true
    player:RegisterEvent(function(_, _, _, p)
        local home = p:GetHomebind()
        local spots = GroupHearth.circle(home.x, home.y, #h.members)
        for k, guid in ipairs(h.members) do
            if guid ~= h.hearther and h.accepted[guid] then
                local m = GetPlayerByGUID(guid)
                if m and not m:IsDead() then
                    m:GossipComplete()
                    m:Teleport(home.mapId, spots[k].x, spots[k].y, home.z, math.random() * 2 * math.pi)
                end
            end
        end
        GroupHearth.pending[h.hearther] = nil
    end, FOLLOW_MS, 1)
end

for spell in pairs(HEARTH_SPELLS) do
    RegisterSpellEvent(spell, SPELL_EVENT_ON_PREPARE,     GroupHearth.onPrepare)
    RegisterSpellEvent(spell, SPELL_EVENT_ON_CAST_CANCEL, GroupHearth.onCancel)
end
RegisterPlayerEvent(PLAYER_EVENT_ON_SPELL_CAST, GroupHearth.onCast)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT,     GroupHearth.onLogout)
RegisterPlayerGossipEvent(MENU_ID, GOSSIP_EVENT_ON_SELECT, GroupHearth.onAnswer)
