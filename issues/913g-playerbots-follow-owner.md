# 913g - Playerbots Follow Their Owner Across Nodes

## Status
- Created: 2026-09-23
- Parent: Issue 913 (clustered-worldserver)
- Phase: 9 (numbered under its parent)
- **Blocked by:** 913b, 913c

## Overview

Playerbots have no client connection. Each one is a pretend session inside
the worldserver, attached to its owner. A redirect moves only the human
player, so the bots have to be logged out on the old node and logged in
again on the new one, keeping their place in the party and their orders.

## Current Behavior

- mod-playerbots logs a player's bots in on the same worldserver as the
  owner, and keeps their strategies and orders in memory and in the
  playerbots database.

## Intended Behavior

- When the owner is redirected, the old node saves and logs out the owner's
  bots. The new node logs them in beside the owner at the destination.
- Their strategies and orders survive the move.
- Bots that don't belong to any player (the random bots filling the world)
  belong to the node that owns their map and are never redirected.

## Implementation Steps

1. Find where mod-playerbots logs a bot in and out for its owner, and
   whether it can be triggered from a session that arrived by redirect.
2. Save strategies and orders before the move (the playerbots database may
   already hold them).
3. Log the bots in on the new node when the owner arrives there.

## Open Questions

1. Can mod-playerbots allow a bot owner's session to arrive by redirect
   instead of by normal login? (Carried over from 913a.)

## Related
- `issues/913a-client-redirect-handoff.md`
- `docs/playerbots/`
