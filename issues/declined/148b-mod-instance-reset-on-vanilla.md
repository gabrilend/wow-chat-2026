# 148b - Add mod-instance-reset to Vanilla — DECLINED

## Status
- Created: 2026-06-01
- **Decision: Declined 2026-06-02.** Vanilla ships with the default
  WotLK 5-instances-per-hour cap. The Uldaman re-run concern was
  hypothetical; revisit only if play-testing produces evidence that
  the cap actually blocks the loop in practice.
- Phase: 1 (Foundation — profile model)
- Parent: 148 (vanilla profile)
- Priority: N/A (declined)

## Why Recorded

Ticket retained as a record of the consideration. Future sessions
that wonder "should vanilla have instance-reset?" will find this
ticket first and know the answer is "no, not unless something
changed." Re-open by editing the decision line above if the
situation changes.

## Problem

WotLK's stock 5-instances-per-hour cap was written for a server with
60+ dungeons, dozens of raids, and a months-long progression curve. On
vanilla — level cap 40, Uldaman as the endgame dungeon — there is
effectively one piece of endgame content. Hitting the 5/hour cap
during a serious Uldaman session takes about 90 minutes of focused
play and shuts the player out of their primary activity for the rest
of the hour.

mod-instance-reset removes or relaxes that cap so players (and their
playerbot groups) can run dungeons on demand.

## Intended Behavior

A vanilla player can re-enter Uldaman without waiting on the hourly
cap. Either the cap is removed entirely, or raised to a number large
enough that normal play never reaches it (e.g. 30/hour).

The bot group's lockout behaviour follows whatever the human leader
sees — if the leader can reset, the bots reset with them.

## Module Details

- **Upstream:** `https://github.com/azerothcore/mod-instance-reset` (or
  a maintained fork if upstream is stale; verify at install time).
- **Configuration:** the module typically exposes a configurable cap
  rather than removing it outright. Pick a high number (suggest 30)
  rather than disabling the system, so the underlying anti-spam
  guardrails still exist.
- **Compatibility:** standalone module; no known conflicts with
  mod-playerbots, mod-solo-lfg, mod-aoe-loot, or mod-fireworks-on-level.

## Implementation Steps

1. Add `mod-instance-reset` to `PROFILE_MODULES["vanilla"]` in
   `scripts/install`.
2. Add the upstream URL to `MODULE_REPOS`.
3. Drop the module's config file into vanilla's `etc/modules/` overlay,
   set the cap to 30/hour (or the agreed value).
4. Rebuild vanilla via `scripts/install --profile vanilla`.
5. In-game test: run Uldaman six times in succession. Confirm the
   sixth run starts cleanly with no hourly-cap rejection.
6. Confirm playerbots in the party follow the reset and do not get
   locked out.

## Open Questions

- Should the cap be config-driven so we can tune it without rebuilds,
  or is the module's compiled-in default acceptable?
- Does this module also handle raid-lockout resets, or only 5-mans?
  (Likely 5-mans only; verify if any 40-cap-relevant raids exist.)
