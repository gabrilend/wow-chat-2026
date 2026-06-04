# 916f - Cluster Health Tracking and Rotation

## Status
- Created: 2026-06-03
- Parent: Issue 916 (mod-soren-chat)
- Phase: 3
- Priority: Medium (system works without this, but degrades badly when a box dies)
- Depends on: 916e (worker pool exists)

## Overview

Extend the worker pool with per-host health state. A worker whose HTTP
calls fail repeatedly is taken out of rotation; periodic re-probes let
it rejoin when the host recovers. The system degrades gracefully —
losing one box drops to 2/3 throughput, not zero. Losing two drops to
1/3. Losing all three falls back to default playerbots behavior with no
LLM input.

## Current Behavior

After 916e, three workers run with no awareness of each other or of
their host's health. A box that's down causes its worker's requests to
timeout repeatedly, wasting time and producing dropped requests.

## Intended Behavior

After this sub-issue lands:

- Each worker tracks consecutive failure count and recent error rate
- After N consecutive failures (default 3), the worker enters a
  "quarantined" state and stops accepting new requests
- A background re-probe runs every M seconds (default 60) calling the
  Ollama `/api/tags` endpoint with a short timeout; success demotes
  the worker back to "healthy"
- The submit() API skips quarantined workers when dispatching
- When all workers are quarantined, submit() returns nil + "no healthy
  workers" so the caller can fall back to default playerbots behavior
- A small log line emits on health state transitions (healthy →
  quarantined → healthy), nothing on steady state

## Implementation Steps

1. Refactor the inbox structure: replace the single shared inbox with
   one inbox per worker plus a router function `pick_worker_for(req)`
   that selects a healthy worker.
2. Add health state to each worker (effil channels can carry this too —
   each worker pushes a heartbeat to a `health` channel periodically;
   the main thread reads).
3. Router logic in `pick_worker_for(req)`: round-robin among healthy
   workers, skip quarantined.
4. Worker loop modification: on N consecutive failures, set self to
   quarantined (via shared state or by emitting a health event). Stay
   alive but only accept re-probe requests.
5. Background re-probe: a separate small effil thread (or piggy-back on
   one of the worker threads) that wakes every 60s, sends a `/api/tags`
   GET to each quarantined host, marks healthy on 200.
6. Smoke test:
   - Kill ollama on box2 mid-run, verify next request routes to box1 or
     box3
   - Confirm "quarantined" log line appears
   - Restart ollama on box2, wait 60-120s, verify it rejoins
   - Confirm "healthy" log line appears
7. Pathological test: kill all three boxes, verify submit() returns nil
   + error, verify caller falls back gracefully

## Configuration

In `01-config.lua`:

```lua
M.host_failure_threshold     = 3       -- consecutive failures → quarantine
M.host_reprobe_seconds       = 60      -- re-probe cadence
M.host_reprobe_timeout_ms    = 2000    -- probe timeout
M.health_log_state_changes   = true    -- log healthy↔quarantined transitions
```

## Files to Update

- `source-beta/modules/mod-soren-chat/lua/03-effil-workers.lua` — add
  the health tracking and router logic
- `source-beta/modules/mod-soren-chat/lua/01-config.lua` — add the
  health-related knobs

## Files to Create

- (optional) `source-beta/modules/mod-soren-chat/lua/03b-health-prober.lua`
  if the re-probe logic gets large enough to warrant its own file

## Open Questions

- Per-worker inbox vs single shared inbox + per-request routing: the
  shared inbox model from 916e doesn't let us steer requests away from
  a specific worker. This sub-issue probably has to convert to per-
  worker inboxes. Decide during implementation.
- Should the failure threshold be consecutive failures or a sliding-
  window error rate? Consecutive is simpler and adequate for the
  failure modes we expect (network partition, ollama daemon crash).
- What counts as a "failure"? Timeout, non-200 HTTP, JSON parse error,
  ollama-reported model error. Probably all of them — the worker
  doesn't get a useful response either way.

## Related

- Parent: [916 - mod-soren-chat](916-mod-soren-chat.md)
- [916e - Worker pool](916e-effil-worker-pool.md) — extends this
- [916m - Bash health check](916m-bash-health-check.md) — pre-flight
  version of the same check; runs once at worldserver startup
- [916n - Debug commands](916n-debug-commands-observability.md) — adds
  `.soren status` to view current health state
