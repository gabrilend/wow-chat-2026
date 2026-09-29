# 913b - Connectivity Reliance Improvements Required

## Status
- Created: 2026-09-23
- Parent: Issue 913 (clustered-worldserver)
- Phase: 9 (numbered under its parent)
- Priority: Gate. Nothing that splits one world across several worldservers
  starts until this issue shows that it has to
- **Blocked by:** 157
- **Blocks:** 913c, 913d, 913e, 913f, 913g, 913h

## Overview

This issue is the gate in front of the clustered worldserver. The server
feels slow, but slowness has many possible sources: the database sharing a
machine with the game, the authserver, the playerbots, the local language
model, disk, the network. Splitting the world across machines only helps if
the one worldserver machine is the ceiling. That means its world-update
loop can't keep up even with the database and authserver moved off it.

The gate opens when a measurement says so, not when it feels so. Until
then, the cheaper fix is issue 157: one machine each for the authserver,
the worldserver, and MySQL.

## Current Behavior

- One machine runs MySQL, the authserver, the worldserver, the playerbots
  and the build tools together. Nobody has measured which of these the
  slowness comes from.
- AzerothCore already measures how long each pass of its world-update loop
  takes. `.server info` shows the recent "update time diff", and
  worldserver.conf has settings to write it to the log periodically. The
  project doesn't read or record these numbers anywhere.

## Intended Behavior

A measuring tool that runs alongside a live server and writes a plain
report to `tmp/shared-memory/`. For each sample it records:

| Measure | Datatype | Where it comes from |
|---|---|---|
| world update time | milliseconds, integer, per pass | the core's own update-time-diff record |
| players online / bots online | integer counts | the characters database, or the console |
| worldserver CPU per thread | percent, float, per thread | `/proc/<pid>/task/*/stat` on the world machine |
| MySQL query time | milliseconds, float | the slow-query log on the database machine |
| network round trip world→database | milliseconds, float | a ping between role machines after 157 |

The report ends with one verdict line: **required** or **not required**.
"Required" means the world update time stays over budget while the world
machine's map threads are all busy and the database and network are not.
In other words, more cores in one place would help, and 157 has already
taken everything else off that machine.

When the verdict reads "required" on a real play session, this issue is
completed, and 913c–913h are unblocked.

## Implementation Steps

1. Confirm the core's update-time settings and their log line
   (`RecordUpdateTimeDiffInterval`, `MinRecordUpdateTimeDiff` in
   worldserver.conf, as far as the source shows). Turn them on with a
   config patch rather than a hand edit.
2. Write the sampler as a Lua tool under `src/tools/`. It reads the log
   line, the `/proc` thread times and the online counts at a fixed
   interval.
3. Write the verdict as a separate step that reads the samples. Measuring
   and judging are kept apart.
4. Run it once before 157 and once after, so the effect of moving MySQL and
   the authserver off the world machine is on record.

## Open Questions

1. What is the budget? AzerothCore aims for a world update well under
   100 ms per pass. Which number should count as "slow" for this server:
   the average, or the worst pass in a minute?
2. How long must the verdict stay "required" before the gate opens: one
   play session, or several on different days?
3. Should the language model's machine (if the chat bots use one) be
   measured as its own role here?

## Related
- Parent: `issues/913-clustered-worldserver`
- `issues/157-three-machine-deployment.md`: the cheaper fix that is
  measured first
- `issues/913a-client-redirect-handoff.md`: the research spike; not gated
  by this issue
