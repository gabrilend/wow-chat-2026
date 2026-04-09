# 329 - Algorism Priority Scheduler

## Status
- Created: 2026-04-08
- Phase: Research
- Priority: Low (experimental)
- Milestone: None (future architecture exploration)

## Overview

Replace N independent bot timers with a single WorldTick scheduler using algorism-style priority resolution. Algorism is a task distribution system that rewards patience with compounding priority while still allowing immediate access for focused investment.

## Current Architecture

```
Bot A: RegisterEvent(PeriodicBotWander, 2000ms, 1)
Bot B: RegisterEvent(PeriodicBotWander, 2000ms, 1)
Bot C: RegisterEvent(PeriodicBotWander, 2000ms, 1)
...
Bot N: RegisterEvent(PeriodicBotWander, 2000ms, 1)
```

- N independent timers for N bots
- Each fires independently, no coordination
- Race conditions when bots aren't fully loaded (GetPosition nil)
- No priority system - first registered, first served

## Proposed Architecture

### Single WorldTick Heartbeat

```lua
-- One timer for the entire world
CreateLuaEvent(WorldTick.heartbeat, 100, 0)  -- 100ms tick, forever
```

### Algorism Priority Model

Each entity has a **stake** in each behavior queue:

```lua
entity.queues = {
    wander = {
        initial = 1,      -- base investment (immutable once set)
        periods = 0,      -- ticks waited since last service
        total   = 1,      -- initial + periods (compounds over time)
    },
    combat = { ... },
    social = { ... },
}
```

**Priority formula:**
```
priority = initial_stake + periods_waited
```

**Resolution each tick:**
1. Collect all entities with pending work in this queue
2. Sort by total priority (descending)
3. Process top N (configurable throughput)
4. Processed entities: reset periods to 0, stake remains
5. Skipped entities: periods += 1, priority grows

### Two Valid Strategies

| Strategy | Behavior | Result |
|----------|----------|--------|
| Patient | Small stake, many queues | Eventually services everything |
| Focused | Large stake, few queues | Immediate service, rapid throughput |

A bot with stake=1 waiting 50 ticks (priority 51) beats a bot with stake=10 waiting 0 ticks (priority 10).

### Batch Resolution

All priority calculations happen at tick start. No mid-tick changes. Like a board game:
1. Everyone commits allocations
2. All resolves at once
3. Repeat

This eliminates race conditions - if a bot isn't ready (no position), it simply isn't in this tick's batch.

### Immutable Past, Mutable Future

- Cannot remove stake from a queue (prevents gaming)
- Can redirect future allocations
- Creates commitment to choices

### Load Balancer (Optional)

If a queue falls too far behind (periods > threshold), auto-redistribute from a system reserve pool. Prevents starvation even for zero-stake entities.

```lua
if entity.queues.wander.periods > STARVATION_THRESHOLD then
    entity.queues.wander.total += RESERVE_BOOST
end
```

## Implementation Sketch

### WorldTick Module

```lua
local WorldTick = {
    tick_interval = 100,  -- ms
    queues = {
        wander    = {},   -- { entity, priority }
        combat    = {},
        social    = {},
        loneliness = {},
    },
    throughput = {
        wander    = 10,   -- process 10 per tick max
        combat    = 20,   -- combat is more urgent
        social    = 5,
        loneliness = 5,
    },
}

-- {{{ WorldTick.heartbeat
function WorldTick.heartbeat()
    local now = GetTime()

    for queue_name, queue in pairs(WorldTick.queues) do
        -- Sort by priority
        table.sort(queue, function(a, b)
            return a.priority > b.priority
        end)

        -- Process top N
        local limit = WorldTick.throughput[queue_name]
        for i = 1, math.min(limit, #queue) do
            local item = queue[i]
            if WorldTick.isReady(item.entity) then
                WorldTick.process(queue_name, item.entity)
                item.periods = 0
            end
        end

        -- Age the rest
        for i = limit + 1, #queue do
            queue[i].periods = queue[i].periods + 1
            queue[i].priority = queue[i].initial + queue[i].periods
        end
    end
end
-- }}}

-- {{{ WorldTick.isReady
function WorldTick.isReady(entity)
    if not entity then return false end
    if not entity:IsInWorld() then return false end
    if not entity:GetPosition() then return false end
    return true
end
-- }}}
```

### LockedValue Atoms (Optional Extension)

For shared state that multiple systems touch:

```lua
local position = LockedValue.new({x=0, y=0, z=0})

-- Acquires lock, returns true if got it
if position:acquire(self) then
    local pos = position:get()
    pos.x = pos.x + dx
    position:set(pos)
    position:release()  -- next waiter gets it
else
    -- Couldn't get lock - added to wait queue
    -- Will be resumed when lock available
    -- Priority: downstream_weight + (wait_time × aging_factor)
end
```

## Benefits

1. **Solves GetPosition nil** - `isReady()` check happens once per tick, centrally
2. **Single timer** - instead of hundreds
3. **Fair scheduling** - patience rewarded, no starvation
4. **Predictable throughput** - configure how many per tick
5. **Batch processing** - more cache-friendly, less context switching
6. **Foundation for parallelism** - if Lua gets threads, this architecture is ready

## Migration Path

1. Implement WorldTick alongside existing system
2. Migrate one behavior at a time (wander first)
3. Validate behavior parity
4. Remove old per-bot timers
5. Tune throughput values

## Open Questions

- What's the right tick interval? 100ms? 50ms?
- How to handle urgent events (combat) vs leisurely ones (social)?
- Should stake be configurable per-bot or system-wide?
- How does this interact with playerbots' internal scheduling?

## Related

- Issue 327: Atomic shadow builds (similar "don't touch until ready" philosophy)
- Issue 328: GetPosition nil errors (immediate problem this solves architecturally)
- Concept: Software Transactional Memory
- Concept: Priority inheritance / aging
- Game engine tick systems (Unity Update, Unreal Tick)

## Notes

This is exploratory architecture work. The immediate fix for issue 328 is adding `IsInWorld()` guards. This issue documents a longer-term vision for how scheduling could work if we redesign from scratch.

The algorism model comes from a broader task distribution / resource allocation philosophy that rewards patience with compounding returns while still allowing immediate access for those who invest heavily in focus.
