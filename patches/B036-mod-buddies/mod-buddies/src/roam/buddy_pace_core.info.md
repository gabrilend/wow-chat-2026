# buddy_pace_core.h

A dungeon tank's pace (issue 617z): whether to pull the next pack or wait,
how wide to clear round its route, and what the group's words do to it.
Plain arithmetic, no server; checked by `scripts/test-buddy-pace`. Not yet
wired into the server: the route to the next boss, hearing the words, and
the walk and pull are the server's part, still to build.

## Settings

| Field | Type | Default | Meaning |
|---|---|---|---|
| `recordSize` | size_t | 5 | fights remembered |
| `startConfidence` | float | 0.9 | where confidence starts, and the top it regains to |
| `minConfidence` | float | 0.1 | the floor |
| `slowDrop` | float | 0.3 | taken off by one slowing word |
| `regainPerMinute` | float | 0.05 | regained each minute, up to `startConfidence` |
| `wellDoneGain` | float | 0.05 | added by a fight the healer left above the reserve |
| `maxReserve` | float | 40 | mana (percent) a fully nervous tank keeps in hand |
| `defaultCostPerWeight` | float | 10 | mana (percent) per unit of pack weight with no record |
| `eliteWeight` | float | 3 | an elite counts as this many normals |
| `levelFactor` | float | 1.1 | per level above the group's average |
| `clearMin`, `clearMax` | float | 10, 30 | yards cleared either side of the route, nervous to confident |
| `healerLowAfter` | float | 25 | mana (percent) a healer buddy's fight ending under counts as too low |
| `healerWindow` | size_t | 3 | fights a healer buddy looks back over |
| `healerLowCount` | size_t | 2 | of them, this many too low: it says "slow down" |
| `healerQuiet` | size_t | 3 | fights it keeps quiet (and doesn't count) after saying it |

## Pieces

| Name | What it is |
|---|---|
| `Pack` | `normals`, `elites` (uint32), `levelDiff` (float: the pack's average level less the group's) |
| `Weight(pack, settings)` | -> float: normals + 3 x elites, times 1.1 per level of `levelDiff` |
| `Word` (uint8 enum) | `None`, `Slow`, `Oom`, `Ready` |
| `ReadWord(text)` | -> Word: "wait", "slow down", "go slower", "slower", "slow" slow; "oom", "out of mana", "mana" stop; "ready", "rdy" go on; the whole line must be the word (case and punctuation ignored) |
| `FightCost` | `healerManaPct` (float, 0-100 spent), `packWeight` (float) |

## Tank

| Member | Type | Meaning |
|---|---|---|
| `confidence` | float | 0 to 1 |
| `stopped` | bool | a healer said "oom"; waits for "ready" |
| `lastMs` | uint64 | the last `Tick` |
| `record` | deque of FightCost | the last fights |
| `Tick(nowMs, s)` | | confidence regained for the time since the last tick |
| `Heard(word, s)` | | Slow: down by `slowDrop`; Oom: stopped and down; Ready: no longer stopped |
| `Reserve(s)` | -> float | mana kept in hand: (1 - confidence) x `maxReserve` |
| `Fought(cost, healerManaAfterPct, s)` | | remembered; above the reserve after it, `wellDoneGain` added |
| `ExpectedCost(pack, s)` | -> float | the record's mana per weight (or the default) times the pack's weight |
| `ShouldPull(healerManaPct, pack, s)` | -> bool | not stopped, and the mana less the expected cost keeps the reserve |
| `ClearYards(s)` | -> float | `clearMin` to `clearMax` by confidence |
| `NeededFor(healerManaPct, pack, s)` | -> float | the confidence it would need to pull that pack itself (`minConfidence` to 1) |
| `PlayerPulled(cost, healerManaBeforePct, healerManaAfterPct, pack, s)` | -> char const* | a pack someone else pulled, picked up: remembered; the healer above the reserve after it, confidence at least `NeededFor` the pack at the mana it began with; returns the put-out line |
| `WaitLine(healerManaPct, pack, s)` | -> char const* | "Waiting for ready." when stopped, "Waiting for mana." when short, null when it would pull |

## Harmless packs

| Name | What it is |
|---|---|
| `GreyLevel(level)` | -> int32: the game's grey level (AzerothCore's `GetGrayLevel`) |
| `Plan` (uint8 enum) | `Pull`, `WalkPast`, `Sweep` |
| `PackPlan(tankLevel, packLevel, hostile)` | -> Plan: above grey, Pull (asked as any pack); grey and not hostile, WalkPast; grey and hostile, Sweep (cleared by area attacks on the way) |

## HealerVoice

A healer buddy's own judgement of when to whisper "slow down" to the tank.

| Member | Type | Meaning |
|---|---|---|
| `after` | deque of float | its mana (percent) at each counted fight's end |
| `quiet` | size_t | fights still to keep quiet for |
| `Fought(manaAfterPct, fellBehind, s)` | -> Word | `Slow` when `healerLowCount` of the last `healerWindow` fights ended under `healerLowAfter`, or the group's health fell faster than it could heal; then quiet for `healerQuiet` fights; `None` otherwise |
