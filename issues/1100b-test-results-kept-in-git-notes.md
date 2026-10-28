# 1100b - Test Results Kept in Git's Notes

## Status
- Created: 2026-10-26
- Phase: 1
- Parent: 1100
- Depends on: 1100a (the runs start MySQL), 199 (the parallel runner)
- Related: `scripts/test-memory`, `scripts/test-commit`,
  `scripts/install-commit-test-hook`, `scripts/compile` (quick tests),
  `scripts/test-test-memory`, `scripts/lib/patch-header.lua` (the
  `remember` field)
- State: built; its open questions answered (2026-10-27); waiting to be
  seen in the owner's compile

## Current Behavior

Built 2026-10-26; the commit hook is installed in `.git/hooks/post-commit`.
Not yet seen by the owner in a compile.

**What a test reads** (`scripts/test-memory reads TEST`). Found by reading
the test, not by watching it run: no tracer (`strace`) is installed. Every
project path the test's code names, with comments left out (a comment
names what to read, not what is read): a file named exactly; a folder or
the start of a name (`src/lua-`, `patches/B[0-9]`), which takes every file
under it; a name from the scripts folder (`lib/toy-world.lua`); a name
from the reading file's own folder (`here .. "data/x.lua"`: missed at
first, found when the death knight souls test's data file was not in its
set); a bare file name with an extension (`ambush.lua`). Each word is also tried from every
`/` inside it, since `"$1/src/x"` reads as the word `1/src/x`. Scripts
named exactly (under `scripts/`, `patches/`, `config/patches/`, or ending
`.lua`/`.sh`) are read for names in turn, until nothing new turns up;
files reached through a folder are read as data, not followed. The set
errs large: a test runs again more often than it must, rarely less. The
sets today run from 1 file to about 1600 (`test-check-issue-references`
lists every issue).

**The fingerprint**: one SHA-1 of the read set's paths and each file's
content hash. Files as in a commit (`--commit`), or as in the working tree
(uncommitted changes and new untracked files included).

**The record**: git notes, ref `refs/notes/tests`, one line per result:
`pass|fail TEST FINGERPRINT UNIXTIME HOW` (HOW: `commit` or `compile`).
`git log --notes=tests` shows them. A result is matched by fingerprint, not
by commit, so a test whose files changed and changed back is remembered
again. The latest result for a fingerprint wins; in a tie, the fail.

**At each commit** (`.git/hooks/post-commit`, from
`scripts/install-commit-test-hook`): for a commit on main in this folder,
`scripts/test-commit` starts in the background (in a session of its own).
It lays out the commit's files as a git worktree in `tmp/tmp/ct-<short>`
(a short name: a socket path longer than 107 characters is cut off, and
the full commit name made MySQL's 128), links in what git ignores (MySQL,
the installed trees, source trees, `tmp/`) plus the untracked runtime
folders (`mysql/databases/`, `installed-files-*/`, `logs-*`), and runs, by
`scripts/run-tests-in-parallel`, the quick tests that read a file the
commit changed and are not remembered. Results go into the commit's note,
and the report into `tmp/shared-memory/commit-tests/<commit>/summary`.

**A new kind of record** in a commit (added lines with `CREATE TABLE` or
`ALTER TABLE ... ADD`) also runs every quick test that talks to the
database, and the whole-database builds (`test-basic-sql-in-ram`,
`test-beta-sql-in-ram`).

**At the compile**: the quick-test step asks `test-memory plan` which
tests are remembered, runs the rest, and records their results onto
`HEAD` (as `compile`). `--retest` runs every one. A lock
(`tmp/shared-memory/test-runs.lock`) keeps the compile's run and a
commit's run from overlapping (they share the tests' scratch folders); the
compile waits, and says so.

**Never remembered**: a test whose header says `remember: no` (a new
optional header field). Today `test-datapath-installed-lua`, which reads
the installed trees.

First runs (2026-10-26, on commit 35ec16d): 18 tests read files that
commit changed, in 3 min 26 s. Two failed at first because of the worktree
(the socket path; `mysql/databases/` not linked). Fixed, the re-run had 16
remembered and ran 2 in 4 s; both passed. `scripts/test-test-memory`
checks the memory on a pretend repository (16 checks), and found the
`$1/...` gap before the first real use.

## Intended Behavior

- A test is run at a commit when the commit changed a file it reads, and
  at a compile when no recorded pass has its files' fingerprint.
- No remembered pass outlives a change to a file its test reads.
- Commits are never slowed or refused by their tests.

## Suggested Implementation Steps

1. `scripts/test-memory`: the read set, the fingerprint, `plan`, `record`.
2. `scripts/test-test-memory`: the memory's own quick test.
3. `scripts/test-commit`: the worktree, the plan, the run, the note.
4. `scripts/install-commit-test-hook`: the post-commit hook.
5. The compile: lock, plan, run the rest, record, `--retest`.
6. The header field `remember` in `scripts/lib/patch-header.lua`.

## Open Questions

Answered together, 2026-10-27, the owner: "sounds like a lot of effort,
too much for my hardware." So none of the three below is built: the
database stays out of the fingerprint, no limit is measured or changed,
and `.gitignore` is left as it is. `--retest` is the hand-run answer to a
reinstall or a system upgrade.

- **Database contents are in no fingerprint.** Tests that ask the live
  database (`test-buddy-gems`, `test-acherus-vendors`, and others) see
  what the last install put there; a reinstall can change their answer
  while their files stay the same. Following "the database is fine", they
  are remembered like the rest. Should a reinstall forget them (for
  example, the install time of the profile taking part in their
  fingerprint)?
- **Programs outside the project** (luajit, g++, MySQL itself) are in no
  fingerprint either; a system upgrade does not re-run anything. `--retest`
  covers it by hand. Enough?
- **The whole-database builds** run under the runner's ten-minute limit per
  test. If they take longer, a commit with a new kind of record reports
  them as failed. How long do they take today?
- **`mysql/databases/` is untracked but not ignored** (only some files in it
  are in `.gitignore`), as are `installed-files-alpha/` and
  `installed-files-cc-test/`. Should `.gitignore` name them whole?
