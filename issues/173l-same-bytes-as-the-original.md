# 173l - Same Bytes as the Original (a twin-client check)

## Status
- Created: 2026-10-05
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173e (what the server checks), the network layer (part of 173e)
- Priority: High (the custom client's proof)

## Origin

Verbatim, 2026-10-05:

> Can we make a plan for the custom client to listen to input even when
> the proprietary client is being used? The idea is, we run both at once,
> walk around do stuff maybe fight monsters complete quests whatever, and
> if they both emit the exact same bytes to the server, then we are in
> the clear.

Simplified by the owner, 2026-10-05:

> Why don't we just... catch all the packets that the custom client are
> sending with the twinned inputs, and compare at the end? We should also
> keep track of what packets the proprietary client sends, and what packets
> the server receives, to ensure there's no difference between the three.
> I think just a small utility (or three) that intercepts the packets,
> records them, and passes them along, with a compare step at the end, is
> sufficient.

## Current Behavior

Not built. The custom client has no network layer; the original client
talks to the server directly.

## Intended Behavior

**Record now, compare at the end.** Three records of one play session,
compared afterwards by one small program:

1. **What the original client sent**: a tap (a small relay between the
   original client and the server) passes every packet along unchanged and
   writes a copy to a record.
2. **What the server received**: the server's own packet log
   (`PacketLogFile` in worldserver.conf, empty today; the core writes
   every packet in and out to it when set).
3. **What the custom client would have sent**: the custom client, in a
   shadow mode, given the owner's twinned inputs (recorded from the input
   devices while playing) and the server's replies (from the tap's record),
   writes what it would send to a third record instead of a server.
   Because the inputs and replies are recorded, this can run live beside
   the original or be replayed afterwards from the records; either way
   its output is only compared at the end.

**Built for replays too** (owner, 2026-10-05: "this system will be
useful if we ever wanna build a, I dunno, 'replay system' or something,
so build it with that in mind maybe."): the records are a session's
complete story, so they are kept in one documented, versioned file format
(each packet with its direction, its time since the session began, and
its plain bytes; the input events beside them), written so a later
program can play a session back: the custom client fed a record's server
packets draws the session as it happened, from any camera. The recorders
write that format from the start; the comparer is its first reader.

The compare step lines the three up packet by packet: original vs server
(proves the tap is transparent), original vs custom (proves the custom
client). The rest of this section is the detail of what each record
needs.

The earlier (live comparer) design, kept for the detail it holds:

The owner plays the original client as usual. Beside it, the custom
client runs as a **shadow**: it sees exactly what the original client
sees from the server and exactly what the owner presses, decides what it
would send, and a comparer sets its packets beside the original's. A
session where every packet matches is a pass; any difference is shown
with the packets side by side and the moment it happened.

Why a shadow and not two clients on the server: one account has one
session; two connected clients would get different packets (two
characters, two positions), so their bytes could never match. A shadow
gets the very same server packets, so the only difference left is the
client.

### The pieces

1. **The tap** (a small proxy between the original client and the
   server, on this machine): it relays every packet both ways unchanged,
   and copies each one, decrypted, to the shadow and the comparer. The
   world connection's packet headers are encrypted with a key from the
   login (the session key); the project owns the server, so the tap
   reads the session key from the auth database for the account
   (`account.session_key`) instead of breaking anything. The original
   client is pointed at the tap by its realmlist; the server sees the
   tap's connection as the client's.
2. **The input mirror**: the owner's keyboard and mouse, read from the
   operating system's input devices (Linux evdev, read-only) while the
   original client has focus, timestamped, and fed to the shadow as if
   pressed in it. The camera matters for movement (right-drag turns her),
   so mouse motion is mirrored too.
3. **The shadow**: the custom client in a mode with no server
   connection of its own: server packets arrive from the tap, inputs
   from the mirror, and every packet it would send goes to the comparer
   instead.
4. **The comparer**: pairs each original packet with the shadow's of the
   same kind in order, and compares field by field after decoding (the
   encrypted bytes differ by design; the comparison is of the plain
   packets). Fields that can't match by nature are named and compared by
   rule rather than by byte:
   - the client's own clock in movement packets (milliseconds since the
     program started): compared as differences between packets, which
     must match within a frame;
   - anything random the original sends (none known in 3.3.5a world
     traffic; the comparer lists any field that differs every time, to
     find them).
   Every other byte must be equal. A report: packets compared, equal,
   different, with the first difference of each kind shown in full.

### What "the exact same bytes" can and can't mean

Movement packets carry positions the client computed from its own frame
times, and the two programs draw frames at different moments. The same
key held for the same time gives the same distance only if both step
movement the same way; the shadow therefore steps its movement on the
original's packet times (taken from the tap), not its own frames, so
positions are comparable to the last bit. Where they still differ, that
is a real difference in the mover (speed, slope, fall), which is what the
check is for.

## Suggested Implementation Steps

1. The tap: relay and log, both directions, auth then world; read the
   session key; decrypt headers; packet log in the RAM tier.
2. A packet decoder for the opcodes the client sends (movement first,
   then casts, chat, interact, quests, loot), both as a library for the
   shadow and as the comparer's eyes.
3. The input mirror (evdev, read-only; needs read access to
   `/dev/input`).
4. The shadow mode in the custom client.
5. The comparer and its report; first target: ten minutes of walking,
   jumping and turning with no difference.

## Open Questions

1. (Answered 2026-10-05) The owner is in the `input` group (checked:
   `id` lists group 25, input), so the input recorder can read the devices
   with no change; group membership counts from the login that started
   the session.
2. Should the tap also become the place the custom client connects
   through later (one program for logging, comparing and debugging)?
