# 1100e - The Realm Locked to Game Masters While Testing

## Status
- Created: 2026-10-28
- Phase: 1 (the build and its tests)
- Parent: 1100 (tests)
- Related: 617e13, 617e14d (tests that log in a test clan), 617's question 12
- Priority: Medium
- State: built 2026-10-28; `status` and `--dry-run` tried, the lock itself
  not yet used

## Origin

The owner, 2026-10-28, on tests logging in characters of their own: "Only
on a separate testing server. Not beta. We can use basic for now, they're
all testing servers right now. But, we should not allow players to connect
unless they're a GM account when we're doing these tests."

## Current Behavior

**Built 2026-10-28**: `scripts/test-lock on|off|status [--profile P]
[--dry-run]`. Each verb:
- `on`: only game-master accounts may log in to the profile's realm. Two
  places, so the lock holds now and after a restart: the realm list's
  lowest allowed account level (`acore_auth.realmlist.allowedSecurityLevel`,
  read by the world server at its start) set to 1, and, when the server
  is running, the console command `server plimit moderator`, sent by
  `scripts/gm-command`, which also logs out the accounts below it.
- `off`: both set back to everyone (0, `server plimit reset`).
- `status`: what the realm list says, and whether the server answers.
- Refuses beta (the owner: "Not beta"), naming why.

## Intended Behavior

As the owner's words: a test with characters of its own runs with the
realm closed to everyone but game masters, and opens it again after.

## Suggested Implementation Steps

1. The tool (done).
2. Tests that log in a test clan call `test-lock on` first and `off`
   after (none exists yet).

## Open Questions

- None.
