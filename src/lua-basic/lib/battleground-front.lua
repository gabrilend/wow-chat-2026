--------------------------------------------------------------------------------
-- battleground-front.lua (issue 629) - bots holding a front, on paper
--
-- For a general audience: in a battleground each side's bots push along
-- one line across the field, the way two armies meet. The line is cut into
-- sections side by side, like the bars of a bar chart, and each section
-- counts the allies in it. A bot coming up to the fight joins the thinnest
-- section; where one section has 3 more than another, 2 allies move over
-- to help. Bots get to the front by roads that fork, and at each fork each
-- bot deals itself the next card from its own shuffled deck of branches
-- (with two branches: a switch flipped each time). Ranged bots that are
-- hit step behind a melee ally; melee bots never run, they give ground by
-- slow steps backwards. Bots that break through stop to heal, and nobody
-- chases far past the enemy's line.
--
-- This file is the whole rule set as plain arithmetic, so it runs with no
-- server: scripts/test-battleground-front checks it, and
-- scripts/generate-battleground-front-gifs draws it. The buddy module's
-- C++ is meant to be ported from it and compared against it, as the
-- roaming core was (scripts/test-buddy-roam-core).
--
-- The front's own frame: every position here is (u, v) in yards, u across
-- the front (0 at its left edge, `width` at its right), v along the push
-- (0 at side "a"'s home, `depth` at side "b"'s). Side a pushes toward +v,
-- side b toward -v. Front.to_world turns (u, v) into map yards through the
-- front's axis (629a), so the same rules run on any battleground.
--
-- The order help goes in (629 question 2) is held behind a switch:
--   opts.help_order = "worst last"   (the design, confirmed 2026-10-18:
--                                      "yes, to create the behavior of
--                                      encirclement. In-universe it's
--                                      justified like thinner lines are
--                                      harder to reinforce.")
--                   = "worst first"  (the most desperate section is
--                                      helped first; kept for comparison)
-- Section counts include only the living (629c question 2, default
-- chosen here and said so; the dead are not on the ground to count).
--------------------------------------------------------------------------------

local Front = {}

-- {{{ tuning
-- Times are in ticks of half a second; distances in yards.
Front.DEFAULTS = {
    tick_seconds      = 0.5,
    width             = 80,     -- yards across the front
    depth             = 120,    -- yards from home to home
    sections          = 5,      -- bars across the width (629c question 1)

    run_per_tick      = 3.5,    -- 7 yards a second, the stock run
    backstep_per_tick = 2.25,   -- 4.5 yards a second, the stock walk backwards
    step_yards        = 2,      -- one running stride ("3-6 steps", 629 question 4)
    join_steps_min    = 3,
    join_steps_max    = 6,

    melee_reach       = 4,
    ranged_reach      = 25,
    ranged_keep       = 20,     -- where a ranged bot likes to stand from its foe
    melee_hit         = 6,      -- health a tick
    ranged_hit        = 4,
    health            = 100,
    regen_per_tick    = 2,      -- out of combat only

    help_every        = 4,      -- ticks between counts (2 seconds)
    help_gap          = 3,      -- "a differential of like, 3"
    help_movers       = 2,      -- "then 2 allies will come to assist"
    help_order        = "worst last",

    chase_limit       = 10,     -- yards past the enemy's line a bot follows a foe
    backstep_depth    = 10,     -- yards behind its own line a melee bot may give
    need_health       = 0.3,    -- share of health under which need is great
    need_outnumbered  = 2,      -- or this many more foes than allies near it
    near              = 10,     -- "near it", for the count above
    shelter_gap       = 4,      -- yards a sheltering bot stands behind its ally

    respawn_every     = 60,     -- graveyard wave, ticks (30 seconds)
    fork_v            = { 12, 28 },  -- where the two levels of forks stand, yards from home
}
-- }}}

-- {{{ function Front.rand
-- A fixed random sequence (a linear congruential generator), so the same
-- seed always gives the same match. Returns a function: r() a number in
-- [0, 1), r(n) a whole number in 1..n.
function Front.rand(seed)
    local s = seed % 2147483647
    if s <= 0 then s = s + 2147483646 end
    return function(n)
        s = (s * 16807) % 2147483647
        local f = (s - 1) / 2147483646
        if n then return math.floor(f * n) + 1 end
        return f
    end
end
-- }}}

-- {{{ function Front.axis
-- A battleground's push axis (629a): the map's north (+y) turned by the
-- battleground's heading, in radians counter-clockwise. Returns the unit
-- vector side "a" pushes along; side "b" pushes the opposite way.
-- Alterac Valley: side a the Alliance at Dun Baldar in the north, so its
-- heading is pi (it pushes south) and the Horde pushes north.
function Front.axis(heading)
    return -math.sin(heading), math.cos(heading)
end
-- }}}

-- {{{ function Front.to_world
-- (u, v) in the front's frame to map yards. front = { ox, oy (side a's
-- home edge, left corner), ax, ay (the push axis, unit) }; across is the
-- axis turned a quarter clockwise, so u grows to side a's right.
function Front.to_world(front, u, v)
    local cx, cy = front.ay, -front.ax          -- across: a quarter turn clockwise
    return front.ox + cx * u + front.ax * v,
           front.oy + cy * u + front.ay * v
end
-- }}}

-- {{{ function Front.borders
-- The fronts between neighbouring objectives (629a). objectives = list of
-- { name, x, y, holder ("a", "b" or nil), neighbours = { names } };
-- opts.border_width yards. A border exists between neighbours not held by
-- the same side: its middle is midway, its axis the unit line from the
-- first to the second, its width given. Each pair once, in list order.
function Front.borders(objectives, border_width)
    local by, out, seen = {}, {}, {}
    for _, o in ipairs(objectives) do by[o.name] = o end
    for _, a in ipairs(objectives) do
        for _, n in ipairs(a.neighbours) do
            local b   = by[n]
            local key = a.name < n and (a.name .. "|" .. n) or (n .. "|" .. a.name)
            if not b then error("objective " .. a.name .. " names neighbour " .. n .. ", which is not in the list") end
            if not seen[key] and not (a.holder and a.holder == b.holder) then
                seen[key] = true
                local dx, dy = b.x - a.x, b.y - a.y
                local len    = math.sqrt(dx * dx + dy * dy)
                table.insert(out, {
                    from = a.name, to = b.name,
                    mx   = (a.x + b.x) / 2, my = (a.y + b.y) / 2,
                    ax   = dx / len,        ay = dy / len,
                    width = border_width,   length = len,
                })
            end
        end
    end
    return out
end
-- }}}

-- {{{ function Front.new_deck
-- A bot's deck at one fork (629b): its branches (1..n) in a shuffled
-- order, dealt one per pass, shuffled again when used up. With two
-- branches it is a switch: which way first is the only draw, then it
-- flips every pass ("we can just flip a switch back and forth").
-- Deck: { n (integer), order (list of branch numbers), next (integer) }.
local function shuffle(order, r)
    for i = #order, 2, -1 do
        local j = r(i)
        order[i], order[j] = order[j], order[i]
    end
end

function Front.new_deck(n, r)
    local order = {}
    for i = 1, n do order[i] = i end
    shuffle(order, r)
    return { n = n, order = order, next = 1 }
end
-- }}}

-- {{{ function Front.deal
-- The next branch from a deck. Two branches: the switch flips (no draw).
-- Three or more: the next card; a used-up deck is shuffled again first.
-- (At a reshuffle the first new card may equal the last old one, which a
-- true deck allows.)
function Front.deal(deck, r)
    if deck.next > deck.n then
        -- two branches keep their order, so the switch goes on flipping
        -- across the refill (a, b, a, b); a reshuffle could deal b, b
        if deck.n ~= 2 then shuffle(deck.order, r) end
        deck.next = 1
    end
    local card = deck.order[deck.next]
    deck.next  = deck.next + 1
    return card
end
-- }}}

-- {{{ function Front.section_of
-- Which section (1..sections) a position across the front falls in.
function Front.section_of(o, u)
    local s = math.floor(u / (o.width / o.sections)) + 1
    if s < 1 then s = 1 elseif s > o.sections then s = o.sections end
    return s
end
-- }}}

-- {{{ function Front.pick_section
-- The section a bot joins (629c): the one with the fewest allies, a tie
-- broken by the nearest to where the bot stands (then the lower number).
function Front.pick_section(o, counts, u)
    local here, best, bestc, bestd = Front.section_of(o, u), nil, math.huge, math.huge
    for s = 1, o.sections do
        local c, d = counts[s] or 0, math.abs(s - here)
        if c < bestc or (c == bestc and d < bestd) then best, bestc, bestd = s, c, d end
    end
    return best
end
-- }}}

-- {{{ function Front.help_moves
-- Where help goes (629c): counts per section in, a list of moves out,
-- each { from = section, to = section }, help_movers of them per needy
-- section served. A section is needy when the fullest holds help_gap more.
-- Needy sections are served one after another, in order of need:
--   "worst last"  least short first, most short last (the default)
--   "worst first" most short first
-- each from the fullest section of the moment, while the gap still holds.
function Front.help_moves(o, counts)
    local c = {}
    for s = 1, o.sections do c[s] = counts[s] or 0 end
    local function fullest()
        local best = 1
        for s = 2, o.sections do if c[s] > c[best] then best = s end end
        return best
    end
    local top, needy = c[fullest()], {}
    for s = 1, o.sections do
        if top - c[s] >= o.help_gap then table.insert(needy, s) end
    end
    local worst_first = o.help_order == "worst first"
    if not worst_first and o.help_order ~= "worst last" then
        error("help_order must be \"worst last\" or \"worst first\", got " .. tostring(o.help_order))
    end
    table.sort(needy, function(x, y)
        if c[x] ~= c[y] then
            if worst_first then return c[x] < c[y] end
            return c[x] > c[y]
        end
        return x < y
    end)
    local moves = {}
    for _, s in ipairs(needy) do
        local from = fullest()
        if c[from] - c[s] >= o.help_gap then
            for _ = 1, o.help_movers do
                table.insert(moves, { from = from, to = s })
                c[from], c[s] = c[from] - 1, c[s] + 1
            end
        end
    end
    return moves, #needy
end
-- }}}

-- {{{ function Front.shelter_spot
-- Where a struck ranged bot stands (629d): on the line from its foe
-- through a melee ally, shelter_gap behind the ally, but no farther from
-- the foe than its reach less a yard, so it can still cast. Returns u, v.
-- If the ally itself stands past that reach, the ranged bot stands at the
-- reach on the same line (still behind the foe-to-ally direction).
function Front.shelter_spot(o, fu, fv, mu, mv)
    local du, dv = mu - fu, mv - fv
    local len    = math.sqrt(du * du + dv * dv)
    if len < 0.01 then du, dv, len = 0, 1, 1 end
    du, dv = du / len, dv / len
    local want = math.min(len + o.shelter_gap, o.ranged_reach - 1)
    return fu + du * want, fv + dv * want
end
-- }}}

-- {{{ function Front.new_match
-- A match on one front. opts override Front.DEFAULTS; opts.per_side bots
-- a side, opts.ranged_share of them ranged, opts.seed. Bots start dead
-- and waiting, so the first wave walks out together.
-- Bot: { id, side ("a"/"b"), role ("melee"/"ranged"), u, v, hp,
--        state ("waiting", "roads", "line", "through", "dead"),
--        section (integer or nil), path (list of {u, v}), at (integer),
--        decks (fork number -> deck), join_yards (number), facing (radians),
--        struck_by (bot or nil, last tick) }
function Front.new_match(opts)
    local o = {}
    for k, val in pairs(Front.DEFAULTS) do o[k] = val end
    for k, val in pairs(opts or {}) do o[k] = val end
    local m = { o = o, r = Front.rand(o.seed or 7), bots = {}, tick = 0,
                stats = { kills = { a = 0, b = 0 }, moves = 0, shelters = 0, backsteps = 0,
                          breakthroughs = 0, joins = 0, deals = 0, crowded_needs = 0 } }
    local id = 0
    for _, side in ipairs({ "a", "b" }) do
        local ranged = math.floor((o.per_side or 15) * (o.ranged_share or 0.4) + 0.5)
        for k = 1, (o.per_side or 15) do
            id = id + 1
            table.insert(m.bots, { id = id, side = side, role = k <= ranged and "ranged" or "melee",
                                   u = o.width / 2, v = side == "a" and 0 or o.depth, hp = 0,
                                   state = "dead", decks = {}, facing = 0 })
        end
    end
    return m
end
-- }}}

-- {{{ function Front.road_path
-- The roads from a side's home to the front (629b), as a fork tree: from
-- the home's middle, a fork at fork_v[1] into the left and right halves,
-- then a fork at fork_v[2] into quarters; three forks a side (1 at the
-- first level, 2 and 3 at the second, left and right). Each fork deals
-- from the bot's own deck there. Returns the path as {u, v} points.
function Front.road_path(m, bot)
    local o, path = m.o, {}
    local function vv(d) return bot.side == "a" and d or o.depth - d end
    local function deal(fork)
        bot.decks[fork] = bot.decks[fork] or Front.new_deck(2, m.r)
        m.stats.deals   = m.stats.deals + 1
        return Front.deal(bot.decks[fork], m.r)
    end
    table.insert(path, { o.width / 2, vv(o.fork_v[1]) })
    local half    = deal(1)                                    -- 1 left, 2 right
    local quarter = deal(half + 1)                             -- fork 2 (left half) or 3 (right half)
    local q       = (half - 1) * 2 + quarter                   -- 1..4 across
    table.insert(path, { o.width * (2 * half - 1) / 4, vv(o.fork_v[2]) })
    table.insert(path, { o.width * (2 * q - 1) / 8,    vv(o.depth / 2) })
    return path
end
-- }}}

-- {{{ local helpers: distances, foes, lines
local function dist(a, b)
    local du, dv = a.u - b.u, a.v - b.v
    return math.sqrt(du * du + dv * dv)
end

local function forward(side) return side == "a" and 1 or -1 end

local function alive(b) return b.state == "roads" or b.state == "line" or b.state == "through" end

local function nearest_foe(m, b)
    local best, bestd = nil, math.huge
    for _, f in ipairs(m.bots) do
        if f.side ~= b.side and alive(f) then
            local d = dist(b, f)
            if d < bestd then best, bestd = f, d end
        end
    end
    return best, bestd
end

-- A side's line: the average v of its living bots on the line (nil if none).
local function line_of(m, side)
    local sum, n = 0, 0
    for _, b in ipairs(m.bots) do
        if b.side == side and b.state == "line" then sum, n = sum + b.v, n + 1 end
    end
    if n == 0 then return nil end
    return sum / n
end

-- The farthest back a side's living bots stand: a foe past this has broken
-- through every one of them.
local function rearmost(m, side)
    local best
    for _, b in ipairs(m.bots) do
        if b.side == side and alive(b) then
            local fwd = b.v * forward(side)
            if not best or fwd < best then best = fwd end
        end
    end
    return best and best * forward(side)
end

local function step_toward(b, tu, tv, per_tick)
    local du, dv = tu - b.u, tv - b.v
    local len    = math.sqrt(du * du + dv * dv)
    if len <= per_tick then b.u, b.v = tu, tv return len end
    b.u, b.v = b.u + du / len * per_tick, b.v + dv / len * per_tick
    return per_tick
end

function Front.counts(m, side)
    local c = {}
    for s = 1, m.o.sections do c[s] = 0 end
    for _, b in ipairs(m.bots) do
        if b.side == side and b.state == "line" and b.section then c[b.section] = c[b.section] + 1 end
    end
    return c
end
-- }}}

-- {{{ function Front.tick
-- One half-second of the match, in order: the graveyard wave; each living
-- bot moves or fights (bots in id order, so a match repeats exactly); the
-- dead are counted; every help_every ticks, help is sent.
function Front.tick(m)
    local o, r = m.o, m.r
    m.tick = m.tick + 1

    -- the wave: every dead bot rises at home and takes the roads
    if m.tick % o.respawn_every == 1 then
        for _, b in ipairs(m.bots) do
            if b.state == "dead" then
                b.state, b.hp, b.section, b.broke = "roads", o.health, nil, false
                b.u, b.v = o.width / 2, b.side == "a" and 0 or o.depth
                b.path, b.at = Front.road_path(m, b), 1
                b.join_yards = (o.join_steps_min + r(o.join_steps_max - o.join_steps_min + 1) - 1) * o.step_yards
            end
        end
    end

    -- slots: each section's bots on the line, in id order, spread evenly
    -- across the section's width (slot[bot] = its u)
    local slot, members = {}, {}
    for _, b in ipairs(m.bots) do
        if b.state == "line" and b.section then
            local key = b.side .. b.section
            members[key] = members[key] or {}
            table.insert(members[key], b)
        end
    end
    for _, list in pairs(members) do
        local sw = o.width / o.sections
        for k, b in ipairs(list) do slot[b] = (b.section - 1) * sw + (k - 0.5) * sw / #list end
    end

    local struck = {}
    for _, b in ipairs(m.bots) do
        if alive(b) then
            local foe, fd = nearest_foe(m, b)
            local reach   = b.role == "melee" and o.melee_reach or o.ranged_reach
            local fwd     = forward(b.side)

            -- facing: toward the foe, or along the push with none
            if foe then b.facing = math.atan2(foe.v - b.v, foe.u - b.u)
            else        b.facing = math.atan2(fwd, 0) end

            -- on the roads: walk the path; join the line when the fight is
            -- join_yards away (3-6 steps from facing the foe), or at the end
            if b.state == "roads" then
                local p = b.path[b.at]
                if foe and fd - reach <= b.join_yards then
                    b.state, b.section = "line", Front.pick_section(o, Front.counts(m, b.side), b.u)
                    m.stats.joins = m.stats.joins + 1
                elseif p then
                    if step_toward(b, p[1], p[2], o.run_per_tick) < o.run_per_tick then b.at = b.at + 1 end
                else
                    b.state, b.section = "line", Front.pick_section(o, Front.counts(m, b.side), b.u)
                    m.stats.joins = m.stats.joins + 1
                end
            end

            -- broken through: past every living foe. Hurt, it stops to heal
            -- (counted once a life); whole, it fights on from where it is
            -- (the chase limit below walks it back toward its own line)
            if b.state == "line" then
                local enemy_rear = rearmost(m, b.side == "a" and "b" or "a")
                if enemy_rear and (b.v - enemy_rear) * fwd > o.melee_reach then
                    if not b.broke then
                        b.broke = true
                        m.stats.breakthroughs = m.stats.breakthroughs + 1
                    end
                    if b.hp < o.health then b.state = "through" end
                end
            end
            if b.state == "through" then
                if b.hp < o.health and not (foe and fd <= o.melee_reach) then
                    b.hp = math.min(o.health, b.hp + o.regen_per_tick)
                else
                    b.state = "line"           -- healed (or caught): back to the fight where it stands
                    b.section = Front.section_of(o, b.u)
                end
            end

            if b.state == "line" then
                local own  = line_of(m, b.side) or b.v
                local need = false
                if b.role == "melee" and foe then
                    local foes, friends = 0, 0
                    for _, x in ipairs(m.bots) do
                        if alive(x) and dist(x, b) <= o.near then
                            if x.side == b.side then friends = friends + 1 else foes = foes + 1 end
                        end
                    end
                    need = b.hp < o.health * o.need_health or foes >= friends + o.need_outnumbered
                end

                if foe and fd <= reach then
                    -- in reach: strike; a melee bot in great need also backsteps
                    struck[foe] = struck[foe] or b
                    foe.hp = foe.hp - (b.role == "melee" and o.melee_hit or o.ranged_hit)
                    if need and (own - b.v) * fwd < o.backstep_depth then
                        b.v = b.v - fwd * o.backstep_per_tick
                        m.stats.backsteps = m.stats.backsteps + 1
                    end
                    if b.role == "ranged" and fd < o.ranged_keep - 2 and not b.struck_by then
                        step_toward(b, b.u, b.v - fwd * o.run_per_tick, o.run_per_tick)
                    end
                elseif need and (own - b.v) * fwd < o.backstep_depth then
                    b.v = b.v - fwd * o.backstep_per_tick
                    m.stats.backsteps = m.stats.backsteps + 1
                else
                    -- close in, keeping its own place across the section
                    -- (its slot) so a section is a stretch of line, not a
                    -- knot; only for the last few yards does it turn
                    -- aside to the foe. Never farther than chase_limit
                    -- past its own line.
                    local sw   = o.width / o.sections
                    local tu   = slot[b] or (b.section - 0.5) * sw
                    local tv   = b.v + fwd * o.run_per_tick
                    if foe and math.abs(foe.u - tu) <= sw then
                        tv = foe.v - fwd * (reach - 1)
                        if math.abs(foe.v - b.v) < reach + 4 then tu = foe.u end
                    end
                    -- the chase limit is measured from the enemy's line, not
                    -- its own: closing with the enemy line is the fight; it
                    -- is following a foe deep behind that line that stops.
                    -- (First written from its own line, 2026-10-17: own line
                    -- is an average that includes the ranged standing 20
                    -- yards back, so melee could never reach the enemy and
                    -- the two lines stood 45 yards apart.)
                    local enemy_line = line_of(m, b.side == "a" and "b" or "a")
                    if enemy_line and (tv - enemy_line) * fwd > o.chase_limit then tv = enemy_line + fwd * o.chase_limit end
                    local v0 = b.v
                    step_toward(b, tu, tv, o.run_per_tick)
                    -- melee never runs back: any ground it gives (pulled
                    -- back by the chase limit, or turning to a foe that
                    -- got past) is given at backstep speed
                    if b.role == "melee" and (v0 - b.v) * fwd > o.backstep_per_tick then
                        b.v = v0 - fwd * o.backstep_per_tick
                    end
                end

                -- regeneration out of combat
                if not foe or fd > o.ranged_reach then b.hp = math.min(o.health, b.hp + o.regen_per_tick) end
            end
            -- the field's edges: a line backstepping onto its home edge
            -- stops there (its graveyard) and fights to the last
            if b.u < 0 then b.u = 0 elseif b.u > o.width then b.u = o.width end
            if b.v < 0 then b.v = 0 elseif b.v > o.depth then b.v = o.depth end
        end
    end

    -- struck ranged bots take shelter behind the nearest melee ally
    for _, b in ipairs(m.bots) do
        b.struck_by = struck[b]
        if b.struck_by and b.role == "ranged" and b.state == "line" and b.hp > 0 then
            local best, bestd = nil, math.huge
            for _, x in ipairs(m.bots) do
                if x.side == b.side and x.role == "melee" and x.state == "line" then
                    local d = dist(x, b)
                    if d < bestd then best, bestd = x, d end
                end
            end
            if best then
                local su, sv = Front.shelter_spot(o, b.struck_by.u, b.struck_by.v, best.u, best.v)
                step_toward(b, su, sv, o.run_per_tick)
                m.stats.shelters = m.stats.shelters + 1
            end
        end
    end

    -- the fallen
    for _, b in ipairs(m.bots) do
        if alive(b) and b.hp <= 0 then
            b.state, b.section, b.hp = "dead", nil, 0
            local killer = b.side == "a" and "b" or "a"
            m.stats.kills[killer] = m.stats.kills[killer] + 1
        end
    end

    -- help where the line is uneven: the movers nearest the needy section
    if m.tick % o.help_every == 0 then
        for _, side in ipairs({ "a", "b" }) do
            -- crowded_needs counts the times two or more sections were
            -- short at once: only then does help_order change anything
            local moves, needy = Front.help_moves(o, Front.counts(m, side))
            if needy >= 2 then m.stats.crowded_needs = m.stats.crowded_needs + 1 end
            for _, mv in ipairs(moves) do
                local best, bestd = nil, math.huge
                for _, b in ipairs(m.bots) do
                    if b.side == side and b.state == "line" and b.section == mv.from then
                        local d = math.abs(b.u - (mv.to - 0.5) * o.width / o.sections)
                        if d < bestd then best, bestd = b, d end
                    end
                end
                if best then best.section = mv.to; m.stats.moves = m.stats.moves + 1 end
            end
        end
    end
end
-- }}}

-- {{{ function Front.line_positions
-- Each side's line (average v of its bots on the line), for reports.
function Front.line_positions(m)
    return line_of(m, "a"), line_of(m, "b")
end
-- }}}

return Front
