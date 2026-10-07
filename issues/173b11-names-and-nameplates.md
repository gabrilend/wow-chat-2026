# 173b11 - Names and Nameplates

*Continues in the W client (`/mnt/mtwo/games/azeroth-core/custom-client/`), since the move on 2026-10-07 (173v): issue 1001. This issue stays as the record of how the client began; its paths are as they were then.*

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

One "kind" test (friend / enemy, player / pet / guardian / totem /
critter) answers all 21 switches. It uses only what any 3.3.5a server
sends about a unit, nothing particular to this project's servers.

## Suggested Implementation Steps

1. The kind test, tested against a few creature and player records.
2. Names, then nameplates, each switch read live.

## Decisions

- **No buddy switches in the client** (owner, 2026-10-06: "that's a great
  idea. But I'm not sure how integrated we want our custom changes to be,
  so try and keep the client separate from the various changes we've made
  to the server profiles. We want to make something that anyone can use
  to play World of Warcraft private servers."). Buddies are players and
  party members as far as the client knows, and the original's switches
  cover them. If buddy-specific switches are ever built, they would come
  from a separate, optional layer (see 173, *Who the client is for*), not
  from this panel.

## Open Questions

None.
