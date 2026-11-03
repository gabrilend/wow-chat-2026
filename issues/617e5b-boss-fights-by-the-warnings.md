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

## Credits

Boss mechanics are researched with **Deadly Boss Mods** as a reference
(http://www.deadlybossmods.com; DBM-Core by Paul Emmerich, DBM-GUI by
Martin Verges, boss mods by Adam Williams; the 3.3.5 version maintained as
DBM-Warmane). Nothing of DBM's code or files is copied into this project.

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

Gathered 2026-10-28 into 617's own list (question 22), merged with the
same questions from other sub-issues; answers are written back here.

- **Answered 2026-10-28** (617's question 22): "order doesn't matter, we
  want to build all of them". A failure is being hit by what could have
  been avoided, and also a missed duty: an interrupt not made, a dispel not
  cast, a stack taken late.

- **Decided 2026-10-28** (617's question 22): "Okay let's read them as a
  reference. We can find out WHAT they are paying attention to, and then
  build our own tracking capabilities. We are using it for buddy-bots. Be
  sure to credit them." So: DBM is read as a reference only, to learn what
  it watches in each fight (which spells, auras, emotes and timings); our
  own tracking is built from that understanding and from the game itself
  (the server's boss scripts), for the buddies' use; no DBM file or
  transformed table enters the project; and DBM is credited wherever its
  guidance shaped our work: a credits line in this issue, in the tracking
  code's header and in the project's credits ("Boss mechanics researched
  with Deadly Boss Mods as a reference, http://www.deadlybossmods.com, by
  Paul Emmerich, Martin Verges and Adam Williams").

- **The licence's specifics** (asked again 2026-10-28; engineering notes,
  not legal advice). DBM-Core's own header (the 3.3.5 version, DBM-Warmane),
  word for word: "The code of this addon is licensed under a Creative
  Commons Attribution-Noncommercial-Share Alike 3.0 License. (see
  license.txt) All included textures and sounds are copyrighted by their
  respective owners ... You are free: to Share - to copy, distribute,
  display, and perform the work; to Remix - to make derivative works.
  Under the following conditions: Attribution. You must attribute the
  work in the manner specified by the author or licensor (but not in any
  way that suggests that they endorse you or your use of the work). (A
  link to http://www.deadlybossmods.com is sufficient). Noncommercial. You
  may not use this work for commercial purposes. Share Alike. If you
  alter, transform, or build upon this work, you may distribute the
  resulting work only under the same or similar license to this one."
  Copyright: Paul Emmerich, Martin Verges, Adam Williams.
  What that means here:
  - **Reading it** is not something a licence governs: a licence covers
    copying, changing and handing on the work. Reading DBM to learn how a
    boss behaves needs no permission.
  - **Copying it in** (its files, or a table made by transforming them)
    makes a derived work: non-commercial only, under CC BY-NC-SA, credited.
    That cannot sit in RGPL code (the AGPL lets anyone sell; CC's
    "non-commercial" forbids it), so nothing transformed from DBM's files
    goes into the project.
  - **Facts are free**: a boss's spells and timings are the game's; a
    table we write from the game (the server's boss scripts) is ours, even
    if DBM taught us where to look.
  - **"Commercial"** in CC 3.0 means intended for commercial advantage or
    money; a project never sold until its assets are its own is
    non-commercial meanwhile, but its code is meant to be sellable later,
    which is why nothing of DBM may enter it.
  - The textures and sounds are licensed apart; not needed.

- **The licence, in detail** (asked 2026-10-28: "How compatible is it with
  the RGPL? ... I need more details on the license"; engineering notes,
  not legal advice):
  - **What DBM's licence says.** Creative Commons Attribution-
    NonCommercial-ShareAlike 3.0: anyone may copy it and make works from
    it, if they (1) credit DBM with a link, (2) never use it commercially
    (no selling, no paid product), and (3) put what they make from it
    under the same licence.
  - **The RGPL** is the AGPL (a GPL-family licence) with this project's
    own clauses. GPL-family licences require that anyone may sell the
    work; CC's NonCommercial forbids it, and its ShareAlike requires CC's
    terms instead of the GPL's. The two can't hold one work at once: a
    table derived from DBM's files couldn't be part of RGPL'd code, and
    couldn't be in a product that is sold.
  - **What isn't DBM's.** Facts about the game (a boss casts spell N, every
    30 seconds) belong to no one in most places; DBM's own wording, code,
    and its selection and arrangement of those facts are its own. Reading
    DBM to learn facts and writing our own table from the game itself is
    the usual safe line; copying its files in is not.
  - **What fits the owner's plan.** The bosses will be new ("we need to
    create entirely new bosses anyway"), so no DBM-derived file is ever
    part of the product. For today's bosses, the table can be written by
    our own tool from the server's own boss scripts (the code that makes
    each boss act), and players may run DBM as their own addon. The
    server's boss scripts carry the server's licence, which the project
    already builds on.
  - Still the owner's to decide: whether to read DBM at all during
    development (for ideas and to check our own table), knowing nothing
    of it ships.

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
