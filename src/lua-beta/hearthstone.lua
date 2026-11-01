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
-- 2026-10-31, the owner's rules of 2026-10-30: saying yes to a hearthstone
-- starts the member's own hearthstone (its cooldown cleared), which puts
-- them on the circle when it completes; an interrupted one is started
-- again; when the hearther's cast ends, windows still open close as a no;
-- a hearther invites at most every 10 seconds; nobody ignoring the
-- hearther is asked. Bots ride the same way. A profile may leave members
-- out (GroupHearth.skip): basic runs this file in place
-- (src/lua-basic/group-hearth.lua) and leaves out buddies, whose own
-- script brings them.
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
                      confirm  = "Travel with %s to %s when their hearthstone finishes?",
                      ownCast  = true }   -- "okay" starts the member's own hearthstone (2026-10-30, below)

-- the owner's rules of 2026-10-30 (issue 211, question 1, word for word in
-- the issue): "pressing "okay" causes them to cast their own hearthstone
-- (even if it's on cooldown!) and if it's interrupted they'll address the
-- interruption and then try again. It'll take them to the other party
-- member's hearthstone location, not to their saved location"; "Once the
-- original party member's cast expires because it completed successfully
-- or was cancelled, the in-progress prompts to other players will
-- immediately pick "no""; "it has a 10 second cooldown before it can start
-- again"; "players who are on the ignore list should never ever be able to
-- give other players prompts"
local HEARTHSTONE       = 8690                 -- what a member casts on "okay", whatever the hearther cast
local OPEN_COOLDOWN_MS  = 10000                -- a hearther invites their group at most this often
local RIDE_RETRY_MS     = 2000                 -- an interrupted ride cast is started again after this
local RIDE_TRIES        = 5                    -- and no more often than this per ride
local CURRENT_GENERIC_SPELL = 1
local SOCIAL_FLAG_IGNORED   = 2                -- character_social.flags: the game's ignore list
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
-- members riding along on their own hearthstone, by guid: { hearth = the
-- hearth they ride with (kept after it leaves `pending`), tries = number }
GroupHearth.riding = {}
-- when each hearther last invited their group (game time, ms), for the
-- 10-second limit
GroupHearth.lastOpen = {}

-- {{{ GroupHearth.skip
-- Members this profile leaves out of the invitation altogether, neither
-- asked nor brought (a profile's own script replaces it after loading
-- this file; basic's leaves out every buddy, whose hearth its own script
-- handles). Default: nobody.
function GroupHearth.skip(member, hearther) return false end
-- }}}

-- {{{ local function ignores
-- Whether `member` has `hearther` on their ignore list (the game keeps it
-- in character_social, the ignored flag): such a member is never asked.
local function ignores(member, hearther)
    return CharDBQuery(string.format("SELECT 1 FROM character_social WHERE guid = %d AND friend = %d AND (flags & %d) <> 0",
        member:GetGUIDLow(), hearther:GetGUIDLow(), SOCIAL_FLAG_IGNORED)) ~= nil
end
-- }}}

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

-- {{{ local function ride
-- A member who said yes to a hearthstone's invitation casts their own
-- hearthstone, its cooldown cleared first ("even if it's on cooldown!");
-- where it lands is replaced by the hearther's circle when it completes
-- (GroupHearth.onCast).
local function ride(member, h)
    local r = GroupHearth.riding[member:GetGUID()] or { hearth = h, tries = 0 }
    r.hearth = h
    r.tries  = r.tries + 1
    GroupHearth.riding[member:GetGUID()] = r
    member:ResetSpellCooldown(HEARTHSTONE, true)
    member:CastSpell(member, HEARTHSTONE, false)
end
-- }}}

-- {{{ local function stopRide
-- A ride called off: its cast stopped, if it is still being cast.
local function stopRide(guid)
    if not GroupHearth.riding[guid] then return end
    GroupHearth.riding[guid] = nil
    local m = GetPlayerByGUID(guid)
    if m then m:InterruptSpell(CURRENT_GENERIC_SPELL) end
end
-- }}}

-- {{{ GroupHearth.rideTarget
-- Where a member riding along will be put when their own hearthstone
-- completes: { map, x, y, z }, or nil when they are not riding (other
-- scripts ask, so a rider's buddies follow them there, not home).
function GroupHearth.rideTarget(guid)
    local r = GroupHearth.riding[guid]
    if not r or not r.hearth.home then return nil end
    local h = r.hearth
    for k, g in ipairs(h.members) do
        if g == guid then
            local spot = GroupHearth.circle(h.home.x, h.home.y, #h.members)[k]
            return { map = h.home.mapId, x = spot.x, y = spot.y, z = h.home.z }
        end
    end
    return nil
end
-- }}}

-- {{{ GroupHearth.open
-- A cast begins that the group may follow: bots are counted in at once,
-- players are asked. Returns the hearth, or nil. Each path:
--   not grouped, or alone: nothing to do (nil)
--   the hearther invited their group under OPEN_COOLDOWN_MS ago: nil, and
--     they are told
--   grouped: open the hearth and ask; members this profile skips
--     (GroupHearth.skip) and members ignoring the hearther are neither
--     asked nor brought; for a kind that rides (a hearthstone), bots start
--     their own hearthstone at once
-- kind: { question, confirm }, each a string with two %s, the hearther's
-- name and then the place (HEARTH_KIND for a Hearthstone), and withDead =
-- true to ask the dead too (the druids' glade raises them; a Hearthstone
-- does not). place: where they are going, a name (string).
function GroupHearth.open(player, kind, place)
    local members = members_of(player)
    if not members or #members < 2 then return nil end
    local now  = GetCurrTime()
    local last = GroupHearth.lastOpen[player:GetGUID()]
    if last and now - last < OPEN_COOLDOWN_MS then
        player:SendBroadcastMessage("Your group was asked a moment ago; wait a few seconds before asking again.")
        return nil
    end
    GroupHearth.lastOpen[player:GetGUID()] = now
    -- a cast begun again before the first one ended replaces it: the new
    -- window replaces the old on each member's screen, and an answer to the
    -- old one is ignored (onAnswer matches the hearth's own number)
    nextHearth = nextHearth + 1
    local hearth = { id = nextHearth, hearther = player:GetGUID(), name = player:GetName(), kind = kind, place = place,
                     members = members, accepted = {}, asked = {}, done = false,
                     home = kind.ownCast and player:GetHomebind() or nil }
    GroupHearth.pending[hearth.hearther] = hearth
    for _, guid in ipairs(members) do
        if guid ~= hearth.hearther then
            local m = GetPlayerByGUID(guid)
            -- offline: not asked; dead: not asked, unless the kind takes the dead;
            -- skipped by the profile, or ignoring the hearther: never asked
            if m and (kind.withDead or not m:IsDead()) and not GroupHearth.skip(m, player) and not ignores(m, player) then
                if m:IsBot() then
                    hearth.accepted[guid] = true
                    if kind.ownCast then ride(m, hearth) end
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
    if GroupHearth.riding[caster:GetGUID()] then return end              -- riding along on someone's hearth: no invitation of its own
    local place = GroupHearth.homeName(caster)
    if place then GroupHearth.open(caster, HEARTH_KIND, place) end
end -- }}}

-- {{{ GroupHearth.onCancel
-- A cast was cancelled or interrupted. Each path:
--   a hearther's, their hearth still open    - the hearth is withdrawn
--   a rider's, its hearth still going         - started again RIDE_RETRY_MS
--     later ("they'll address the interruption and then try again"), up to
--     RIDE_TRIES casts; past that the ride ends and they are told
--   a rider's, its hearth called off          - nothing (withdraw ended it)
function GroupHearth.onCancel(event, caster, spell, bySelf)
    if not caster:IsPlayer() then return end
    local guid = caster:GetGUID()
    local r = GroupHearth.riding[guid]
    if r then
        if r.tries >= RIDE_TRIES then
            GroupHearth.riding[guid] = nil
            caster:SendBroadcastMessage("Your hearthstone was interrupted too often; you stay where you are.")
            return
        end
        caster:RegisterEvent(function(_, _, _, p)
            local again = GroupHearth.riding[p:GetGUID()]
            if again and again == r then ride(p, r.hearth) end
        end, RIDE_RETRY_MS, 1)
        return
    end
    local h = GroupHearth.pending[guid]
    if h and not h.done then GroupHearth.withdraw(h) end
end -- }}}

-- {{{ GroupHearth.onLogout
-- A hearther who logs out mid-cast: their hearth is withdrawn.
function GroupHearth.onLogout(event, player)
    GroupHearth.riding[player:GetGUID()] = nil                          -- a rider gone: their ride with them
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
-- (sender carries its number), and only while it is open.
--   "come along": counted in; for a hearthstone, their own hearthstone
--     starts (ride)
--   "stay": counted out; a ride of theirs under way is stopped (the
--     party leader's "no" cancels the leader's own cast, 2026-10-30)
function GroupHearth.onAnswer(event, player, object, sender, intid, code, menuId)
    player:GossipComplete()
    for _, h in pairs(GroupHearth.pending) do
        if h.id == sender and h.asked[player:GetGUID()] and not h.done then
            h.accepted[player:GetGUID()] = (intid == INTID_COME) or nil
            if intid == INTID_COME and h.kind.ownCast then
                player:SendBroadcastMessage("Your hearthstone takes you with " .. h.name .. ".")
                ride(player, h)
            elseif intid == INTID_COME then
                player:SendBroadcastMessage("You will travel with " .. h.name .. " when their hearthstone finishes.")
            else
                stopRide(player:GetGUID())
            end
        end
    end
end -- }}}

-- {{{ GroupHearth.withdraw
-- The hearth did not happen: close the windows still open, stop the rides
-- under way (their own hearthstones would take them home), and forget it.
function GroupHearth.withdraw(h)
    for guid in pairs(h.asked) do
        local m = GetPlayerByGUID(guid)
        if m then
            m:GossipComplete()
            m:SendBroadcastMessage(h.name .. "'s hearth was called off; you stay where you are.")
        end
    end
    for guid, r in pairs(GroupHearth.riding) do
        if r.hearth == h then stopRide(guid) end
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

    -- a rider's own hearthstone completed: a moment later (once the spell
    -- has put them home) they are put on the hearther's circle instead
    local target = GroupHearth.rideTarget(player:GetGUID())
    if target then
        GroupHearth.riding[player:GetGUID()] = nil
        player:RegisterEvent(function(_, _, _, p)
            if not p:IsDead() then
                p:GossipComplete()
                p:Teleport(target.map, target.x, target.y, target.z, math.random() * 2 * math.pi)
            end
        end, FOLLOW_MS, 1)
        return
    end

    local h = GroupHearth.pending[player:GetGUID()]
    if not h or h.done then return end
    h.done = true

    -- a hearth whose members ride on their own hearthstones: the windows
    -- still open answer "no" at once, the riders arrive by their own casts,
    -- and the hearth is closed now
    if h.kind.ownCast then
        for guid in pairs(h.asked) do
            if not h.accepted[guid] then
                local m = GetPlayerByGUID(guid)
                if m then m:GossipComplete() end
            end
        end
        GroupHearth.pending[h.hearther] = nil
        return
    end
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
