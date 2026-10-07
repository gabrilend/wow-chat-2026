--------------------------------------------------------------------------------
-- lib/mover.lua (issue 173a) - how a character moves, the game's way
--
-- For a general audience: one step of a character's movement, given what
-- the player is pressing and how much time passed: turning, walking along
-- the ground, falling and jumping. The numbers are the game's own base
-- speeds (the client and server agree on them), times the speed bonus:
-- the owner asked for 120%. No drawing here, so it can be tested alone
-- (scripts/test-custom-client).
--
-- Facing is the game's: radians, 0 = north (+x), rising toward west (+y).
--------------------------------------------------------------------------------

local Mover = {}

-- {{{ the game's movement numbers
Mover.BASE = {
    run      = 7.0,           -- yards a second forward (and strafing)
    back     = 4.5,           -- yards a second backward
    turn     = math.pi,       -- radians a second (half a circle)
    gravity  = 19.29110527,   -- yards a second squared
    jump     = 7.95554,       -- yards a second upward at take-off
    terminal = 60.148003,     -- the fastest fall, yards a second
}
local STICK_DOWN = 1.5        -- yards: ground this far below a walking character is still walked on (slopes, steps)
-- }}}

-- {{{ function Mover.new
-- A character at (x, y, z) facing o, moving at `speed` times the base
-- speeds (1.2 for 120%). `max_slope` (degrees, number) is the steepest
-- ground it may walk on: the server's own rule, read from its navigation
-- tiles (lib/navmesh-slope.lua). Required: there is no made-up default.
function Mover.new(x, y, z, o, speed, max_slope)
    if type(max_slope) ~= "number" then
        error("Mover.new: max_slope (degrees) is required; read it with lib/navmesh-slope.lua")
    end
    return { x = x, y = y, z = z, o = o, speed = speed or 1, vz = 0, grounded = true,
             vx = 0, vy = 0,                                     -- sliding speed, yards a second
             max_grad = math.tan(math.rad(max_slope)) }          -- rise per yard at the limit
end
-- }}}

-- {{{ local function gradient
-- The ground's uphill direction and steepness at (x, y), as rise per yard
-- along x and along y (numbers): the exact slope of the map triangle the
-- point lies in, as `ground` gives it (lib/maps.lua). An earlier version
-- measured it from heights a quarter yard either side, which blurred the
-- corner at the foot of a cliff and left a character resting on the steep
-- part (2026-10-05). nil in a hole or off the loaded world: there is no
-- slope to stand on there, and the fall logic below takes over.
local function gradient(ground, x, y)
    local z, gx, gy = ground(x, y)
    if z < -10000 then return nil end
    if not gy then error("Mover: ground(x, y) must give the slope too: height, rise per yard along x, along y") end
    return gx, gy
end
-- }}}

-- {{{ function Mover.step
-- Moves `m` by `dt` seconds. `input` fields, each true or false:
--   forward, back, left, right (turn, or strafe when `strafe_turns` is set,
--   as holding the right mouse button does), strafe_left, strafe_right, jump.
-- `ground(x, y)` gives the ground height there (a number below -10000
-- for none: a hole, or the edge of the loaded world), then the ground's rise
-- per yard along x and along y there.
function Mover.step(m, input, dt, ground)
    local B, k = Mover.BASE, m.speed

    -- turning (A / D), unless the right button makes them strafes
    local strafe_l = input.strafe_left  or (input.strafe_turns and input.left)
    local strafe_r = input.strafe_right or (input.strafe_turns and input.right)
    if not input.strafe_turns then
        if input.left  then m.o = m.o + B.turn * dt end
        if input.right then m.o = m.o - B.turn * dt end
        m.o = m.o % (2 * math.pi)
    end

    -- the wanted direction in the character's own frame: ahead (+1/-1), to the left (+1/-1)
    local ahead = (input.forward and 1 or 0) - (input.back and 1 or 0)
    local left  = (strafe_l and 1 or 0) - (strafe_r and 1 or 0)
    if ahead ~= 0 or left ~= 0 then
        -- the game moves at one speed whatever the mix of keys: forward or
        -- strafing at run speed, any backward part at the backward speed
        local speed = (ahead < 0 and B.back or B.run) * k
        local len = math.sqrt(ahead * ahead + left * left)
        local dx = (ahead * math.cos(m.o) + left * math.cos(m.o + math.pi / 2)) / len
        local dy = (ahead * math.sin(m.o) + left * math.sin(m.o + math.pi / 2)) / len
        local nx, ny = m.x + dx * speed * dt, m.y + dy * speed * dt
        -- too steep to climb: a step that would go up onto ground steeper
        -- than the server's limit is not taken (on the ground only; in the
        -- air a character goes where its jump carries it). Down onto steep
        -- ground is allowed, and the slide below takes over there.
        local blocked = false
        if m.grounded then
            local gx, gy = gradient(ground, nx, ny)
            if gx and gx * gx + gy * gy > m.max_grad * m.max_grad and ground(nx, ny) > m.z then
                blocked = true
            end
        end
        if not blocked then m.x, m.y = nx, ny end
    end

    -- sliding: standing on ground steeper than the limit, a character
    -- slides down it as an object on a frictionless slope would: gravity's
    -- pull along the slope, g sin(a), of which g sin(a) cos(a) is
    -- horizontal, toward downhill. It keeps that speed until it reaches
    -- ground it can stand on, then stops.
    if m.grounded then
        local gx, gy = gradient(ground, m.x, m.y)
        local g2 = gx and (gx * gx + gy * gy) or 0
        if g2 > m.max_grad * m.max_grad then
            local g     = math.sqrt(g2)
            local a     = math.atan(g)
            local push  = Mover.BASE.gravity * math.sin(a) * math.cos(a) * dt
            m.vx, m.vy  = m.vx - gx / g * push, m.vy - gy / g * push
            m.sliding   = true
        else
            m.vx, m.vy, m.sliding = 0, 0, false
        end
    end
    m.x, m.y = m.x + m.vx * dt, m.y + m.vy * dt

    -- up and down: walking along the ground, or falling, or a jump
    local floor = ground(m.x, m.y)
    if m.grounded and input.jump then
        m.grounded, m.vz = false, B.jump
    end
    if m.grounded then
        if floor > -10000 and floor >= m.z - STICK_DOWN then
            m.z = floor                                  -- walking: on the ground, up or down a slope
        else
            m.grounded, m.vz = false, 0                  -- walked off an edge (or into a hole): falling
        end
    end
    if not m.grounded then
        m.vz = math.max(m.vz - B.gravity * dt, -B.terminal)
        m.z = m.z + m.vz * dt
        if floor > -10000 and m.z <= floor then
            m.z, m.vz, m.grounded = floor, 0, true      -- landed (a slide's speed is kept; the slope decides next step)
        end
    end
    return m
end
-- }}}

return Mover
