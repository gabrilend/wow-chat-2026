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

`scripts/test-mysql-start` checks the new session separation (MySQL leads
a session of its own, apart from the starter's). It needs MySQL stopped,
so it is run by hand; not yet run.

## Intended Behavior

- Quick tests with MySQL down: MySQL is started, then the tests run.
- MySQL never stops because its launcher was interrupted.
- A slow start shows that it is progressing.

## Suggested Implementation Steps

1. In the compile's quick-test step, replace the "MySQL isn't answering"
   stop with a call to the starter; stop only if the starter fails.
2. In the starter, `setsid`, the progress line, the longer wait.
3. Extend `scripts/test-mysql-start` with the session check.

## Open Questions

- Did you press Ctrl-C during that first 48-second wait? If not, something
  else sent MySQL a stop signal at the moment it became ready, and that
  sender is still unknown.
