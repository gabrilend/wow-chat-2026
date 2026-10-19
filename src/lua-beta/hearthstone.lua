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
-- 2026-10-18: the invitation follows the spell, not the Hearthstone item.
-- The first version opened it on the item's use and guessed a cancel from a
-- timer, so Astral Recall (a spell with no item) never invited anyone. Now
-- the engine's per-spell events open it as the cast begins and withdraw it
-- the moment the cast is cancelled; a hearther logging out withdraws it too.
-- Other scripts open the same invitation for their own spells and place the
-- travellers themselves (GroupHearth.open / GroupHearth.take): the druids'
-- Moonglade trip (druid-moonglade.lua, issue 211a).
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
local FOLLOW_MS         = 1500                 -- after completion: the hearther has arrived
local RING_SPACING      = 2.5                  -- yards between neighbours on the circle
local RING_MIN_RADIUS   = 3                    -- yards
local MENU_ID           = 211000               -- this window's number (player-sent gossip needs one)
local INTID_COME, INTID_STAY = 1, 2
local NPC_TEXT          = 100                  -- the game's plain header text
local GOSSIP_ICON_TAXI  = 2
local GOSSIP_ICON_CHAT  = 0
local PLAYER_EVENT_ON_LOGOUT     = 4
local PLAYER_EVENT_ON_SPELL_CAST = 5    -- fires as a cast completes, before its effect
local SPELL_EVENT_ON_PREPARE     = 1    -- a cast begins (Spell::prepare)
local SPELL_EVENT_ON_CAST_CANCEL = 3    -- a cast is cancelled or interrupted (Spell::cancel)
local GOSSIP_EVENT_ON_SELECT     = 2

-- what the window says, for a Hearthstone or Astral Recall, with the
-- hearther's name and where they are going (the owner, 2026-10-18: "make
-- it say where the person is hearthing to, like 'moonglade' or 'eversong
-- woods' or similar. For both."); another script's kind brings its own
-- (GroupHearth.open)
local HEARTH_KIND = { question = "%s is hearthing to %s. Come along?",
                      confirm  = "Travel with %s to %s when their hearthstone finishes?" }
-- }}}

-- made here only; druid-moonglade.lua uses it when a spell is cast
GroupHearth = {}

-- One hearth under way per hearther, keyed by the hearther's guid:
-- { id = number (this hearth's own), hearther = guid, name = string,
--   kind = { question, confirm } (strings with one %s for the name),
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
-- In a battleground or arena the game puts a player in the match's raid
-- group and keeps their own party aside as the "original group"; the trip
-- is for their own party (the owner, 2026-10-18: "their own party, of
-- course"), so that one is used when it exists.
--   in a match: their own party, or nil without one (never the match's raid)
--   anywhere else: their group, or nil
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
-- }}}

-- {{{ local function ask
-- The window: a line saying who is going where, and two answers; "come
-- along" carries a confirm box, the okay/cancel the owner asked for.
local function ask(member, hearth)
    member:GossipClearMenu()
    member:GossipMenuAddItem(GOSSIP_ICON_TAXI, string.format(hearth.kind.question, hearth.name, hearth.place), hearth.id, INTID_COME,
                             false, string.format(hearth.kind.confirm, hearth.name, hearth.place))
    member:GossipMenuAddItem(GOSSIP_ICON_CHAT, "Stay here.", hearth.id, INTID_STAY)
    member:GossipSendMenu(NPC_TEXT, member, MENU_ID)
end
-- }}}

-- {{{ GroupHearth.open
-- A cast begins that the group may follow: bots are counted in at once,
-- players are asked. Returns the hearth, or nil.
--   not grouped, or alone: nothing to do (nil)
--   grouped: open the hearth and ask
-- kind: { question, confirm }, each a string with two %s, the hearther's
-- name and then the place (HEARTH_KIND for a Hearthstone), and withDead =
-- true to ask the dead too (the druids' glade raises them; a Hearthstone
-- does not). place: where they are going, a name (string).
function GroupHearth.open(player, kind, place)
    local members = members_of(player)
    if not members or #members < 2 then return nil end
    -- a cast begun again before the first one ended replaces it: the new
    -- window replaces the old on each member's screen, and an answer to the
    -- old one is ignored (onAnswer matches the hearth's own number)
    nextHearth = nextHearth + 1
    local hearth = { id = nextHearth, hearther = player:GetGUID(), name = player:GetName(), kind = kind, place = place,
                     members = members, accepted = {}, asked = {}, done = false }
    GroupHearth.pending[hearth.hearther] = hearth
    for _, guid in ipairs(members) do
        if guid ~= hearth.hearther then
            local m = GetPlayerByGUID(guid)
            -- offline: not asked; dead: not asked, unless the kind takes the dead
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
end -- }}}

-- {{{ GroupHearth.homeName
-- The name of the zone a player is bound in: the zone the game writes into
-- character_homebind when they bind (Player::SetHomebind, at once), named
-- by the game's area data. Nil, with a line in the server log, when the
-- character has no bind row (the game gives every character one when it is
-- made, so none is a fault to look into, not a case to word around).
function GroupHearth.homeName(player)
    local q = CharDBQuery("SELECT zoneId FROM character_homebind WHERE guid = " .. player:GetGUIDLow())
    if not q then
        print("[GroupHearth] ERROR: " .. player:GetName() .. " has no character_homebind row; no invitation sent")
        return nil
    end
    return GetAreaName(q:GetUInt32(0))
end -- }}}

-- {{{ GroupHearth.onPrepare
-- A Hearthstone or Astral Recall cast begins (the engine's per-spell event:
-- caster may be any unit; only players hearth with a group). The window
-- names the zone of the hearther's bind point.
--   the bind point's zone known: the group is invited
--   not known (no bind row): nobody is, and the log says why
function GroupHearth.onPrepare(event, caster, spell)
    if not caster:IsPlayer() or not members_of(caster) then return end   -- nobody to invite
    local place = GroupHearth.homeName(caster)
    if place then GroupHearth.open(caster, HEARTH_KIND, place) end
end -- }}}

-- {{{ GroupHearth.onCancel
-- The cast was cancelled or interrupted: its hearth is withdrawn.
function GroupHearth.onCancel(event, caster, spell, bySelf)
    if not caster:IsPlayer() then return end
    local h = GroupHearth.pending[caster:GetGUID()]
    if h and not h.done then GroupHearth.withdraw(h) end
end -- }}}

-- {{{ GroupHearth.onLogout
-- A hearther who logs out mid-cast: their hearth is withdrawn.
function GroupHearth.onLogout(event, player)
    local h = GroupHearth.pending[player:GetGUID()]
    if h then GroupHearth.withdraw(h) end
end -- }}}

-- {{{ GroupHearth.take
-- For a script placing the travellers itself, as its spell completes: the
-- members who said yes and are still in the world, as a list of
-- { guid, place = their number in the group }, with the group's size; the
-- hearth is closed. No hearth open: an empty list. The dead are left out
-- unless the hearth's kind says withDead (the druids' glade raises them on
-- arrival).
function GroupHearth.take(guid)
    local h = GroupHearth.pending[guid]
    if not h or h.done then return {}, 0 end
    GroupHearth.pending[guid] = nil
    local out = {}
    for k, g in ipairs(h.members) do
        if g ~= h.hearther and h.accepted[g] then
            local m = GetPlayerByGUID(g)
            -- offline: left out; dead: left out, unless the kind takes the dead
            if m and (h.kind.withDead or not m:IsDead()) then
                m:GossipComplete()
                out[#out + 1] = { guid = g, place = k }
            end
        end
    end
    return out, #h.members
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
function GroupHearth.withdraw(h)
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

for spell in pairs(HEARTH_SPELLS) do
    RegisterSpellEvent(spell, SPELL_EVENT_ON_PREPARE,     GroupHearth.onPrepare)
    RegisterSpellEvent(spell, SPELL_EVENT_ON_CAST_CANCEL, GroupHearth.onCancel)
end
RegisterPlayerEvent(PLAYER_EVENT_ON_SPELL_CAST, GroupHearth.onCast)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT,     GroupHearth.onLogout)
RegisterPlayerGossipEvent(MENU_ID, GOSSIP_EVENT_ON_SELECT, GroupHearth.onAnswer)
