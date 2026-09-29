# 913f - Cross-Node Social Relay

## Status
- Created: 2026-09-23
- Parent: Issue 913 (clustered-worldserver)
- Phase: 9 (numbered under its parent)
- **Blocked by:** 913b, 913e

## Overview

Whispers, chat channels, guild chat, the who list, friend lists, and party
and raid membership all assume that everyone is inside one process. Once
players are spread across machines, a whisper to someone in Kalimdor sent
from Eastern Kingdoms has to cross between worldservers. So does a party
whose members are on different continents.

## Current Behavior

- Social systems look players up in the worldserver's own memory
  (`ObjectAccessor`, `ChannelMgr`, `GroupMgr`, `GuildMgr`). A player on
  another machine would look offline.

## Intended Behavior

- Every node keeps a directory of which node each online player is on,
  fed by the scheduler (913e).
- Messages addressed to a player on another node are forwarded to that
  node and delivered there as if they had been sent locally.
- Party and raid state is owned by the node of the party leader. Members
  on other nodes receive updates about each other.

## Implementation Steps

1. Choose the transport between nodes. 913 suggests Redis publish/subscribe
   or plain TCP; decide from 913b's measured network timings.
2. Relay whispers and channels first, since they are stateless.
3. Then guild chat and the who list.
4. Groups last, because they carry state (loot rules, leader, instance
   binding).

## Open Questions

1. How do the chat bots (916, 917) see players on other nodes?

## Related
- `issues/913-clustered-worldserver`: "Inter-Node Communication"
