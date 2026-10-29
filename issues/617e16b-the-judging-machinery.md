# 617e16b - The Judging Machinery

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617e16
- Related: 617e14e (the picture judge), 617e14f (the movement benchmark)
- Priority: High
- State: in progress (the human half built 2026-10-28; the machine half
  waits on the image pipeline's repair)

## Origin

The owner, 2026-10-28: "yes please repair the image generation pipeline. I
can manually judge for now but we should build the judgement machinery so
we can compare things and evaluate whether or not they're done / correct
in a headless way in the future." And of direction: "The path finding
should eventually be both clockwise and counter clockwise. Right now we're
isolating one direction until we get the pattern right, then we do both."

## Current Behavior

**Built 2026-10-28**:
- **Runs**: `scripts/judge-run` takes a named variant of the flock (the
  sandbox page's settings: zone, fence, bots, turning, seconds of play)
  and photographs it headless (Firefox's screenshot, a frame at each of
  several moments), into `tmp/shared-memory/judging/<run>/`, with the
  sandbox's own measures beside each frame.
- **Judgements**: a judgement is a line in `docs/judgements.tsv` (kept in
  git): when, the run, who judged (the owner, or a machine judge by name),
  the question asked, the score (0-10), and a note. The owner judges by
  `scripts/judge-run --ask`, which shows each frame and asks for a score
  and a note.
- **Comparing**: `scripts/judge-compare` lists runs by their scores, per
  judge, and where a machine judge has scored runs the owner also scored,
  how closely the two agree (the machine judge is trusted when it ranks
  runs as the owner does).

Not built: the machine judge itself (the image pipeline makes reference
pictures of a school of fish seen from above; frames and references are
turned into picture embeddings by its CLIP image encoder; the score is how
near they lie). It waits on the pipeline's repair (started 2026-10-28:
its last update had been stopped mid-build on 2026-10-10).

## Intended Behavior

As the owner's words: the same runs judged by her now, by a machine later,
the machine's judgement trusted only as far as it agrees with hers, so a
change can be called done without a person watching.

## Suggested Implementation Steps

1. Runs, judgements, comparing (done).
2. The machine judge, once the pipeline runs.
3. One direction now (clockwise); both when the pattern is right.

## Open Questions

- None yet.
