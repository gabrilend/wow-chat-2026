# 155w - No Mounts in Towns

## Status
- Created: 2026-09-27
- Phase: 1
- Parent: 155
- Blocked by: None
- Priority: Medium

## Decision, 2026-09-27 (Ritz): withdrawn

"maybe mounts should be allowed in town actually, but they have to walk
when mounted? No restrictions on player behavior." The rule below is
withdrawn: players ride where the stock game lets them. Buddies riding in
town walk their mounts (617e4). The code built for this rule is removed.

## Current Behavior

**Withdrawn 2026-09-27; nothing of it is in the code.** Stock: any
character with a mount may ride it anywhere outdoors, towns and capitals
included, and players keep that ("No restrictions on player behavior").
Buddies riding in town walk their mounts (617e4).

The rule was built and removed the same day: a dismount on entering a town
(the area-change event) and a refusal of mount spells cast in one (the
server's cast check, `AllSpellScript::OnSpellCheckCast`, which lets a
module set a cast's result without a server patch), both in
`src/cpp-basic/basic_rules.cpp`. Kept here as the way to do it if it is
ever wanted again.

## Intended Behavior

Owner, 2026-09-27, asked whether buddies may ride in towns: "nah, even for
players." On basic nobody rides inside a town or city: players and bots
alike walk or run on foot there.

- A town or city is an area flagged town (0x00200000), capital
  (0x00000100) or capital subzone (0x00000008) in the server's area data
  (the same rule the buddies use, 617e4).
- Entering one dismounts a mounted character, with a line saying why.
- A mount spell cast inside one is refused, with the same line.
- Flight paths are unaffected (the taxi mount is not a player mount).

## Suggested Implementation Steps

1. A module script (basic's C++ rules, `src/cpp-basic/`, or mod-buddies'
   neighbour) on the area-change event: dismount in a town.
2. A spell check before a cast starts: a spell that applies the mounted
   aura is refused in a town (find the server's hook that can refuse a
   cast; otherwise a small patch).
3. Tests: the config/profile gates as applicable; in game, ride into
   Goldshire (dismounted), try to mount there (refused).

## Related Issues

- **155** parent; **617e4** buddies in towns
