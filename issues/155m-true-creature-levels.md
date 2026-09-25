# 155m - True Creature Levels Instead of the Skull

> **Part of this will not be implemented, because it needs AIO:** route 1 as written (the level shown through AIO).
> The project no longer plans to use AIO, the server-to-client addon framework
> (Ritz, 2026-09-25: "I think we should update the plan of the project to
> NOT use AIO, or at least to mark anything that requires it as 'will not
> implement because it needs AIO. But here's how we would if we could:'").
> The AIO parts below are kept as how we would build them if we could. Route 2 and a plain addon without AIO are open (see Open Questions).

## Status
- Created: 2026-09-24
- Phase: 1
- Parent: 155
- Blocked by: 155a
- Related: 155f, 155j (the boss levels players will now see), 803
- Priority: Low — **parked 2026-09-24** (Ritz: "Let's put a pin in the
  skull interface concern for now. We'll come back to it later.")

## Origin

Verbatim, 2026-09-24:

> Can we also add a patch that makes it so very high level creatures don't
> have their level shown as a skull, but instead show the actual number
> instead?

## Current Behavior

Stock. The server sends every creature's real level to the client. The
**client** decides to hide it: its level query (`UnitLevel` in the
interface's scripting) returns -1 for a unit 10 or more levels above the
player, and for any creature ranked as a boss whatever its level, and the
interface draws a skull wherever it gets -1 (target frame, focus frame,
tooltip, nameplates). This is in the client program itself, not in data the
server controls.

On basic this now matters: the +4 Outland dungeons put creatures at 70–76
against level-60 players (skulls from 70), and the world bosses are level
73 and boss-ranked.

## Intended Behavior

- Players see the actual number for every creature, however high, where
  the client would draw a skull.
- Boss-ranked creatures: see Open Questions.

## Suggested Implementation Steps

Two routes; the first needs no client binary change:

1. **An interface addon, fed by the server (recommended).** The project
   already runs AIO, the server-to-client addon channel. On target, focus
   and mouse-over, the addon asks the server for the unit's level (by its
   GUID), caches the answer, and replaces the skull with the number in the
   target frame, focus frame, tooltip and nameplates. Players get it
   through the project's addon install (`scripts/install-client-addons`),
   or pushed by AIO itself.
2. **Patching the client program** to raise the 10-level threshold. Needs
   a binary patch of the game executable handed to every player; not
   checked whether a known offset exists for this build.

Test: target a level-76 Shattered Halls boss as a level 60 and read 76 in
each place.

## Related Issues

- **155** parent
- **155f** / **155j** the high-level creatures this is for
- **158** player-machine safety before public release (anything shipped to
  players' machines)

## Open Questions

- Boss-ranked creatures (Kazzak, Doomwalker, dungeon end bosses) always
  show a skull in stock, even at the player's level. Show their number
  too, or keep the skull as the "this is a boss" sign?
- (Answered 2026-09-25) No required addons: "can't ask users to install
  addons, at least until the custom client is done..." / "They can install
  whatever they'd like, we just can't require them to." So the skull stays
  for everyone by default. Route 1 through AIO is out (the project doesn't
  use AIO); a plain, optional addon over the client's addon-message channel
  would be allowed as an extra for players who choose it, but nothing may
  depend on it. Route 2 (a patched game program) waits for the custom
  client.
- Build the optional addon now, or leave this issue until the custom
  client?
