# 625e - What Each Fight Taught, Written Down to Be Read Later

## Status
- Created: 2026-10-29
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625d (choosing by the moment's economy: the movement measure),
  617e5b (boss fights by the warnings)
- Priority: Medium
- State: planned: the log first; reading it is to be built later, from
  scratch when a use for it arrives

## Origin

The owner, 2026-10-29, answering whether the movement measure should
count the whole fight or the last half minute:

> should reset when the phase changes. Also, we should remember, so write
> our learnings to a log file and make sure we mark somewhere that we have
> to come back and consume that log file and it's machinery to learn which
> fights and which phases require "lots of movement" and what that
> coincides with. We never want to forget how to generate these
> conclusions, but we can build the machinery from scratch whenever a new
> use-case arises. [expansion oriented darling]

## Current Behavior

Nothing is written down about fights.

## Intended Behavior

- **The log.** Every fight a buddy is in writes lines: the fight (the
  boss, or the creatures), each phase as it begins (a boss's phase, its
  health bands, or a change in what it casts), and through each phase how
  much of the time each buddy had to move, with what was happening when
  movement rose (a spell cast, a creature summoned, fire on the ground).
  Plain text, one fight per block, kept by date on disk.
- **This issue is the mark.** It stays open, saying the log is waiting to
  be read: which fights and which phases ask for "lots of movement", and
  what that coincides with.
- **The reading is built when it is needed**, from scratch if need be.
  What must never be lost is how to make the conclusions: this issue
  keeps the method (count the moving share per phase, line it up with
  what began just before, compare across fights of the same boss), so it
  can be built again for any new use.

## Suggested Implementation Steps

1. The log writer in the buddy module: a fight's start and end, phase
   changes, each buddy's moving share per phase, the casts and summons
   around each rise.
2. A short note in the fight's log of the conclusions the buddies already
   act on (625d's measure, reset at each phase).
3. Later, when a use arrives: a reader that turns the logs into "this
   phase moves a lot" for each fight, fed back into 625d as a starting
   guess for the next time.

## Open Questions

1. Where should the logs live: in the RAM drive (lost at a reboot, cheap)
   or on disk in the project (kept, growing), and for how long?
