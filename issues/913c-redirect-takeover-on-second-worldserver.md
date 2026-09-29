# 913c - Redirect Takeover on a Second Worldserver

## Status
- Created: 2026-09-23
- Parent: Issue 913 (clustered-worldserver)
- Phase: 9 (numbered under its parent)
- **Blocked by:** 913b, 913a
- **Blocks:** 913e, 913g

## Overview

913a finds out what the client does when told to reconnect elsewhere. This
issue makes a real worldserver on the far end accept that reconnection and
carry on the player's session. The old worldserver hands the player over
cleanly.

## Current Behavior

- The worldserver answers every new connection with a login challenge and
  accepts only the normal login packet (0x1ED). It drops the redirect proof
  (0x512) and the redirect refusal (0x50E) with its do-nothing handler
  (`Opcodes.cpp`).
- Nothing saves a player and releases them to another server. The only way
  a player leaves a worldserver today is logging out.

## Intended Behavior

- **Receiving side.** The new worldserver accepts 0x512 in place of a normal
  login. It looks up the account by name in the shared auth database and
  checks the digest (SHA1 of account name, session key, and the seed it
  just sent). Then it turns on header scrambling, creates a game session,
  loads the character from the shared characters database, and places them
  on the map they were headed to.
- **Sending side.** The old worldserver saves the character, sends the
  redirect, and releases the character only once the new side confirms. If
  the client refuses (0x50E, carrying the token), nothing moves and the
  player stays where they are.
- The handoff happens at a loading screen: portals, boats, zeppelins,
  instance doors, hearthstones.

## Implementation Steps

1. A source patch (`patches/B0xx-...`) that gives 0x512 a real handler in
   `WorldSocket`, modelled on the normal login path
   (`WorldSocket::HandleAuthSession`). Its account lookup and scrambler
   start are shared rather than copied.
2. A source patch for the sending side: save, send 0x50D, wait for the
   confirmation, then release. The confirmation travels over whatever link
   913e's scheduler uses.
3. A handler for 0x50E that logs the token and cancels the move.
4. A patch description in `docs/patches/client-redirect.md`, and a datapath
   document for the handoff.
5. Tests: the pretend client from 913a (`src/tools/redirect-fake-client.lua`)
   run against a real worldserver instead of the listener.

## Open Questions

1. What confirmation reaches the old server: a message from the new
   server, or the client closing its old connection? This depends on 913a's
   findings.
2. Does the whole login sequence (character list, world entry) need to
   happen again on the new server, or can the client go straight into the
   world?

## Related
- `issues/913a-client-redirect-handoff.md`: the client's side, decoded
- `source-beta/src/server/game/Server/WorldSocket.cpp`
