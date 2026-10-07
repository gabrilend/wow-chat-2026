# 173b13 - Status Text and Unit Frames

*Continues in the W client (`/mnt/mtwo/games/azeroth-core/custom-client/`), since the move on 2026-10-07 (173v): issue 1001. This issue stays as the record of how the client began; its paths are as they were then.*

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store), unit frames in the client (not
  yet an issue)
- Related: 616 (public healer frames), 617s7 (box select)
- Priority: Low

## Origin

See 173b (the owner's words, 2026-10-06).

## Current Behavior

Not built. The client has no health bars or portraits.

## Intended Behavior

The original's Status Text and UnitFrames panels (reference page,
*Interface* → *Status Text*, *UnitFrames*), built with the frames:

**Status Text** (numbers on the bars): the experience bar (`xpBarText`),
the player's, pet's, party's and target's health and mana bars
(`playerStatusText` ...), and *Display Percentages*
(`statusTextPercentage`): percent instead of numbers.

**UnitFrames**
- Party: *background* behind the frames (`showPartyBackground`), *party
  members' pets* (`showPartyPets`), *hide party frames in a raid*
  (`hidePartyInRaid`).
- Raid: *range* fading (`showRaidRange`).
- Arena enemy frames, their cast bars and pets.
- *Larger Focus Frame* (`fullSizeFocusFrame`).

A player's buddies are party members, so these settings decide how the
buddies' frames look.

## Suggested Implementation Steps

1. With the frames.

## Open Questions

None yet.
