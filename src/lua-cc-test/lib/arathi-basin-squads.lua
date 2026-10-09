--------------------------------------------------------------------------------
-- arathi-basin-squads.lua (issues 176a2a, 176a2b) - who goes out together,
-- where the dead come back, and how players take stand-ins' places
--
-- For a general audience: Arathi Basin's stand-ins fight in small squads.
-- This holds the rules that decide squads, without any creature in them:
--
--   grouping     those coming back together form trios of two damage and a
--                healer when they divide evenly that way, else go as one
--                group (owner, 2026-10-08)
--   the river    one climbing out of the river joins the first group it
--                meets; a merged group of four damage and two healers
--                splits into two trios
--   departures   every 12 seconds the dead come back as a group at one
--                place: a base the side fully holds, drawn at random, or
--                home; invisible and still until the next graveyard wave
--                (every 30 seconds), then active; one waiting group a
--                place, except home, where groups stack; a base lost
--                while they wait sends them home; tanks (one per capture)
--                wait at home for a departure and never leave alone
--   places       players and stand-ins share a side's places: a player
--                joining takes the place of the next stand-in to die
--
-- Where the owner's answers left a choice open, each reading is built and
-- picked by an option (the report compares them):
--   opts.claimed    "assault" | "capture"   (176a2b question 8: a waiting
--                   group is sent home when the enemy clicks its base's
--                   banner, or only when the enemy fully captures it)
--   opts.tanks      "home only" | "any group" (question 9: a tank leaves
--                   only with a group appearing at home, or is placed with
--                   whichever group comes back this departure)
--   opts.places     15 | 30                  (176a2a question 5: the
--                   stock side, or doubled as 617t's battlegrounds)
--
-- A unit is { id = string, role = "damage" | "healer" | "tank" }. A side's
-- state is plain tables; the random draw takes a function returning
-- 1..n, so a test can fix it.
--------------------------------------------------------------------------------

local Squads = {}

Squads.DEPARTURE_EVERY = 12                         -- seconds between departures ("a party every 12 seconds or so")
Squads.WAVE_EVERY      = 30                         -- seconds between graveyard waves (stock Arathi Basin spirit healers)
Squads.DEFAULTS        = { claimed = "assault", tanks = "home only", places = 15 }

local function opt(opts, key)
    local v = (opts or {})[key]
    if v == nil then v = Squads.DEFAULTS[key] end
    return v
end

-- {{{ function Squads.group
-- Units coming back together, as squads: trios of two damage and a healer
-- when the damage and healers divide exactly so (twice as many damage as
-- healers), else all of them as one group. Tanks are not counted here:
-- they join at departure (Squads.depart).
function Squads.group(units)
    local damage, healers = {}, {}
    for _, u in ipairs(units) do
        if u.role == "damage" then damage[#damage + 1] = u elseif u.role == "healer" then healers[#healers + 1] = u end
    end
    if #healers > 0 and #damage == 2 * #healers then
        local squads = {}
        for k = 1, #healers do squads[k] = { damage[2 * k - 1], damage[2 * k], healers[k] } end
        return squads
    end
    if #units == 0 then return {} end
    local one = {}
    for _, u in ipairs(units) do one[#one + 1] = u end
    return { one }
end
-- }}}

-- {{{ function Squads.merge
-- One climbing out of the river (or any lone group) joins the first group
-- it meets: the two become one; six of them that make two trios' worth
-- (four damage, two healers, nothing else) split into two trios.
function Squads.merge(a, b)
    local all = {}
    for _, u in ipairs(a) do all[#all + 1] = u end
    for _, u in ipairs(b) do all[#all + 1] = u end
    local d, h, other = 0, 0, 0
    for _, u in ipairs(all) do
        if u.role == "damage" then d = d + 1 elseif u.role == "healer" then h = h + 1 else other = other + 1 end
    end
    if #all == 6 and d == 4 and h == 2 and other == 0 then return Squads.group(all) end
    return { all }
end
-- }}}

-- {{{ function Squads.new_side
-- A side's squad state for one match: its home, the dead waiting to come
-- back (the pool), groups placed and waiting for the wave, tanks waiting
-- at home, and how many places players hold.
function Squads.new_side(home, opts)
    return { home = home, opts = opts or {}, pool = {}, waiting = {}, tanks = {}, players = 0, stand_ins = 0, held_out = 0 }
end
-- }}}

-- {{{ events: deaths, captures, players
-- A stand-in died: it goes to the pool, or, if a player is owed a place,
-- it is held out of the battle instead.
function Squads.died(side, unit)
    if side.held_out < side.players and side.stand_ins + side.players > opt(side.opts, "places") then
        side.held_out = side.held_out + 1
        side.stand_ins = side.stand_ins - 1
        return "held out"
    end
    side.pool[#side.pool + 1] = unit
    return "pool"
end

-- The side fully captured a base: a tank waits at home.
function Squads.captured(side, tank)
    side.tanks[#side.tanks + 1] = tank
end

-- A player joined or left the side.
function Squads.player_joined(side) side.players = side.players + 1 end
function Squads.player_left(side)
    side.players = math.max(0, side.players - 1)
    if side.held_out > 0 then side.held_out = side.held_out - 1; side.stand_ins = side.stand_ins + 1; return "a stand-in may come back" end
end

-- Something happened to a base where a group waits. Under "assault" a
-- banner click by the enemy sends the group home; under "capture" only
-- the enemy's full capture does. Returns how many groups were moved.
function Squads.base_event(side, base, what)
    local trigger = opt(side.opts, "claimed")
    if not ((what == "assaulted" and trigger == "assault") or what == "captured") then return 0 end
    local moved = 0
    for _, w in ipairs(side.waiting) do
        if w.place == base then w.place = side.home; w.moved_home = true; moved = moved + 1 end
    end
    return moved
end
-- }}}

-- {{{ function Squads.choose_place
-- Where a group coming back appears: a base the side fully holds (held and
-- not under attack) with no group already waiting there, drawn at random;
-- else home, where groups may stack. `held` = list of base names the side
-- fully holds; `draw(n)` returns 1..n.
function Squads.choose_place(side, held, draw)
    local taken = {}
    for _, w in ipairs(side.waiting) do taken[w.place] = true end
    local free = {}
    for _, b in ipairs(held or {}) do if not taken[b] then free[#free + 1] = b end end
    table.sort(free)
    -- the draw: home is one of the choices ("a random fully controlled
    -- base or the home base"), so it can be drawn even with bases free
    local choices = { side.home }
    for _, b in ipairs(free) do choices[#choices + 1] = b end
    local pick = draw and draw(#choices) or 1
    if type(pick) ~= "number" or pick < 1 or pick > #choices then return side.home, "fallback: a bad draw" end
    return choices[pick]
end
-- }}}

-- {{{ function Squads.depart
-- A departure (every 12 seconds): the pool comes back as groups (one place
-- each), placed and waiting for the next wave; tanks at home go with a
-- group placed at home ("home only") or with the first group placed at
-- all ("any group"); with no group to go with, they wait. Returns the
-- groups placed this departure: { { place, units } }.
function Squads.depart(side, held, draw)
    local placed = {}
    local groups = Squads.group(side.pool)
    side.pool = {}
    for _, g in ipairs(groups) do
        local place = Squads.choose_place(side, held, draw)
        local w = { place = place, units = g }
        side.waiting[#side.waiting + 1] = w
        placed[#placed + 1] = w
    end
    if #side.tanks > 0 then
        local carrier
        for _, w in ipairs(placed) do
            if opt(side.opts, "tanks") == "any group" or w.place == side.home then carrier = w; break end
        end
        if carrier then
            for _, t in ipairs(side.tanks) do carrier.units[#carrier.units + 1] = t end
            side.tanks = {}
        end
    end
    return placed
end
-- }}}

-- {{{ function Squads.wave
-- The graveyard wave: every waiting group appears and acts. Returns them.
function Squads.wave(side)
    local out = side.waiting
    side.waiting = {}
    return out
end
-- }}}

return Squads
