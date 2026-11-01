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
