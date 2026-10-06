# 173b9 - Display and Objectives

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store), the interface (173c onward)
- Priority: Low

## Origin

See 173b (the owner's words, 2026-10-06).

## Current Behavior

Not built. The client has no interface.

## Intended Behavior

The original's Display and Objectives panels (reference page, *Interface*
→ *Display*, *Objectives*):

**Display**
- *Rotate Minimap* (`rotateMinimap`), *Show Clock* (`showClock`). With the
  minimap.
- *Screen Edge Flash* (`screenEdgeFlash`, red edges at low health), *Play
  Aggro Sounds* (`threatPlaySounds`), *Show Aggro Percentages*
  (`threatShowNumeric`), and when the threat warning shows
  (`threatWarning`: Always, In Instance, In Party, Never). With combat.
- *World PvP objectives* on screen (`displayWorldPVPObjectives`: Always,
  Dynamic, Never). With world PvP, if ever.
- *Detailed Loot Information* (`showLootSpam`), *Show Free Bag Space*
  (`displayFreeBagSlots`), *Show Item Level* (`showItemLevel`). With bags,
  chat and tooltips.
- *Colorblind Mode* (`colorblindMode`): item quality and similar colours
  written as words too. Every coloured element is built with it, from the
  start.
- *Cinematic Subtitles* (`movieSubtitle`). With cinematics, if ever.

**Objectives**
- *Instant Quest Text* (`questFadingDisable`), *Automatic Quest Tracking*
  (`autoQuestWatch`), *Automatic Quest Progress Updates*
  (`autoQuestProgress`), *Wider Objectives Tracker* (`watchFrameWidth`).
  With quests.
- *Quest Difficulty Color* on the map (`mapQuestDifficulty`), *Movable
  World Map* (`advancedWorldMap`). With the world map.

## Suggested Implementation Steps

1. Each setting in the same change as its feature.

## Open Questions

None yet.
