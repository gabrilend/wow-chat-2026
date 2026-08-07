# 1101b - Ward State Reader

## Status
- Created: 2026-08-01
- Parent: Issue 1101 (Bellwether — attended play)
- Phase: 11
- Priority: High
- Depends on: 1101a (the roster says who to read)

## Overview

Produces one raw snapshot per ward, per sampling tick. Values only — no
names, no interpretation, no judgement about what matters. The next two
issues do those jobs, and keeping them separate is what makes the
pipeline debuggable: if the narration is wrong, the fault is in exactly
one of three files.

## Current Behavior

Nothing collects per-character state for external consumption. Issue
916's proximity hook reads party state for its guidance prompt, but it
reads a *party near a player* and shapes the result for a tactical
prompt. Attendance needs a different cut: a specific enrolled set,
sampled continuously, whether or not anyone is near them.

## Intended Behavior

### The snapshot

One flat struct per ward. Every field a primitive or a small list of
primitives — no nested objects beyond one level, because everything
downstream has to diff two of these cheaply.

| Field | Type | Notes |
|-------|------|-------|
| `guid` | int | ward identity |
| `taken_at` | int | server ms, for age and diffing |
| `map_id`, `zone_id`, `area_id` | int | resolved to names in 1101c |
| `x`, `y`, `z` | float | position |
| `level` | int | |
| `xp`, `xp_max` | int | progress within level |
| `health`, `health_max` | int | absolute, not percentage — 1101c derives the ratio |
| `power`, `power_max`, `power_type` | int | mana / rage / energy |
| `in_combat` | bool | |
| `is_dead`, `is_ghost` | bool | |
| `target_guid`, `target_entry` | int | what they're fighting |
| `attackers` | list of {entry, level, health_pct} | who is fighting them |
| `party_guids` | list of int | who they're with |
| `strategies` | list of string | current bot strategy set |
| `bot_activity` | string | what mod-playerbots thinks it's doing |
| `money` | int | copper |
| `bag_free` | int | free slots |
| `durability_pct` | int | lowest equipped item |
| `last_loot_entries` | list of int | items acquired since last snapshot |

### Sampling

Two rates, because the cost is not uniform:

- **Fast fields** (health, power, combat, target, position) — every
  second or two. Cheap reads off objects already in memory.
- **Slow fields** (money, bags, durability, strategies, xp) — every
  fifteen to thirty seconds, or on an event that implies a change.

A snapshot always carries all fields; slow fields simply carry their
last-read value with the age implied by `taken_at`. Downstream never has
to know which rate a field came from.

### Out-of-world wards

A ward can be offline, dead, in a loading screen, or on a different map
than any observer. The reader emits a snapshot regardless, with an
explicit `presence` field (`in_world` / `offline` / `dead` / `unknown`)
rather than omitting fields or returning nil. Nil checks downstream are
asking for errors; an explicit state is not.

## Implementation Steps

1. ALE Lua module that, given a ward guid, produces the struct above.
   Start with fast fields only.
2. Sampling loop over the enrolled roster, at the fast rate, writing the
   latest snapshot per ward into an in-memory table.
3. Add slow fields on the slower cadence, with their own last-read
   timestamps.
4. Add `presence` handling for every way a ward can fail to be readable,
   and confirm each path emits a struct rather than a nil.
5. Determine which fields need a C++ binding versus which ALE already
   exposes — particularly `strategies` and `bot_activity`, which are
   mod-playerbots internals and likely need 916b.
6. Expose the current snapshot table to 1101c, and dump-to-log for
   inspection.
7. Measure: cost per ward per tick, at family sizes of 1, 5, and 10.
   The reader runs forever; if it costs meaningfully into the tick
   budget at five wards, the sampling rates are wrong.

## Files to Create

- ALE Lua ward-state reader module
- Possibly bindings added to 916b's shim for the playerbots-internal
  fields

## Open Questions

- Are `strategies` and `bot_activity` reachable from ALE, or does every
  attended session need the 916b shim compiled in? This decides whether
  1101b can land before the 916 foundation does.
- Should the reader keep a short history ring per ward (say the last 30
  snapshots), or is the previous-snapshot diff in 1101d enough? A ring
  makes "she's been losing health steadily for a minute" expressible;
  it also multiplies memory by the family size.
- `last_loot_entries` implies hooking the loot event rather than
  diffing bags. Which is cheaper and which is more accurate? Bag diffing
  misses anything looted and consumed between samples.
- What identifies a ward that is offline — is the roster's record enough
  to keep narrating "Tessa is logged out," or does an offline ward drop
  out of the lap entirely?

## Related

- Parent: [1101 - Bellwether](1101-bellwether-attended-play.md)
- [1101a - Family enrollment](1101a-family-enrollment-and-persistence.md)
  — supplies the roster this iterates
- [1101c - Fact extraction](1101c-fact-extraction-aided-by-data.md) —
  the only consumer
- [916b - ALE bindings for playerbots](916b-ale-bindings-playerbots.md)
  — likely home for the playerbots-internal reads
- [916g - Proximity detection hook](916g-proximity-detection-hook.md) —
  the adjacent existing sampler; worth reading for its throttling and
  hysteresis approach before writing a second one
</content>
