# 1100 - Tests Remembered With Each Commit

## Status
- Created: 2026-10-26
- Phase: 1
- Related: 199 (the quick tests stop on Ctrl-C; its runner is what these
  build on), 189f (each test's header says whether it is quick), 144 (the
  compile's validate-and-promote pipeline), `docs/datapaths/`
- Sub-issues: 1100a, 1100b, 1100c
- Priority: Medium
- State: in progress

## Origin

The owner, 2026-10-26:

> the quick tests before the compilation should start the mysql server if
> it isn't running. Also, we should cache test results with the git
> commit, and later on-ings. That way we don't have to run it again if that
> part didn't change. Be sure that we have some tests that follow data
> through the entire datapath. As best we can without user intervention.

Asked how a remembered result should know its part had not changed, and
how far the end-to-end tests should reach:

> run the tests as part of the git commit, any of them that touch anything
> created or modified by the module in question. Run it in the background
> as a matter of course, when committing.

> we can simulate database answers. The database is fine, so long as we
> don't add new types of records. And those must be thoroughly tested at
> their git commit time, which we should do as a matter of course.

## Current Behavior

See each sub-issue. Before this issue: the compile ran all 54 quick tests
every time (`scripts/compile`, its quick-test step), stopped with an error
when MySQL was down, and kept no record of any result past the RAM logs in
`tmp/shared-memory/compile-tests/`. Commits ran no tests.

## Intended Behavior

- The compile's quick tests start the project's MySQL when it is down.
- Each commit runs, in the background, the quick tests that read any file
  the commit changed, and the results are kept with that commit (in git's
  notes, beside the commit, not in the tree). The compile then runs only
  the tests whose files differ from a state some earlier run passed in.
- A commit that adds a new kind of database record (a new table, a new
  column) is tested thoroughly at that commit.
- End-to-end tests follow one piece of data along a whole data path, from
  the folder the install links into the server through each step the
  datapath document names, with the database's answers simulated.

## Sub-issues

| ID    | Name                                   | Dependencies | Description |
|-------|----------------------------------------|--------------|-------------|
| 1100a | quick-tests-start-mysql                | None         | the compile's quick-test step starts MySQL instead of stopping |
| 1100b | test-results-kept-in-git-notes         | 1100a        | what each test reads, results kept with commits, the commit hook, the compile reusing them |
| 1100c | tests-that-follow-a-datapath-end-to-end | None        | one datum along each datapath, and the install's links checked |

Order: 1100a → 1100b; 1100c in parallel (its tests join the compile and
the commit runs like any quick test).

## Suggested Implementation Steps

1. 1100a.
2. 1100c (the tests exist before the machinery that remembers them).
3. 1100b.

## Open Questions

(in the sub-issues)
