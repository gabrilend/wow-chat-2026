# Strategem: The Intuition Copy

A strategem is a data flow pattern that recurs across multiple areas
of the project and has been proven useful enough to standardize. This
one says:

> Keep a second copy of the project that holds only what the machine
> runs: the source with its comments removed, no explanation documents,
> no instructions but a short default. Work a problem in both copies, one
> agent in each, and use the two results together.

The owner, 2026-10-19: "The parallel copy is meant to be the "machine's
intuition", and it is used in tandem with ours to achieve the desired goal
or outcome."

## Why two copies

The commented copy is understanding written down: why each thing is as it
is, what was tried, what the owner said. An agent reading it reasons from
that record, and takes on its framing, its names for things and its
mistakes along with its knowledge.

The comment-free copy has only the mechanism. An agent there has to learn
the project the way the machine meets it: which scripts exist, what the
build pulls in and in what order, what each function does when called. It
sees what the code does rather than what the comments say it does. Where
the two agents agree, the understanding is confirmed twice from two
directions; where they disagree, either a comment has gone stale or the
reasoning from the record went somewhere the code does not.

## The shape

1. **Made from the committed state only**, never the working folder: the
   copy is a snapshot of something the project stands behind.
2. **Comments removed by each language's own rules**, so the copy still
   parses and still runs. A comment the program reads (a marker line an
   installer looks for, a hint the database runs) is code, and stays.
3. **Explanations left out whole**: documents, issues, notes, transcripts,
   summaries beside each source file, the project's own instructions.
4. **One fixed default instruction file** at the copy's root, the same for
   every project, with only ways of finding one's way: where the common
   actions are, and the build's order of sources as the order to learn
   the project in.
5. **A receipt** naming the source commit, so either agent knows which
   state the other is looking at.
6. **Remade, not edited**: the maker builds a fresh copy and swaps it in,
   and only ever removes a folder that holds its own receipt.

## In this project

- Maker: `scripts/make-intuition-copy`, tested by
  `scripts/test-make-intuition-copy`.
- Default instructions: `strategems/intuition-copy-CLAUDE.md`.
- Issue: `issues/190-a-comment-free-copy-for-the-machines-intuition.md`
  (when it is remade, and where it lives, are open there).
