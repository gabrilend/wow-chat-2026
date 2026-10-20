
local Roam = {}

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

local function inside_rects(rects, x, y)
    for _, r in ipairs(rects) do
        if x >= r[1] and x <= r[3] and y >= r[2] and y <= r[4] then return true end
    end
    return false
end

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

function Roam.centre(area)
    if area.centre then return area.centre[1], area.centre[2] end
    local sx, sy = 0, 0
    for _, p in ipairs(area.outline) do sx, sy = sx + p[1], sy + p[2] end
    return sx / #area.outline, sy / #area.outline
end

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

local function far_list(buddies, me, x, y, spacing)
    local list = {}
    for _, b in ipairs(buddies) do
        if b ~= me and (b.x - x) ^ 2 + (b.y - y) ^ 2 >= spacing * spacing then list[#list + 1] = b.id end
    end
    return list
end

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

local function tangent(cx, cy, x, y, spin)
    local rx, ry = x - cx, y - cy
    local len = math.sqrt(rx * rx + ry * ry)
    if len < 1e-6 then return 0, 0 end
    return -ry / len * spin, rx / len * spin
end

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
    if s.reading == "waypoints" or s.reading == "paint" then
        for _, b in ipairs(buddies) do b.angle = math.atan2(b.y - s.cy, b.x - s.cx) end
    end
    if s.reading == "paint" then
        s.grid        = params.grid
        s.paint_mode  = params.paint_mode or "choose"
        s.entrance    = params.entrance
        s.wall_paint  = params.wall_paint ~= false
        s.paint_every = params.paint_every or 4
        s.wall_every  = params.wall_every or 48
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

local function keep_at(s, b, x, y)
    local nn = nearest(s.buddies, b, x, y)
    return -math.min(math.abs(nn - s.spacing) / s.spacing, 2)
end

local function score(s, b, x, y, dx, dy, rand, base)
    local list = far_list(s.buddies, b, x, y, s.spacing)
    local gain = s.spacing / s.step
    local tx, ty = tangent(s.cx, s.cy, b.x, b.y, b.spin)
    local turn = dx * tx + dy * ty
    local keep = (keep_at(s, b, x, y) - base.keep) * gain
    local fill = (far_fill(s.buddies, b, x, y, s.spacing) - base.fill) * gain
    local nudge = (rand() - 0.5) * 2 * s.noise
    local ed = Roam.edge_distance(s.area, x, y)
    local rim = ed < s.edge and -(1 - ed / s.edge) or 0
    local wall = 1.2 * rim

    if s.reading == "spring" then
        return 1.0 * keep + 0.5 * turn + wall + nudge, list
    end
    return 1.5 * fill + 0.5 * turn + 0.3 * keep + wall + nudge, list
end

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


local PLAN = {
    STEP_RISE  = 0.6,
    BOWS       = { 0, -0.15, 0.15, -0.3, 0.3 },
    SLOPE_W    = 6,
    ROAD_F     = 0.6,
    MAX_DETOUR = 8,
    MAX_SIDE   = 16,
    RAMP_MIN   = 3,
}
Roam.PLAN = PLAN

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

local function ray_to_edge(area, cx, cy, a)
    local dx, dy, best = math.cos(a), math.sin(a), math.huge
    local o = area.outline
    for i = 1, #o do
        local j = i % #o + 1
        local ax, ay = o[i][1], o[i][2]
        local ex, ey = o[j][1] - ax, o[j][2] - ay
        local den = dx * ey - dy * ex
        if math.abs(den) > 1e-9 then
            local t = ((ax - cx) * ey - (ay - cy) * ex) / den
            local u = ((ax - cx) * dy - (ay - cy) * dx) / den
            if t > 0 and u >= 0 and u <= 1 and t < best then best = t end
        end
    end
    return best
end

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

local function seen_through(area, ax, ay, bx, by)
    local len = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
    local n = math.max(1, math.ceil(len))
    for i = 1, n - 1 do
        local k = i / n
        if not Roam.walkable({ outline = area.outline, walls = {} }, ax + (bx - ax) * k, ay + (by - ay) * k, 0) then return false end
    end
    return true
end

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

local SHARE_TRIES, TURN_TRIES = 8, 12
local Y_DRAW = {
    points = function(s, y, rand)
        local lo, hi = math.max(0, y - s.y_limit), math.min(1, y + s.y_limit)
        return lo + (hi - lo) * rand()
    end,
    ratio  = function(s, y, rand)
        local lo, hi = math.max(s.y_floor, y * (1 - s.y_limit)), math.min(1, y * (1 + s.y_limit))
        return lo + (hi - lo) * rand()
    end,
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
        local bearing = s.openings > 0 and find_opening(s, b.angle) or b.angle
        if bearing ~= b.angle then b.opened = (b.opened or 0) + 1 end
        local reach = ray_to_edge(s.area, s.cx, s.cy, bearing) - s.clearance
        local best, best_room
        local limited = s.y_limit > 0 and b.share
        local slide = limited and s.y_mode == "step"
        local drawn = slide and Y_DRAW.step(s, b.share, rand)
        if slide and s.pierce > 0 then
            b.inward = drawn < b.share and (b.inward or 0) + 1 or 0
            if b.inward >= 2 and drawn * 100 <= s.pierce + 1e-9 then
                b.angle, b.spin, b.inward = b.angle + math.pi, -b.spin, 0
                bearing = b.angle
                reach = ray_to_edge(s.area, s.cx, s.cy, bearing) - s.clearance
                b.pierced = (b.pierced or 0) + 1
            end
        end
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
            if slide and (share < 0.01 or share > 1) then goto next_share end
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
            b.wp_ticks = 0
            b.via = s.reading ~= "paint" and turning_point(s, b, best) or nil
            b.via_kind = b.via and "turn" or nil
            if not b.via and #s.mobs > 0 then
                b.via = lure_point(s, b, best)
                b.via_kind = b.via and "lure" or nil
            end
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
            local along = cx * ux + cy * uy
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
        local cross = cx * uy - cy * ux
        b.orbit_side = math.abs(cross) > 0.5 and (cross > 0 and 1 or -1) or b.spin
        b.orbit_w = block
    end
    local side = b.orbit_side
    local rx, ry = cx / cd, cy / cd
    if cd > R then
        local a = math.asin(R / cd) * side
        return rx * math.cos(a) - ry * math.sin(a), rx * math.sin(a) + ry * math.cos(a), block
    end
    local tx, ty = -ry * side, rx * side
    local ox, oy = tx - rx * 0.4, ty - ry * 0.4
    local ol = math.sqrt(ox * ox + oy * oy)
    return ox / ol, oy / ol, block
end

local function waypoint_tick(s, b, rand)
    if (b.busy or 0) > 0 then b.busy = b.busy - 1 return end
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


local PAINT = {
    VISION     = 60,
    RAYS       = 90,
    NEAR_PAINT = 12,
    WALL_REACH = 5,
    WALL_PAINT = 400,
    ROOM_MIN   = 7,
    ROOM_LEAVE = 0.8,
    SATURATE   = 200,
    DISC       = 6,
    PATH_MARGIN = 1.5,
    CLOSE      = 20,
    REVISIT    = 400,
    OWN_TRAIL  = 60,
}
Roam.PAINT = PAINT

local paint_wall_cells
local function paint_grid_rects(g, area, cell)
    local nx, ny = g.nx, g.ny
    for iy = 0, ny - 1 do
        for ix = 0, nx - 1 do
            local i = iy * nx + ix
            local x, y = g.x0 + (ix + 0.5) * cell, g.y0 + (iy + 0.5) * cell
            g.inside[i] = inside_rects(area.rects, x, y)
        end
    end
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

function Roam.paint_grid(area, cell)
    local ffi = require("ffi")
    local minx, maxx, miny, maxy = math.huge, -math.huge, math.huge, -math.huge
    if area.rects then
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
    g.buddy = ffi.new("uint16_t[?]", g.n)
    g.wallp = ffi.new("uint16_t[?]", g.n)
    g.last_t, g.last_id = {}, {}
    g.close = {}
    g.close_t = {}
    g.now = 0
    g.open_list = {}
    if area.rects then return paint_grid_rects(g, area, cell) end
    for iy = 0, g.ny - 1 do
        for ix = 0, g.nx - 1 do
            local i = iy * g.nx + ix
            local x, y = minx + (ix + 0.5) * cell, miny + (iy + 0.5) * cell
            g.inside[i] = inside_polygon(area.outline, x, y)
            g.open[i] = g.inside[i] and Roam.walkable(area, x, y, 0)
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
function paint_wall_cells(g)
    g.wall_cells = {}
    for _, i in ipairs(g.open_list) do
        if g.wall[i] < PAINT.WALL_REACH then
            local k = 1 - g.wall[i] / PAINT.WALL_REACH
            g.wall_cells[#g.wall_cells + 1] = { i, math.floor(PAINT.WALL_PAINT * k * k + 0.5) }
        end
    end
end

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

local function deposit(g, x, y)
    for k = 0, PAINT.RAYS - 1 do
        local a = 2 * math.pi * k / PAINT.RAYS
        local dx, dy = math.cos(a), math.sin(a)
        local d = 0
        while d <= PAINT.VISION do
            local i = cell_of(g, x + dx * d, y + dy * d)
            if not i or not g.open[i] then break end
            local f = 1 - d / PAINT.VISION
            g.buddy[i] = g.buddy[i] + math.floor(PAINT.NEAR_PAINT * f * f) + 1
            if d <= PAINT.CLOSE then g.close[i] = true; g.close_t[i] = g.now end
            d = d + g.cell
        end
    end
end
Roam.paint_deposit = deposit

local function wall_pulse(g)
    for _, c in ipairs(g.wall_cells) do if g.wallp[c[1]] < c[2] then g.wallp[c[1]] = c[2] end end
end

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

function Roam.paint_disc_map(g, sweeps)
    local o = g.area.outline
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
    local w = 1.9
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
    g.disc_clear = {}
    for _, i in ipairs(g.open_list) do
        if g.wall[i] >= 3 and g.du[i] then g.disc_clear[#g.disc_clear + 1] = i end
    end
end

local function nearest_in_disc(g, a, r)
    local u, v = math.cos(a) * r, math.sin(a) * r
    local best, bd
    for _, i in ipairs(g.disc_clear) do
        local d = (g.du[i] - u) ^ 2 + (g.dv[i] - v) ^ 2
        if not bd or d < bd then best, bd = i, d end
    end
    return best
end

local function score_spot(s, x, y)
    local far = math.sqrt((x - s.entrance[1]) ^ 2 + (y - s.entrance[2]) ^ 2) / s.far_ref
    return painted_near(s.grid, x, y) - s.far_weight * far
end

local PAINT_PICK = {}

PAINT_PICK.pinwheel = function(s, b, rand)
    pick_waypoint(s, b, rand)
    b.goal = { x = b.wp.x, y = b.wp.y }
end

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

PAINT_PICK.least = function(s, b, rand)
    local g = s.grid
    local best, bs, weighed = nil, nil, 0
    for _ = 1, 400 do
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
    b.goal = best or { x = b.x, y = b.y }
end

local SENSE = {
    RADIUS     = 40,
    BLOCKED    = 0.6,
    RECENT     = 900,
    RECENT_MAX = 0.35,
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
    local function each_sector(a, fn, half)
        half = half or math.pi / 4
        for k = 1, 8 do
            local da = (a - secs[k].angle + math.pi) % (2 * math.pi) - math.pi
            if math.abs(da) <= half + 1e-9 then fn(secs[k]) end
        end
    end
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

local function recent_share(s, g, sc)
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

local function cells_explored(g, cells)
    local n, seen = 0, 0
    for _, i in ipairs(cells) do n = n + 1; if g.close[i] then seen = seen + 1 end end
    return n > 0 and seen / n or 1
end
local function room_explored(g, r) return cells_explored(g, g.rooms[r].cells) end
Roam.paint_room_explored = room_explored
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
    if b.heading and (in_place(g, g.places[b.heading], ci) or (b.goal and (b.goal.x - b.x) ^ 2 + (b.goal.y - b.y) ^ 2 < 4)) then
        b.heading = nil
    end
    if not b.room then
        local best, bd
        for k, room in ipairs(g.rooms) do
            local d = (room.cx - b.x) ^ 2 + (room.cy - b.y) ^ 2
            if not bd or d < bd then best, bd = k, d end
        end
        b.room, b.rshare = best, 0.5
    end
    local r = b.room
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
    local room = g.rooms[r]
    b.rang = (b.rang or math.atan2(b.y - room.cy, b.x - room.cx)) + s.turn * b.spin
    b.rshare = Y_DRAW.step(s, b.rshare or 0.5, rand)
    local best, bs
    for _, da in ipairs({ 0, -s.turn / 2, s.turn / 2 }) do
        for _, dy in ipairs({ 0, -0.15, 0.15 }) do
            local a = b.rang + da
            local reach = room_reach(g, r, a) - s.clearance
            local share = math.max(0.01, math.min(1, b.rshare + dy))
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

local function paint_tick(s, rand)
    local g = s.grid
    s.t = (s.t or 0) + 1
    g.now = s.t
    if s.wall_paint and (s.t - 1) % s.wall_every == 0 then wall_pulse(g) end
    local st = s.stats
    for _, b in ipairs(s.buddies) do
        if (s.t + b.id) % s.paint_every == 0 then deposit(g, b.x, b.y) end
        local ci = cell_of(g, b.x, b.y)
        st.ticks = st.ticks + 1
        if ci and g.wall[ci] and g.wall[ci] < 3 then st.near_wall = st.near_wall + 1 end
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

function Roam.paint_coverage(g)
    local n = 0
    for _, i in ipairs(g.open_list) do if g.close[i] then n = n + 1 end end
    return n / #g.open_list
end

function Roam.tick(s, rand)
    if s.reading == "paint" then return paint_tick(s, rand) end
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

function Roam.rest_chance(health, max_health)
    return (1 - health / max_health) / 2
end

function Roam.grouping(buddies, ox, oy, join, leave, seats, far)
    local count = 0
    for _, b in ipairs(buddies) do
        local d = math.sqrt((b.x - ox) ^ 2 + (b.y - oy) ^ 2)
        if b.grouped and d > leave then b.grouped = false end
        if b.grouped then count = count + 1 end
    end
    local waiting = {}
    for _, b in ipairs(buddies) do
        local d = math.sqrt((b.x - ox) ^ 2 + (b.y - oy) ^ 2)
        if not b.grouped and d < join then waiting[#waiting + 1] = { b = b, d = d } end
    end
    table.sort(waiting, function(p, q) return p.d < q.d end)
    for _, w in ipairs(waiting) do
        if count < seats then w.b.grouped = true; count = count + 1 end
    end
    if far then
        for _, b in ipairs(buddies) do
            local d = math.sqrt((b.x - ox) ^ 2 + (b.y - oy) ^ 2)
            b.far = not b.grouped and d > far
        end
    end
    return count
end

return Roam
