# 124 - Randomize Ambush Spawn Interval

## Status: In Progress

## Current Behavior
- Fixed 40 second spawn interval
- Predictable timing feels mechanical
- Timer starts on login, repeats forever

## Intended Behavior
- Base interval: 40 seconds
- Jitter: +/- 2, 3, or 4 seconds (integer only)
- Each offset value has equal probability (uniform distribution)
- Possible intervals: 36, 37, 38, 42, 43, 44 seconds
- Re-randomize each spawn cycle

## Implementation v2 - Random Walk with Boundaries

### Core Behavior
- Jitter (+/- 2-4 seconds) applies to PREVIOUS interval, not base
- Creates a random walk that drifts over time
- Boundaries prevent runaway values

### Boundary Rules
```
INTERVAL_MIN = 10 seconds
INTERVAL_SOFT_CAP = 100 seconds
INTERVAL_HARD_CAP = 200 seconds

if interval <= INTERVAL_MIN:
    direction = +1 only (forced positive)

if interval >= INTERVAL_SOFT_CAP:
    direction can be +1 or -1
    but +1 is half as likely

if interval >= INTERVAL_HARD_CAP:
    +1 is quarter as likely
```

### Probability Table (above soft cap)
| Range | P(positive) | P(negative) |
|-------|-------------|-------------|
| < 100 | 50%         | 50%         |
| 100-199 | 33%       | 67%         |
| >= 200 | 20%        | 80%         |

### Grace Period
- 30 second fixed grace period on login
- Only triggers if offline for 10+ minutes
- Quick relogs resume random walk immediately
- Logout time tracked via PLAYER_EVENT_ON_LOGOUT

### Persistence
- Current interval stored in player data
- Logout time stored in player data
- TODO: Save to database for cross-session persistence
- Quick relogs preserve interval (within session)

### No Floats Rule
- All values in milliseconds (integers)
- math.random returns integers
- Probability weights use integer ratios

## Configuration Constants
```lua
AMBUSH_BASE_INTERVAL   =  40000  -- ms (40 seconds) - starting value only
AMBUSH_INTERVAL_MIN    =  10000  -- ms (10 seconds) - floor
AMBUSH_INTERVAL_SOFT   = 100000  -- ms (100 seconds) - positive bias starts
AMBUSH_INTERVAL_HARD   = 200000  -- ms (200 seconds) - strong positive bias
AMBUSH_JITTER_MIN      =   2000  -- ms (2 seconds)
AMBUSH_JITTER_MAX      =   4000  -- ms (4 seconds)
AMBUSH_JITTER_STEP     =   1000  -- ms (1 second increments)
```

## Future Improvements

### Adaptive Spawn Rate
- Increase spawn rate when player is winning easily
- Decrease when player is struggling (low health, deaths)
- Track kill time to adjust difficulty

### Zone-Based Intervals
- Different zones could have different spawn rates
- Dangerous zones: faster spawns
- Safe zones: slower spawns

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

## Related Files
- src/lua/ambush.lua
- issues/113-investigate-ambush-monsters-not-spawning.md
