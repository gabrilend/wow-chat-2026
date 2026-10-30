# 625k - Learning That Can Start Over

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625e (what each fight taught: the log), 625f, 625h, 625j (the
  economies whose numbers learning moves)
- Priority: Low (after the economies exist)
- State: planned

## Origin

The owner, 2026-10-30 (the whole passage in 625f): the economies "Ideally,
they could adjust with time spent learning, though only if we keep track
of both A. how to learn, and B. where we started from, so if we wanted to
we could either 1. learn from scratch as a batch, to see if we grow into
different conclusions (the ideal state), or 2. to learn individually and
become better at the game and our class as we level up and get better."

Then, of this idea: "this could be a strategem or something. The idea
that we can "grow" functionality, and it must be re-learnable as it's
underlying environment changes." Written as one:
`strategems/grown-and-relearnable.md`.

## Current Behavior

Not built. Nothing a buddy does changes its numbers; 625e plans the log
of what fights taught.

## Intended Behavior

- **Where we started is kept.** Every number an economy uses has its
  starting value written down, with why, and never overwritten: learning
  writes a learned value beside it.
- **How to learn is kept.** The method that turns logs (625e) into learned
  values is a tool in the project, run the same way every time, so it can
  be run again.
- **Two ways to learn:**
  1. **From scratch, as a batch**: every log so far read anew from the
     starting values, to see whether the same conclusions come out (the
     owner's "ideal state").
  2. **Each buddy on its own**, as it levels: its own learned values,
     improving with its own fights.
- **Either can be undone**: back to the starting values, or to any
  learned set kept.

## Suggested Implementation Steps

1. The starting values as one data file per economy, with reasons.
2. The learning tool reading 625e's logs, writing a learned set beside the
   start, dated.
3. Per-buddy learned sets, and a switch for which set a buddy uses.

## Open Questions

1. Should a buddy's own learning ever flow into the shared values (the
   whole server learning from one buddy's good fights), or stay its own?
