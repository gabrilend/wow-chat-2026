# 916n - Debug Commands and Observability

## Status
- Created: 2026-06-03
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: Low (system runs without this, but debugging it requires this)
- Depends on: everything else being mostly working

## Overview

Operator-facing console commands and lightweight metrics for inspecting
mod-soren-chat's state at runtime. Builds on the rest of the system —
this sub-issue is where you find out what's actually happening when
guidance feels off, when chat seems silent, or when one box is
underperforming.

## Current Behavior

No `.soren` commands exist. The only feedback channel is the
worldserver log, which scrolls quickly. Diagnosing "why isn't Healbot
responding to the LLM?" requires reading source.

## Intended Behavior

After this sub-issue lands, the GM can run console commands:

| Command | Behavior |
|---|---|
| `.soren status` | Per-host health, current queue depth (in/out), worker error rates, recent latency p50/p99 |
| `.soren queue` | Snapshot of pending requests with age and target host |
| `.soren reload` | Hot-reload the Lua scripts (via ALE) |
| `.soren benchmark` | Submit a synthetic round of guidance + chat requests, report timings |
| `.soren persona <botname>` | Show the bot's stored persona archetype and origin story |
| `.soren policy <botname>` | Show the bot's current LLM-set policy (stance, focus, multiplier overrides) |
| `.soren history <botname>` | Show the last N chat lines this bot has emitted |
| `.soren dryrun <botname>` | Build a guidance prompt for the bot's party but log it instead of sending |

Plus periodic logging of aggregate stats every minute when the cluster
is active:

```
[soren-chat] stats: 14 requests/min (4.7/box avg), p50 1.8s, p99 6.2s,
                    0 errors, queue 0/16, 4 chats emitted
```

Steady-state with healthy cluster: one of these lines per minute,
nothing else.

## Metrics Tracked

Per-host (rolling 60-second window):
- Requests submitted
- Requests succeeded
- Requests failed
- Median latency
- p99 latency
- Current health state

Global (rolling 60-second window):
- Total queue depth (current)
- Chat emissions
- Guidance applications
- Validation rejection rate

In memory, no DB persistence. Reset on worldserver restart.

## Implementation Steps

1. Write `lua/99-debug.lua`:
   - Register each `.soren` subcommand via ALE's command-registration
     mechanism (similar to how other modules register chat commands)
   - Each subcommand reads from the relevant in-memory state and
     formats output
2. Add stats tracking to the workers (`03-effil-workers.lua`):
   - Per-worker rolling window of last 60 seconds of request results
   - Per-worker latency histogram (lightweight — just bucket counts)
3. Add stats reporting timer:
   - Once per 60 seconds, print the aggregate stats line
   - Skip if zero requests in window
4. Smoke test each subcommand:
   - `.soren status` after a few minutes of activity
   - `.soren persona Healbot` for a bot with a persona
   - `.soren benchmark` to confirm round-trip works
5. Document the commands in the project's playerbots/commands docs or
   in a new `docs/soren-chat-commands.md`

## Files to Create

- `source-beta/modules/mod-soren-chat/lua/99-debug.lua`
- `docs/soren-chat-commands.md` — reference for operators

## Files to Update

- `source-beta/modules/mod-soren-chat/lua/03-effil-workers.lua` — emit
  stats events that 99-debug.lua can read
- `source-beta/modules/mod-soren-chat/lua/06-response-parse.lua` —
  emit validation-rejection stats
- `source-beta/modules/mod-soren-chat/lua/09-chat-emit.lua` — emit
  chat-emission count
- `docs/table-of-contents.md` — add the new command reference doc

## Open Questions

- Should stats be exposed as a Prometheus/textfile metrics endpoint for
  external monitoring? Probably overkill for the user's deployment.
  Console commands cover the realistic cases.
- `.soren reload` hot-reloads Lua, but effil workers are real OS
  threads — what happens to in-flight requests? Workers should
  complete their current request before picking up new scripts.
  Coordinate with 916e.
- Storing chat history: in-memory only, capped at last N (10?) lines
  per bot. Lost on restart, fine.

## Related

- Parent: [916 - mod-soren-chat](916-mod-soren-chat.md)
- [916f - Cluster health rotation](916f-cluster-health-rotation.md) —
  state that `.soren status` displays
- [916m - Bash health check](916m-bash-health-check.md) — startup-time
  equivalent of one slice of `.soren status`
- All other 916 sub-issues — this one observes them all
