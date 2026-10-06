# 173b11 - Names and Nameplates

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store), 173j (other models in the
  world), the client talking to the server
- Priority: Low

## Origin

See 173b (the owner's words, 2026-10-06).

## Current Behavior

Not built. Only the night elf is drawn, with no name over her.

## Intended Behavior

The original's Names panel (reference page, *Interface* → *Names*), built
when other characters are drawn:

- **Names over heads**, on/off by who: my own (`UnitNameOwn`), NPCs
  (`UnitNameNPC`), critters and vanity pets, guild names, titles; friendly
  players, their pets, guardians and totems; enemy players, their pets,
  guardians and totems (`UnitName...`, 13 switches in all).
- **Nameplates** (the health bars over heads), on/off by who: friendly
  units, pets, guardians, totems; enemy units, pets, guardians, totems
  (`nameplateShow...`, 8 switches).
- *Allow Overlapping Unit Nameplates* (`nameplateAllowOverlap`): off
  stacks them so they don't cover each other.

In this project nearly every character near the player is a buddy or a
monster, so the switches decide most of what floats over the world. One
"kind" test (friend / enemy, player / pet / guardian / totem / critter)
answers all 21 switches.

## Suggested Implementation Steps

1. The kind test, tested against a few creature and player records.
2. Names, then nameplates, each switch read live.

## Open Questions

1. **A buddy kind?** Should buddies have their own switches (names and
   nameplates for the player's buddies, separate from other players)? The
   original has no such kind; this project's world is mostly buddies.
