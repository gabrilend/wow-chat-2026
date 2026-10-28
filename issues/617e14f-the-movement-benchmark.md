# 617e14f - The Movement Benchmark

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 617e14
- Related: 617e14c (the pictures), 617e14e (the picture judge, one of the
  judges to come), 617e13 (the spread numbers and the live watcher)
- Priority: High
- State: built 2026-10-27 with the judges of numbers; the picture judge
  joins when 617e14e is built

## Origin

The owner, 2026-10-27, of the world watch and its judge:

> okay let's use a pass through that system as a testing benchmark - like,
> does the test come back okay? okay good we can stop iterating on it then.
> Does it not? Okay let's try again, what else could be wrong with it?
> [initiate debug sequences]

## Current Behavior

**Built 2026-10-27**: `scripts/movement-benchmark` takes a stretch of a
positions record (617e14a's world record or 617e13's spread record) and:
1. **judges** each owner's buddies by the measures of
   `scripts/lib/movement-judges.lua` against the targets in
   `src/lua-basic/data/movement-benchmark-targets.lua`: how much they
   move, how often they circle, whether they circle both ways ("in all
   directions at once"), how winding their paths are (the "semi chaotic"),
   how much of their sub-zone they cover, and the watcher's rule breaks
   (still, stacked, far);
2. **draws** the stretch (`scripts/animate-zone`), for eyes and, later, for
   the picture judge;
3. **passes** (exit 0) when every target is met: "okay good we can stop
   iterating on it then";
4. **or runs the debug sequence** (exit 1): for each target missed, its
   catalogue of causes, each checked against the record and the logs (the
   bot module's own action lines, `logs-<profile>/Playerbots.log`, and the
   buddy module's lines in `Server.log`), and reports them most-evidenced
   first: "what else could be wrong with it?".
The report: `tmp/shared-memory/movement-benchmark/<time>/report.md`, with
the animation beside it. `scripts/test-movement-benchmark` gives it three
made-up clans: one swirling (passes), one standing (fails, and the debug
names standing far from the owner, with nothing moving them), one walking
in straight lines (fails, names it).

## Intended Behavior

As the owner's words: one command that says whether the movement is right,
and when it is not, what might be wrong, with the evidence for each, so the
next change is aimed.

## Suggested Implementation Steps

1. The measures as pure functions (done), their targets as data (done).
2. The benchmark and its debug sequence (done), its test (done).
3. The picture judge as one more judge, when 617e14e is built.

## Open Questions

1. **The targets are ours**: the owner described the look ("whirling, but
   semi chaotic, like a maelstrom of swirls but in all directions at
   once"), not numbers. The first targets are in the targets file with
   their reasons; to be set again by the owner, or by the first runs she
   says look right.
