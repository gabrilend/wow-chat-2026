# 910d - Speech by Mail

## Status
- Created: 2026-10-18
- Phase: 9
- Parent: 910 (wandering narrator system)
- Blocked by: 910a (narrators read aloud), 1004 (rmail in-game bridge)
- Priority: Low

## Origin

See 910, "TTS Integration (via rmail)" and step 12; and 909's question 4,
which asked to move the forwarding here: what a player heard a narrator
say in person, and only that, sent to their rmail.

## Current Behavior

Not built.

## Intended Behavior

- A player who subscribes hears nothing new: what a narrator says while
  they stand within hearing is collected and sent to their rmail inbox,
  so they keep what they already heard. Nothing is sent for speech they
  were not near.
- Spoken audio (text to speech with the narrator's rhythm) later.

## Suggested Implementation Steps

1. Wait for 1004's bridge.
2. Collect, per subscribed player, what narrators said within their
   hearing (910a knows who is in hearing on every line).
3. Send on the bridge's schedule.

## Open Questions

1. Subscribe how: a whisper to the narrator ("send me this"), or a setting?
