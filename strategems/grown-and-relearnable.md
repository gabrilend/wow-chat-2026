# Strategem: Grown, and Relearnable

A strategem is a data flow pattern that recurs across the project and is
worth standardizing. This one says:

> When behaviour is grown from experience rather than written by hand,
> keep three things apart and forever: **where it started** (the starting
> numbers and why), **how it learns** (the method, as a tool that runs the
> same way every time), and **what it learned** (the learned numbers,
> dated, beside the start, never over it). Then the behaviour can always be
> grown again: from scratch, as a batch, when the world under it changes,
> or on, one learner at a time.

The owner, 2026-10-30, on the buddies' economies learning: "Ideally, they
could adjust with time spent learning, though only if we keep track of
both A. how to learn, and B. where we started from, so if we wanted to we
could either 1. learn from scratch as a batch, to see if we grow into
different conclusions (the ideal state), or 2. to learn individually and
become better at the game and our class as we level up and get better."
And, of this idea: "this could be a strategem or something. The idea that
we can "grow" functionality, and it must be re-learnable as it's
underlying environment changes."

## Why

What is learned is true of the world it was learned in. A patch to the
game, a new boss, a changed rule, and the learned numbers are stale; if
the start and the method are gone, they can only be thrown away or kept
wrong. Kept, they can be grown again in an afternoon.

## The shape

| Part | Kept as | Changes |
|------|---------|---------|
| The start | a data file, each number with its reason | only by a person, with a reason |
| The method | a tool in the project, with a test | like any code |
| The record | logs of what happened (raw in RAM, the essence on disk) | appended |
| What was learned | dated sets beside the start | each run writes a new set |
| Which set is used | a switch | by a person, or per learner |

Two ways to learn, both from the same start, method and record:
1. **As a batch, from scratch**: every record read anew; if the
   conclusions differ from last time, the world (or the method) changed.
2. **One learner at a time**: each buddy grows its own set as it plays.

## Where it is used, or will be

- The buddies' economies (issues 625e, 625k): fights logged, bosses'
  phases learned, numbers grown and relearned.
- The painted map (617o8): walls learned by walking; the start is the
  game's own navigation mesh; relearning is clearing a region's file.
- The bosses' plans (625d): learned together, cached, switched off by
  hand once tested, relearned from scratch when a fight changes.
