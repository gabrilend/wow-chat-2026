# 913h - Global Service Coherence

## Status
- Created: 2026-09-23
- Parent: Issue 913 (clustered-worldserver)
- Phase: 9 (numbered under its parent)
- **Blocked by:** 913b, 913e

## Overview

Some game state is saved in the database but also kept in the
worldserver's memory: mail, the auction house, instance lockouts, arena
teams, and the Lua scripts' own tables (for example the ambush timers). Two
worldservers would each keep their own copy in memory, and the copies would
drift apart. This issue gives each of those one owner.

## Current Behavior

- The auction house, mail, instance saves and guild banks load into memory
  at startup and write back to the database, assuming nothing else
  touches those rows.
- Lua state lives in the Lua engine's tables and is lost when a player
  changes worldserver.

## Intended Behavior

- Each shared service is owned by exactly one node (913 suggests the
  scheduler machine). Other nodes forward requests to the owner.
- Per-player Lua state that must survive a move is saved to the characters
  database before the redirect and read back on arrival.

## Implementation Steps

1. List every service that caches database rows, with its owner class and
   the tables behind it.
2. Pick an owner for each, and decide whether the other nodes forward
   requests or only read.
3. A save and restore step for per-player Lua state, run as part of the
   913c handoff.

## Open Questions

1. Which Lua state is per-player and must travel with the player, and which
   is per-map and stays with the map?

## Related
- `issues/913-clustered-worldserver`: "Global Services"
