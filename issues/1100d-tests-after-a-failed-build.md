# 1100d - The Quick Tests After a Failed Build, Not Before

## Status
- Created: 2026-10-28
- Phase: 1 (the build)
- Parent: 1100 (tests remembered with each commit)
- Related: 189f (which tests are quick: their headers), 1100b (test memory)
- Priority: High
- State: built 2026-10-28, not yet run by the owner

## Origin

The owner, 2026-10-28:

> I think in the compile script we should only do our tests if the
> compilation fails. if we find nothing wrong in the tests we try the
> compilation again, and if that doesn't work then we try a design
> session.

## Current Behavior

**Built 2026-10-28** (`scripts/compile`; committed 2026-10-30 in
138b89ea8, whose message is about basic's module list: the whole file was
taken into that commit, this change with it): the build goes first. Each path:
- the build succeeds: no quick tests run (the commit's own background
  tests, 1100b, still run at each commit);
- it fails: the quick tests run (those whose files changed since they last
  passed; `--retest` runs them all). A test that fails is named, with its
  log, as the likely cause, and the compile stops there;
- it fails and every test passes: "the tests find nothing wrong", and the
  build runs once more (a failure that does not happen twice, a race in
  make or a file caught mid-write, is over);
- it fails again: a design session. The compile writes what is known to
  `tmp/shared-memory/design-session-<profile>.md` (the compiler's error
  lines, that the tests passed, which source and patch files differ from
  the last commit, and the last good build's time) and says to open a
  Claude Code session on it; it stops, failed.
`--tests-first` runs the quick tests before the build, as before (stop on
a failure, nothing built); `--skip-tests` runs none, before or after.
Until 2026-10-28 the quick tests always ran first and a failure stopped
the compile before it built anything.

## Intended Behavior

As the owner's words: tests only when the build fails; a clean test run
earns one more build; a second failure is a design question, not a
build question.

## Suggested Implementation Steps

1. The order in `scripts/compile` (done).
2. The design session's note (done); its content to be shaped by use.

## Open Questions

1. **The design session**: is a note for a Claude Code session to read
   what you meant, or should the compile start that session itself (a
   `claude` run with the note as its first message)?
