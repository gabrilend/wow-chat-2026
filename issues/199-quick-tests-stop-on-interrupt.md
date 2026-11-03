# 199 - The Quick Tests Stop on Ctrl-C

## Status
- Created: 2026-10-26
- Phase: 1
- Related: `scripts/compile` (the quick-test step, before anything is
  patched or built), 189f (each test's header says whether it is quick),
  144 (the compile's validate-and-promote pipeline, which the quick tests
  now stand in front of)
- Priority: Medium
- State: in progress; one open question

## Origin

The owner, 2026-10-26 (a note left in the project root, `issue`):

> hi, new issue, the 55ish tests that run when starting the compile don't
> receive interrupts to their multithreaded cc1 plus shared processes.
>
> whoa cool
>
> also, what are they testing? Are they necessary if not on a --debug build?

## Current Behavior

Built 2026-10-26; waiting on the open question below, and on the owner
seeing Ctrl-C work in a real compile (the compile is the owner's to run).

**Why Ctrl-C missed the tests.** Pressing Ctrl-C makes the terminal send
an interrupt signal to one **process group**: the group the terminal calls
"in front" (the foreground group). The compile, the parallel launcher and
each test's small shell wrapper are in that group. But `timeout` (the
ten-minute limit around each test) puts itself and everything it starts
into a group of its own, so that on a timeout it can end the whole test at
once. That same move takes each test out of the terminal's front group, so
Ctrl-C never reached it. Three tests build C++ with the system compiler
(`g++`, whose worker `cc1plus` does the compiling): `test-buddy-kit`,
`test-buddy-stand-ins` and `test-buddy-roam-core`; those, and every other
test still running, carried on until they finished or ran out of time.
Seen by running `timeout 30 sleep 20` beside a shell: the shell's group was
27421, `timeout`'s and `sleep`'s 27426.

**What runs now.** The compile's quick-test step (in `scripts/compile`)
still gathers the tests from their headers and checks MySQL, then hands
the running to `scripts/run-tests-in-parallel`. The runner starts the
launcher (`xargs`, one test per processor) in the background and waits,
with a trap on interrupt and terminate. On either, it reads which tests
have not finished (each wrapper leaves a `.done` mark beside the log when
its test ends), sends terminate to every `timeout`'s whole group (the test
and all it started), waits, names the unfinished tests and exits 130. The
compile, seeing 130, says nothing was patched or built and exits 130; its
end-of-run report follows as for any other stop. Any other status from the
runner (not a test failing: the runner itself breaking) stops the compile
with an error rather than being read as a pass.

**The test.** `scripts/test-tests-stop-on-ctrl-c` (a quick test) builds a
pretend project with one test that ends at once and two that start a
long-running program (one directly, one through a shell, as `g++` starts
`cc1plus`), then interrupts the runner, once with Ctrl-C's signal and once
with terminate. It checks that nothing the pretend tests started is left,
the status is 130, the finished test keeps its `.ok`, and the runner names
the unfinished tests and only those. Run against a copy of the runner with
the trap taken out, it fails: three programs left running.

## Intended Behavior

- Ctrl-C (or a terminate signal) during the quick tests ends every running
  test, compilers included, and the compile stops, saying it was
  interrupted and which tests had not finished.
- A test that runs past its ten minutes is still ended as a whole, as now.
- Nothing else about the step changes: the tests run before anything is
  patched or built, failures are reported with their logs, `--skip-tests`
  skips the step.

## Suggested Implementation Steps

1. Move the parallel running out of `scripts/compile` into a small script of
   its own (`scripts/run-tests-in-parallel`), so it can be tested without a
   compile. It takes the project folder, the log folder and the test names;
   it writes each test's log and, for a test that passed, its `.ok` mark,
   exactly as the compile did.
2. In it, start the launcher in the background and wait for it, with a trap
   on interrupt and terminate. The trap sends terminate to each test's
   `timeout`; `timeout` passes the signal to its whole group (the test and
   any compiler it started), which is the same path a timeout already uses.
   It then waits for them to end, names the unfinished tests, and exits with
   130 (the usual status for "ended by Ctrl-C").
3. The compile calls the script; its own report of which tests failed stays
   in the compile.
4. A quick test, `scripts/test-tests-stop-on-ctrl-c`: runs the
   script on made-up tests that each start a long child, interrupts it, and
   checks that no child outlives it, that the status is 130, and that a
   test which finished before the interrupt still has its `.ok`.

## Open Questions

- **Are the quick tests needed on a build that is not `--debug`?** What
  they check: the project's own scripts, Lua, SQL and patches (the patch
  headers and the build order they make, the config patches' values per
  profile, SQL applying and reverting in rolled-back transactions, Lua
  files loading and their names not colliding, the buddy module's C++
  logic against its Lua model). None of that depends on how the server is
  compiled: `--debug` changes only the compiler's optimisation and whether
  assertions stay on. So the build type is not the thing that should
  decide. Is the owner's concern the time they take, or the processor they
  hold while the build wants it? (`--skip-tests` already skips them.)
