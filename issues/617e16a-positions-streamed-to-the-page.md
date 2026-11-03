# 617e16a - Positions Streamed From the World Server to the Page

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617e16
- Related: 617e14a (the world recorder, a file of positions; this is the
  live way)
- Priority: High
- State: built 2026-10-28, syntax-checked; not yet compiled or run

## Origin

The owner, 2026-10-28: "Can we build a patch for the world server that
lets it stream it's player positions to the websitepage?"

## Current Behavior

**Built 2026-10-28** (`buddies_map_stream.cpp`, in the buddy module, which
already knows who is whose buddy):
- Once a second, on the world's own thread, the server takes a snapshot
  of every character in the world: number, name, kind (player, buddy,
  bot), a buddy's owner, map, zone, sub-zone, position, facing, fighting,
  dead. As JSON, kept in memory.
- A small web listener on its own thread answers
  `http://127.0.0.1:8097/positions` with the latest snapshot, and nothing
  else. It listens on this computer only (127.0.0.1), and answers with the
  header that lets a page opened from a file read it.
- The port is `Buddies.MapStream.Port` in `worldserver.conf` (8097 when
  the line is absent; 0 turns the stream off). The listener stops with
  the server.
- The sandbox page (`docs/HTML/fish-sandbox.html`) has a "Live players"
  switch: on, it asks for the snapshot every second and draws everyone in
  the world view and the zone view (people white, buddies in their
  owner's colour, other bots grey), with tails.

## Intended Behavior

As above: the page shows where everyone in the game is, live, with no
other server running.

## Suggested Implementation Steps

1. The snapshot and the listener (done).
2. The page's live layer (done).
3. Seen working after the owner's compile.

## Open Questions

- None.
