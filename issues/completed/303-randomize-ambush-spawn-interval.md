# 303 - Randomize Ambush Spawn Interval

**Phase:** 3 (Danger - Ambush System)
**Effect:** Spawn timing feels organic, not mechanical
**Status:** Completed (2026-04-08)

---

## The Effect

Ambush spawns use a random walk algorithm instead of fixed 40-second intervals. The timer drifts between 10-200 seconds with soft boundaries at 100 seconds, creating unpredictable but bounded danger.

Players can't rely on "exactly 40 seconds until next spawn" timing.

---

## What This Solved

### Before (Fixed Interval)

**Predictable timing:**
- Fixed 40 second spawn interval
- Timer starts on login, repeats forever
- Players can count down: "20 seconds until spawn"
- Feels mechanical, not organic

**Problem:** Predictability undermines tension. If you know exactly when danger arrives, you can prepare perfectly.

### After (Random Walk)

**Unpredictable timing:**
- Base interval: 40 seconds (starting value only)
- Each spawn: interval changes by +/- 2, 3, or 4 seconds from PREVIOUS value
- Creates random walk that drifts over time
- Boundaries prevent runaway values

**Result:** Players can't predict timing. Tension remains high.

---

## Implementation: Random Walk with Boundaries

### Core Algorithm

**Jitter applies to previous interval, not base:**
```lua
-- NOT this (jitter from base):
next_interval = BASE_INTERVAL + random(-4, +4)  -- Always near 40

-- THIS (jitter from previous):
next_interval = current_interval + random(-4, +4)  -- Drifts over time
```

**Example walk:**
```
Start:  40 seconds
+3:     43 seconds
-2:     41 seconds
+4:     45 seconds
+3:     48 seconds
-4:     44 seconds
...drift continues...
```

Over time, interval wanders away from 40 seconds. Boundaries prevent extremes.

### Boundary Rules

**Floor (10 seconds):**
```lua
if interval <= INTERVAL_MIN then
    -- Force positive jitter only
    jitter = math.random(JITTER_MIN, JITTER_MAX)  -- Always positive
end
```

When hitting floor, can only go up. Prevents spawns faster than every 10 seconds.

**Soft Cap (100 seconds):**
```lua
if interval >= INTERVAL_SOFT then
    -- Bias toward negative jitter (2:1 ratio)
    if math.random(1, 3) <= 2 then
        jitter = -math.random(JITTER_MIN, JITTER_MAX)  -- 67% negative
    else
        jitter = math.random(JITTER_MIN, JITTER_MAX)   -- 33% positive
    end
end
```

Above 100 seconds, downward drift is twice as likely. Gentle pull toward center.

**Hard Cap (200 seconds):**
```lua
if interval >= INTERVAL_HARD then
    -- Strong bias toward negative (4:1 ratio)
    if math.random(1, 5) <= 4 then
        jitter = -math.random(JITTER_MIN, JITTER_MAX)  -- 80% negative
    else
        jitter = math.random(JITTER_MIN, JITTER_MAX)   -- 20% positive
    end
end
```

Above 200 seconds, downward drift is four times as likely. Strong pull toward center.

### Probability Table

| Interval Range | P(positive) | P(negative) | Effect |
|----------------|-------------|-------------|--------|
| < 10s | 100% | 0% | Floor (forced up) |
| 10-99s | 50% | 50% | Free random walk |
| 100-199s | 33% | 67% | Soft pull down |
| >= 200s | 20% | 80% | Strong pull down |

### Grace Period

**30 second fixed grace on login:**
```lua
if logoutTime and (currentTime - logoutTime) >= 600 then  -- 10+ minutes offline
    interval = 30000  -- 30 second grace
else
    interval = lastInterval  -- Resume random walk
end
```

**Why grace period:**
- Just logged in, player needs time to orient
- Immediate spawn feels punishing
- 30 seconds lets player check inventory, buffs, position

**Why 10-minute threshold:**
- Quick relogs (< 10 min) = same session, resume walk
- Long breaks (> 10 min) = new session, grant grace
- Prevents logout-exploit to reset timer

### Persistence

**Server-session memory, by character:** a table inside the ambush script
(`AmbushMemory` in `src/lua-beta/ambush.lua`), keyed by the character's
guid (low part, a number), holding `interval` (milliseconds, number) and
`logoutTime` (unix seconds, number).

It is not kept with `SetData()`: the object-variables extension
(`extensions/ObjectVariables.ext`) wipes a player's `SetData` store when
they log out, so a value kept there is gone at the next login. Until
2026-10-17 the interval was kept there, and every login restarted the walk
at 40 seconds; the logout time survived only because the ambush's logout
handler happened to run after the wipe. The memory table:
- Preserved through logouts and relogs, for as long as the server runs
- Survives zone transfers
- Emptied by a server restart or `.reload ale` (every player then starts
  from the base interval, with the grace period)

**Not database-persisted** (future enhancement):
- Could save to the characters database
- Would preserve the random walk across restarts

Tested offline by `scripts/test-ambush` (a quick relog carries the walk on;
more than ten minutes away gives the grace period).

---

## Configuration Constants

```lua
AMBUSH_BASE_INTERVAL   =  40000  -- ms (40s) - starting value only
AMBUSH_INTERVAL_MIN    =  10000  -- ms (10s) - floor
AMBUSH_INTERVAL_SOFT   = 100000  -- ms (100s) - soft cap starts
AMBUSH_INTERVAL_HARD   = 200000  -- ms (200s) - hard cap starts
AMBUSH_JITTER_MIN      =   2000  -- ms (2s) - minimum jitter
AMBUSH_JITTER_MAX      =   4000  -- ms (4s) - maximum jitter
AMBUSH_JITTER_STEP     =   1000  -- ms (1s) - step size
```

**All integers (no floats):**
- Milliseconds are whole numbers
- math.random() returns integers
- Probability weights use integer ratios (1:3, 1:5)

---

## Why This Matters

**Unpredictability Creates Tension**

Fixed timing: "I have 20 seconds to loot and move."
Random walk: "Could be 10 seconds, could be 3 minutes."

The uncertainty keeps players alert. Can't relax into patterns.

**Bounded Randomness**

Pure randomness (any value 10-200s) would feel chaotic:
- Sometimes 10s spawns forever (overwhelming)
- Sometimes 200s spawns forever (boring)

Random walk with boundaries:
- Drifts naturally (organic feel)
- Soft boundaries guide toward playable range (100s center)
- Hard boundaries prevent extremes

**Grace Period Balance**

Without grace: Login → immediate spawn → feels unfair
With grace: Login → 30s to prepare → fair

But grace must expire or players exploit by relogging.

10-minute threshold separates:
- Quick relogs (strategy, teleport, fix) = no grace
- Long breaks (lunch, sleep) = grant grace

---

## Future Enhancements

### Adaptive Spawn Rate
- Increase rate when player winning easily
- Decrease when player struggling (low health, deaths)
- Track kill time to adjust difficulty

### Zone-Based Intervals
- Dangerous zones: faster spawns
- Safe zones: slower spawns
- Creates geographic risk gradient

### Group Scaling
- Solo: base rate
- Party: faster spawns, more creatures per wave
- Raid: spawn packs instead of singles

### Time-of-Day Variation
- Night: more frequent spawns
- Day: less frequent
- Creates gameplay rhythm

### Combat State Awareness
- Pause timer during active combat
- Resume after combat ends
- Prevents overwhelming the player

### Streak System
- Track consecutive kills without rest
- Increase spawn rate during "hot streaks"
- Creates risk/reward tension

---

## Related Phase 3 Issues

- 302 - investigate-ambush-monsters-not-spawning (spawn system must work first)
- 304 - clear-ambush-data-on-death (memory cleanup)
- 305 - ambush-aggro-and-corpse-movement (aggro/corpse fixes)

---

## Lessons Learned

### Random Walk > Simple Randomness

**Simple randomness:**
```lua
interval = math.random(10000, 200000)  -- Any value 10-200s
```
Problem: Extreme values too common (10s or 200s).

**Random walk:**
```lua
interval = interval + math.random(-4000, 4000)  -- Drift from current
```
Advantage: Values cluster around playable range naturally.

### Soft Boundaries Beat Hard Limits

**Hard limit:**
```lua
if interval > 200000 then interval = 200000 end  -- Clamp to 200
```
Problem: Hits ceiling and stays there. Feels artificial.

**Soft boundary:**
```lua
if interval >= 100000 then bias_toward_negative() end
```
Advantage: Gentle pull, not wall. More organic drift.

### Grace Period Needs Threshold

**Without threshold:**
- Every login gets grace period
- Players relog to reset timer (exploit)

**With threshold (10 min):**
- Quick relogs resume walk (no exploit)
- Long breaks get grace (fair)

### Session Data vs Database

**Session data (`SetData()`):**
- Fast, no SQL overhead
- Good for temporary state
- Resets on logout

**Database (`character_stats`):**
- Persistent across sessions
- Requires SQL reads/writes
- Good for long-term progression

Random walk state is borderline: currently kept for the server's run (the
memory table above, not `SetData()`, which logout wipes), could become
persistent.

---

## Phase 3 Contribution

This issue enables **Phase 3: Danger (Ambush System)** by ensuring:
> "Danger timing feels organic, not mechanical"

Fixed spawns feel like a game mechanic. Random walk spawns feel like a world alive with unpredictable threats.

This transforms ambush from "timer mechanic" to "environmental hazard."

---

## Debug Prints Removed 2026-05-21

Two diagnostic prints added during the random-walk implementation
have been removed now that the algorithm is verified working in
production:

- `print("[Ambush] Grace period: ... (offline ...s)")` — logged each
  long-offline login that received the fixed grace period instead of
  resuming the random walk.
- `print("[Ambush] Quick relog, resuming at ...s")` — logged each
  short-offline login that resumed mid-walk.

Both were instrumentation for the offline-time-vs-grace-threshold
branching logic at `Ambush.setupPlayer`. The branching has been
verified correct via in-game testing across multiple offline
durations, so the prints are no longer needed.

The constants `AMBUSH_GRACE_PERIOD` and `AMBUSH_OFFLINE_RESET`
remain documented in the configuration block at the top of
`src/lua/ambush.lua`.

## Since then (checked 2026-10-17)

- **Still the live design**, in `src/lua-beta/ambush.lua` (was
  `src/lua/ambush.lua`; per-profile folders, 2026-06-04). This walk belongs
  to the line of the ambush that runs today, made in the 2026-03-31 stash;
  `docs/datapaths/ambush.md` tells the story of the two lines.
- **Persistence was never what the text said** (see Persistence above,
  corrected 2026-10-17): `SetData` is wiped at logout, so until then every
  login restarted at 40 seconds.
- **The clock booking itself** (this walk) is what turned an old
  one-second retry into a second clock whenever the database had no rare
  for the player's level (levels 1-5 and 16): fixed 2026-10-17 by asking
  the next rank down.
- **The scheduler's holds**, lost when the ambush started booking itself,
  were restored the same day. `scripts/test-ambush` checks the walk's steps,
  floor and caps statistically, a quick relog, the grace period, and one
  clock per player.
