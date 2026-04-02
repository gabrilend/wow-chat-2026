# 132 - Healer Bot Ping-Pong Spiral Behavior

## Status: Open

## Vision

Healer playerbots become mobile healing stations that spiral through 3D space,
weaving between players in an optimized path like a bee pollinating flowers.
They don't stand still and spam heals - they MOVE, creating a visual rhythm
of healing that winds down through the party like water down a staircase.

## Current Behavior

- Healer bots stand in place
- Target lowest health player
- Spam healing spells
- Occasionally move if threatened

## Intended Behavior

### The Ping-Pong Spiral
```
Top View:                          Side View (3D Staircase):

    P1 ─────┐                         P1 ○
            │                            ╲
    P2 ←────┘                             ╲ Healer descends
    │                                  P2  ○
    └───── P3                               ╲
           │                                 ╲
    P4 ←───┘                           P3    ○
    │                                         ╲
    └───── P5                                  ╲
                                       P4      ○
                                                ╲
Healer winds through all                P5      ○
players in optimal path
```

### Traveling Salesman Optimization
```lua
-- Priority factors for next target:
-- 1. Proximity (closer = higher priority)
-- 2. Health deficit (lower health = higher priority)
-- 3. Role importance (tank > healer > dps)
-- 4. Time since last healed (longer = higher priority)

score = (1 / distance) * health_deficit * role_weight * time_factor
```

### Speed of Sound Movement
```lua
-- Configuration
PING_PONG_SPEED = 300        -- % of normal run speed
HEAL_WINDOW = 1.5            -- seconds to cast while passing
MIN_PROXIMITY = 5            -- yards to trigger heal
SPIRAL_RADIUS = 3            -- yards offset from direct path

-- Movement feels like:
-- "woooosh" past player → instant heal → "woooosh" to next
```

## Implementation

### Path Generation
```lua
-- {{{ calculate_healing_path
local function calculate_healing_path(healer, party_members)
    -- Sort by combined score
    local targets = {}
    for _, member in ipairs(party_members) do
        if needs_healing(member) then
            local score = calculate_priority_score(healer, member)
            table.insert(targets, {player = member, score = score})
        end
    end

    table.sort(targets, function(a, b) return a.score > b.score end)

    -- Apply traveling salesman nearest-neighbor heuristic
    local path = {}
    local current_pos = healer:GetPosition()
    local remaining = targets

    while #remaining > 0 do
        local nearest_idx = find_nearest(current_pos, remaining)
        local nearest = table.remove(remaining, nearest_idx)
        table.insert(path, nearest.player)
        current_pos = nearest.player:GetPosition()
    end

    return path
end
-- }}}
```

### 3D Spiral Movement
```lua
-- {{{ spiral_to_target
local function spiral_to_target(healer, target, callback)
    local start_pos = healer:GetPosition()
    local end_pos = target:GetPosition()

    -- Calculate spiral waypoints
    local distance = start_pos:Distance(end_pos)
    local num_spirals = math.floor(distance / 10)  -- one spiral per 10 yards

    local waypoints = {}
    for i = 1, num_spirals do
        local t = i / num_spirals
        local direct_point = lerp(start_pos, end_pos, t)

        -- Add spiral offset (circular motion around direct path)
        local angle = t * math.pi * 4  -- two full rotations
        local offset_x = math.cos(angle) * SPIRAL_RADIUS
        local offset_y = math.sin(angle) * SPIRAL_RADIUS

        table.insert(waypoints, {
            x = direct_point.x + offset_x,
            y = direct_point.y + offset_y,
            z = direct_point.z  -- maintains height for staircase effect
        })
    end

    healer:MoveAlongPath(waypoints, PING_PONG_SPEED, callback)
end
-- }}}
```

### Heal-While-Moving
```lua
-- {{{ ping_pong_heal_loop
local function ping_pong_heal_loop(healer)
    local party = healer:GetGroup():GetMembers()
    local path = calculate_healing_path(healer, party)

    if #path == 0 then
        -- Nobody needs healing, orbit the tank
        orbit_tank(healer)
        return
    end

    local function heal_next(index)
        if index > #path then
            -- Completed circuit, recalculate
            ping_pong_heal_loop(healer)
            return
        end

        local target = path[index]

        spiral_to_target(healer, target, function()
            -- Arrived near target, instant heal
            if healer:IsInRange(target, MIN_PROXIMITY) then
                cast_instant_heal(healer, target)
            end

            -- Continue to next
            heal_next(index + 1)
        end)
    end

    heal_next(1)
end
-- }}}
```

### Priority Score Calculation
```lua
-- {{{ calculate_priority_score
local function calculate_priority_score(healer, target)
    local distance = healer:GetDistance(target)
    local health_pct = target:GetHealthPct()
    local health_deficit = 100 - health_pct

    -- Role weights
    local role_weight = 1.0
    if is_tank(target) then
        role_weight = 2.0
    elseif is_healer(target) then
        role_weight = 1.5
    end

    -- Time since last healed by this healer
    local last_heal_time = healer.heal_timestamps[target:GetGUID()] or 0
    local time_since_heal = GetTime() - last_heal_time
    local time_factor = math.min(time_since_heal / 10, 2.0)  -- caps at 2x

    -- Proximity is king (inverse distance)
    local proximity_score = 100 / math.max(distance, 1)

    -- Combined score
    return proximity_score * (health_deficit / 100) * role_weight * time_factor
end
-- }}}
```

## Visual Effect

```
Frame 1:     Frame 2:     Frame 3:     Frame 4:
  T            T            T            T
      H→           ↓H           H→           ↓H
  D   D        D   D        D   D        D   D
    D            D            D            D

H = Healer, T = Tank, D = DPS
Healer spirals through the formation like a figure-8
```

## Configuration

```lua
-- worldserver.conf options
WowChat2.Bot.Healer.PingPongEnabled = true
WowChat2.Bot.Healer.PingPongSpeed = 300
WowChat2.Bot.Healer.SpiralRadius = 3
WowChat2.Bot.Healer.HealWindow = 1.5
WowChat2.Bot.Healer.MinHealthToHeal = 90
```

## Related Issues

- **114 - Find Monsters**: Similar movement optimization
- **116 - Avoid Monsters**: Healer must dodge while spiraling
- **119 - Orbit Player**: Fallback behavior when no healing needed

## Edge Cases

1. **Tight Spaces**: Reduce spiral radius in dungeons
2. **Spread Mechanics**: Increase speed, reduce spiral
3. **Stack Mechanics**: Collapse spiral, stand and heal
4. **Moving Targets**: Predict target movement, lead the spiral
5. **Multiple Healers**: Coordinate paths to avoid overlap

## The Poetry of It

```
Down the staircase, round and round,
The healer moves without a sound.
From tank to mage, from priest to knight,
A spiral dance of healing light.

No standing still, no rooted feet,
The ping-pong path is swift and sweet.
Through 3D space the healer flows,
Wherever wounded health bar shows.
```

