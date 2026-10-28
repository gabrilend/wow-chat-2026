# 617e5b - Boss Fights by the Warnings

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 617e5 (fighting together)
- Related: 617c3 (the dungeon draw), 617e10 (closer in danger), 619 (combat
  footwork), `docs/pathfinding-improvements.md` (6: not fighting on
  errands; 8: hard places)
- Priority: Medium
- State: plan only; nothing built

## Origin

The owner, 2026-10-27:

> can we add Deadly Boss Mods support? The buddy-bots should have movement
> patterns for every dungeon and raid boss that corresponds to the warnings
> and outputs of the Deadly Boss Mods system. And they should mess up or
> fail roughly the same amount of percentage time that the player does.

## Current Behavior

Buddies fight bosses with the playerbots module's general combat
strategies (and its own handful of boss strategies, where it has them):
they do not move out of fire, spread, stack, or interrupt by the boss's
mechanics, and nothing measures how often a player fails a mechanic.

## Intended Behavior

1. **The warnings as the buddies' knowledge**: Deadly Boss Mods is an
   addon in the player's game client; the server cannot read it. Its
   knowledge is written in its encounter files (per boss: which spells,
   cast or aura, warn of what, and the kind of answer: move away, spread,
   stack, interrupt, dispel, run out of a zone, hide behind something, face
   away). That knowledge is read once into the server's terms: a table per
   boss of (spell, event, answer, distance or place).
2. **An answer per kind**, not per boss: each answer is a movement pattern
   built once and used wherever the table names it: leave a circle round a
   spot or a player; spread to a distance from the others; stack on a
   chosen buddy; get behind an object (line of sight); stop casting
   (interrupt); dispel; move to a named place. Bosses differ by their
   tables, not by code.
3. **As often wrong as the player**: each player's own record on the same
   mechanics (an avoidable spell that hit them, or one they avoided)
   measured over their fights; each buddy fails a mechanic at about that
   rate, chosen at random each time (the owner: "they should mess up or
   fail roughly the same amount of percentage time that the player does").
   A player with no record yet: a default rate.

## Suggested Implementation Steps

1. **Read the knowledge**: a tool that reads a Deadly Boss Mods release
   for this game version (the 3.3.5 one, its encounter files in Lua) and
   writes the table: boss creature id, spell id, event (cast start, cast
   success, aura applied, emote text), the warning's kind, and its numbers
   (range, duration). Its licence decides whether its files may be read
   into ours: to be checked first (an open question).
2. **The answers**: the movement patterns of 2, each a pure function (where
   to stand) with a test in the pretend world, then a buddy action that
   carries it out with the mesh (617o).
3. **The hook**: the server's spell and aura events for the boss (cast
   start, aura applied) look the spell up in the table and give the
   buddies near it their answer.
4. **The player's record**: for each mechanic in the table, whether the
   player was hit by the avoidable part (an aura applied, damage taken from
   that spell) or avoided it; a rate per player; the buddies' failure
   chance from it.
5. Seen in game: a dungeon boss with a fire circle; buddies leaving it, and
   failing about as often as the owner.

## Open Questions

1. **Deadly Boss Mods' licence**: may its encounter files be read and
   their knowledge written into the project's own table, or must the table
   be written by us from the encounters themselves (the game's spell data,
   boss scripts in the server)? The owner, 2026-10-27: "I don't know it's
   license. It's an addon." Then, on the proposal to use the server's own
   boss scripts instead: "okay that's our fallback. You don't understand,
   DBM is the most comprehensive tool for this topic imaginable. [...]
   Perfect coverage of all boss-related mechanics. We could use their addon
   as signals for *so* many complex behaviors." **Decided: Deadly Boss Mods
   is the source; the server's boss scripts are the fallback**, for a boss
   it does not cover. **Its licence**, read 2026-10-27 from the header of
   `DBM-Core/DBM-Core.lua` in the 3.3.5 version
   (github.com/Zidras/DBM-Warmane): "Creative Commons Attribution-
   Noncommercial-Share Alike 3.0 License", copyright Paul Emmerich, Martin
   Verges and Adam Williams. It allows copying and making derived works on
   three conditions: credit with a link to deadlybossmods.com,
   noncommercial use only, and the derived work under the same licence.
   Its textures and sounds are licensed separately and are not needed. So
   the table a tool reads out of its encounter files may be built and
   kept, provided the table's file carries that licence and that credit,
   and the project never sells it. Open: the owner's confirmation that
   those three conditions are acceptable for this project.
2. **Which bosses first**: the dungeons basic's players reach (1-60), then
   raids?
3. **"Fail"**: being hit by an avoidable spell, or also a missed interrupt,
   a late stack? One rate for all of a player's mechanics, or one per kind?
