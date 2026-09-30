# 164 - Creatures One Player Cannot Select, or See

## Status
- Created: 2026-09-29
- Phase: 1 (server infrastructure)
- First user: 718 (a death knight who owes a soul can select no one in
  Acherus but Sargobras)

## Origin

Verbatim, the owner, 2026-09-29, of the Lich King in Acherus:

> he should be untargetable unless you've given a soul. In-fact, it'd be
> great if all the NPCs were. Do we have tech to make a creature
> untargetable to a specific other player? If not, then we should build it,
> because that's useful.

## Current Behavior

**Extended 2026-09-29, the seeing half** (owner: "okay let's build that
mechanism then. We will need it for the neus anyway."): one creature
*spawn*, by its spawn number, can be hidden from one player alone
(`PerPlayerCreatures::SetHidden`; the see-check in `Object.cpp`'s
`CanSeeOrDetect`, right after its "can never see" test; Lua
`player:SetCreatureSpawnHidden(spawnId, hidden)`). By spawn number so a
script can set it at login before the creature loads. GM mode still sees.
The code is now named `PerPlayerCreatures` (header `PerPlayerCreatures.h`).
First use: Sargobras in the Heart of Acherus goes up in flame after a
soul trade and is then gone for that death knight only, at later logins
too. Not yet compiled or tried in game.

**Built 2026-09-29, not yet compiled or tried in game:** `patches/B040-per-player-unselectable.sh`
(core: the rule, the per-viewer bit, the refused interaction, the rule
forgotten when the player object goes) and `patches/B041-ale-per-player-unselectable.sh`
(Lua: `player:SetUnselectableCreatures(entries, allExcept)`,
`player:ClearUnselectableCreatures()`), registered for basic. Both pass
the round-trip test. 718 uses it: an owing death knight is held to "all
except Sargobras" at first login and every login, released at the trade.
Creatures only (owner: "just creatures is fine for now"); GM mode still
wins, so test with `.gm off`.

Before:

A creature is selectable or not for everyone at once: the "not
selectable" bit lives in its unit flags, one value per creature. The
server already rewrites that value per viewer in one case: when it sends
a unit's fields to a player (`Unit::PatchValuesUpdate` in
`source-beta/src/server/game/Entities/Unit/Unit.cpp`), a game master in
GM mode has the bit taken off, so GMs can select anything. Nothing lets
a script choose, per player, which creatures that player can select.

718 today holds back only the Lich King's quest menu, from Lua (a greeting
hook that replaces his menu while a soul is owed); he, and everyone else
in Acherus, can still be selected.

## Intended Behavior

- **A per-player rule**, held on the player in memory: either "these
  creature entries are not selectable to me", or "no creature is
  selectable to me except these entries". Cleared at logout; a script
  sets it again at login.
- **Sent per viewer:** when a creature's unit flags go to a player whose
  rule covers it, the "not selectable" bit is added to that player's copy
  only; everyone else sees the creature as it is. GM mode still wins (the
  existing rule, applied after the new one).
- **Refreshed at once:** setting or clearing a rule re-sends the unit
  flags of every creature the player can currently see, so a change shows
  without walking away and back.
- **Held on the server too:** a player's interaction with a creature
  their rule covers (gossip, quest, vendor, trainer) is refused, in
  case a client sends one anyway.
- **From Lua:** two methods on a player, to set a rule (a list of
  entries, and whether the list is the blocked ones or the only allowed
  ones) and to clear it.
- **718's use:** a death knight owing a soul gets "none except Sargobras"
  at login and on its first login; the trade clears it.

## Suggested Implementation Steps

1. **Core B-patch** (reversible, `patches/B040-*.sh`, see the
   `upstream-patch-system` skill):
   - `Player.h`: the rule (a set of creature entries plus an
     "all-except" switch) and its setter, clearer and test.
   - `Unit.cpp`, `PatchValuesUpdate`, the unit-flags block: before the
     GM line, if the viewer's rule covers this creature, add
     `UNIT_FLAG_NOT_SELECTABLE`.
   - `Player.cpp`, `GetNPCIfCanInteractWith`: refuse a creature the rule
     covers.
   - the setter and the clearer mark `UNIT_FIELD_FLAGS` changed on each
     creature in the player's visible set, so the next update re-sends it.
2. **ALE B-patch**: `Player:SetUnselectableCreatures(entries, allExcept)`
   and `Player:ClearUnselectableCreatures()`.
3. Register both for the basic profile in `patches/patches.sh`; round-trip
   and syntax checks (`scripts/test-source-patches`,
   `scripts/test-patched-syntax`).
4. **718**: `src/lua-basic/death-knight-souls.lua` sets the rule for an
   owing death knight (all except creature 7180001) at login and first
   login, and clears it at the trade; the Lich King's greeting hook stays
   as the server-side refusal until step 1's interaction check is in.
5. **Test** in game with `.gm off`: an owing death knight can select only
   Sargobras; another player beside it can select everyone; after the
   trade everyone is selectable without relogging.

## Open Questions

- The owner's test account is a game master. With GM mode on, the
  existing rule makes everything selectable, so testing needs `.gm off`.
  Should the new rule win over GM mode instead?
- "All the NPCs": only creatures, or game objects too (the teleport pads,
  the Runeforge)? Game objects have no "not selectable" bit; hiding or
  locking them would be a separate mechanism.
