# 913a - Client Redirect Handoff

## Status
- Created: 2026-09-23
- Parent: Issue 913 (clustered-worldserver)
- Phase: 9 (numbered under its parent; the work itself is infrastructure)
- Priority: Research spike. It decides whether 913's zone nodes can be reached
  without a relaying front door
- Depends on: nothing in the tree. Not gated by 913b: the experiment is
  already built and costs one login to run
- **Blocks:** 913c

## Overview

The stock 3.3.5a game client knows how to be told "hang up and call this
other address instead." Blizzard used that for its instance servers in 2010.
The client-side code is intact in `Wow.exe` build 12340. On our side the
message is only a name in the opcode table, marked never sent, and the
client's two replies go to the do-nothing handler
(`source-beta/src/server/game/Server/Protocol/Opcodes.cpp`, rows 0x50D,
0x50E, 0x512).

If the handoff works, each machine in the cluster can hold its own players'
connections directly. The front-door machine only has to answer the first
login and later point clients at the right node. It does not have to relay
every packet for the whole session.

## Current Behavior

- The client's redirect code has been read out of the stock executable
  (method and addresses below). The stock file is
  `/mnt/mtwo/games/project-ascension/Wow.exe`, md5
  `45892bdedd0ad70aed4ccd22d9fb5984`, "WoW [Release] Build 12340 (Jun 24
  2010)".
- The client that gets played is `/home/ritz/games/azeroth-core/client/run`,
  whose files are in `/mnt/dile/ritz/games/wotlk/`. Its `Wow.exe` differs from
  stock in 13 bytes: the large-memory flag, the removed signature block, and
  three small patches at other addresses. None of those bytes fall in the
  redirect code (0x632730..0x633440).
- Built and ready, not yet run against the real client:
  - `src/lua-vanilla/redirect-probe.lua` adds an in-game `.redirect` command
    for administrators. It sends 0x50D with a chosen address and port and
    either byte order, and proves it with the account's session key. Written
    as an ALE script instead of a C++ patch, so no recompile is needed.
  - `src/tools/redirect-listener.lua` is the pretend second server: it
    greets, logs, checks the proof, and unscrambles headers.
  - `scripts/test-redirect-listener` checks the listener against
    `src/tools/redirect-fake-client.lua`, which answers the way the
    disassembly says the real client does. It passes.
- The server still has no handler for 0x50E or 0x512. The listener stands in
  for the second server, and a refusal (0x50E) would appear on the original
  connection, which the listener doesn't see; watch it with `tshark` instead.

## What the Client Does (read from Wow.exe 12340)

Method: `objdump -d -M intel` over the executable, then find the immediates
0x50D, 0x50E and 0x512. The client's network object handles five opcodes
itself, before normal packet dispatch, in one function at 0x633330: 0x1DD
(pong), 0x1EC (auth challenge), 0x50D (redirect), 0x50F and 0x511.

### Step 1: the server sends the redirect, opcode 0x50D (handler at 0x632E00)

Payload, in read order:

| Field | Type | Meaning |
|---|---|---|
| address | uint32 (4 bytes) | IPv4 address of the new server. Byte order not yet confirmed by experiment |
| port | uint16 (2 bytes) | TCP port of the new server. Byte order not yet confirmed |
| token | uint32 (4 bytes) | Opaque number. The client stores it and only sends it back in the failure reply |
| proof | 20 bytes | HMAC-SHA1 over the 4 address bytes followed by the 2 port bytes, keyed with the account's 40-byte session key |

The client checks, in this order:

1. If a redirect is already pending (a second connection object exists), or
   an internal "busy" flag is set, it sends back the failure reply 0x50E.
   That reply carries only the uint32 token.
2. It recomputes the HMAC. A mismatch disconnects the client. So only a
   server that knows the session key can move the client, and a stranger on
   the network cannot.
3. If the packet has bytes left over, it disconnects.
4. Otherwise it opens a **second** TCP connection to address:port. The
   original connection stays open while this happens.

### Step 2: the new server greets the client with the normal auth challenge, 0x1EC

This uses the same handler (0x632730) as a first login. The handler looks at
which connection the challenge arrived on:
- on the original connection, it answers with the normal login packet (0x1ED);
- on the redirect connection, it answers with **0x512, redirect proof**.

### Step 3: the client proves itself to the new server, opcode 0x512

| Field | Type | Meaning |
|---|---|---|
| account name | zero-terminated string | Same name as in the normal login |
| anti-flood answer | uint64 (8 bytes) | Worked out from the 32 challenge bytes. Same meaning as the "dos response" in the normal login |
| digest | 20 bytes | SHA1 over (account name, then 40-byte session key, then the 4-byte server seed from the challenge) |

Right after sending it, the client switches that connection's header
scrambling on, keyed with the same session key. That's the same scrambler the
normal login turns on (`_authCrypt.Init` in `WorldSocket.cpp`).

What the client expects from the new server next, and when it drops the
original connection, has **not** been read yet. See Open Questions.

## Intended Behavior

A GM command, and later the cluster scheduler, can move one logged-in player
from this worldserver to another address:port. The new worldserver:

1. accepts the connection and sends the auth challenge;
2. checks the redirect proof against the session key in the shared auth
   database (`acore_auth.account.session_key`);
3. switches on header scrambling, loads the character from the shared
   character database, and puts the player into the world.

The old worldserver saves the player first, and drops its copy only after the
new one has taken over.

## Implementation Steps

1. **Experiment packet (done: `src/lua-vanilla/redirect-probe.lua`).**
   An administrator-only chat command that sends 0x50D to the caller. It
   reloads the session key from the auth database, because the game session
   doesn't keep one after login (`WorldSocket::HandleAuthSession` uses it
   once and drops it). It builds the proof by calling the worldserver's own
   libcrypto through LuaJIT's C bridge. The token is 0xC0FFEE13, so a
   refusal is easy to spot in a capture. It prints the session key on the
   server console for the listener.
2. **Listening post (done: `src/tools/redirect-listener.lua`, tested by
   `scripts/test-redirect-listener`).** Plays the new server's opening move
   (0x1EC, seed 0xDEADBEEF, challenge bytes 00..1F), logs everything that
   comes back to `tmp/shared-memory/redirect-listener.log`, checks the
   digest when given the key, and can answer AUTH_OK. Capture the original
   connection with `tshark` at the same time, so it's visible where the
   client tries to connect and in what order it closes things.
3. **Settle byte order.** Send the redirect with the address written both
   ways (127.0.0.1 and 1.0.0.127), and the port both ways. Watch which one
   the client actually dials.
4. **Settle the tail.** Once 0x512 arrives, find out what the client needs to
   finish: an auth response, a fresh character list, or nothing (it just
   starts talking world packets on the new line). Find out whether it closes
   the old connection by itself or waits for the old server to close it.
   Read 0x632B50, 0x633020 (0x50F) and 0x633250 (0x511) in the binary
   alongside the experiment.
5. Write the findings from steps 3 and 4 into this issue's "What the Client
   Does" section, and into 913c, which builds the real takeover (a second
   worldserver accepting 0x512, and save-then-move on the old side).

## Open Questions

1. ~~Where is a complete 3.3.5a client?~~ Answered 2026-09-23:
   `/home/ritz/games/azeroth-core/client/`, which the owner pointed to.
2. **The tail of the handshake** (step 4 above): what does the client wait
   for after sending 0x512, and who closes the first connection?
3. **Byte order** of address and port in 0x50D.
4. **Is the redirect honoured during a loading screen?** The natural moment
   to move someone is a map change. The client's "busy" flag (offset 0x538 in
   its network object) may refuse the redirect at exactly that moment.
5. **Playerbots ride with their owner.** Bots have no client connection, so
   they cannot be redirected. The new node has to log them in itself. Does
   mod-playerbots allow a bot owner's session to arrive by redirect instead
   of by normal login?

## Related
- Parent: `issues/913-clustered-worldserver`
- `source-beta/src/server/game/Server/Protocol/Opcodes.cpp`: opcode table
  rows 0x50D / 0x50E / 0x512
- `source-beta/src/server/game/Server/WorldSocket.cpp`: normal login path
  (`HandleAuthSession`), session key use, header scrambler start
- `source-beta/src/common/Cryptography/HMAC.h`: HMAC-SHA1 for the proof
- `docs/connection-guide.md`: how players point a client at the server
