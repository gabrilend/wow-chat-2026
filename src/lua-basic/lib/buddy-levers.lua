
local M = {}

local JUMP_UP_SPEED   = 7.96
local JUMP_GRAVITY    = 19.29
local JUMP_AIR_TIME   = 2 * JUMP_UP_SPEED / JUMP_GRAVITY
local JUMP_MIN_SPEED  = 0.5
local NEAR_RANGE      = 30
local RUN_SPEED       = 7
local CIRCLE_POINTS   = 8
local TWO_PI          = 6.283185307

local FIND = {
    none     = function() return true end,
    partner  = function(buddy, ctx)
        local p = ctx.partner
        if p and p:GetMapId() == buddy:GetMapId() and buddy:GetDistance(p) <= NEAR_RANGE then return p end
    end,
    buddy    = function(buddy, ctx)
        local best, best_d
        for _, b in ipairs(ctx.buddies or {}) do
            if b:GetGUIDLow() ~= buddy:GetGUIDLow() and b:GetMapId() == buddy:GetMapId() then
                local d = buddy:GetDistance(b)
                if d <= NEAR_RANGE and (not best_d or d < best_d) then best, best_d = b, d end
            end
        end
        return best
    end,
    player   = function(buddy, ctx)
        local skip = { [buddy:GetGUIDLow()] = true }
        if ctx.partner then skip[ctx.partner:GetGUIDLow()] = true end
        for _, b in ipairs(ctx.buddies or {}) do skip[b:GetGUIDLow()] = true end
        local best, best_d
        for _, p in ipairs(buddy:GetPlayersInRange(NEAR_RANGE, 0, 1) or {}) do
            if not skip[p:GetGUIDLow()] then
                local d = buddy:GetDistance(p)
                if not best_d or d < best_d then best, best_d = p, d end
            end
        end
        return best
    end,
    creature = function(buddy) return buddy:GetNearestCreature(NEAR_RANGE, 0, 0, 1) end,
}

local NEED = {
    ["out-of-combat"] = function(buddy) return not buddy:IsInCombat() end,
    ["idle"]          = function(_, ctx) return ctx.idle == true end,
}
local function may(buddy, lever, ctx)
    for _, n in ipairs(lever.needs) do
        local test = NEED[n]
        if not test then return false, "a need no test knows: " .. n end
        if not test(buddy, ctx) then return false, n end
    end
    return true
end

local PLAY = {
    once  = function(buddy, v) buddy:PerformEmote(v.motion) end,
    stand = function(buddy, v) buddy:SetStandState(v.param) end,
    loop  = function(buddy, v) buddy:EmoteState(v.motion) end,
    none  = function() end,
}
local function play_motion(buddy, v)
    if v.motion == 0 then return end
    PLAY[v.act](buddy, v)
end

local function ground_ahead(buddy, turn, yards)
    local x, y, z, o = buddy:GetLocation()
    local a  = o + turn
    local nx = x + math.cos(a) * yards
    local ny = y + math.sin(a) * yards
    local nz = buddy:GetMap():GetHeight(nx, ny) or z
    return nx, ny, nz, a
end

local WAY = {
    ["text-emote"] = function(buddy, v, target)
        if target ~= true then buddy:SetFacingToObject(target) end
        play_motion(buddy, v)
        local text = target ~= true and v.text:gsub("%%s", target:GetName()) or v.text
        buddy:TextEmote(text)
    end,
    motion  = function(buddy, v) play_motion(buddy, v) end,
    stand   = function(buddy, v) buddy:SetStandState(v.state) end,
    sheathe = function(buddy, v) buddy:SetSheath(v.state) end,
    face    = function(buddy, v, target)
        buddy:SetFacingToObject(target)
        if v.away == 1 then buddy:SetFacing(buddy:GetO() + math.pi) end
    end,
    turn    = function(buddy, v) buddy:SetFacing(buddy:GetO() + v.turn) end,
    hop     = function(buddy, v)
        local x, y, z = ground_ahead(buddy, v.turn, v.yards)
        buddy:MoveJump(x, y, z, math.max(v.yards / JUMP_AIR_TIME, JUMP_MIN_SPEED), JUMP_UP_SPEED)
    end,
    step    = function(buddy, v)
        local x, y, z = ground_ahead(buddy, v.turn, v.yards)
        buddy:MoveTo(0, x, y, z, true)
    end,
    approach = function(buddy, v, target)
        local tx, ty, tz = target:GetLocation()
        local x, y = buddy:GetX(), buddy:GetY()
        local d = math.max(target:GetDistance(buddy), 0.01)
        local k = math.max(d - v.stop_at, 0) / d
        buddy:MoveTo(0, x + (tx - x) * k, y + (ty - y) * k, tz, true)
    end,
    withdraw = function(buddy, v, target)
        local a = target:GetAngle(buddy)
        local x = buddy:GetX() + math.cos(a) * v.yards
        local y = buddy:GetY() + math.sin(a) * v.yards
        buddy:MoveTo(0, x, y, buddy:GetMap():GetHeight(x, y) or buddy:GetZ(), true)
    end,
    circle  = function(buddy, v)
        local cx, cy = ground_ahead(buddy, v.dir * -1.5708, v.radius)
        local start  = math.atan2(buddy:GetY() - cy, buddy:GetX() - cx)
        local guid   = buddy:GetGUID()
        local step_ms = math.floor(TWO_PI * v.radius / CIRCLE_POINTS / RUN_SPEED * 1000)
        local n = 0
        buddy:RegisterEvent(function(_, _, _, b)
            n = n + 1
            local a = start - v.dir * n * TWO_PI / CIRCLE_POINTS
            local x, y = cx + math.cos(a) * v.radius, cy + math.sin(a) * v.radius
            b:MoveTo(0, x, y, b:GetMap():GetHeight(x, y) or b:GetZ(), true)
        end, step_ms, CIRCLE_POINTS)
    end,
}
M.WAY_KINDS = {}
for k in pairs(WAY) do M.WAY_KINDS[k] = true end

function M.pull(buddy, lever, ctx)
    ctx = ctx or {}
    local way = WAY[lever.kind]
    if not way then return false, "no way to do a lever of kind " .. lever.kind end
    local ok, need = may(buddy, lever, ctx)
    if not ok then return false, "not now: " .. need end
    local find = FIND[lever.target]
    if not find then return false, "no way to find a target of kind " .. lever.target end
    local target = find(buddy, ctx)
    if not target then return false, "no " .. lever.target .. " within " .. NEAR_RANGE .. " yards" end
    way(buddy, lever.values, target)
    return true
end

function M.index(levers)
    local by_id = {}
    for _, l in ipairs(levers) do by_id[l.id] = l end
    return by_id
end

return M
