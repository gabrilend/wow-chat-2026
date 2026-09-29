--------------------------------------------------------------------------------
-- buddy-roam.lua (issue 617e)
--
-- Where a roaming buddy steps next, inside its owner's named area (the place
-- whose name shows on screen, e.g. Fargodeep Mine). Pure decisions on plain
-- numbers, no server calls: the server script will run it on real positions,
-- and scripts/generate-buddy-roaming-gifs runs it on a drawn map to make
-- the animations the design is being settled with.
--
-- The owner's words (2026-09-27): buddies "wander throughout the zone
-- pseudo-randomly, trying to distance themselves so that they're in roughly
-- the same distance from one another. Whether that's close or far, doesn't
-- matter, they just try and congregate at a certain distance. Then, they
-- pinwheel around the center of the zone. a random direction is chosen for
-- each of them, and they each have their own separate 'far enough away from
-- these buddy-bots' lists, one for each direction."
--
-- Every tick, each buddy looks at a ring of candidate steps (and standing
-- still), throws out the ones that leave the area or walk into a wall, and
-- takes the best-scoring one. What "best" means is the part still being
-- designed, so three readings of the owner's words are kept side by side
-- (param `reading`):
--
--   "far-lists"  one "far enough" list per candidate step: the buddies it
--                would be at least the spacing away from after that step.
--                Prefer the step that gets closest to having every other
--                buddy on its list (scored by distance, so each yard gained
--                counts), then the one that turns with its pinwheel
--                direction, then the one keeping its nearest neighbour
--                closest to the spacing.
--   "spring"     no lists: each buddy is pulled toward the spacing distance
--                from its nearest neighbour (pushed if closer, pulled if
--                farther), plus its pinwheel turn.
--   "spin-lists" one list per pinwheel direction (clockwise, counter-
--                clockwise): the buddies it would stay far enough from by
--                circling that way for a while. It circles the way whose
--                list is longer, and may switch.
--   "waypoints"  the owner's own suggestion (2026-09-27), replacing the
--                spacing: "when choosing a new waypoint for the pinwheel,
--                pick a position at the desired rotation, but it's distance
--                from the center of the area should be fully randomized.
--                And they don't pick a new rotation until they reach it."
--                Each waypoint is the last one's bearing from the centre
--                turned by a fixed step in the buddy's direction, at a
--                random share of the way to the edge, 3 yards clear of
--                rocks and the edge. A buddy near the centre laps quickly;
--                one sent to 65% spends a while walking out. No spacing:
--                buddies may cross and bunch.
--   "waypoints" with `avoid` > 0: the blend the owner allowed for ("we
--                might want some combination of these behaviors"): the
--                same waypoints, but of up to 8 random spots on the
--                bearing the first at least `avoid` yards from every other
--                buddy's waypoint is taken (else the roomiest), so spacing
--                is kept between destinations rather than step by step.
--------------------------------------------------------------------------------

local Roam = {}

-- {{{ local function inside_polygon
-- Ray casting: is the point inside the area's outline (a list of {x, y})?
local function inside_polygon(poly, x, y)
    local inside, j = false, #poly
    for i = 1, #poly do
        local xi, yi, xj, yj = poly[i][1], poly[i][2], poly[j][1], poly[j][2]
        if (yi > y) ~= (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi then
            inside = not inside
        end
        j = i
    end
    return inside
end
-- }}}

-- {{{ local function inside_rects
-- An area may be given as a union of rectangles (area.rects, each
-- { x0, y0, x1, y1 }) instead of one outline: rooms joined by corridors,
-- where a loop (two corridors round a block of rock) needs a hole that a
-- single outline can't have (2026-09-27, the big dungeon arena). Only the
-- painting grid reads such areas (Roam.paint_grid); the pinwheel readings
-- need an outline.
local function inside_rects(rects, x, y)
    for _, r in ipairs(rects) do
        if x >= r[1] and x <= r[3] and y >= r[2] and y <= r[4] then return true end
    end
    return false
end
-- }}}

-- {{{ function Roam.walkable
-- Inside the area and clear of every wall (walls are circles {x, y, r};
-- a buddy keeps `margin` yards off them).
--   an outline area: inside its polygon
--   a rectangles area (area.rects): inside any of its rectangles
function Roam.walkable(area, x, y, margin)
    if area.rects then
        if not inside_rects(area.rects, x, y) then return false end
    elseif not inside_polygon(area.outline, x, y) then return false end
    for _, w in ipairs(area.walls) do
        local dx, dy = x - w[1], y - w[2]
        if dx * dx + dy * dy < (w[3] + margin) ^ 2 then return false end
    end
    return true
end
-- }}}

-- {{{ function Roam.edge_distance
-- Yards from (x, y) to the nearest side of the area's outline.
function Roam.edge_distance(area, x, y)
    local best, o = math.huge, area.outline
    for i = 1, #o do
        local j = i % #o + 1
        local ax, ay, bx, by = o[i][1], o[i][2], o[j][1], o[j][2]
        local vx, vy = bx - ax, by - ay
        local t = ((x - ax) * vx + (y - ay) * vy) / (vx * vx + vy * vy)
        t = math.max(0, math.min(1, t))
        local d = math.sqrt((ax + vx * t - x) ^ 2 + (ay + vy * t - y) ^ 2)
        if d < best then best = d end
    end
    return best
end
-- }}}

-- {{{ function Roam.centre
-- The area's centre: the average of its outline's corners.
function Roam.centre(area)
    -- a map may name its centre (a chamber with a side tunnel: the corners'
    -- average would sit near the tunnel's mouth, not in the chamber)
    if area.centre then return area.centre[1], area.centre[2] end
    local sx, sy = 0, 0
    for _, p in ipairs(area.outline) do sx, sy = sx + p[1], sy + p[2] end
    return sx / #area.outline, sy / #area.outline
end
-- }}}

-- {{{ function Roam.default_spacing
-- A spacing that spreads n buddies evenly over the area: 0.6 of the side of
-- the square each would get if the area were shared out. The whole side
-- was tried first (2026-09-27, in the animations): it can't be met
-- everywhere at once, so the best-scoring places were the area's edges and
-- the buddies pinned themselves there in pairs. (The owner: "whether that's
-- close or far, doesn't matter", so this is only a starting value.)
local SPACING_SHARE = 0.6
function Roam.default_spacing(area, n)
    local a = 0
    local o = area.outline
    for i = 1, #o do
        local j = i % #o + 1
        a = a + o[i][1] * o[j][2] - o[j][1] * o[i][2]
    end
    return SPACING_SHARE * math.sqrt(math.abs(a) / 2 / math.max(n, 1))
end
-- }}}

-- {{{ local function nearest
local function nearest(buddies, me, x, y)
    local best = math.huge
    for _, b in ipairs(buddies) do
        if b ~= me then
            local d = math.sqrt((b.x - x) ^ 2 + (b.y - y) ^ 2)
            if d < best then best = d end
        end
    end
    return best
end
-- }}}

-- {{{ local function far_list
-- The buddies that would be at least `spacing` away from (x, y).
local function far_list(buddies, me, x, y, spacing)
    local list = {}
    for _, b in ipairs(buddies) do
        if b ~= me and (b.x - x) ^ 2 + (b.y - y) ^ 2 >= spacing * spacing then list[#list + 1] = b.id end
    end
    return list
end
-- }}}

-- {{{ local function far_fill
-- How far toward "far enough" a step gets, 0..1: each other buddy counts
-- its distance over the spacing, capped at 1, averaged. The list itself is
-- all-or-nothing, so a buddy deep inside a cluster sees every small step
-- give the same empty list and has no way out (found 2026-09-27 in the
-- animations: they lined up along the edges); this measure rises with
-- every yard gained, and equals the list's share once all are far enough.
local function far_fill(buddies, me, x, y, spacing)
    local sum, n = 0, 0
    for _, b in ipairs(buddies) do
        if b ~= me then
            sum = sum + math.min(math.sqrt((b.x - x) ^ 2 + (b.y - y) ^ 2) / spacing, 1)
            n = n + 1
        end
    end
    return n > 0 and sum / n or 1
end
-- }}}

-- {{{ local function tangent
-- The unit direction of circling the centre at (x, y): spin 1 counter-
-- clockwise, -1 clockwise.
local function tangent(cx, cy, x, y, spin)
    local rx, ry = x - cx, y - cy
    local len = math.sqrt(rx * rx + ry * ry)
    if len < 1e-6 then return 0, 0 end
    return -ry / len * spin, rx / len * spin
end
-- }}}

-- {{{ function Roam.new
-- A roaming state: the area, its buddies ({ id, x, y }), and parameters:
--   reading  "far-lists" | "spring" | "spin-lists" | "waypoints"
--   spacing  yards (default Roam.default_spacing)
--   step     yards walked per tick
--   headings candidate directions per tick
--   margin   yards kept off walls
--   noise    0..1, how much a random nudge weighs ("pseudo-randomly")
--   edge     yards from the area's edge where a buddy starts being
--            pushed back in (so the circling happens inside the area,
--            not along its rim)
-- and for "waypoints" only:
--   turn      radians the bearing turns per waypoint (default 40 degrees,
--             nine waypoints a lap)
--   clearance yards a waypoint keeps off rocks and the edge (the owner:
--             "it can't go within 5 yards of a wall. Maybe 2 yards. or 3.";
--             default 3)
--   avoid     yards a waypoint keeps off other buddies' waypoints; 0 (the
--             default) is the pure reading, more is the blend
--   y_limit   how far the next waypoint's distance from the centre (the
--             owner's "Y"; the bearing round it is "X") may move from the
--             last one's, as a share of the way to the edge. 0 (default):
--             no limit, any share. The owner (2026-09-27): "next pick's Y
--             value can't be more than + or - 30% of the previous Y value".
--   y_mode    how that limit is read:
--               "points" the next share is within last share +- y_limit
--                        (0.3: from 0.5, anywhere 0.2..0.8)
--               "ratio"  within last share x (1 +- y_limit) (0.3: from 0.5,
--                        0.35..0.65), never under y_floor. The literal
--                        wording; multiplying by a factor that averages 1
--                        still shrinks on average (0.7 x 1.3 = 0.91) and
--                        the edge caps the upside, so without a floor every
--                        buddy ends at the centre (measured 2026-09-27: all
--                        of a long run inside the inner fifth; with a 0.1
--                        floor, half of it).
--               "step"   the owner's rule: Y as a percent 1..100, moved
--                        in or out at even odds by a whole number of
--                        points from y_min to y_limit (1..20)
--   y_floor   "ratio" only: the smallest share (default 0.1)
--   y_min     "step" only: the smallest change, in points (default 1)
--   near      yards: no waypoint closer to the centre than this ("minimum
--             10 yards from the center"; default 0, set 10 with "step")
--   pierce    "step" only, percent: after two inward rolls in a row, a Y
--             at or under this sends the buddy through the middle to the
--             far side and reverses its direction (the owner, 2026-09-27:
--             "pierce through the center and reverse their orientation [...]
--             To make an S shape, or a figure 8"). 0 (default): never
--   mobs      monsters, { {x, y, r, alive = true}, ... } with r their aggro
--             radius against the buddy; a trip whose line passes within
--             lure_reach yards outside a living monster's radius bends to
--             pass lure_depth of the way inside it (the owner, 2026-09-27:
--             "move the tangent line between them and the mob's aggro radius
--             somewhere interior to the radius [...] ensuring that the
--             monsters will notice and attack"). Empty (default): none
--   openings  yards: when the line from the centre half a step either side
--             runs this much farther than the bearing's own, this waypoint
--             takes the middle of that opening (find_opening). 0 (default):
--             never
--   crowd     "step" only, yards: when a new waypoint lands this close to
--             another buddy or a player (s.others, { {x, y}, ... }), its Y
--             moves crowd_shift points (default 10) toward the middle of
--             the way out, 50 (the owner, 2026-09-27: "we shouldn't place a
--             waypoint within 5 yards of another player or buddybot - if we
--             do, then the next waypoint should be +10% or -10%, whichever
--             one is closer to the midpoint"). 0 (default): no check
--   body      yards wide (0: walk straight at the waypoint, steering round
--             rocks); more plans each trip with the path planner, testing
--             the ground every `body` yards. A buddy's own b.body overrides
--             it (a tauren's 1.95, a human's 0.61: twice the server's
--             creature_model_info bounding radius for the race's model)
--   orbit     yards to keep between a buddy's path and an obstacle it walks
--             round (0: none, the old walk that slides along the rock's
--             edge). The owner: "if there's an object in the way, we should
--             try and orbit instead of running up right against it".
--   look      yards ahead an obstacle is noticed (default 15)
-- Each buddy draws its pinwheel direction at random ("a random direction is
-- chosen for each of them").
function Roam.new(area, buddies, params, rand)
    local s = {
        area = area, buddies = buddies,
        reading  = params.reading  or "far-lists",
        spacing  = params.spacing  or Roam.default_spacing(area, #buddies),
        step     = params.step     or 1.5,
        headings = params.headings or 12,
        margin   = params.margin   or 1.5,
        noise    = params.noise    or 0.15,
        edge     = params.edge     or 12,
        turn      = params.turn      or math.rad(40),
        clearance = params.clearance or 3,
        avoid     = params.avoid     or 0,
        y_limit   = params.y_limit   or 0,
        y_mode    = params.y_mode    or "points",
        y_floor   = params.y_floor   or 0.1,
        y_min     = params.y_min     or 1,
        near      = params.near      or 0,
        crowd     = params.crowd     or 0,
        openings  = params.openings  or 0,
        pierce    = params.pierce    or 0,
        mobs      = params.mobs      or {},
        lure_reach = params.lure_reach or 25,
        lure_depth = params.lure_depth or 0.7,
        crowd_shift = params.crowd_shift or 10,
        others    = params.others    or {},
        body      = params.body      or 0,
        orbit     = params.orbit     or 0,
        look      = params.look      or 15,
    }
    s.cx, s.cy = Roam.centre(area)
    for _, b in ipairs(buddies) do b.spin = b.spin or (rand() < 0.5 and 1 or -1) end
    -- waypoints: start from the bearing the buddy stands on, so its first
    -- waypoint is one turn round from where it is (picked on its first tick)
    if s.reading == "waypoints" or s.reading == "paint" then
        for _, b in ipairs(buddies) do b.angle = math.atan2(b.y - s.cy, b.x - s.cx) end
    end
    -- paint: the clan's grid and the choosing (only the "paint" reading)
    if s.reading == "paint" then
        s.grid        = params.grid
        s.paint_mode  = params.paint_mode or "choose"
        s.entrance    = params.entrance
        s.wall_paint  = params.wall_paint ~= false
        s.paint_every = params.paint_every or 4
        s.wall_every  = params.wall_every or 48            -- 3 seconds at 16 ticks a second
        s.far_weight  = params.far_weight or 0.3
        s.path_weight = params.path_weight or 3
        s.stats       = { ticks = 0, near_wall = 0, entries = 0, revisits = 0, tunnel_ticks = 0, tunnel_off = 0 }
        local far = 0
        for _, i in ipairs(s.grid.open_list) do
            local x, y = Roam.paint_cell_xy(s.grid, i)
            far = math.max(far, math.sqrt((x - s.entrance[1]) ^ 2 + (y - s.entrance[2]) ^ 2))
        end
        s.far_ref = far
        if s.paint_mode == "disc" then
            for _, b in ipairs(buddies) do
                local i = Roam.paint_cell_of(s.grid, b.x, b.y)
                local u, v = s.grid.du[i] or 0, s.grid.dv[i] or 0
                b.dang, b.dshare = math.atan2(v, u), math.max(0.01, math.min(1, math.sqrt(u * u + v * v)))
            end
        end
    end
    return s
end
-- }}}

-- {{{ local function keep_at
-- 0 when the nearest other buddy is exactly the spacing away, falling off
-- either way: the "congregate at a certain distance" pull.
local function keep_at(s, b, x, y)
    local nn = nearest(s.buddies, b, x, y)
    return -math.min(math.abs(nn - s.spacing) / s.spacing, 2)
end
-- }}}

-- {{{ local function score
-- How good a candidate step (to x, y, heading dx, dy) is for buddy b.
-- base = { fill, keep } where b stands now. The spacing terms are scored as
-- the improvement over standing still, scaled by spacing / step, so a step
-- straight out of a crowd is worth about 1 whatever the step length; scored
-- raw, one small step changed them by a few hundredths and the random
-- nudge drowned them (found 2026-09-27 in the animations). Once everyone
-- is far enough the improvement is 0 and the circling decides.
-- Returns the score and the step's "far enough" list (the drawing shows it).
local function score(s, b, x, y, dx, dy, rand, base)
    local list = far_list(s.buddies, b, x, y, s.spacing)
    local gain = s.spacing / s.step
    local tx, ty = tangent(s.cx, s.cy, b.x, b.y, b.spin)
    local turn = dx * tx + dy * ty                          -- -1..1: with the pinwheel
    local keep = (keep_at(s, b, x, y) - base.keep) * gain
    local fill = (far_fill(s.buddies, b, x, y, s.spacing) - base.fill) * gain
    local nudge = (rand() - 0.5) * 2 * s.noise
    local ed = Roam.edge_distance(s.area, x, y)
    local rim = ed < s.edge and -(1 - ed / s.edge) or 0      -- -1 at the edge .. 0 inside
    local wall = 1.2 * rim

    if s.reading == "spring" then
        return 1.0 * keep + 0.5 * turn + wall + nudge, list
    end
    -- far-lists (and spin-lists, which differ in how the spin is chosen)
    return 1.5 * fill + 0.5 * turn + 0.3 * keep + wall + nudge, list
end
-- }}}

-- {{{ local function choose_spin
-- spin-lists: compare the "far enough" list a buddy would keep by circling
-- each way (looking a few steps ahead) and circle the way whose list is
-- longer; a tie keeps the current way.
local function choose_spin(s, b)
    local best, best_n
    for _, spin in ipairs({ b.spin, -b.spin }) do
        local x, y = b.x, b.y
        for _ = 1, 4 do
            local tx, ty = tangent(s.cx, s.cy, x, y, spin)
            x, y = x + tx * s.step, y + ty * s.step
        end
        local n = #far_list(s.buddies, b, x, y, s.spacing)
        if not best_n or n > best_n then best, best_n = spin, n end
    end
    b.spin_lists = best_n
    return best
end
-- }}}

-- {{{ the path planner
-- The owner's walk to a waypoint (2026-09-27): "pick a waypoint, and then
-- draw a line to it. Then, create imaginary waypoints at N percentage toward
-- the target, based on the character's size [...] if a character is 1 yard
-- wide, then a path to a place 45 yards away will have 45 test waypoints
-- [...] Then, we test the height differential. If we need to orbit for some
-- reason, we'll create a sine wave projection or something that curves
-- around it and normalizes to a straight line at the peak of the curve
-- around the object. Then, we should try and find the gentlest path down a
-- slope, or the flattest path up a hill. [...] If it's flagged as a 'road'
-- material, then we should prefer it as well."
--
-- The ground is two functions of (x, y) on the area (in game: the server's
-- height lookup, and a road grid we would have to extract ourselves, 617e):
--   area.height(x, y) -> yards up
--   area.road(x, y)   -> true on a road
-- A path is a base curve from A to B (the straight line, or a gentle bow to
-- either side: the "gentlest slope" candidates) plus detours, each a bump
-- off to one side over a stretch of the curve.

local PLAN = {
    STEP_RISE  = 0.6,   -- yards: a rise (or drop) between neighbouring test
                        -- points this much sharper than the slope around it
                        -- is an obstacle (a crate, a rock, a ledge); a hill's
                        -- steady rise is not
    BOWS       = { 0, -0.15, 0.15, -0.3, 0.3 }, -- bow height, share of the trip
    SLOPE_W    = 6,     -- cost per yard of grade squared (1: 45 degrees)
    ROAD_F     = 0.6,   -- a yard of road costs this much of a yard off-road
    MAX_DETOUR = 8,     -- detours per candidate before it is given up
    MAX_SIDE   = 16,    -- yards a detour may bulge before that side is given up
    RAMP_MIN   = 3,     -- yards: shortest ease into / out of a detour
}
Roam.PLAN = PLAN

-- {{{ local function curve_point
-- Where on the path, `s` yards along the straight line from A to B: the
-- line, pushed sideways (normal nx, ny) by the bow and every detour.
--   bow:    k x length x sin(pi s / length), a gentle arc the whole way
--   detour: over [s0, s1] (the obstacle's stretch) the full bulge `amp` to
--           `side`; before and after, an ease of `ramp` yards shaped as
--           half a cosine wave, so the path curves out, runs straight past
--           the obstacle at its peak, and curves back to the line
local function curve_point(c, s)
    local off = c.bow * c.len * math.sin(math.pi * s / c.len)
    for _, d in ipairs(c.detours) do
        local u
        if s < d.s0 - d.ramp or s > d.s1 + d.ramp then u = 0
        elseif s < d.s0 then u = (1 - math.cos(math.pi * (s - d.s0 + d.ramp) / d.ramp)) / 2
        elseif s > d.s1 then u = (1 - math.cos(math.pi * (d.s1 + d.ramp - s) / d.ramp)) / 2
        else u = 1 end
        off = off + d.side * d.amp * u
    end
    return c.ax + c.ux * s + c.nx * off, c.ay + c.uy * s + c.ny * off
end
-- }}}

-- {{{ local function sample
-- The test points: every `body` yards along the line (the owner's
-- "imaginary waypoints", one per body width, so a tauren tests in steps
-- about three times a human's), each with its place and ground height:
--   h    under the centre (what the slope cost reads)
--   top  the highest of the centre and both shoulders, half a body width
--        either side across the line (what the obstacle test reads, so a
--        wide body keeps its shoulders off a rock the centre line would
--        just miss; with the centre alone a human's path grazed a rock
--        with 0.3 yards to spare, 2026-09-27)
local function sample(area, c, from, to)
    local pts = {}
    local n = math.max(1, math.ceil((to - from) / c.body))
    local half = c.body / 2
    for i = 0, n do
        local s = from + (to - from) * i / n
        local x, y = curve_point(c, s)
        local x2, y2 = curve_point(c, math.min(c.len, s + 0.01))
        local tx, ty = x2 - x, y2 - y
        local tl = math.sqrt(tx * tx + ty * ty)
        if tl < 1e-9 then tx, ty, tl = c.ux, c.uy, 1 end
        local sx, sy = -ty / tl * half, tx / tl * half
        local h = area.height(x, y)
        local top = math.max(h, area.height(x + sx, y + sy), area.height(x - sx, y - sy))
        pts[#pts + 1] = { s = s, x = x, y = y, h = h, top = top }
    end
    return pts
end
-- }}}

-- {{{ local function first_step
-- The first obstacle along the test points: a height change between two
-- neighbours that stands out from the changes either side by more than
-- STEP_RISE (a slope changes by about the same each step, so it never
-- stands out; a crate's edge does). Also any point outside the area.
-- Returns the stretch [s0, s1] it covers: from the step up to the step
-- back down (or 0, s of the step, when it never comes back down in the
-- points given), or nil when the way is clear.
local function first_step(area, pts)
    local d = {}
    for i = 2, #pts do d[i] = pts[i].top - pts[i - 1].top end
    local function sharp(i)
        local around = math.min(math.abs(d[i - 1] or d[i + 1] or 0), math.abs(d[i + 1] or d[i - 1] or 0))
        return math.abs(d[i]) - around > PLAN.STEP_RISE
    end
    for i = 2, #pts do
        if not Roam.walkable({ outline = area.outline, walls = {} }, pts[i].x, pts[i].y, 0) then
            return pts[i - 1].s, pts[i].s, true
        end
        if sharp(i) then
            for j = i + 1, #pts do
                if sharp(j) and d[j] * d[i] < 0 then return pts[i - 1].s, pts[j].s end
            end
            return pts[i - 1].s, pts[#pts].s
        end
    end
    return nil
end
-- }}}

-- {{{ local function path_cost
-- Walking cost of the test points: each stretch's length, raised by its
-- grade squared (steep up or down both cost; the owner's "gentlest path
-- down a slope, or the flattest path up a hill"), lowered on road.
local function path_cost(area, pts)
    local cost = 0
    for i = 2, #pts do
        local a, b = pts[i - 1], pts[i]
        local ds = math.sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2)
        local grade = ds > 0 and (b.h - a.h) / ds or 0
        local road = (area.road and area.road((a.x + b.x) / 2, (a.y + b.y) / 2)) and PLAN.ROAD_F or 1
        cost = cost + ds * (1 + PLAN.SLOPE_W * grade * grade) * road
    end
    return cost
end
-- }}}

-- {{{ local function add_detour
-- Clear the obstacle on [s0, s1]: for each side, bulge out one body width
-- at a time until the test points from the ease-in to the ease-out show no
-- step, and keep the side whose whole path costs less. Returns false when
-- neither side clears within MAX_SIDE yards (then this candidate is given
-- up; a straight bow or another candidate may still get through).
local function add_detour(area, c, s0, s1)
    local best, best_cost
    for _, side in ipairs({ 1, -1 }) do
        local amp = c.body
        while amp <= PLAN.MAX_SIDE do
            local d = { s0 = s0, s1 = s1, side = side, amp = amp, ramp = math.max(PLAN.RAMP_MIN, 2 * amp) }
            c.detours[#c.detours + 1] = d
            local from, to = math.max(0, s0 - d.ramp), math.min(c.len, s1 + d.ramp)
            local clear = not first_step(area, sample(area, c, from, to))
            if clear then
                local cost = path_cost(area, sample(area, c, 0, c.len))
                if not best_cost or cost < best_cost then best, best_cost = d, cost end
            end
            c.detours[#c.detours] = nil
            if clear then break end
            amp = amp + c.body
        end
    end
    if not best then return false end
    c.detours[#c.detours + 1] = best
    return true
end
-- }}}

-- {{{ function Roam.plan_path
-- A path from (ax, ay) to (bx, by) for a body `body` yards wide over the
-- area's ground. Every bow candidate gets its detours, one obstacle at a
-- time from A toward B; the cheapest candidate that clears wins.
-- Returns points = { {x, y, h}, ... } (the test points of the chosen path,
-- A first, B last) and plan = { candidates = { { points, cost, ok }, ... },
-- chosen } for drawing. Errors when no candidate clears: the waypoint
-- picker only chooses spots clear of obstacles, so a trip that cannot be
-- planned is a map or setting to look at, not something to walk anyway.
function Roam.plan_path(area, ax, ay, bx, by, body)
    local len = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
    local ux, uy = (bx - ax) / len, (by - ay) / len
    local plan = { candidates = {} }
    for _, bow in ipairs(PLAN.BOWS) do
        local c = { ax = ax, ay = ay, len = len, ux = ux, uy = uy, nx = -uy, ny = ux, bow = bow, body = body, detours = {} }
        local ok = true
        for _ = 1, PLAN.MAX_DETOUR + 1 do
            local s0, s1 = first_step(area, sample(area, c, 0, len))
            if not s0 then break end
            if #c.detours >= PLAN.MAX_DETOUR or not add_detour(area, c, s0, s1) then ok = false break end
        end
        local pts = sample(area, c, 0, len)
        if ok and first_step(area, pts) then ok = false end
        local entry = { points = pts, cost = ok and path_cost(area, pts) or math.huge, ok = ok, detours = #c.detours }
        plan.candidates[#plan.candidates + 1] = entry
        if ok and (not plan.chosen or entry.cost < plan.chosen.cost) then plan.chosen = entry end
    end
    if not plan.chosen then
        error(string.format("buddy-roam: no path for a %.2f yd body from (%.1f, %.1f) to (%.1f, %.1f): every candidate (%d bows) met an obstacle it could not bulge past within %d yd in %d detours", body, ax, ay, bx, by, #PLAN.BOWS, PLAN.MAX_SIDE, PLAN.MAX_DETOUR))
    end
    return plan.chosen.points, plan
end
-- }}}
-- }}}

-- {{{ local function ray_to_edge
-- Yards from (cx, cy) along bearing a to the first side of the area's
-- outline it meets (the area's "radius" in that direction).
local function ray_to_edge(area, cx, cy, a)
    local dx, dy, best = math.cos(a), math.sin(a), math.huge
    local o = area.outline
    for i = 1, #o do
        local j = i % #o + 1
        local ax, ay = o[i][1], o[i][2]
        local ex, ey = o[j][1] - ax, o[j][2] - ay
        local den = dx * ey - dy * ex
        if math.abs(den) > 1e-9 then
            -- ray: c + t*d; side: a + u*e; solve c + t*d = a + u*e
            local t = ((ax - cx) * ey - (ay - cy) * ex) / den
            local u = ((ax - cx) * dy - (ay - cy) * dx) / den
            if t > 0 and u >= 0 and u <= 1 and t < best then best = t end
        end
    end
    return best
end
-- }}}

-- {{{ local function waypoint_room
-- Yards from (x, y) to the nearest other buddy's waypoint (math.huge when
-- there is none yet). Only the blended reading (s.avoid > 0) asks.
local function waypoint_room(s, b, x, y)
    local best = math.huge
    for _, o in ipairs(s.buddies) do
        if o ~= b and o.wp then
            local d = math.sqrt((o.wp.x - x) ^ 2 + (o.wp.y - y) ^ 2)
            if d < best then best = d end
        end
    end
    return best
end
-- }}}

-- {{{ local function pick_waypoint
-- The owner's pinwheel by waypoints (2026-09-27): turn the bearing from the
-- centre by the rotation step in the buddy's own direction, then put the
-- waypoint a random share (0..1, uniform) of the way from the centre to the
-- area's edge along that bearing, less the clearance. Records
-- b.wp = { x, y, share, reach } (reach = yards centre-to-edge on that
-- bearing, for drawing).
--
-- Up to 8 shares are drawn on the bearing. A spot inside a rock's
-- clearance (or within the clearance of the edge) is thrown out; if all 8
-- are, a rock covers the bearing and it turns one more step (up to 12
-- steps, then an error: the area is too rocky for the clearance). With a
-- Y limit the shares are drawn only from the allowed range round the last
-- one (Y_DRAW); a turn for a rock keeps the last share, so the limit
-- holds across it.
--   pure reading (avoid 0): the first spot that isn't thrown out is taken.
--   blend (avoid > 0): the first spot at least `avoid` yards from every
--     other buddy's waypoint is taken; if none of the 8 is, the one with
--     the most room is (b.crowded counts these). Turning the bearing
--     further for crowding was tried first (2026-09-27): at 20 yards a
--     quarter of the waypoints skipped a step, and a buddy could be sent
--     across the whole area, breaking the steady rotation.
-- {{{ local function seen_through
-- Whether the straight line from (ax, ay) to (bx, by) stays inside the
-- area's outline (its own walls; rocks are walked round, not seen past),
-- tested every yard.
local function seen_through(area, ax, ay, bx, by)
    local len = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
    local n = math.max(1, math.ceil(len))
    for i = 1, n - 1 do
        local k = i / n
        if not Roam.walkable({ outline = area.outline, walls = {} }, ax + (bx - ax) * k, ay + (by - ay) * k, 0) then return false end
    end
    return true
end
-- }}}

-- {{{ local function turning_point
-- A buddy in a side tunnel can't walk straight to a waypoint round the
-- corner (2026-09-27, the owner's side tunnel). Every waypoint is placed
-- on a line from the centre that stops at the first wall ("move the edge
-- of the map to the closest of the walls"), so every waypoint can be seen
-- from the centre, and so can every point a buddy walks through on the way
-- to one (the triangle of centre, start and end is walled on all three
-- sides by lines inside the area, and the area has no holes). So: when the
-- straight way is walled, walk toward the centre until the waypoint comes
-- into view, and turn there. Returns nil when the way is clear.
-- Errors if even the centre can't be seen from the buddy: that breaks the
-- reasoning above, and the map or walker needs looking at.
local function turning_point(s, b, wp)
    if seen_through(s.area, b.x, b.y, wp.x, wp.y) then return nil end
    if not seen_through(s.area, b.x, b.y, s.cx, s.cy) then
        error(string.format("buddy-roam: buddy %s at (%.1f, %.1f) can't see the area's centre (%.1f, %.1f); every waypoint is placed in sight of it, so the buddy has left the lines it should walk", tostring(b.id), b.x, b.y, s.cx, s.cy))
    end
    local len = math.sqrt((s.cx - b.x) ^ 2 + (s.cy - b.y) ^ 2)
    for d = 1, math.ceil(len) do
        local k = math.min(1, d / len)
        local x, y = b.x + (s.cx - b.x) * k, b.y + (s.cy - b.y) * k
        if seen_through(s.area, x, y, wp.x, wp.y) then return { x = x, y = y } end
    end
    return { x = s.cx, y = s.cy }
end
-- }}}

-- {{{ local function find_opening
-- Side tunnels (2026-09-27): the owner asked that buddies be "encouraged
-- to walk through" one. With the bearing turning a fixed step, a buddy
-- repeats the same bearings lap after lap, and only the few that line up
-- with a narrow tunnel reach into it (measured: without this, no
-- waypoints past the mouth of an 8-yard tunnel, one buddy of six in it
-- once). So: look up to half a step either side of the bearing, one degree
-- at a time; where the line from the centre runs `openings` yards or more
-- beyond this bearing's, that is an opening (a tunnel's mouth, a doorway),
-- and this one waypoint takes the middle of the longest such run of
-- degrees. Half a step either side covers the whole circle between a
-- buddy's bearings, so every lap passes every opening once. The
-- pinwheel's own bearing is left as it was, so the lap keeps its pace.
local function find_opening(s, angle)
    local base = ray_to_edge(s.area, s.cx, s.cy, angle)
    local half = math.floor(math.deg(s.turn) / 2)
    local run_from, best_from, best_len = nil, nil, 0
    for k = -half, half + 1 do
        local open = k <= half and ray_to_edge(s.area, s.cx, s.cy, angle + math.rad(k)) >= base + s.openings
        if open and not run_from then run_from = k end
        if not open and run_from then
            if k - run_from > best_len then best_from, best_len = run_from, k - run_from end
            run_from = nil
        end
    end
    if not best_from then return angle end
    return angle + math.rad(best_from + (best_len - 1) / 2)
end
-- }}}

-- {{{ local function lure_point
-- The monster nudge (2026-09-27). Along the straight line from the buddy to
-- its waypoint, the first living monster whose aggro radius the line
-- misses by no more than lure_reach yards (and by more than nothing: a line
-- through the radius already brings it) gets the trip bent through a point
-- lure_depth of its radius from it, on the side the line passes: the
-- nearest a straight walker comes to it is then inside its radius, so it
-- notices the buddy and attacks. The point must be a clear place to stand
-- (the walking margin off rocks and off the area's edge: the C++ core asks
-- its ground the same one "clear" question, 617e2) and in sight of both
-- ends; otherwise that monster is passed over.
-- Returns the point or nil.
local function lure_point(s, b, wp)
    local vx, vy = wp.x - b.x, wp.y - b.y
    local len2 = vx * vx + vy * vy
    if len2 < 1e-9 then return nil end
    local best, best_t
    for _, m in ipairs(s.mobs) do
        if m.alive then
            local t = math.max(0, math.min(1, ((m.x - b.x) * vx + (m.y - b.y) * vy) / len2))
            local qx, qy = b.x + vx * t, b.y + vy * t
            local miss = math.sqrt((qx - m.x) ^ 2 + (qy - m.y) ^ 2) - m.r
            if miss > 0 and miss <= s.lure_reach and (not best_t or t < best_t) then
                local ux, uy = qx - m.x, qy - m.y
                local ul = math.sqrt(ux * ux + uy * uy)
                local px, py = m.x + ux / ul * m.r * s.lure_depth, m.y + uy / ul * m.r * s.lure_depth
                if Roam.walkable(s.area, px, py, s.margin) and Roam.edge_distance(s.area, px, py) >= s.margin
                    and seen_through(s.area, b.x, b.y, px, py) and seen_through(s.area, px, py, wp.x, wp.y) then
                    best, best_t = { x = px, y = py, mob = m }, t
                end
            end
        end
    end
    return best
end
-- }}}

local SHARE_TRIES, TURN_TRIES = 8, 12
-- How the next share is drawn from the last one (y), per y_mode:
local Y_DRAW = {
    -- anywhere within y +- y_limit, on the whole way's scale
    points = function(s, y, rand)
        local lo, hi = math.max(0, y - s.y_limit), math.min(1, y + s.y_limit)
        return lo + (hi - lo) * rand()
    end,
    -- anywhere within y x (1 +- y_limit)
    ratio  = function(s, y, rand)
        local lo, hi = math.max(s.y_floor, y * (1 - s.y_limit)), math.min(1, y * (1 + s.y_limit))
        return lo + (hi - lo) * rand()
    end,
    -- the owner's rule (2026-09-27): Y is a whole number 1..100 (the
    -- percent of the way out); each waypoint adds or takes away, at even
    -- odds, a whole number from y_min to y_limit (1..20), kept within
    -- 1..100. Adding and taking away the same amounts has no lean either
    -- way, so the buddies spread evenly (measured 2026-09-27: 18-23% of
    -- waypoints in each fifth of the way out). Multiplying Y by 1 +- the
    -- change was tried first (a misreading): it leans inward, since a step
    -- out then back in is (1 + c)(1 - c) < 1, and over half the waypoints
    -- ended in the inner fifth.
    step   = function(s, y, rand)
        local pct    = math.floor(y * 100 + 0.5)
        local change = s.y_min + math.floor(rand() * (s.y_limit - s.y_min + 1))
        local sign   = rand() < 0.5 and -1 or 1
        return math.max(1, math.min(100, pct + sign * change)) / 100
    end,
}
local function pick_waypoint(s, b, rand)
    for _ = 1, TURN_TRIES do
        b.angle = b.angle + s.turn * b.spin
        -- this waypoint's bearing: the pinwheel's, or the middle of an
        -- opening near it (s.openings); the pinwheel's own stays b.angle
        local bearing = s.openings > 0 and find_opening(s, b.angle) or b.angle
        if bearing ~= b.angle then b.opened = (b.opened or 0) + 1 end
        local reach = ray_to_edge(s.area, s.cx, s.cy, bearing) - s.clearance
        local best, best_room
        -- a first waypoint, or no limit, draws from the whole way; after
        -- that the limit's reading draws it from the last share (Y_DRAW)
        local limited = s.y_limit > 0 and b.share
        -- the owner's "step" rule draws once and, when that spot is blocked,
        -- slides it along the bearing to the nearest clear point, one point
        -- (1%) at a time, nearer first then farther: redrawing instead threw
        -- away blocked draws, and the ones that passed round a rock near
        -- the centre lay farther out, so waypoints leaned to the rim
        -- (measured 2026-09-27: 17/13/18/27/26% by fifths with the big rocks,
        -- 26/20/20/20/13% with none). The rule's own Y stays the drawn
        -- value (b.share); only this waypoint is moved. Carrying the slid
        -- value on pushed the walk outward instead, since a rock whose
        -- clearance covers the centre sends every inner draw on those
        -- bearings out past it (5/11/24/26/35%).
        local slide = limited and s.y_mode == "step"
        local drawn = slide and Y_DRAW.step(s, b.share, rand)
        -- piercing: count inward rolls in a row; the second (or later) that
        -- lands at or under `pierce` percent puts this waypoint on the far
        -- side of the centre at the same Y (the line there runs through
        -- the middle) and turns the buddy the other way round, so its lap
        -- draws an S, or with the next pierce a figure 8. The count starts
        -- again after. The reach is measured anew along the new bearing.
        if slide and s.pierce > 0 then
            b.inward = drawn < b.share and (b.inward or 0) + 1 or 0
            if b.inward >= 2 and drawn * 100 <= s.pierce + 1e-9 then
                b.angle, b.spin, b.inward = b.angle + math.pi, -b.spin, 0
                bearing = b.angle
                reach = ray_to_edge(s.area, s.cx, s.cy, bearing) - s.clearance
                b.pierced = (b.pierced or 0) + 1
            end
        end
        -- crowding: someone within `crowd` yards of where the drawn Y lands
        -- moves Y crowd_shift points toward 50 (from 50 itself, either way
        -- at even odds), once, and the moved Y is the one carried on (a
        -- nudge toward the middle is the point: it spreads buddies out).
        -- A second crowd at the moved spot is left alone.
        if slide and s.crowd > 0 then
            local d = math.max(s.near, drawn * reach)
            local x, y = s.cx + math.cos(bearing) * d, s.cy + math.sin(bearing) * d
            local near_someone = false
            for _, o in ipairs(s.buddies) do
                if o ~= b and (o.x - x) ^ 2 + (o.y - y) ^ 2 < s.crowd * s.crowd then near_someone = true end
            end
            for _, o in ipairs(s.others) do
                if (o[1] - x) ^ 2 + (o[2] - y) ^ 2 < s.crowd * s.crowd then near_someone = true end
            end
            if near_someone then
                local pct  = math.floor(drawn * 100 + 0.5)
                local sign = pct < 50 and 1 or pct > 50 and -1 or (rand() < 0.5 and 1 or -1)
                drawn = (pct + sign * s.crowd_shift) / 100
                b.crowd_moves = (b.crowd_moves or 0) + 1
            end
        end
        for k = 1, slide and 199 or SHARE_TRIES do
            local share
            if slide then
                local off = math.floor(k / 2) * (k % 2 == 0 and -1 or 1) / 100
                share = drawn + off
            else
                share = limited and Y_DRAW[s.y_mode](s, b.share, rand) or rand()
            end
            if slide and (share < 0.01 or share > 1) then goto next_share end   -- slid off either end of the bearing
            local d = math.max(s.near, share * reach)
            local x, y = s.cx + math.cos(bearing) * d, s.cy + math.sin(bearing) * d
            if Roam.walkable(s.area, x, y, s.clearance) and Roam.edge_distance(s.area, x, y) >= s.clearance then
                local room = s.avoid > 0 and waypoint_room(s, b, x, y) or math.huge
                if not best_room or room > best_room then
                    best, best_room = { x = x, y = y, share = share, reach = reach + s.clearance, bearing = bearing }, room
                end
                if room >= s.avoid then break end
            end
            ::next_share::
        end
        if best then
            if best_room < s.avoid then b.crowded = (b.crowded or 0) + 1 end
            b.wp = best
            b.share = slide and math.floor(drawn * 100 + 0.5) / 100 or best.share
            -- (when drawn is below 1% or above 100%, Y_DRAW.step already
            -- clamped it)
            b.wp_ticks = 0
            -- the way there: straight, or by a turning point when the area's
            -- own walls are in the way (b.via; see turning_point)
            -- (the "paint" reading walks grid paths, which find their own way
            -- round walls, so it needs no turning point; nor does it keep the
            -- straight-line guarantee a turning point relies on, an L-shaped
            -- hall's leg being out of sight of its centre)
            b.via = s.reading ~= "paint" and turning_point(s, b, best) or nil
            b.via_kind = b.via and "turn" or nil
            -- a monster near the way: bend the trip through its aggro radius
            -- (only when the way is otherwise straight; a turning point
            -- already bends it)
            if not b.via and #s.mobs > 0 then
                b.via = lure_point(s, b, best)
                b.via_kind = b.via and "lure" or nil
            end
            -- planned walking (body > 0): the whole path now, walked point
            -- by point (b.path, b.plan kept for drawing), leg by leg
            local body = b.body or s.body
            if body > 0 then
                if b.via then
                    local leg1 = Roam.plan_path(s.area, b.x, b.y, b.via.x, b.via.y, body)
                    local leg2, plan = Roam.plan_path(s.area, b.via.x, b.via.y, best.x, best.y, body)
                    for i = 2, #leg2 do leg1[#leg1 + 1] = leg2[i] end
                    b.path, b.plan = leg1, plan
                else
                    b.path, b.plan = Roam.plan_path(s.area, b.x, b.y, best.x, best.y, body)
                end
                b.path_i = 2
            end
            b.wp_limit = math.sqrt((best.x - b.x) ^ 2 + (best.y - b.y) ^ 2) / s.step * 2 + 20
            return
        end
    end
    error(string.format("buddy-roam: buddy %s found no waypoint clear of rocks in %d turns of %.2f rad (clearance %.1f yd); the area is too small or rocky for this clearance", tostring(b.id), TURN_TRIES, s.turn, s.clearance))
end
-- }}}
-- {{{ local function orbit_aim
-- Where to aim instead of straight at the goal, when an obstacle is in the
-- way (the owner, 2026-09-27: orbit rather than run right up against it;
-- small rocks, raised ground, colliding doodads like a ruined crate).
-- Each obstacle is a circle; "in the way" is: within `look` yards, and the
-- straight line to the goal passes within its radius + `orbit` (the orbit
-- circle). Of those, the nearest along the line decides:
--   outside its orbit circle: aim along the tangent to that circle, on the
--     side the goal lies (so the path bends round at the orbit distance
--     instead of touching the obstacle and sliding along it);
--   inside it already: aim along the circle (tangent at the buddy),
--     leaning a little outward, until the line to the goal clears.
-- The side is kept per obstacle (b.orbit_w, b.orbit_side) so a goal almost
-- straight behind it doesn't flip the buddy left and right every tick;
-- dead ahead, the buddy goes round the way it circles the area (its spin).
-- Returns the unit aim and the obstacle (nil when the way is clear).
local function orbit_aim(s, b, gx, gy)
    local dx, dy = gx - b.x, gy - b.y
    local len = math.sqrt(dx * dx + dy * dy)
    local ux, uy = dx / len, dy / len
    local block, block_t
    for _, w in ipairs(s.area.walls) do
        local R = w[3] + s.orbit
        local cx, cy = w[1] - b.x, w[2] - b.y
        local cd = math.sqrt(cx * cx + cy * cy)
        if cd - R < s.look then
            local along = cx * ux + cy * uy                         -- how far along the line
            local tq = math.max(0, math.min(len, along))
            local off = math.sqrt((cx - ux * tq) ^ 2 + (cy - uy * tq) ^ 2)
            local goal_in = (gx - w[1]) ^ 2 + (gy - w[2]) ^ 2 < R * R
            if off < R and not goal_in and along > -R and (not block_t or along < block_t) then block, block_t = w, along end
        end
    end
    if not block then b.orbit_w = nil return ux, uy, nil end

    local R = block[3] + s.orbit
    local cx, cy = block[1] - b.x, block[2] - b.y
    local cd = math.sqrt(cx * cx + cy * cy)
    if b.orbit_w ~= block then
        -- side: +1 passes with the obstacle on the right, round the goal's side
        local cross = cx * uy - cy * ux
        b.orbit_side = math.abs(cross) > 0.5 and (cross > 0 and 1 or -1) or b.spin
        b.orbit_w = block
    end
    local side = b.orbit_side
    local rx, ry = cx / cd, cy / cd                                  -- toward the obstacle
    if cd > R then
        local a = math.asin(R / cd) * side                           -- tangent: turn off the centre line
        return rx * math.cos(a) - ry * math.sin(a), rx * math.sin(a) + ry * math.cos(a), block
    end
    local tx, ty = -ry * side, rx * side                             -- along the circle
    local ox, oy = tx - rx * 0.4, ty - ry * 0.4                      -- lean outward
    local ol = math.sqrt(ox * ox + oy * oy)
    return ox / ol, oy / ol, block
end
-- }}}

-- {{{ local function waypoint_tick
-- Walk toward the waypoint: of the step headings that stay walkable (rocks
-- and the edge refused, as in the other readings), take the one pointing
-- most nearly at it (or, with orbit > 0, at the way round an obstacle:
-- orbit_aim); arriving (within a step) picks the next one. A buddy
-- that hasn't arrived in twice the straight-line time plus 20 ticks is
-- stuck behind a rock and gives up on that waypoint for the next one.
local function waypoint_tick(s, b, rand)
    -- busy (b.busy ticks left): something else has the buddy, a fight in
    -- the drawn scenes (in game, playerbots' own fighting and looting come
    -- first the same way); it stands, and walks on after
    if (b.busy or 0) > 0 then b.busy = b.busy - 1 return end
    -- planned walking: step along the planned points; the last one is the
    -- waypoint, and reaching it picks the next
    if b.path then
        local left = s.step
        while left > 0 do
            local p = b.path[b.path_i]
            local d = math.sqrt((p.x - b.x) ^ 2 + (p.y - b.y) ^ 2)
            if d > left then
                b.x, b.y = b.x + (p.x - b.x) / d * left, b.y + (p.y - b.y) / d * left
                return
            end
            b.x, b.y, left = p.x, p.y, left - d
            b.path_i = b.path_i + 1
            if b.path_i > #b.path then pick_waypoint(s, b, rand) return end
        end
        return
    end
    -- a turning point first (reached: dropped), then the waypoint
    if b.via and (b.via.x - b.x) ^ 2 + (b.via.y - b.y) ^ 2 <= s.step * s.step then b.via = nil end
    local goal = b.via or b.wp
    local dx, dy = goal.x - b.x, goal.y - b.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if not b.via and dist <= s.step then
        b.x, b.y = b.wp.x, b.wp.y
        pick_waypoint(s, b, rand)
        return
    end
    b.wp_ticks = b.wp_ticks + 1
    if b.wp_ticks > b.wp_limit then pick_waypoint(s, b, rand) return end
    -- aim: straight at the waypoint, or round an obstacle (orbit > 0)
    local ax, ay = dx / dist, dy / dist
    if s.orbit > 0 then ax, ay, b.orbiting = orbit_aim(s, b, goal.x, goal.y) end
    local bx, by, best = b.x, b.y, -math.huge
    for k = 0, s.headings - 1 do
        local a = 2 * math.pi * k / s.headings
        local hx, hy = math.cos(a), math.sin(a)
        local x, y = b.x + hx * s.step, b.y + hy * s.step
        if Roam.walkable(s.area, x, y, s.margin) then
            local aim = hx * ax + hy * ay
            if aim > best then bx, by, best = x, y, aim end
        end
    end
    b.x, b.y = bx, by
end
-- }}}

-- {{{ painting (617e, "Proposal, 2026-09-27: exploring as painting")
-- The owner's exploring-as-painting, for the drawn comparisons (reading
-- "paint"; nothing else uses it). Each buddy lays paint on the ground it can
-- see, most where it stands and less out to 60 yards; walls paint the ground
-- within about 5 yards of themselves in a pulse every 3 seconds; waypoints
-- and paths prefer unpainted ground. Paint belongs to the clan (one grid per
-- clan and area) and lasts while the owner stays in the area (the owner:
-- "last until the player leaves the area for 15 seconds").
--
-- The grid: square cells `cell` yards across over the area's bounds. Each
-- cell is inside the area's outline or not, open (inside and off every
-- rock) or not, and knows its distance to the nearest wall or rock.
-- Paint is kept as 16-bit counts that only grow: at 65,536 a count wraps to
-- a small number and that patch looks unexplored for a while. The owner
-- accepted this ("they'll wrap around at 60 thousand or whenever an integer
-- wraps [...] Might look a little janky randomly, but that's okay, leave a
-- note about it"): this is the note.

local PAINT = {
    VISION     = 60,    -- yards a buddy paints out to
    RAYS       = 90,    -- sight lines per deposit (every 4 degrees)
    NEAR_PAINT = 12,    -- paint laid at the buddy's own spot per sight line;
                        -- falls off as (1 - d / VISION)^2, at least 1
    WALL_REACH = 5,     -- yards from a wall its paint reaches
    WALL_PAINT = 400,   -- the level a wall pulse tops its ground up to at the wall itself, falling
                        -- to 0 at WALL_REACH (squared, so the middle of a 10-yard tunnel gets
                        -- little and its edges much). 8 added per pulse was tried first
                        -- (2026-09-27, animation 19): beside a buddy's hundreds per deposit it
                        -- changed nothing, and it was never drawn; the owner saw no wall paint.
    ROOM_MIN   = 7,     -- yards from the area's outline: ground this deep inside is a room's core
                        -- (the place is at least 14 yards across there); narrower is a tunnel
    ROOM_LEAVE = 0.8,   -- a room this explored (seen up close) lets the paint draw a buddy onward
    SATURATE   = 200,   -- paint p counts as p / (p + SATURATE) toward "painted" (0..1)
    DISC       = 6,     -- yards round a candidate waypoint its paint is judged over
    PATH_MARGIN = 1.5,  -- yards a path keeps off walls and rocks
    CLOSE      = 20,    -- yards: ground seen from this near counts as explored (the coverage measure)
    REVISIT    = 400,   -- ticks within which stepping on a cell someone stood on is a revisit
    OWN_TRAIL  = 60,    -- ... unless it was the same buddy this recently (its own trail)
}
Roam.PAINT = PAINT

-- {{{ local function paint_grid_rects
-- The grid of a rectangles area (area.rects): inside = in some rectangle;
-- open = inside and off every rock. The distance to the area's own edge
-- (g.edge: rocks left out, as for outlines) comes from a sweep instead of
-- an outline: every outside cell next to an inside one is a seed, each
-- inside cell takes the seed nearest to it (passed from neighbour to
-- neighbour, eight ways, breadth first: the usual "nearest seed"
-- propagation, within a fraction of a cell of the true distance), and its
-- edge is its distance to that seed cell's nearest side. A few cells can
-- be off by up to half a cell where two corridors meet at an angle; the
-- room/tunnel split (7 yards) is far coarser than that.
local paint_wall_cells   -- forward: the wall pulse's cell list (below)
local function paint_grid_rects(g, area, cell)
    local nx, ny = g.nx, g.ny
    for iy = 0, ny - 1 do
        for ix = 0, nx - 1 do
            local i = iy * nx + ix
            local x, y = g.x0 + (ix + 0.5) * cell, g.y0 + (iy + 0.5) * cell
            g.inside[i] = inside_rects(area.rects, x, y)
        end
    end
    -- seeds: outside cells touching an inside one
    local seed, queue, head = {}, {}, 1
    for i = 0, g.n - 1 do
        if not g.inside[i] then
            local ix, iy = i % nx, math.floor(i / nx)
            for oy = -1, 1 do for ox = -1, 1 do
                local jx, jy = ix + ox, iy + oy
                if jx >= 0 and jy >= 0 and jx < nx and jy < ny and g.inside[jy * nx + jx] and not seed[i] then
                    seed[i] = i; queue[#queue + 1] = i
                end
            end end
        end
    end
    -- a point's distance to a seed cell's square (its nearest side)
    local function to_square(x, y, s)
        local sx, sy = g.x0 + (s % nx) * cell, g.y0 + math.floor(s / nx) * cell
        local dx = math.max(sx - x, 0, x - (sx + cell))
        local dy = math.max(sy - y, 0, y - (sy + cell))
        return math.sqrt(dx * dx + dy * dy)
    end
    local near = {}
    for _, s in ipairs(queue) do near[s] = s end
    while head <= #queue do
        local c = queue[head]; head = head + 1
        local ix, iy = c % nx, math.floor(c / nx)
        for oy = -1, 1 do for ox = -1, 1 do
            local jx, jy = ix + ox, iy + oy
            if (ox ~= 0 or oy ~= 0) and jx >= 0 and jy >= 0 and jx < nx and jy < ny then
                local j = jy * nx + jx
                if g.inside[j] then
                    local x, y = g.x0 + (jx + 0.5) * cell, g.y0 + (jy + 0.5) * cell
                    local d = to_square(x, y, near[c])
                    if not near[j] then near[j] = near[c]; g.edge[j] = d; queue[#queue + 1] = j
                    elseif d < g.edge[j] then near[j] = near[c]; g.edge[j] = d end
                end
            end
        end end
    end
    for iy = 0, ny - 1 do
        for ix = 0, nx - 1 do
            local i = iy * nx + ix
            if g.inside[i] then
                local x, y = g.x0 + (ix + 0.5) * cell, g.y0 + (iy + 0.5) * cell
                g.open[i] = Roam.walkable(area, x, y, 0)
                if g.open[i] then
                    local d = g.edge[i]
                    for _, w in ipairs(area.walls) do d = math.min(d, math.sqrt((x - w[1]) ^ 2 + (y - w[2]) ^ 2) - w[3]) end
                    g.wall[i] = d
                    g.open_list[#g.open_list + 1] = i
                end
            end
        end
    end
    paint_wall_cells(g)
    Roam.paint_rooms(g)
    return g
end
-- }}}

-- {{{ function Roam.paint_grid
-- A clan's paint grid over an area (see above). area.outline and
-- area.walls as everywhere in this model; or area.rects (above).
function Roam.paint_grid(area, cell)
    local ffi = require("ffi")
    local minx, maxx, miny, maxy = math.huge, -math.huge, math.huge, -math.huge
    if area.rects then
        -- a rectangles area: its bounds, padded one cell all round so every
        -- inside cell has outside neighbours to measure its edge from
        for _, r in ipairs(area.rects) do
            minx, maxx = math.min(minx, r[1]), math.max(maxx, r[3])
            miny, maxy = math.min(miny, r[2]), math.max(maxy, r[4])
        end
        minx, maxx, miny, maxy = minx - cell, maxx + cell, miny - cell, maxy + cell
    else
        for _, p in ipairs(area.outline) do
            minx, maxx = math.min(minx, p[1]), math.max(maxx, p[1])
            miny, maxy = math.min(miny, p[2]), math.max(maxy, p[2])
        end
    end
    local g = { area = area, cell = cell, x0 = minx, y0 = miny }
    g.nx, g.ny = math.ceil((maxx - minx) / cell), math.ceil((maxy - miny) / cell)
    g.n = g.nx * g.ny
    g.inside, g.open, g.wall, g.edge = {}, {}, {}, {}
    g.buddy = ffi.new("uint16_t[?]", g.n)   -- paint laid by buddies (wraps at 65,536: see above)
    g.wallp = ffi.new("uint16_t[?]", g.n)   -- paint laid by the walls' pulses
    g.last_t, g.last_id = {}, {}            -- who last stood in each cell, and when
    g.close = {}                            -- cells some buddy has seen from within PAINT.CLOSE yards
    g.close_t = {}                          -- ... and when last (g.now at that deposit): what "painted
                                            -- recently" means to the quadrant sensing (Roam.sense_sectors)
    g.now = 0
    g.open_list = {}
    if area.rects then return paint_grid_rects(g, area, cell) end
    for iy = 0, g.ny - 1 do
        for ix = 0, g.nx - 1 do
            local i = iy * g.nx + ix
            local x, y = minx + (ix + 0.5) * cell, miny + (iy + 0.5) * cell
            g.inside[i] = inside_polygon(area.outline, x, y)
            g.open[i] = g.inside[i] and Roam.walkable(area, x, y, 0)
            -- distance to the outline alone (rocks left out): what tells a
            -- room from a tunnel (Roam.paint_rooms)
            if g.inside[i] then g.edge[i] = Roam.edge_distance(area, x, y) end
            if g.open[i] then
                local d = Roam.edge_distance(area, x, y)
                for _, w in ipairs(area.walls) do
                    d = math.min(d, math.sqrt((x - w[1]) ^ 2 + (y - w[2]) ^ 2) - w[3])
                end
                g.wall[i] = d
                g.open_list[#g.open_list + 1] = i
            end
        end
    end
    paint_wall_cells(g)
    Roam.paint_rooms(g)
    return g
end
-- the wall pulse's cells and levels, worked out once
function paint_wall_cells(g)
    g.wall_cells = {}
    for _, i in ipairs(g.open_list) do
        if g.wall[i] < PAINT.WALL_REACH then
            local k = 1 - g.wall[i] / PAINT.WALL_REACH
            g.wall_cells[#g.wall_cells + 1] = { i, math.floor(PAINT.WALL_PAINT * k * k + 0.5) }
        end
    end
end
-- }}}

-- {{{ function Roam.paint_rooms
-- Rooms and tunnels (the owner, 2026-09-27: "we should identify rooms, as
-- in, not tunnels, and we should orbit around those until the paint
-- system tells us to be drawn toward a tunnel").
-- Method: each cell's distance to the area's outline (g.edge; rocks left
-- out, a rock in a hall doesn't make it a tunnel) is a distance transform.
--   1. cores: cells at least ROOM_MIN yards from the outline, the deep
--      middles of wide places; each connected group of cores is one room.
--   2. growth: every other inside cell within ROOM_MIN yards (walked over
--      cells, eight neighbours) of a room's core joins that room, nearest
--      core first: the band between a room's middle and its walls.
--   3. the rest: cells too far from any core, the narrow places between
--      rooms and in dead ends, are tunnels; each connected group one tunnel.
-- An L-shaped hall stays one room (its corner is as wide as its arms); a
-- corridor under 14 yards wide is a tunnel; a dead-end passage is a tunnel
-- that leads nowhere. Each room gets a centre: the average of its open
-- cells, moved to its nearest open cell of that room if the average falls
-- outside it. Fills g.room[i] (room number or nil), g.tunnel[i] (tunnel
-- number or nil), g.rooms = { {cx, cy, cells = {...}}, ... }, g.tunnels
-- = { {half = widest distance to the outline in it}, ... }.
function Roam.paint_rooms(g)
    local reach = math.floor(PAINT.ROOM_MIN / g.cell + 0.5)
    g.room, g.tunnel, g.rooms, g.tunnels = {}, {}, {}, {}
    local function each_nb(i, fn)
        local ix, iy = i % g.nx, math.floor(i / g.nx)
        for oy = -1, 1 do for ox = -1, 1 do
            if ox ~= 0 or oy ~= 0 then
                local jx, jy = ix + ox, iy + oy
                if jx >= 0 and jy >= 0 and jx < g.nx and jy < g.ny then
                    local j = jy * g.nx + jx
                    if g.inside[j] then fn(j) end
                end
            end
        end end
    end
    -- 1. cores, grouped
    for i = 0, g.n - 1 do
        if g.inside[i] and g.edge[i] >= PAINT.ROOM_MIN and not g.room[i] then
            local r = #g.rooms + 1
            g.rooms[r] = { cells = {} }
            local stack = { i }
            g.room[i] = r
            while #stack > 0 do
                local c = table.remove(stack)
                each_nb(c, function(j)
                    if not g.room[j] and g.edge[j] >= PAINT.ROOM_MIN then g.room[j] = r; stack[#stack + 1] = j end
                end)
            end
        end
    end
    -- 2. growth, breadth first from every core at once, up to `reach` cells
    local queue, depth, head = {}, {}, 1
    for i = 0, g.n - 1 do if g.room[i] then queue[#queue + 1] = i; depth[i] = 0 end end
    while head <= #queue do
        local c = queue[head]; head = head + 1
        if depth[c] < reach then
            each_nb(c, function(j)
                if not g.room[j] then g.room[j] = g.room[c]; depth[j] = depth[c] + 1; queue[#queue + 1] = j end
            end)
        end
    end
    -- 3. tunnels
    for i = 0, g.n - 1 do
        if g.inside[i] and not g.room[i] and not g.tunnel[i] then
            local k = #g.tunnels + 1
            g.tunnels[k] = { half = 0, cells = {} }
            local stack = { i }
            g.tunnel[i] = k
            while #stack > 0 do
                local c = table.remove(stack)
                g.tunnels[k].half = math.max(g.tunnels[k].half, g.edge[c])
                each_nb(c, function(j)
                    if not g.room[j] and not g.tunnel[j] then g.tunnel[j] = k; stack[#stack + 1] = j end
                end)
            end
        end
    end
    -- centres
    for _, i in ipairs(g.open_list) do
        local r = g.room[i]
        if r then g.rooms[r].cells[#g.rooms[r].cells + 1] = i end
        local k = g.tunnel[i]
        if k then g.tunnels[k].cells[#g.tunnels[k].cells + 1] = i end
    end
    for r, room in ipairs(g.rooms) do
        local sx, sy = 0, 0
        for _, i in ipairs(room.cells) do
            local ix, iy = i % g.nx, math.floor(i / g.nx)
            sx, sy = sx + g.x0 + (ix + 0.5) * g.cell, sy + g.y0 + (iy + 0.5) * g.cell
        end
        local cx, cy = sx / #room.cells, sy / #room.cells
        local ci = math.floor((cx - g.x0) / g.cell) + math.floor((cy - g.y0) / g.cell) * g.nx
        if g.room[ci] ~= r or not g.open[ci] then
            local best, bd
            for _, i in ipairs(room.cells) do
                local ix, iy = i % g.nx, math.floor(i / g.nx)
                local d = (g.x0 + (ix + 0.5) * g.cell - cx) ^ 2 + (g.y0 + (iy + 0.5) * g.cell - cy) ^ 2
                if not bd or d < bd then best, bd = i, d end
            end
            local ix, iy = best % g.nx, math.floor(best / g.nx)
            cx, cy = g.x0 + (ix + 0.5) * g.cell, g.y0 + (iy + 0.5) * g.cell
        end
        room.cx, room.cy = cx, cy
    end
    -- the places a buddy can be drawn to: every room, and every tunnel (a
    -- dead end is a tunnel leading nowhere, and must be walked to be seen),
    -- each with its cells and a middle
    g.places = {}
    for r, room in ipairs(g.rooms) do g.places[#g.places + 1] = { kind = "room", id = r, cells = room.cells, cx = room.cx, cy = room.cy } end
    for k, tn in ipairs(g.tunnels) do
        if #tn.cells > 0 then
            local best, be = tn.cells[1], -1
            for _, i in ipairs(tn.cells) do if g.edge[i] > be then best, be = i, g.edge[i] end end
            local ix, iy = best % g.nx, math.floor(best / g.nx)
            g.places[#g.places + 1] = { kind = "tunnel", id = k, cells = tn.cells,
                cx = g.x0 + (ix + 0.5) * g.cell, cy = g.y0 + (iy + 0.5) * g.cell }
        end
    end
end
-- }}}

-- {{{ local paint helpers
local function cell_of(g, x, y)
    local ix, iy = math.floor((x - g.x0) / g.cell), math.floor((y - g.y0) / g.cell)
    if ix < 0 or iy < 0 or ix >= g.nx or iy >= g.ny then return nil end
    return iy * g.nx + ix
end
local function cell_xy(g, i)
    local ix, iy = i % g.nx, math.floor(i / g.nx)
    return g.x0 + (ix + 0.5) * g.cell, g.y0 + (iy + 0.5) * g.cell
end
Roam.paint_cell_of, Roam.paint_cell_xy = cell_of, cell_xy

-- Lay a buddy's paint from where it stands: sight lines every 4 degrees,
-- marched cell by cell until a wall or rock stops them. Cells near the
-- buddy are crossed by many lines, so the paint heaps up where it stands
-- ("more paint at their location and less and less drifting out").
local function deposit(g, x, y)
    for k = 0, PAINT.RAYS - 1 do
        local a = 2 * math.pi * k / PAINT.RAYS
        local dx, dy = math.cos(a), math.sin(a)
        local d = 0
        while d <= PAINT.VISION do
            local i = cell_of(g, x + dx * d, y + dy * d)
            if not i or not g.open[i] then break end
            local f = 1 - d / PAINT.VISION
            g.buddy[i] = g.buddy[i] + math.floor(PAINT.NEAR_PAINT * f * f) + 1   -- wraps: see the note above
            if d <= PAINT.CLOSE then g.close[i] = true; g.close_t[i] = g.now end
            d = d + g.cell
        end
    end
end
Roam.paint_deposit = deposit

-- A wall pulse tops the ground near the walls up to its level (it does
-- not add on top of what is there): walls never stop pulsing, so paint
-- added without end would, over a session, outweigh every buddy's and flatten
-- the difference between a tunnel's edges and its middle, which is what
-- keeps a buddy walking the middle. Topped up, the walls' paint stays a
-- steady fringe (the owner's "more near the wall and less farther out"),
-- and a buddy's own paint piles on top of it.
local function wall_pulse(g)
    for _, c in ipairs(g.wall_cells) do if g.wallp[c[1]] < c[2] then g.wallp[c[1]] = c[2] end end
end

-- 0..1: how painted the ground within PAINT.DISC yards of (x, y) is,
-- walls' paint included.
local function painted_near(g, x, y)
    local sum, n = 0, 0
    local r = math.ceil(PAINT.DISC / g.cell)
    local ci = cell_of(g, x, y)
    if not ci then return 1 end
    local cx, cy = ci % g.nx, math.floor(ci / g.nx)
    for oy = -r, r do
        for ox = -r, r do
            local ix, iy = cx + ox, cy + oy
            if ix >= 0 and iy >= 0 and ix < g.nx and iy < g.ny and (ox * ox + oy * oy) <= r * r then
                local i = iy * g.nx + ix
                if g.open[i] then
                    local p = g.buddy[i] + g.wallp[i]
                    sum, n = sum + p / (p + PAINT.SATURATE), n + 1
                end
            end
        end
    end
    return n > 0 and sum / n or 1
end
Roam.paint_near = painted_near
-- }}}

-- {{{ local function grid_path
-- The way from (ax, ay) to (bx, by) over the open cells that keep
-- PAINT.PATH_MARGIN off walls: A* with eight neighbours. Each step costs
-- its length, and with `weight` > 0 more through painted cells (length x
-- (1 + weight x painted share)), so paths lean through unexplored ground
-- (the owner's "dijkstra heat map style"). The cell path is then pulled
-- straight where a straight line stays on open cells, so buddies walk
-- lines, not staircases. Returns a list of points, start excluded, or nil.
local NEIGHBOURS = { { 1, 0, 1 }, { -1, 0, 1 }, { 0, 1, 1 }, { 0, -1, 1 },
                     { 1, 1, 1.4142 }, { 1, -1, 1.4142 }, { -1, 1, 1.4142 }, { -1, -1, 1.4142 } }
local function passable(g, i) return g.open[i] and g.wall[i] >= PAINT.PATH_MARGIN end
local function nearest_passable(g, x, y)
    local i = cell_of(g, x, y)
    if i and passable(g, i) then return i end
    local best, bd
    for _, j in ipairs(g.open_list) do
        if passable(g, j) then
            local jx, jy = cell_xy(g, j)
            local d = (jx - x) ^ 2 + (jy - y) ^ 2
            if not bd or d < bd then best, bd = j, d end
        end
    end
    return best
end
local function line_clear(g, ax, ay, bx, by)
    local len = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
    local n = math.max(1, math.ceil(len / (g.cell * 0.5)))
    for k = 1, n do
        local i = cell_of(g, ax + (bx - ax) * k / n, ay + (by - ay) * k / n)
        if not i or not passable(g, i) then return false end
    end
    return true
end
local function grid_path(g, ax, ay, bx, by, weight)
    local start, goal = nearest_passable(g, ax, ay), nearest_passable(g, bx, by)
    if not start or not goal then return nil end
    local gx, gy = cell_xy(g, goal)
    local cost, from, closed = { [start] = 0 }, {}, {}
    local heap = { { 0, start } }
    local function push(f, i)
        heap[#heap + 1] = { f, i }
        local k = #heap
        while k > 1 do
            local p = math.floor(k / 2)
            if heap[p][1] <= heap[k][1] then break end
            heap[p], heap[k] = heap[k], heap[p]
            k = p
        end
    end
    local function pop()
        local top = heap[1]
        heap[1] = heap[#heap]
        heap[#heap] = nil
        local k = 1
        while true do
            local l, r, m = 2 * k, 2 * k + 1, k
            if heap[l] and heap[l][1] < heap[m][1] then m = l end
            if heap[r] and heap[r][1] < heap[m][1] then m = r end
            if m == k then break end
            heap[m], heap[k] = heap[k], heap[m]
            k = m
        end
        return top
    end
    while #heap > 0 do
        local i = pop()[2]
        if i == goal then break end
        if not closed[i] then
            closed[i] = true
            local ix, iy = i % g.nx, math.floor(i / g.nx)
            for _, nb in ipairs(NEIGHBOURS) do
                local jx, jy = ix + nb[1], iy + nb[2]
                if jx >= 0 and jy >= 0 and jx < g.nx and jy < g.ny then
                    local j = jy * g.nx + jx
                    if passable(g, j) and not closed[j] then
                        local step = nb[3] * g.cell
                        if weight > 0 then
                            local p = g.buddy[j] + g.wallp[j]
                            step = step * (1 + weight * p / (p + PAINT.SATURATE))
                        end
                        local c = cost[i] + step
                        if not cost[j] or c < cost[j] then
                            cost[j], from[j] = c, i
                            local x, y = cell_xy(g, j)
                            push(c + math.sqrt((x - gx) ^ 2 + (y - gy) ^ 2), j)
                        end
                    end
                end
            end
        end
    end
    if not cost[goal] then return nil end
    local cells = {}
    local i = goal
    while i do table.insert(cells, 1, i); i = from[i] end
    -- pull straight: from each kept point, jump to the farthest cell ahead
    -- (up to 16) that a straight line reaches over passable cells
    local pts, px, py, k = {}, ax, ay, 1
    while k <= #cells do
        local best = k
        for j = math.min(#cells, k + 16), k, -1 do
            local x, y = cell_xy(g, cells[j])
            if line_clear(g, px, py, x, y) then best = j; break end
        end
        px, py = cell_xy(g, cells[best])
        pts[#pts + 1] = { x = px, y = py }
        k = best + 1
    end
    pts[#pts] = { x = bx, y = by }
    return pts
end
Roam.paint_path = grid_path
Roam.paint_line_clear = line_clear
Roam.paint_passable = passable
-- }}}

-- {{{ function Roam.paint_disc_map
-- The squished circle (the owner, 2026-09-27: "project the actual borders
-- onto a circle that's been squished to fit them"): every cell inside the
-- area's outline gets a place (u, v) in the unit disc. The cells on the
-- outline are put round the circle in order, spaced by distance along the
-- outline; every other cell is moved again and again to the average of its
-- four neighbours until nothing moves (a harmonic, or Tutte, map; solved by
-- over-relaxed Gauss-Seidel sweeps).
-- Why it can't fold: a harmonic map whose border goes once round a convex
-- shape (the circle) in order is one-to-one inside (Rado-Kneser-Choquet;
-- Tutte's theorem for graphs): each cell is the average of its neighbours,
-- so none can be pushed past them, and the local stretch (the Jacobian)
-- keeps one sign everywhere, never flipping into a fold. That is the
-- property docs/reference/jacobian-conjecture/ is about: locally undoable
-- everywhere; here the convex border makes it undoable overall too. So each
-- point of the disc names one place in the area, and a pinwheel run in the
-- disc's angle and radius turns round an L's bend, runs down corridors
-- (thin bands of the disc) and into dead ends (parts of the rim).
-- Rocks are not holes here: the map covers the outline; a waypoint landing
-- on a rock is moved to the nearest open cell.
function Roam.paint_disc_map(g, sweeps)
    local o = g.area.outline
    -- each outline edge's start, measured along the outline
    local along, total = {}, 0
    for k = 1, #o do
        local j = k % #o + 1
        along[k] = total
        total = total + math.sqrt((o[j][1] - o[k][1]) ^ 2 + (o[j][2] - o[k][2]) ^ 2)
    end
    local function outline_param(x, y)
        local best, bt = math.huge, 0
        for k = 1, #o do
            local j = k % #o + 1
            local ax, ay, vx, vy = o[k][1], o[k][2], o[j][1] - o[k][1], o[j][2] - o[k][2]
            local len2 = vx * vx + vy * vy
            local t = math.max(0, math.min(1, ((x - ax) * vx + (y - ay) * vy) / len2))
            local d = (ax + vx * t - x) ^ 2 + (ay + vy * t - y) ^ 2
            if d < best then best, bt = d, along[k] + t * math.sqrt(len2) end
        end
        return bt / total
    end
    g.du, g.dv, g.rim = {}, {}, {}
    local inner = {}
    for iy = 0, g.ny - 1 do
        for ix = 0, g.nx - 1 do
            local i = iy * g.nx + ix
            if g.inside[i] then
                local rim = false
                for _, nb in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
                    local jx, jy = ix + nb[1], iy + nb[2]
                    if jx < 0 or jy < 0 or jx >= g.nx or jy >= g.ny or not g.inside[jy * g.nx + jx] then rim = true end
                end
                if rim then
                    local x, y = cell_xy(g, i)
                    local a = 2 * math.pi * outline_param(x, y)
                    g.du[i], g.dv[i], g.rim[i] = math.cos(a), math.sin(a), true
                else
                    g.du[i], g.dv[i] = 0, 0
                    inner[#inner + 1] = i
                end
            end
        end
    end
    local w = 1.9                            -- over-relaxation: converges far faster on long corridors
    for _ = 1, sweeps or 3000 do
        for _, i in ipairs(inner) do
            local ix, iy = i % g.nx, math.floor(i / g.nx)
            local su, sv, n = 0, 0, 0
            for _, j in ipairs({ i - 1, i + 1, i - g.nx, i + g.nx }) do
                if g.du[j] then su, sv, n = su + g.du[j], sv + g.dv[j], n + 1 end
            end
            if n > 0 then
                g.du[i] = (1 - w) * g.du[i] + w * su / n
                g.dv[i] = (1 - w) * g.dv[i] + w * sv / n
            end
        end
    end
    -- the cells a waypoint may take (open, 3 yards off walls), for lookups
    g.disc_clear = {}
    for _, i in ipairs(g.open_list) do
        if g.wall[i] >= 3 and g.du[i] then g.disc_clear[#g.disc_clear + 1] = i end
    end
end
-- }}}

-- {{{ local function nearest_in_disc
-- The waypoint-worthy cell whose disc place is nearest the disc point at
-- angle `a` and radius `r` (0..1).
local function nearest_in_disc(g, a, r)
    local u, v = math.cos(a) * r, math.sin(a) * r
    local best, bd
    for _, i in ipairs(g.disc_clear) do
        local d = (g.du[i] - u) ^ 2 + (g.dv[i] - v) ^ 2
        if not bd or d < bd then best, bd = i, d end
    end
    return best
end
-- }}}

-- {{{ local function score_spot
-- How worth visiting a spot is, lower better: how painted the ground round
-- it is (0..1), less a bonus for being far from where the owner entered
-- the area (the owner: "prioritizing the spots farthest from the
-- entrance"), far_weight x the share of the farthest distance.
local function score_spot(s, x, y)
    local far = math.sqrt((x - s.entrance[1]) ^ 2 + (y - s.entrance[2]) ^ 2) / s.far_ref
    return painted_near(s.grid, x, y) - s.far_weight * far
end
-- }}}

-- {{{ the four ways of choosing (s.paint_mode)
-- Each sets b.goal = { x, y } (and may move the pinwheel's own state).
local PAINT_PICK = {}

-- "pinwheel": today's rules (the owner's pinwheel, crowding, openings);
-- paint is laid and drawn but not used.
PAINT_PICK.pinwheel = function(s, b, rand)
    pick_waypoint(s, b, rand)
    b.goal = { x = b.wp.x, y = b.wp.y }
end

-- "choose": the pinwheel proposes; it and eight neighbours of it (half a
-- turn either way, 15 points out or in) are weighed and the least
-- painted, farthest from the entrance, wins. The pinwheel's own bearing
-- and Y stay as proposed, so its laps keep their shape.
PAINT_PICK.choose = function(s, b, rand)
    pick_waypoint(s, b, rand)
    local best, bs = { x = b.wp.x, y = b.wp.y }, score_spot(s, b.wp.x, b.wp.y)
    for _, da in ipairs({ 0, -s.turn / 2, s.turn / 2 }) do
        for _, dy in ipairs({ 0, -0.15, 0.15 }) do
            if da ~= 0 or dy ~= 0 then
                local a = b.wp.bearing + da
                local reach = ray_to_edge(s.area, s.cx, s.cy, a) - s.clearance
                local share = math.max(0.01, math.min(1, b.wp.share + dy))
                local d = math.max(s.near, share * reach)
                local x, y = s.cx + math.cos(a) * d, s.cy + math.sin(a) * d
                if Roam.walkable(s.area, x, y, s.clearance) and Roam.edge_distance(s.area, x, y) >= s.clearance then
                    local sc = score_spot(s, x, y)
                    if sc < bs then best, bs = { x = x, y = y }, sc end
                end
            end
        end
    end
    b.goal = best
end

-- "least": no pinwheel: of 30 random open spots 12 to 70 yards away, the
-- least painted (farthest from the entrance breaking near-ties). The walls'
-- own paint is what keeps it off them.
PAINT_PICK.least = function(s, b, rand)
    local g = s.grid
    local best, bs, weighed = nil, nil, 0
    for _ = 1, 400 do                                  -- draws, of which 30 in range are weighed
        local i = g.open_list[math.floor(rand() * #g.open_list) + 1]
        if g.wall[i] >= s.clearance then
            local x, y = cell_xy(g, i)
            local d = math.sqrt((x - b.x) ^ 2 + (y - b.y) ^ 2)
            if d >= 12 and d <= 70 then
                local sc = score_spot(s, x, y)
                if not bs or sc < bs then best, bs = { x = x, y = y }, sc end
                weighed = weighed + 1
                if weighed >= 30 then break end
            end
        end
    end
    -- none in range (a buddy boxed into a tiny room): stay put this time
    b.goal = best or { x = b.x, y = b.y }
end

-- {{{ quadrant sensing (Roam.sense_sectors, and "sense" below)
-- The owner, 2026-09-27 (617e6): "let's look at the 4 quadrants around us,
-- then at the 4 peridicular quadrants (rotated 45 degrees, isometric style)
-- and if a high percentage of the terrain in a quadrant is impassible then
-- it's probably a surface. But if there is a high percentage but we can
-- still pathfind to the edge of our pathfinding radius, then it's a tunnel
-- there. [...] Once it checks all of the quadrants and identifies a path,
-- we prioritize the tunnel areas unless we've already painted that area
-- recently."
-- Eight sectors, each a quarter circle (90 degrees) wide, centred every 45
-- degrees: the four quadrants and the four turned 45 degrees, so each
-- direction is read by two overlapping sectors. The view is weighted
-- strongest near the buddy, fading to nothing at the sensing radius
-- (weight 1 - d / RADIUS): what is close decides a sector's character, as
-- a wall at arm's length does more to block a way than one far off.
--   blocked  - the weighted share of the sector's ground that is not walkable
--   through  - a walkable way (breadth first over open cells, anywhere within
--              the radius) reaches the sector's outer ring (the sensing
--              radius, less a cell and a half) within the sector's middle
--              half (22.5 degrees either side of its centre). The whole
--              quarter was tried first (2026-09-27): a straight tunnel's line
--              lies on the edge of the two diagonal sectors beside it, so
--              they read "tunnel" too, and a buddy next to a room read its
--              sideways sectors as tunnels through the room.
--   kind     - blocked >= BLOCKED: "tunnel" if through, else "wall";
--              otherwise "open"
-- The breadth-first walk grows ring by ring from the buddy (the owner's
-- "growing circular"), so each sector also records how far its way got
-- (reach) and the cell it got to (far): a tunnel's far cell is where a
-- buddy heading into it aims.
local SENSE = {
    RADIUS     = 40,    -- yards the buddy senses round itself
    BLOCKED    = 0.6,   -- a sector this blocked is a wall, or a tunnel if a way runs through.
                        -- Tuned 2026-09-27 on the big dungeon arena, 16 runs each, 1/2/4 buddies:
                        -- 0.4 counted room corners as tunnels (most picks, best only with 4
                        -- buddies); 0.5 was between; 0.6 reached both far rooms soonest with 1
                        -- and 2 buddies (1929 and 1215 ticks, against 2666 and 1994 with no
                        -- sensing) and explored 90% soonest with 2; 0.7 almost never saw a tunnel
                        -- (3 picks a run) and was no better than none.
    RECENT     = 900,   -- ticks: ground seen up close this recently counts as "painted recently"
    RECENT_MAX = 0.35,  -- a tunnel whose far half is more than this share recently seen is passed over
}
Roam.SENSE = SENSE
function Roam.sense_sectors(g, x, y, radius)
    radius = radius or SENSE.RADIUS
    local ci = cell_of(g, x, y)
    if not ci then return {} end
    local cxi, cyi = ci % g.nx, math.floor(ci / g.nx)
    local rc = math.ceil(radius / g.cell)
    local secs = {}
    for k = 0, 7 do secs[k + 1] = { angle = k * math.pi / 4, wsum = 0, bsum = 0, reach = 0 } end
    -- which sectors a direction falls in: within `half` of a centre (45
    -- degrees for the view, 22.5 for the way through)
    local function each_sector(a, fn, half)
        half = half or math.pi / 4
        for k = 1, 8 do
            local da = (a - secs[k].angle + math.pi) % (2 * math.pi) - math.pi
            if math.abs(da) <= half + 1e-9 then fn(secs[k]) end
        end
    end
    -- the weighted view
    for oy = -rc, rc do
        for ox = -rc, rc do
            if ox ~= 0 or oy ~= 0 then
                local d = math.sqrt(ox * ox + oy * oy) * g.cell
                if d <= radius then
                    local ix, iy = cxi + ox, cyi + oy
                    local blocked = true
                    if ix >= 0 and iy >= 0 and ix < g.nx and iy < g.ny then
                        blocked = not g.open[iy * g.nx + ix]
                    end
                    local w = 1 - d / radius
                    each_sector(math.atan2(oy, ox), function(sc)
                        sc.wsum = sc.wsum + w
                        if blocked then sc.bsum = sc.bsum + w end
                    end)
                end
            end
        end
    end
    -- the walk: breadth first over open cells within the radius
    local seen, queue, head = { [ci] = true }, { ci }, 1
    while head <= #queue do
        local c = queue[head]; head = head + 1
        local ix, iy = c % g.nx, math.floor(c / g.nx)
        local ox, oy = ix - cxi, iy - cyi
        local d = math.sqrt(ox * ox + oy * oy) * g.cell
        if c ~= ci then
            each_sector(math.atan2(oy, ox), function(sc)
                if d > sc.reach then sc.reach, sc.far = d, c end
            end, math.pi / 8)
        end
        for _, nb in ipairs(NEIGHBOURS) do
            local jx, jy = ix + nb[1], iy + nb[2]
            if jx >= 0 and jy >= 0 and jx < g.nx and jy < g.ny then
                local j = jy * g.nx + jx
                if not seen[j] and g.open[j] and ((jx - cxi) ^ 2 + (jy - cyi) ^ 2) * g.cell * g.cell <= radius * radius then
                    seen[j] = true
                    queue[#queue + 1] = j
                end
            end
        end
    end
    for _, sc in ipairs(secs) do
        sc.blocked = sc.wsum > 0 and sc.bsum / sc.wsum or 1
        sc.through = sc.reach >= radius - 1.5 * g.cell
        sc.kind = sc.blocked >= SENSE.BLOCKED and (sc.through and "tunnel" or "wall") or "open"
    end
    return secs
end
-- }}}

-- "sense": the owner's quadrant sensing on top of "least". A buddy
-- choosing its next goal reads its eight sectors; a sector read as a
-- tunnel whose far half hasn't been seen up close recently (RECENT_MAX of
-- its cells within RECENT ticks) is a candidate, scored by how tunnel-like
-- it is (its blocked share) less how recently seen, plus a share for being
-- far from the entrance; the best one's far cell becomes the goal, so the
-- buddy walks into the tunnel and on through it (the next reading, inside,
-- sees the tunnel going on ahead and the way it came as recent). With no
-- such tunnel it chooses as "least" does. Scores steer; there is no budget
-- (the owner: "They both provide priority correlation scores, no need to
-- optimize to any metric budgets").
local function recent_share(s, g, sc)
    -- the share of the sector's far half (cells of the walk beyond half the
    -- radius, in the sector) seen up close within RECENT ticks
    local n, r = 0, 0
    local fx, fy = cell_xy(g, sc.far)
    local reach = math.ceil(SENSE.RADIUS / 2 / g.cell)
    local fxi, fyi = sc.far % g.nx, math.floor(sc.far / g.nx)
    for oy = -reach, reach do
        for ox = -reach, reach do
            local ix, iy = fxi + ox, fyi + oy
            if ix >= 0 and iy >= 0 and ix < g.nx and iy < g.ny then
                local i = iy * g.nx + ix
                if g.open[i] then
                    n = n + 1
                    local ct = g.close_t[i]
                    if ct and g.now - ct < SENSE.RECENT then r = r + 1 end
                end
            end
        end
    end
    return n > 0 and r / n or 0, fx, fy
end
PAINT_PICK.sense = function(s, b, rand)
    local g = s.grid
    local secs = Roam.sense_sectors(g, b.x, b.y, SENSE.RADIUS)
    b.sense, b.sense_pick = secs, nil
    local best, bs, bx, by
    for k, sc in ipairs(secs) do
        if sc.kind == "tunnel" and sc.far then
            local recent, fx, fy = recent_share(s, g, sc)
            if recent <= SENSE.RECENT_MAX then
                local far = math.sqrt((fx - s.entrance[1]) ^ 2 + (fy - s.entrance[2]) ^ 2) / s.far_ref
                local score = sc.blocked - recent + s.far_weight * far
                if not bs or score > bs then best, bs, bx, by = k, score, fx, fy end
            end
        end
    end
    if best then
        b.sense_pick = best
        b.goal = { x = bx, y = by }
        s.stats.sense_tunnel = (s.stats.sense_tunnel or 0) + 1
        return
    end
    PAINT_PICK.least(s, b, rand)
end

-- "disc": the pinwheel run in the squished circle (Roam.paint_disc_map):
-- the angle turns a steady step, the radius is the owner's Y rule; that
-- point and its eight neighbours (as in "choose") are looked up to their
-- cells and weighed by paint.
PAINT_PICK.disc = function(s, b, rand)
    local g = s.grid
    b.dang = b.dang + s.turn * b.spin
    b.dshare = Y_DRAW.step(s, b.dshare, rand)
    local best, bs
    for _, da in ipairs({ 0, -s.turn / 2, s.turn / 2 }) do
        for _, dy in ipairs({ 0, -0.15, 0.15 }) do
            local i = nearest_in_disc(g, b.dang + da, math.max(0.01, math.min(1, b.dshare + dy)))
            local x, y = cell_xy(g, i)
            local sc = score_spot(s, x, y)
            if not bs or sc < bs then best, bs = { x = x, y = y }, sc end
        end
    end
    b.goal = best
end

-- "rooms": the pinwheel round the middle of the room the buddy is in
-- (the owner, 2026-09-27: "their midpoint [...] should be the midpoint of
-- the room that they're in"), in that room's own coordinates: the bearing
-- from the room's centre turns a steady step, Y is the owner's step rule,
-- and the edge along a bearing is where the line leaves the room (a wall,
-- or the mouth of a tunnel; rocks inside the room don't stop it). Of the
-- proposal and eight near it the least painted wins, as in "choose".
-- Leaving: once the room is ROOM_LEAVE explored (seen up close) and some
-- other room is less so, the paint draws the buddy on: its goal becomes
-- the least painted of 30 spots in the least explored room (farther from
-- the entrance weighing more), and the paint-weighted path takes it there
-- through the tunnels, kept to their middles by the walls' paint. On
-- arriving in the new room it orbits that room's middle.
local function cells_explored(g, cells)
    local n, seen = 0, 0
    for _, i in ipairs(cells) do n = n + 1; if g.close[i] then seen = seen + 1 end end
    return n > 0 and seen / n or 1
end
local function room_explored(g, r) return cells_explored(g, g.rooms[r].cells) end
Roam.paint_room_explored = room_explored
-- is the buddy's cell part of place p?
local function in_place(g, p, i)
    if not i then return false end
    if p.kind == "room" then return g.room[i] == p.id end
    return g.tunnel[i] == p.id
end
local function room_reach(g, r, a)
    local room = g.rooms[r]
    local dx, dy = math.cos(a), math.sin(a)
    local d = 0
    while true do
        local i = cell_of(g, room.cx + dx * (d + g.cell * 0.5), room.cy + dy * (d + g.cell * 0.5))
        if not i or not g.inside[i] or (g.open[i] and g.room[i] ~= r) then return d end
        d = d + g.cell * 0.5
    end
end
local function room_spot_ok(s, r, x, y)
    local i = cell_of(s.grid, x, y)
    return i and s.grid.open[i] and s.grid.room[i] == r and s.grid.wall[i] >= s.clearance
end
PAINT_PICK.rooms = function(s, b, rand)
    local g = s.grid
    local ci = cell_of(g, b.x, b.y)
    local here = g.room[ci or -1]
    if here and here ~= b.room then b.room, b.rshare = here, 0.5 end
    -- arrived where the paint drew it (a room, or the spot it chose in a
    -- tunnel): the drawing is done
    if b.heading and (in_place(g, g.places[b.heading], ci) or (b.goal and (b.goal.x - b.x) ^ 2 + (b.goal.y - b.y) ^ 2 < 4)) then
        b.heading = nil
    end
    -- a buddy that has never stood in a room (it starts in a tunnel) takes
    -- the room whose middle is nearest
    if not b.room then
        local best, bd
        for k, room in ipairs(g.rooms) do
            local d = (room.cx - b.x) ^ 2 + (room.cy - b.y) ^ 2
            if not bd or d < bd then best, bd = k, d end
        end
        b.room, b.rshare = best, 0.5
    end
    local r = b.room
    -- leave? Once this room is ROOM_LEAVE explored, the paint draws the
    -- buddy to the least explored other place, a room or a tunnel (dead ends
    -- included), farther from the entrance weighing more: first to places
    -- still under ROOM_LEAVE; once every place is past it, to the least
    -- explored place if it is at least 5 points less explored than this
    -- room, so buddies keep circulating until the last corners are seen
    -- (a room that passed ROOM_LEAVE keeps its unseen corners otherwise).
    local mine = room_explored(g, r)
    if not b.heading and mine >= PAINT.ROOM_LEAVE then
        local best, bs, under
        for k, p in ipairs(g.places) do
            if not (p.kind == "room" and p.id == r) then
                local e = cells_explored(g, p.cells)
                if e < 1 then
                    local far = math.sqrt((p.cx - s.entrance[1]) ^ 2 + (p.cy - s.entrance[2]) ^ 2) / s.far_ref
                    local sc = e - s.far_weight * far
                    local u = e < PAINT.ROOM_LEAVE
                    -- places under the bar beat places over it
                    if not bs or (u and not under) or (u == under and sc < bs) then best, bs, under = k, sc, u end
                end
            end
        end
        if best and (under or cells_explored(g, g.places[best].cells) <= mine - 0.05) then b.heading = best end
    end
    if b.heading then
        local room = g.places[b.heading]
        local pick, ps
        for _ = 1, 30 do
            local i = room.cells[math.floor(rand() * #room.cells) + 1]
            if g.wall[i] >= math.min(s.clearance, room.kind == "tunnel" and 2 or s.clearance) then
                local x, y = cell_xy(g, i)
                local sc = score_spot(s, x, y)
                if not ps or sc < ps then pick, ps = { x = x, y = y }, sc end
            end
        end
        b.goal = pick or { x = room.cx, y = room.cy }
        return
    end
    -- orbit this room's middle
    local room = g.rooms[r]
    b.rang = (b.rang or math.atan2(b.y - room.cy, b.x - room.cx)) + s.turn * b.spin
    b.rshare = Y_DRAW.step(s, b.rshare or 0.5, rand)
    local best, bs
    for _, da in ipairs({ 0, -s.turn / 2, s.turn / 2 }) do
        for _, dy in ipairs({ 0, -0.15, 0.15 }) do
            local a = b.rang + da
            local reach = room_reach(g, r, a) - s.clearance
            local share = math.max(0.01, math.min(1, b.rshare + dy))
            -- a blocked spot slides along its bearing to the nearest clear
            -- one, as the owner's step rule does (1% at a time)
            for k = 1, 199 do
                local sh = share + math.floor(k / 2) * (k % 2 == 0 and -1 or 1) / 100
                if sh >= 0.01 and sh <= 1 then
                    local d = math.max(math.min(s.near, reach), sh * reach)
                    local x, y = room.cx + math.cos(a) * d, room.cy + math.sin(a) * d
                    if room_spot_ok(s, r, x, y) then
                        local sc = score_spot(s, x, y)
                        if not bs or sc < bs then best, bs = { x = x, y = y }, sc end
                        break
                    end
                end
            end
        end
    end
    b.goal = best or { x = room.cx, y = room.cy }
end
-- }}}

-- {{{ local function paint_tick
-- One tick of the "paint" reading, for the whole clan: the walls' pulse,
-- each buddy's paint (even while busy fighting: the owner, "bots should
-- keep painting while fighting"), its walk along its path, a new goal and
-- path when it arrives, and the measures the comparisons print (s.stats).
local function paint_tick(s, rand)
    local g = s.grid
    s.t = (s.t or 0) + 1
    g.now = s.t
    -- the walls pulse from the first tick on, every wall_every ticks
    if s.wall_paint and (s.t - 1) % s.wall_every == 0 then wall_pulse(g) end
    local st = s.stats
    for _, b in ipairs(s.buddies) do
        if (s.t + b.id) % s.paint_every == 0 then deposit(g, b.x, b.y) end
        -- measures: time near walls, cells entered, revisits
        local ci = cell_of(g, b.x, b.y)
        st.ticks = st.ticks + 1
        if ci and g.wall[ci] and g.wall[ci] < 3 then st.near_wall = st.near_wall + 1 end
        -- in a tunnel: how far off its middle line (the tunnel's widest
        -- distance to the outline, less this cell's)
        if ci and g.tunnel[ci] then
            st.tunnel_ticks = st.tunnel_ticks + 1
            st.tunnel_off = st.tunnel_off + (g.tunnels[g.tunnel[ci]].half - g.edge[ci])
        end
        if ci and ci ~= b.cell then
            st.entries = st.entries + 1
            local lt = g.last_t[ci]
            if lt and s.t - lt < PAINT.REVISIT and not (g.last_id[ci] == b.id and s.t - lt < PAINT.OWN_TRAIL) then
                st.revisits = st.revisits + 1
            end
            b.cell = ci
        end
        if ci then g.last_t[ci], g.last_id[ci] = s.t, b.id end

        if (b.busy or 0) > 0 then
            b.busy = b.busy - 1
        else
            if not b.path or b.path_i > #b.path then
                PAINT_PICK[s.paint_mode](s, b, rand)
                b.path = grid_path(g, b.x, b.y, b.goal.x, b.goal.y, s.paint_mode == "pinwheel" and 0 or s.path_weight)
                    or { { x = b.x, y = b.y } }
                b.path_i = 1
                b.wp = b.goal
            end
            local left = s.step
            while left > 0 and b.path_i <= #b.path do
                local p = b.path[b.path_i]
                local d = math.sqrt((p.x - b.x) ^ 2 + (p.y - b.y) ^ 2)
                if d > left then
                    b.x, b.y = b.x + (p.x - b.x) / d * left, b.y + (p.y - b.y) / d * left
                    left = 0
                else
                    b.x, b.y, left = p.x, p.y, left - d
                    b.path_i = b.path_i + 1
                end
            end
        end
    end
end
-- }}}

-- {{{ function Roam.paint_coverage
-- The share (0..1) of the area's open cells some buddy has seen from
-- within PAINT.CLOSE yards (explored up close; walls' paint doesn't count).
-- Paint counts themselves grow without end, so they are not the measure.
function Roam.paint_coverage(g)
    local n = 0
    for _, i in ipairs(g.open_list) do if g.close[i] then n = n + 1 end end
    return n / #g.open_list
end
-- }}}
-- }}}

-- {{{ function Roam.tick
-- Every buddy takes one step (or stands). Buddies move in turn, each seeing
-- the others' new places, as the server would update them one by one.
-- Fills b.last = { candidates = { {x, y, score, list, ok}, ... }, chosen }
-- for drawing.
function Roam.tick(s, rand)
    -- paint: the clan paints and chooses by paint (see "painting" above)
    if s.reading == "paint" then return paint_tick(s, rand) end
    -- waypoints: a buddy walks its own route, no candidate scoring. Its
    -- first waypoint is picked here rather than in Roam.new so that every
    -- buddy is in place first (the blend compares waypoints).
    if s.reading == "waypoints" then
        for _, b in ipairs(s.buddies) do
            if not b.wp then pick_waypoint(s, b, rand) end
            waypoint_tick(s, b, rand)
        end
        return
    end
    for _, b in ipairs(s.buddies) do
        if s.reading == "spin-lists" then b.spin = choose_spin(s, b) end
        local cands, best = {}, nil
        local base = { fill = far_fill(s.buddies, b, b.x, b.y, s.spacing), keep = keep_at(s, b, b.x, b.y) }
        -- standing still is always a candidate
        local sc, list = score(s, b, b.x, b.y, 0, 0, rand, base)
        cands[1] = { x = b.x, y = b.y, score = sc - 0.2, list = list, ok = true }
        best = cands[1]
        for k = 0, s.headings - 1 do
            local a = 2 * math.pi * k / s.headings
            local dx, dy = math.cos(a), math.sin(a)
            local x, y = b.x + dx * s.step, b.y + dy * s.step
            local c = { x = x, y = y, ok = Roam.walkable(s.area, x, y, s.margin) }
            if c.ok then
                c.score, c.list = score(s, b, x, y, dx, dy, rand, base)
                if c.score > best.score then best = c end
            end
            cands[#cands + 1] = c
        end
        b.x, b.y = best.x, best.y
        b.last = { candidates = cands, chosen = best }
    end
end
-- }}}

-- {{{ function Roam.rest_chance
-- The chance (0..0.5) a buddy sits down to eat or regenerate on reaching a
-- waypoint: half the share of its health that is missing (the owner,
-- 2026-09-27: "The chance is the % of your health that's missing, divided
-- by 2"). Full health never rests; at 60% health, 20%; near death, 50%.
-- health, max_health: numbers, max_health > 0.
function Roam.rest_chance(health, max_health)
    return (1 - health / max_health) / 2
end
-- }}}

-- {{{ function Roam.grouping
-- The proximity party (617c2): leave past `leave` yards from the owner,
-- join inside `join` while the group has room (`seats`, 4 with the owner's
-- own seat taken). Updates b.grouped (and b.far, the far buddies' own
-- party, when `far` is given); returns the grouped count.
function Roam.grouping(buddies, ox, oy, join, leave, seats, far)
    local count = 0
    for _, b in ipairs(buddies) do
        local d = math.sqrt((b.x - ox) ^ 2 + (b.y - oy) ^ 2)
        if b.grouped and d > leave then b.grouped = false end
        if b.grouped then count = count + 1 end
    end
    -- join nearest first, so a free seat goes to the closest buddy
    local waiting = {}
    for _, b in ipairs(buddies) do
        local d = math.sqrt((b.x - ox) ^ 2 + (b.y - oy) ^ 2)
        if not b.grouped and d < join then waiting[#waiting + 1] = { b = b, d = d } end
    end
    table.sort(waiting, function(p, q) return p.d < q.d end)
    for _, w in ipairs(waiting) do
        if count < seats then w.b.grouped = true; count = count + 1 end
    end
    -- the far buddies' own party (617c2, 2026-09-27), when `far` is given:
    -- ungrouped and past `far` yards is in it, back inside `far` is out
    -- (the party's size limit and leader are the server's business)
    if far then
        for _, b in ipairs(buddies) do
            local d = math.sqrt((b.x - ox) ^ 2 + (b.y - oy) ^ 2)
            b.far = not b.grouped and d > far
        end
    end
    return count
end
-- }}}

return Roam
