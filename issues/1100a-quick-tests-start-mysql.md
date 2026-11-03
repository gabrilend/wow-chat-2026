# 1100a - The Quick Tests Start MySQL

## Status
- Created: 2026-10-26
- Phase: 1
- Parent: 1100
- Related: `scripts/start-mysql`, `scripts/compile` (quick-test step)
- State: in progress

## Current Behavior

Built 2026-10-26, not yet seen in a compile by the owner. The compile's
quick-test step calls `scripts/start-mysql` when MySQL does not answer a
ping. The starter returns once MySQL answers (or says why it could not),
and the step goes on; a failed start stops the compile with the starter's
own report above it.

Found on the same evening, from the owner's "when I start the worldserver,
it doesn't start mysql?": the worldserver's launcher did call the starter.
MySQL's error log shows the first start becoming ready after 48 s of a
silent wait (the first start after a reboot, InnoDB reading from a cold
disk) and, in the same millisecond, "Received SHUTDOWN from user <via user
signal>"; a second start 15 s later stayed up. mysqld ran in the
launcher's process group, so a signal sent to the launcher's group (Ctrl-C
during the wait, or the terminal closing) could reach it. The starter now:

- starts mysqld with `setsid`, in a session of its own, away from the
  launcher's group and terminal;
- prints a "still starting" line every 10 s with MySQL's latest log line;
- waits up to 180 s (was 60 s, near the 48 s just seen).

- starts mysqld holding none of the launcher's open files (2026-11-03).
  A program is handed every file its parent has open, and mysqld outlives
  its launcher, so what it is handed stays open as long as MySQL runs.
  That day the commit tests (1100b) started MySQL from a commit's hook,
  handing it the commit tool's lock; the lock stayed taken, and every
  later commit waited 120 s for it and gave up without a word, until
  MySQL was stopped by hand. The starter now closes every open file above
  standard error before it becomes mysqld. The commit hook's background
  start of the tests does the same (`scripts/install-commit-test-hook`),
  so the tests don't hold the lock either.

**What starts MySQL stops it** (the owner, 2026-11-03: "if we ever
automatically start mysql, we should close it when we're done with it").
The commit tests (`scripts/test-commit`) start MySQL only when it does not
answer a ping, and stop it again when their run ends, however it ends; a
MySQL that was already answering is someone else's and is left running.
`scripts/test-mysql-start` stops the MySQL it started too. Not yet done:
the compile's quick-test step, which starts MySQL the same way and leaves
it running (open question below).

`scripts/test-mysql-start` checks the session separation (MySQL leads a
session of its own, apart from the starter's), that mysqld holds no file
the starter was handed (it hands the starter an extra open file, as the
commit hook once handed it the lock), and that MySQL is stopped again at
the end. It needs MySQL stopped, so it is run by hand: all 12 checks
passed on 2026-11-03.

## Intended Behavior

- Quick tests with MySQL down: MySQL is started, then the tests run.
- MySQL never stops because its launcher was interrupted.
- A slow start shows that it is progressing.
- MySQL holds nothing of whatever started it (no lock, no log file).
- Whatever starts MySQL by itself stops it when done with it; a MySQL
  that was already running is left running.

## Suggested Implementation Steps

1. In the compile's quick-test step, replace the "MySQL isn't answering"
   stop with a call to the starter; stop only if the starter fails.
2. In the starter, `setsid`, the progress line, the longer wait.
3. Extend `scripts/test-mysql-start` with the session check.

## Open Questions

- Did you press Ctrl-C during that first 48-second wait? If not, something
  else sent MySQL a stop signal at the moment it became ready, and that
  sender is still unknown.
- The compile starts MySQL for its quick tests when it is down. By the
  rule above it should stop it after them, but the compile's install
  steps and the servers you run next want it up. Stop it after the quick
  tests, after the whole compile, or leave the compile's MySQL running as
  the exception?
