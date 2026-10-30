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
  Plain text, one fight per block.
- **Raw in RAM, the essence on disk** (the owner, 2026-10-30, word for
  word: "on disk, or maybe in RAM with a step after the boss that
  examines them, finds the crucial information datapoints, and clears
  most of the junk data like position updates and damage values and
  such."). During a fight the full log (positions, damage numbers, every
  cast) is written to the RAM drive. When the fight ends, a distilling
  step reads it, keeps the crucial points (each phase's start and length,
  the moving share per buddy per phase, what began just before movement
  rose, deaths, the fight's length and outcome) and writes those to disk
  in the project, kept by date and by boss. The raw log is then cleared.
  The kept points are what the shared boss memory (625d, "a weak phase is
  learned") is built from.
- **In git, consumed by the plan, and fingerprinted** (the owner,
  2026-10-30, word for word: "learning travels, but we can remove them
  once we've built the plan. They are consumed, yet stored in git. Also,
  if the fight changes, we want to re-create them from scratch, so make
  sure we fingerprint anything related to the boss so we can both
  deterministically re-create the fight (not common) and also notice when
  things related to the fight have changed."). The distilled points are
  committed, so the learning travels to every machine. When a boss's
  plan is built from them they are removed from the working tree (still
  in git's history, where they can be read back). Each fight's points,
  and each boss's plan, carry a fingerprint of everything that makes up
  the fight: the boss's and its helpers' creature rows, their spells,
  their scripts, the encounter's settings and the profile's tuning that
  touches them. The fingerprint serves twice: with it and the run's
  seed, a fight can be replayed the same way (rarely needed); and when
  anything in it changes, the fingerprint no longer matches, the plan is
  marked stale and the boss is learned again from scratch.
- **Learned together, and the learning turns itself off.** Since
  2026-10-30 (625d, question 3) the reading is no longer only "later":
  the distilled points of every buddy's fights feed one shared memory per
  boss, and a boss whose memory has settled is cached and its learning
  switched off automatically.
- **This issue is the mark.** It stays open, saying the log is waiting to
  be read: which fights and which phases ask for "lots of movement", and
  what that coincides with.
- **Built now, whole; on only where switched on** (the owner,
  2026-10-30, told its two purposes, movement per phase and weak
  phases: "got it. Sounds like we should only enable it at specific
  fights and bosses?"; then, asked whether to build it now or wait for
  custom bosses: "build it now entirely."). Everything here is built in
  the next round of work (the log, the distilling, the shared boss
  memory, the fingerprint), and it runs only for the fights and bosses
  switched on for it, each by its own switch, off by default.
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
   **Answered 2026-10-30:** raw in RAM during the fight, distilled to its
   crucial points on disk after it, the junk cleared (above, word for
   word).
2. How long are the distilled points kept on disk: forever (they are
   small), or until a boss's memory has settled and been cached (625d),
   after which only the cached plan is needed? **Answered 2026-10-30:**
   until the plan is built from them; then removed, kept in git's
   history (above, word for word).
3. Should the distilled points live in the project's git (the learning
   travels with the code to other machines), or beside it, untracked?
   **Answered 2026-10-30:** in git, with a fingerprint of the fight
   (above, word for word).
