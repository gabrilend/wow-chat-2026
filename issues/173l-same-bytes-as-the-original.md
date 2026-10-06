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

## Current Behavior

Not built. The custom client has no network layer; the original client
talks to the server directly.

## Intended Behavior

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

1. The input mirror needs read access to the input devices (the `input`
   group). Is that acceptable on this machine?
2. Should the tap also become the place the custom client connects
   through later (one program for logging, comparing and debugging)?
