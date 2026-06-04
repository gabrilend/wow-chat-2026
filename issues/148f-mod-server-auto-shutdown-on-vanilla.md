# 148f - Add mod-server-auto-shutdown to Vanilla — DECLINED

## Status
- Created: 2026-06-01
- **Decision: Declined 2026-06-02.** Server restarts are handled
  manually. No supervisor wrapping, no scheduled shutdown
  announcements, no auto-restart hooks. The original suggestion
  came from a generic ops-hygiene reflex, not from a need observed
  on this project. Revisit only if hosting context changes (e.g. a
  publicly-hosted vanilla realm with players who'd benefit from
  predictable maintenance windows).
- Phase: 1 (Foundation — profile model)
- Parent: 148 (vanilla profile)
- Priority: N/A (declined)

## Problem

Long-running worldserver processes accumulate memory pressure, drift
in script state, and occasional zombie threads. The reliable cure is
a periodic restart. Without an in-server scheduler, restarts either
happen ad-hoc (operator manually shuts down, hopefully with warning
to players) or via external cron with no in-game announcement (players
get dumped to the login screen with no warning).

mod-server-auto-shutdown handles the schedule and the announcements
in-process: at configurable intervals it broadcasts countdown messages
to all online players, then shuts the server down gracefully.

## Intended Behavior

- The vanilla worldserver announces an upcoming restart at e.g. T-30min,
  T-15min, T-5min, T-1min, T-30s before the scheduled shutdown.
- At T-0 the server saves state, kicks remaining sessions cleanly,
  and exits.
- An external process supervisor (systemd unit / shell loop / docker
  restart policy — whatever runs the server) brings the worldserver
  back up automatically.
- The schedule is configurable: a daily restart at a low-traffic hour
  is the proposed default. Weekly is also reasonable for a small
  server.

## Module Details

- **Upstream:** `https://github.com/azerothcore/mod-server-auto-shutdown`
  (or current equivalent).
- **Configuration:** restart cron expression (or interval), warning
  schedule, broadcast message text.
- **Compatibility:** standalone module, no known conflicts.

## External Dependencies

This module only handles the in-server side (announcement + clean
shutdown). It does **not** restart the server back up — that's the
process supervisor's job. Either:

- A systemd unit with `Restart=always`, or
- The existing project shell scripts (`scripts/worldserver`) wrapped
  in a `while true; do ...; done` loop, or
- A docker-compose `restart: always` policy if vanilla ever ships
  containerized.

Pick the cheapest one consistent with how the rest of the project
runs servers. As of writing, the project's `scripts/worldserver` runs
the binary directly without auto-restart wrapping — adding one is in
scope for this ticket.

## Implementation Steps

1. Add the module to `PROFILE_MODULES["vanilla"]` in `scripts/install`.
2. Add the upstream URL to `MODULE_REPOS`.
3. Configure the module: pick a restart schedule (suggest daily at
   06:00 local), pick a warning schedule (T-30/15/5/1min, T-30s).
4. Wrap `scripts/worldserver` (vanilla branch) in an auto-restart
   loop, OR introduce a systemd unit alongside the existing scripts,
   OR document the chosen mechanism in `docs/operations/vanilla.md`.
5. Rebuild vanilla via `scripts/install --profile vanilla`.
6. Test: temporarily configure a 5-minute-from-now shutdown, log a
   character in, observe the countdown announcements, confirm clean
   shutdown at T-0, confirm the supervisor brings the worldserver
   back up.

## Open Questions

- Daily vs weekly restart cadence? Daily is safer (less drift
  accumulation) but more disruptive. Weekly is fine for a small
  server with predictable usage windows.
- Should the announcements be customized per profile (vanilla has a
  different ruleset and a different community than release/beta will
  have), or kept generic?
- Does the module's "graceful shutdown" actually invoke the right
  AzerothCore shutdown path (which saves character state to DB)?
  Verify during testing — a non-graceful shutdown can lose ~5-30
  seconds of player state.
