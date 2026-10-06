# 808c - Karazhan's Door

## Status
- Created: 2026-10-04
- Phase: 8
- Parent: 808 (Karazhan, an endgame raid in Azeroth)
- Blocked by: None
- Priority: Medium

## Origin

See 808 (the owner's words, 2026-10-04).

## Current Behavior

Stock: the front door needs the Master's Key, from a chain of Outland quests that 155l disables on basic.

## Intended Behavior

A level-60 player enters by air (owner, 2026-10-04: "can we add a flight
path from a high vantage point that can see down onto it? The flight path
creature can glide down, then walk back up with an escort waiting down
below."): a flight master on a high point of Deadwind Pass that looks
down on Karazhan; its flight glides down to the tower's door and lands
the player; the mount then walks back up the slope, and an escort (a
guard or two) waits at the door below. The door's own key requirement is
lifted for the front door.

## Suggested Implementation Steps

1. Find the door's requirement (the key item on the door object, or an access requirement row).
2. The chosen way in, as an install step with an exact revert.

## Open Questions

None beyond the parent's.
