
local J = {}

local MOVE_YARDS    = 1
local WINDOW        = 12
local STEP          = 6
local CIRCLE_TURN   = math.pi
local REACH         = 20
local STILL_SECONDS = 30
local REST_YARDS    = 10
local STACK_YARDS   = 1
local STACK_SECONDS = 10
local GRID          = 533.3333

local function dist(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) end

function J.read(path, from, to)
    local f = io.open(path)
    if not f then return nil, "no record at " .. path end
    local groups, first, last = {}, nil, nil
    for line in f:lines() do
        local c = {}
        for v in (line .. "\t"):gmatch("([^\t]*)\t") do c[#c + 1] = v end
        local t, guid, name, kind, map, zone, area, x, y, fighting, dead, owner
        if #c == 13 and (c[4] == "player" or c[4] == "buddy" or c[4] == "bot") then
            t, guid, name, kind, map, zone, area, x, y, fighting, dead, owner = c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[11], c[12], c[13]
        elseif #c == 13 and (c[5] == "owner" or c[5] == "buddy") then
            t, owner, guid, name, map, zone, area, x, y, fighting, dead = c[1], c[2], c[3], c[4], c[6], c[7], c[8], c[9], c[10], c[12], c[13]
            kind = c[5] == "owner" and "player" or "buddy"
        end
        t = tonumber(t)
        if t and (not from or t >= from) and (not to or t <= to) then
            local s = { t = t, x = tonumber(x), y = tonumber(y), map = tonumber(map), zone = tonumber(zone), area = tonumber(area),
                        fighting = fighting == "1", dead = dead == "1" }
            guid = tonumber(guid)
            local key = kind == "buddy" and tonumber(owner) or (kind == "bot" and -guid or guid)
            groups[key] = groups[key] or { buddies = {}, owner = {} }
            local g = groups[key]
            if kind == "buddy" or kind == "bot" then
                g.buddies[guid] = g.buddies[guid] or { name = name, samples = {} }
                table.insert(g.buddies[guid].samples, s)
            else
                table.insert(g.owner, s)
            end
            first, last = math.min(first or t, t), math.max(last or t, t)
        end
    end
    f:close()
    for key, g in pairs(groups) do
        if next(g.buddies) == nil then groups[key] = nil end
    end
    return groups, first, last
end

local function owner_at(group, t)
    local best
    for _, s in ipairs(group.owner) do
        if math.abs(s.t - t) <= 5 and (not best or math.abs(s.t - t) < math.abs(best.t - t)) then best = s end
    end
    return best
end

function J.measure(group, area_squares)
    local moved, pairs_n = 0, 0
    local windows, cw, ccw, circling = {}, 0, 0, 0
    local winding = {}
    local evidence = { still = {}, stacked = {}, windows = {}, standing = {} }
    local still_n, minutes = 0, 0
    local names = {}
    for guid, b in pairs(group.buddies) do
        names[#names + 1] = guid
        local S = b.samples
        if #S > 1 then minutes = minutes + (S[#S].t - S[1].t) / 60 end
        local anchor = S[1]
        for i = 2, #S do
            local a, c = S[i - 1], S[i]
            if c.t - a.t <= 10 then
                pairs_n = pairs_n + 1
                local o = owner_at(group, c.t)
                if dist(a, c) > MOVE_YARDS then
                    moved = moved + 1
                else
                    local po = o and owner_at(group, a.t)
                    evidence.standing[#evidence.standing + 1] = { name = b.name, t = c.t, fighting = c.fighting, dead = c.dead,
                        owner_yards = o and dist(o, c) or nil, owner_moving = (o and po) and dist(o, po) > MOVE_YARDS or false }
                end
                if dist(anchor, c) >= MOVE_YARDS or c.fighting or c.dead then
                    anchor = c
                elseif c.t - anchor.t >= STILL_SECONDS and o and dist(o, c) > REST_YARDS and not anchor.counted then
                    anchor.counted = true
                    still_n = still_n + 1
                    evidence.still[#evidence.still + 1] = { name = b.name, t = anchor.t, seconds = c.t - anchor.t, owner_yards = dist(o, c) }
                end
            end
        end
        for w = 1, math.max(1, #S - WINDOW + 1), STEP do
            local net, len, prev = 0, 0, nil
            local last = math.min(#S, w + WINDOW - 1)
            for i = w + 1, last do
                local d = dist(S[i - 1], S[i])
                len = len + d
                if d > 0.5 then
                    local h = math.atan2(S[i].y - S[i - 1].y, S[i].x - S[i - 1].x)
                    if prev then
                        local turn = (h - prev + math.pi) % (2 * math.pi) - math.pi
                        net = net + turn
                    end
                    prev = h
                end
            end
            if last > w then
                local disp = dist(S[w], S[last])
                windows[#windows + 1] = net
                evidence.windows[#evidence.windows + 1] = { name = b.name, t = S[w].t, net_turn = net, winding = len / math.max(disp, 1), displacement = disp, length = len }
                if math.abs(net) >= CIRCLE_TURN then
                    circling = circling + 1
                    if net > 0 then ccw = ccw + 1 else cw = cw + 1 end
                end
                if len > 5 then winding[#winding + 1] = len / math.max(disp, 1) end
            end
        end
    end
    local stacked_n = 0
    table.sort(names)
    for i = 1, #names do
        for k = i + 1, #names do
            local A, B = group.buddies[names[i]], group.buddies[names[k]]
            local by_t = {}
            for _, s in ipairs(B.samples) do by_t[s.t] = s end
            local since
            for _, s in ipairs(A.samples) do
                local o = by_t[s.t]
                if o and not s.dead and not o.dead and dist(s, o) < STACK_YARDS then
                    since = since or s.t
                    if s.t - since >= STACK_SECONDS and since ~= -1 then
                        stacked_n = stacked_n + 1
                        local own = owner_at(group, s.t)
                        evidence.stacked[#evidence.stacked + 1] = { a = A.name, b = B.name, t = since, near_owner = own and dist(own, s) < 3 or false }
                        since = -1
                    end
                elseif since then
                    since = nil
                end
            end
        end
    end
    local covering
    if area_squares and #area_squares > 0 then
        local near = {}
        for _, b in pairs(group.buddies) do
            for _, s in ipairs(b.samples) do
                local X, Y = math.floor(16 * (32 - s.x / GRID)), math.floor(16 * (32 - s.y / GRID))
                for dx = -1, 1 do for dy = -1, 1 do near[(X + dx) * 4096 + Y + dy] = near[(X + dx) * 4096 + Y + dy] or {} ; table.insert(near[(X + dx) * 4096 + Y + dy], s) end end
            end
        end
        local covered = 0
        for _, sq in ipairs(area_squares) do
            local X, Y = math.floor(16 * (32 - sq.x / GRID)), math.floor(16 * (32 - sq.y / GRID))
            for _, s in ipairs(near[X * 4096 + Y] or {}) do
                if dist(s, sq) <= REACH then covered = covered + 1; break end
            end
        end
        covering = covered / #area_squares
    end
    table.sort(winding)
    local per10 = minutes > 0 and 10 / minutes or 0
    local values = {
        moving    = pairs_n > 0 and moved / pairs_n or 0,
        circling  = #windows > 0 and circling / #windows or 0,
        both_ways = math.max(cw, ccw) > 0 and math.min(cw, ccw) / math.max(cw, ccw) or 0,
        winding   = #winding > 0 and winding[math.floor((#winding + 1) / 2)] or 1,
        covering  = covering,
        still     = still_n * per10,
        stacked   = stacked_n * per10,
    }
    return values, evidence
end

return J
