# 617e14a - Where Everyone Is, Recorded

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 617e14
- Related: 617e13 (the spread recorder, `src/lua-basic/buddy-spread-recorder.lua`, whose way this follows)
- Priority: High
- State: built 2026-10-27, not yet run in game

## Current Behavior

**Built 2026-10-27**: `src/lua-basic/world-positions-recorder.lua` writes,
every 5 seconds, one line per character in the world (players and bots
alike) to `tmp/shared-memory/world-positions.tsv`: time, character, name,
kind (player, buddy, bot), map, zone, sub-zone, x, y, z, fighting, dead.
Only on a Debug build, as the spread record. Loaded by `.reload ale` or a
server start; not yet run.

## Intended Behavior

- Every character in the world, every 5 seconds, so the renderer (617e14c)
  can draw any zone at any moment.
- Its kind: a person's character ("player"), a buddy (on the buddy
  roster), another bot (a companion or random bot account).
- In RAM (`tmp/shared-memory/`), appended; never in git.

## Suggested Implementation Steps

1. The recorder (done), with the spread recorder's Debug-build rule.
2. A size guard: the file is cut to its last hour when it passes a size
   (not yet built: the open question).

## Open Questions

Gathered 2026-10-28 into 617's own list (question 15), merged with the
same questions from other sub-issues; answers are written back here.

- **Answered 2026-10-28** (617's question 15): everyone, on Debug builds;
  the file trimmed to its last hour.

1. **Game masters only?** The owner, of path recording (2026-10-27): "we
   will only record our paths in debug mode. and then, only for GMs." This
   record is of everyone, so that bots with no player can be watched
   (617e14: "we don't need a player to watch them quest"). Debug builds
   only, but of everyone: is that right?
2. **How much to keep**: at a few hundred characters, a line each every
   5 seconds is about 5 MB an hour in RAM. Keep the last hour, or more?
