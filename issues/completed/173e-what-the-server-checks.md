# 173e - What the Server Checks (the client's pass mark)

*Continues in the W client (`/mnt/kaun/custom-client/`), since the move on 2026-10-07 (173v): Phase 5 (networking) and 801. This issue stays as the record of how the client began; its paths are as they were then.*

## Status
- Created: 2026-10-05
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173a (movement), a network layer not yet planned (login, world packets)
- Priority: High (it defines "done" for movement)

## Origin

Verbatim, 2026-10-05:

> if the server accepts the movement packs without correcting, then we
> have a client that handles movement correctly. We're trying to render
> the world exactly as it's expected to render in the proprietary client.

> Design your solution to fit the demands of the test. Look at what the
> server (Warden) guards against from cheaters, and then make sure than a
> normal, unmodded client can meet those demands at all times.

## Current Behavior

Not built: the custom client has no network connection yet. What the
server checks was read from the source on 2026-10-05 (upstream
`MovementHandler.cpp`, `Warden/`, and basic's `worldserver.conf`):

**Movement (the core's own checks).** The server trusts the position a
client reports; it does not re-simulate walking, slopes or gravity. It:
- kicks a client reporting a position outside the map's valid
  coordinates, or one whose grid cell is invalid;
- drops a client's movement packets while the server itself is moving
  that character (a spline: a flight path, a knockback being played,
  a charge), and while the character carries "can't move";
- answers forced speed changes (a slow, a sprint, a mount) with an
  acknowledgement the client must send back carrying the new speed: a
  speed *lower* than the server's is corrected, a speed *higher* kicks
  the client ("Incorrect speed");
- takes teleports, roots, unroots, knockbacks, water walking, feather
  fall and hover as orders the client must acknowledge (the *_ACK
  opcodes), skipping movement packets sent before a teleport's ack;
- computes fall damage from the fall time and height the client
  reports on landing;
- calls anti-cheat hooks (double jump, movement sanity) that do nothing
  unless an anti-cheat module is installed. None is (`modules/`: ale,
  aoe-loot, buddies, fireworks-on-level, playerbots, solo-lfg).

**Warden** (on: `Warden.Enabled = 1`). After login the server sends a
small program (a "module", Windows code, encrypted with a key from the
session) that the original client loads and runs. Every
`Warden.ClientCheckHoldOff` (30) seconds it sends checks: memory checks
(read N bytes of the client program at an address, compare a hash;
`NumMemChecks = 3`), Lua checks (is this function the original one;
`NumLuaChecks = 1`), and others (page, module, driver, timing checks;
`NumOtherChecks = 7`). A failed check is only logged here
(`ClientCheckFailAction = 0`); a client that never answers is kicked
after `ClientResponseDelay` (600) seconds.

So, for an unmodded client the demands are: report only valid
positions, acknowledge every server order with exactly its values,
respect the moments the server is moving it, report falls honestly, and
answer Warden as the original client would.

## Intended Behavior

The custom client meets every one of those demands at all times, so a
server running stock checks (and any stricter anti-cheat module the
project might add) never corrects, kicks or flags it:

- **Movement acks**: every forced change (speed, root, teleport,
  knockback, water walk, feather fall, hover) acknowledged with the
  server's own values, then obeyed.
- **No movement while the server moves her**: while a spline plays, the
  client draws the server's path and sends nothing.
- **Honest falls**: fall time measured as the original client does (from
  leaving the ground to landing), so the server's fall damage matches.
- **Warden answered as the original client answers**: the module request
  and each check answered from the original client's own files (the
  program's bytes read from `Wow.exe` on disk for memory checks, the
  original interface functions for Lua checks), so answers match what an
  unmodded `Wow.exe` gives. Running the server's Windows module is not
  needed if each check type can be answered from its definition.
- **A test harness**: a log of every correction, speed-ack mismatch and
  Warden failure the server records for the custom client's account,
  read after a session; the pass mark is an empty log.

## Suggested Implementation Steps

1. The network layer (its own issue): authentication, the world
   connection, the packet header encryption, character list, enter world.
2. Movement packets: send what the mover does as the original client's
   opcodes (start/stop forward, strafe, turn, jump, fall land,
   heartbeat), with its flags and fall time.
3. Every *_ACK the server can ask for, each with a test that replays a
   recorded server order and checks the reply byte for byte.
4. Warden: read each check type's definition in `Warden/WardenWin.cpp`
   and `WardenCheckMgr`, answer memory checks from `Wow.exe`'s bytes on
   disk, Lua checks from the original interface; log any check the
   client can't answer.
5. The harness: a server log filter for the test account.

## Open Questions

1. (Answered 2026-10-05) Slopes: "sounds like we need different slopes
   for players and monsters? The monsters probably have a different slope
   rule so they can follow players no matter what. Blizzard was very
   concerned about people exploiting the game mechanics because people
   used to do that stuff in Everquest." So two rules: monsters path on
   the navigation mesh's 60 degrees (steeper than players may climb, so
   a player can't escape up a slope a monster can't follow); the player
   in the custom client climbs by the original client's own limit, to be
   measured in the original client and then used in place of the 60 the
   custom client reads today (173a).
2. (Answered 2026-10-07) Turn Warden off for custom-client accounts, or
   always pass it? Always pass it: "people trust Warden because it catches
   cheaters which ruin the game for others. So we should build
   compatibility for it into our system because otherwise it's less
   trustworthy." No server is asked to make an exception for the custom
   client.
