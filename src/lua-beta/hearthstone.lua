--------------------------------------------------------------------------------
-- hearthstone.lua - a group hearthstone, by invitation (issue 211)
--
-- For a general audience: when someone in a group starts their
-- hearthstone, every other player in the group is asked, in a small
-- window, whether to come along. Those who say yes travel when the cast
-- finishes, and arrive standing in a circle round where the hearther lands,
-- each at the place of their number in the group. A cancelled or
-- interrupted hearth withdraws the question and moves no one. Bots in the
-- group can't answer a window, so they always come. Checked offline by
-- scripts/test-hearthstone.
--
-- History: wow-chat-1's version (libs/wow-chat-1/hearthstone.lua, written
-- by hand by the owner) pulled the group 10 seconds after the hearthstone
-- was used, whether or not the cast finished, to a random spot near the
-- hearther, and let a member decline only by sitting down. It stopped at
-- the hearther in the member list, so members after them never came. The
-- owner, 2026-10-17: "sitting down to decline is a dumb idea because how do
-- you know they're hearthing?", and: "They should spawn in a circle around
-- the first hearther's hearth position." Rewritten the same day.
--
-- Choices made without the owner yet (issue 211's open questions):
--   bots in the group always come (wow-chat-1 pulled everyone);
--   a second hearther in the same group while one is under way is asked
--     like anyone else, and if they accept, travels with the first;
--   the window is the clan-name kind (answer now, move when the cast
--     completes), not the game's own summon dialog (which moves at once).
--------------------------------------------------------------------------------

-- {{{ Configuration
local HEARTH_SPELLS     = { [8690] = true,     -- Hearthstone
                            [556]  = true }    -- Astral Recall (shaman)
local HEARTH_ITEM       = 6948                 -- the Hearthstone item
local CAST_MS           = 10000                -- the hearthstone's cast
local CANCEL_AFTER_MS   = CAST_MS + 2500       -- no completion by then: it was cancelled
local FOLLOW_MS         = 1500                 -- after completion: the hearther has arrived
local RING_SPACING      = 2.5                  -- yards between neighbours on the circle
local RING_MIN_RADIUS   = 3                    -- yards
local MENU_ID           = 211000               -- this window's number (player-sent gossip needs one)
local INTID_COME, INTID_STAY = 1, 2
local NPC_TEXT          = 100                  -- the game's plain header text
local GOSSIP_ICON_TAXI  = 2
local GOSSIP_ICON_CHAT  = 0
local PLAYER_EVENT_ON_SPELL_CAST = 5
local ITEM_EVENT_ON_USE          = 2
local GOSSIP_EVENT_ON_SELECT     = 2
-- }}}

GroupHearth = {}

-- One hearth under way per hearther, keyed by the hearther's guid:
-- { id = number (this hearth's own), hearther = guid, name = string,
--   members = list of guids (group order, the hearther included),
--   accepted = { [guid] = true }, asked = { [guid] = true }, done = boolean }
-- Players are kept by guid, never as objects: an object kept across a
-- delay can outlive its player (issue 210's crash).
GroupHearth.pending = {}
local nextHearth = 0

-- {{{ GroupHearth.circle
-- Places on a circle round (cx, cy) for n travellers: index k (1..n) at
-- angle 2*pi*k/n, the radius growing so neighbours stay RING_SPACING apart.
-- Returns a list of { x, y }. Plain arithmetic, tested offline.
function GroupHearth.circle(cx, cy, n)
    local out = {}
    if n < 1 then return out end
    local radius = math.max(RING_MIN_RADIUS, RING_SPACING * n / (2 * math.pi))
    for k = 1, n do
        local a = 2 * math.pi * k / n
        out[k] = { x = cx + math.cos(a) * radius, y = cy + math.sin(a) * radius }
    end
    return out
end -- }}}

-- {{{ local function members_of
-- The group's members as guids, in group order, or nil when not grouped.
local function members_of(player)
    if not player:IsInGroup() then return nil end
    local list = {}
    for _, m in ipairs(player:GetGroup():GetMembers()) do list[#list + 1] = m:GetGUID() end
    return list
end
-- }}}

-- {{{ local function ask
-- The window: a line saying who is going where, and two answers; "come
-- along" carries a confirm box, the okay/cancel the owner asked for.
local function ask(member, hearth)
    member:GossipClearMenu()
    member:GossipMenuAddItem(GOSSIP_ICON_TAXI, hearth.name .. " is hearthing home. Come along?", hearth.id, INTID_COME,
                             false, "Travel with " .. hearth.name .. " when their hearthstone finishes?")
    member:GossipMenuAddItem(GOSSIP_ICON_CHAT, "Stay here.", hearth.id, INTID_STAY)
    member:GossipSendMenu(NPC_TEXT, member, MENU_ID)
end
-- }}}

-- {{{ GroupHearth.onUse
-- The hearthstone is used (the cast begins). Bots are counted in at once;
-- players are asked. The hearth is forgotten if no completion comes in
-- time (a cancel, an interrupt, a death).
--   not grouped, or alone: nothing to do
--   grouped: open the hearth, ask, and set the cancel timer
function GroupHearth.onUse(event, player, item, target)
    local members = members_of(player)
    if not members or #members < 2 then return end
    nextHearth = nextHearth + 1
    local hearth = { id = nextHearth, hearther = player:GetGUID(), name = player:GetName(),
                     members = members, accepted = {}, asked = {}, done = false }
    GroupHearth.pending[hearth.hearther] = hearth
    for _, guid in ipairs(members) do
        if guid ~= hearth.hearther then
            local m = GetPlayerByGUID(guid)
            if m and not m:IsDead() then
                if m:IsBot() then
                    hearth.accepted[guid] = true
                else
                    hearth.asked[guid] = true
                    ask(m, hearth)
                end
            end
        end
    end
    local id = hearth.id
    player:RegisterEvent(function(_, _, _, p)
        local h = GroupHearth.pending[p:GetGUID()]
        if h and h.id == id and not h.done then GroupHearth.withdraw(h, "the hearthstone was not finished") end
    end, CANCEL_AFTER_MS, 1)
end -- }}}

-- {{{ GroupHearth.onAnswer
-- A member's answer in the window. Only the hearth that asked them counts
-- (sender carries its number).
--   "come along": counted in
--   "stay": counted out
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
end -- }}}

-- {{{ GroupHearth.withdraw
-- The hearth did not happen: close the windows still open and forget it.
function GroupHearth.withdraw(h, why)
    for guid in pairs(h.asked) do
        local m = GetPlayerByGUID(guid)
        if m then
            m:GossipComplete()
            m:SendBroadcastMessage(h.name .. "'s hearth was called off; you stay where you are.")
        end
    end
    GroupHearth.pending[h.hearther] = nil
end -- }}}

-- {{{ GroupHearth.onCast
-- A spell cast completes. A hearthstone of an open hearth: a moment later,
-- everyone counted in is moved round the hearther's bind point, by their
-- number in the group (so a member's place does not depend on who else
-- came). Facing: any direction.
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
end -- }}}

RegisterItemEvent(HEARTH_ITEM, ITEM_EVENT_ON_USE, GroupHearth.onUse)
RegisterPlayerEvent(PLAYER_EVENT_ON_SPELL_CAST, GroupHearth.onCast)
RegisterPlayerGossipEvent(MENU_ID, GOSSIP_EVENT_ON_SELECT, GroupHearth.onAnswer)
