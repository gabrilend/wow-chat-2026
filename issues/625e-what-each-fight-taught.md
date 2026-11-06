# 625e - What Each Fight Taught, Written Down to Be Read Later

## Status
- Created: 2026-10-29
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625d (choosing by the moment's economy: the movement measure),
  617e5b (boss fights by the warnings)
- Priority: Medium
- State: the distilling and the fingerprint built offline (2026-11-06,
  on a branch for review); the server's writing and the reading still to
  build

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

Nothing is written down about fights in the server. The raw log's format
exists: the replay log (625n, `buddies_fight_replay.h`), every snapshot
and event of a fight.

**The distilling and the fingerprint, built 2026-11-06 (offline, on a
branch for review):** `buddies_fight_learning.h`. `Distill` reads a
fight's raw log (the replay log's steps) and keeps the crucial points:
the fight's length and outcome (won, lost, left); its phases (the pull,
each health band the boss crosses, 75%, 50% and 25%, and each change its
script reports); each character's share of each phase spent moving (625d's
measure, started again at each phase); each time movement rose (half the
party or more moving, after less), what the enemies began in the 3
seconds before (a cast, an enemy that appeared, a mark on the party, a
spell that hit two or more of them); and each death in the party. `Write`
and `Read` turn that into a short plain-text block and back, one fight
per block; `Path` keeps them by boss and by day
(`learned/fights/ENTRY-name/DATE.fights`). The fingerprint: `Parts`
hashes each part of the fight the server reads (creature rows, spells,
scripts, settings, tuning) and `Whole` the lot; `Changed` names what
differs, and `Stale` says a block was learned from another fight. Checked
by `scripts/test-buddy-fight-learning` (41 checks, a quick test) on a
made-up minute-long boss fight; 39 of 39 deliberately broken versions of
the header caught. Not yet: the server writing the raw log to the RAM
drive, distilling at the fight's end and clearing the raw log, the
per-boss switches, the commit of the blocks, and the reading (step 3).

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

## Decisions (2026-11-06)

The agent's calls while building `buddies_fight_learning.h`, for the owner
to curate (tuning goes to docs/balance-updates.md):
- **Phases** begin at the pull, at each boss health band crossed (75%,
  50%, 25%; a band already passed at the pull begins nothing; two crossed
  at once make one phase, named by the lower), and at each phase change
  the boss's script reports. Changes in one snapshot make one phase, all
  named ("script health 50").
- **"A change in what it casts" is built but off** (`newCastAfter`, -1):
  a boss spell first cast 30 seconds or more after the pull would begin a
  phase. Off because a boss's slow spell (a cooldown over 30 seconds)
  would start a false phase and reset the movement measure; its casts are
  still kept as cues where movement rose.
- **Moving** is faster than 1 yard a second between two snapshots, so
  shuffling and turning don't count, however often snapshots come. Only
  characters count (pets follow their masters), and the dead stop
  counting when they die.
- **Movement rose** when half the party or more is moving after fewer
  were; running in at the pull is no rise. **What began just before**:
  the 3 seconds before the moving stretch, through its first interval;
  only what enemies did: casts begun, marks put on the party, a spell
  that hit two or more of the party (fire on the ground), an enemy that
  appeared (written by its creature entry, "?" when the server didn't
  give one). Damage numbers and positions are left out.
- **Outcome**: won when the boss died (its death written, or no health at
  the end), lost when everyone in the party is down at the end, left
  otherwise. **Deaths**: every death in the party (pets too), each in the
  phase of its own time; one raised and fallen again counts twice.
- **The fingerprint** is FNV-1a, 64 bits: the same text gives the same
  number on every machine and compiler. One hash per named part, so a
  change can be named ("spells changed"), and the whole from those, so
  the order the parts are given in doesn't matter.
- **The block** is plain words, a line per point, times to a tenth of a
  second and shares to a hundredth, so the file is small, reads in a
  diff, and the same fight writes the same block. The run's seed is kept
  on the fight's line, for replaying it the same way.
- **Kept at** `learned/fights/ENTRY-name/DATE.fights` in the project, a
  day's fights of one boss in one file, beside the starts and methods as
  strategems/grown-and-relearnable.md keeps "what was learned".
