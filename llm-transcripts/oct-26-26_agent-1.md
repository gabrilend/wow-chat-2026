# Conversation Summary: d86c6fd0-ee75-4d61-9a81-7c7ca71698ed

Generated on: 2026-10-26 15:54:12
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

hi, can you work on the issue file in the project directory?

--------------------------------------------------------------------------------

### Assistant Response 1

Reading the compile's test runner; I've found why Ctrl-C misses the tests and am
checking which tests run the C++ compiler.

--------------------------------------------------------------------------------

### User Request 2

Base directory for this skill: /home/ritz/.claude/skills/issue-lifecycle

# Issue lifecycle

The owner's CLAUDE.md is the authority on what issue files are for and what
they must contain; where it and this skill ever disagree, CLAUDE.md wins. This
skill adds the mechanics CLAUDE.md leaves open: which tools answer which
question, in what order, and what to do when a tool says no.

All tools live in one place and are called by absolute path:

| Tool | Answers |
|---|---|
| `/home/ritz/programming/ai-stuff/scripts/validate-issues <project>` | is the issue tree consistent; next free number per phase |
| `validate-issues <project> --next <phase>` | the number to give a new issue |
| `validate-issues <project> --file <issue>` | is this one issue well-formed and are its links matched |
| `/home/ritz/programming/ai-stuff/scripts/progress-dashboard.lua <project> -m` | done/open counts per phase (for progress files and demos) |
| `/home/ritz/programming/ai-stuff/scripts/commit-own-changes <repo> -F -` | commits exactly the lines this session wrote, plus the changed transcripts of the commit's projects (any conversation's), and runs the repository's commit hooks, without touching the shared staging area |
| `/home/ritz/programming/ai-stuff/scripts/stage-own-changes <repo>` | previews what that commit would take; writes nothing |
| `/home/ritz/programming/ai-stuff/scripts/claim-own-change <file>` | records lines this session changed by a route the edit ledger cannot see (see Committing) |
| `/home/ritz/programming/ai-stuff/scripts/adopt-left-behind-changes <repo> -- <path>...` | takes ownership, line by line, of uncommitted work a finished session left, leaving lines any other session still holds (see Committing) |

Each tool has a `.info.md` beside it; read that rather than the source.

## Before writing a new issue

1. **Search first, including `issues/completed/`.** Grep the issue tree for
   the feature's nouns, not just the likely title. A completed issue about the
   same machinery is reopened and extended rather than duplicated: history is
   more useful stacked vertically in one file than spread across several.
2. **Pick the phase by what the work builds on**, not by when it is being
   done. Lower numbers are foundations; later issues depend on earlier ones.
3. **Take the number from the tool:** `validate-issues <project> --next
   <phase>`.
   It reads the project's own naming shape (522, 1001, 9-007, A04) and never
   reuses a number that a completed file already holds.
4. **Write the blueprint** with the three sections CLAUDE.md requires, plus
   link fields in the shape the project already uses (look at a neighbour).
   Name related functions, structures and files instead of pasting code.
5. **Check it:** `validate-issues <project> --file <new-issue>`, and fix what it
   reports on the new file. If the new issue blocks or is blocked by others,
   add the matching line to the other side too.

## While working

- Keep **Current Behavior** true. It is the only section that changes while
  an issue is in progress; rewrite it in place rather than appending a log.
- A question that surfaces is written into the issue (an "Open questions"
  section) and then asked. An issue with an unanswered question is in
  progress, not done.
- Anything discovered that changes another issue's assumptions is written into
  that issue now, not at completion.

## Splitting into sub-issues

Split when an issue holds work streams that could be built, tested or reviewed
separately, or when it cannot be finished in one sitting. Do not split an issue
that is already one mechanism. When splitting, produce and then write out:

1. **A table** — `| ID | Name | Dependencies | Description |`, where ID is the
   parent number plus a lower-case letter (103a, 103b), Name is dash-separated
   lower-case words, Dependencies is "None" or sibling IDs.
2. **The rationale** — the distinct work streams, why one issue cannot hold
   them, what splitting buys.
3. **The execution order** — a small dependency graph, e.g.
   `103a (foundation) → 103b (needs 103a) → 103c (parallel with 103b)`.

Each row becomes a file `{parent}{letter}-{name}.md` with the three sections.
The parent keeps its blueprint and gains a short list of its sub-issues; the
analysis itself is not appended to the parent (that would be worklog, not
blueprint). Run `validate-issues` afterwards: it reports orphaned sub-issues
and one-sided links.

## Completing an issue

An issue is complete only when nothing in it is deferred and no open question
is unanswered. Then, in this order:

1. **Run the project's tests.** A fixed bug gets a test that would have caught
   it.
2. **Rewrite the issue as the blueprint of what was built**: Current Behavior
   states the built system; steps name the real functions and files; decisions
   not taken are stated with their reason. Poetry the owner wrote during the
   work goes into the issue verbatim.
3. **Move it** into `issues/completed/` (`git mv`, so the history follows).
4. **Update `issues/phase-<N>-progress.md`** for that phase. Take counts from
   `progress-dashboard.lua <project> -m`, or better, name the command instead
   of copying numbers that will go stale.
5. **Update related issues** whose Current Behavior or assumptions changed.
6. **Run `validate-issues <project>`** and fix new findings that the change
   caused. Findings older than the change are reported to the owner, not
   silently fixed in passing.
7. **Commit** as below.

## Committing

The rule (CLAUDE.md): a commit carries exactly the lines this session wrote —
never another session's work, even if it sits in the same file — and every
changed transcript of the commit's projects rides along — the session's own
project folder and the projects of the files it commits — this
conversation's and any other's left behind (a session that committed, talked
on and quit), so each project's story in git stays whole.

Commit small and often: each piece as soon as it is done and checked, not a
pile at the end.

1. Optionally preview: `stage-own-changes <repo>` lists what would be taken
   and what left out, and writes nothing.
2. Commit: `commit-own-changes <repo> -F -` with the message on standard
   input. It builds the commit on a private staging list from this session's
   own lines (the edit ledger the edit hook keeps) plus those transcripts, and
   never touches the shared staging area, so nothing another
   session has staged can ride along. Plain `git commit` is refused by the
   commit gate.
3. Message style: say what the software now does, in plain English and by
   mechanism or analogy; mention any extra changes and why. No function names.

**When it stops or leaves something out.**

- **A tangled ("mixed") block** means another session changed lines right
  next to or on top of yours. Nothing is committed. Tell the owner which file
  and line; decide together what that region should say. `--leave-mixed`
  commits your other blocks meanwhile.
- **Lines that are yours but were written by a route the ledger could not see**
  (a script you ran, a generator, `sed`, a rename): record them with
  `claim-own-change <file>` and say so in the commit message.
- **Nothing to commit, but the work is there**: an earlier session wrote it
  and ended, or the machine rebooted and emptied the ledgers. Look first with
  `adopt-left-behind-changes <repo> --dry-run -- <path>...`, then adopt and
  commit one batch at a time with `commit-own-changes <repo> -F - --
  <path>...`. Lines reported as **held** belong to another session. Take them
  (`--from <session>`) only if that session has finished, and ask the owner
  if unsure. Say in the commit message that the work was adopted and from
  whom. This is the route for a left-behind backlog, not the token.
- **A warning about the shared staging area** means someone had staged that
  file by hand in a way that overlaps your commit; their entry was left alone.
  Tell the owner.

The one-time permission tokens (`/tmp/claude-allow-*`) belong to the person.
Never create one; if a gate names a token, relay the gate's message and let
the owner decide.

## Open questions

- Phase ≥ 10 in compact names depends on the project's issue-number width;
  `validate-issues` decides it from evidence (progress files, `phase-N-demo`
  names). A project with none of those gets a warning. Should the house rule
  fix one width (two digits, as in the 522 example) for every new project?

--------------------------------------------------------------------------------

### Assistant Response 2

> Searching for the issue that created the compile's quick-test step, so I can
> reopen it rather than write a duplicate.

> Claiming the files, then writing the issue.

> Writing the test that interrupts the new runner and checks nothing outlives
> it.

> Passes. Now checking the test would have caught the bug, by running it against
> a copy of the runner with the stopping removed.

> My stand-in line was bad shell; fixing the copy and rerunning.

> The edit landed (only my lines changed). Running syntax checks and the header
> tools.

> Headers check clean. Regenerating the patch lists so the new quick test is
> listed.

> The long test name widened the generated table's column, rewriting every row.
> Renaming the test shorter to keep the diff to one line.

> Running the renamed test, the header checks, and the generated-lists test.

> Updating the issue to describe what's now built; it stays in progress because
> of the open question.

Ctrl-C now stops the compile's quick tests, compilers included. I haven't
committed, because the issue still has your question open. I didn't run the
compile itself, since that's yours to run.

**Why Ctrl-C missed them:** Ctrl-C goes only to the terminal's foreground
process group, and each test's ten-minute `timeout` moves the test into a group
of its own. That is what lets `timeout` end a whole test on a time-out, but it
also put the tests, and the `g++`/`cc1plus` they start, out of Ctrl-C's reach. I
confirmed it by running `timeout` next to a shell: they came out in different
process groups.

**What changed:**
- **`issues/199-quick-tests-stop-on-interrupt.md`**: new issue, written from
  your note in `issue`.
- **`scripts/run-tests-in-parallel`**: the parallel running now lives here
  instead of inside the compile. On Ctrl-C or a terminate signal it ends each
  test's whole process group, lists the tests that hadn't finished, and exits
  130 (the usual "stopped by Ctrl-C" code).
- **`scripts/compile`**: calls the new runner. On 130 it stops and says nothing
  was patched or built.
- **`scripts/test-tests-stop-on-ctrl-c`**: a new quick test. It interrupts the
  runner, checks that nothing the pretend tests started is still running, and
  checks that a test which finished first still counts as passed. It passes. I
  also ran it against a copy of the runner with the fix removed, and it failed
  there (3 programs left running), so it would have caught this bug.
- **`docs/patches/patch-registry.md`**: regenerated; it gained one line for the
  new test.

To see it in a real run: start `./scripts/compile`, press Ctrl-C during "Running
54 quick tests...", then check that `pgrep cc1plus` prints nothing.

**What the tests check:** the project's own scripts, Lua, SQL and patches. That
covers:
- the patch headers and the build order they produce
- each profile's config values
- SQL applying and reverting in transactions that get rolled back
- Lua files loading without name clashes
- three small C++ checks of the buddy module's logic

None of that depends on how the server is compiled. `--debug` only changes
compiler optimisation and whether assertions stay on, so the build type isn't a
good thing to switch the tests on. `--skip-tests` already skips them.

That leaves the question in the issue: what bothers you about the tests on a
normal build? The ~30 seconds they add, the processor they hold just before the
build needs it, or something else?

Two smaller things:
- Your two loose notes in the project root (`issue` and `new-issue-please-sort`,
  the battleground spy idea) are still there. I didn't touch the spy one.
- Standing reminder: the disks still aren't protected against bit rot (issue
  191). ext4 doesn't checksum file contents.

--------------------------------------------------------------------------------

