# 155c - Basic World-Database and Source Patches

## Status
- Created: 2026-09-23
- Phase: 1
- Parent: 155
- Blocked by: 155a
- Priority: High

## Current Behavior

**Built 2026-09-23; source side tested offline, database side waits on the
owner's install.** Basic's rows in `patches/patches.sh`:

- source patches: vanilla's list minus B025, plus B005 (accuracy cap) and
  B028 (155d's starting-valley rotation);
- setup steps: E001 E004 E006 E008 E019 E020, plus E022 (155e), E023
  (155d), E024 (155f).

basic reads vanilla's flight-path, riding-gate and no-cinematic sources
directly: a small sharing table in `patches/E-patches.sh`
(`_shared_sql_src`: basic → vanilla) points those three steps at
`sql/vanilla/`, and each shared source says so in its header. (Symbolic
links under `sql/basic/` did this first. They were replaced because the
project's commit tooling cannot carry links, and a table in code is the
more visible record anyway.) 35 new flavor lines cover
every flightmaster on the Outland map (the draenei and blood elf home zones
and Outland proper), IDs 90070–90104, in the shared flight-path source.
Vanilla gets them too.

`scripts/test-source-patches <profile>` copies the source tree into RAM,
applies the profile's whole source-patch list, checks each returned
success, reverts, and compares byte for byte. basic, vanilla and release
pass, and so does beta since B006 and B007 were fixed (below).
`scripts/test-patched-syntax <profile>` goes one step further. It
applies the profile's patches to a RAM copy of the tree and asks the
compiler to check every changed file with the last build's own flags, minus
the precompiled-header binary, which was built from unpatched headers. It
compiles nothing and writes no objects.

**B006 and B007 left edits behind on revert**, so beta's tree never went
back to upstream. The cause was a design flaw, not a typo: both reverts
re-matched the inserted text instead of removing a marked block.

- B006 never removed the `#include` it added, and it deleted the hook-call
  lines before trying to remove their `#ifdef` shells, so the shells stayed.
- B007's first method comment carries its "Issue 332" tag on the next line,
  so that pattern never matched, and the other three deletions started one
  line late.

Both now bracket every inserted block with begin/end marker comments (as
B025 and B028 already did) and delete exactly the bracketed ranges. beta
round-trips, and its patched files pass the compiler check.

Found and fixed along the way:

- **B005's revert left a stray blank line** in the core's unit header, so
  beta's tree never round-tripped. Fixed; B005 now round-trips.
- **Both patch runners ignored failure.** The source-patch runner printed
  "Applied" whether or not a patch worked, and the setup runner warned on a
  missing step and always printed "complete". Both now stop at the first
  failure and say what completed, what failed and what never ran. The
  compile script arms its revert-on-exit trap *before* applying, so a
  failure part-way still reverts. `scripts/apply-patches` exits non-zero on
  failure.
- **The database-registration helper hid errors.** With MySQL up, a failed
  registration was discarded; now it fails the step. With MySQL down it
  still defers, as designed, but prints a NOTICE naming the unregistered
  directory.
- **Shared SQL steps went stale.** E008, E019, E020 (and the new E022–E024)
  skipped work whenever their output file carried the right marker, so
  source edits never reached an existing install. They now compare the
  whole file (as E018 already did), and they register on every run, so a
  first run with MySQL down no longer skips registration forever.

**Schema drift found (2026-09-23).** Upstream update `2026_06_16_00`
renamed the spawn table's `creature.id1` to `creature.id` and moved
`id2`/`id3` into `creature_multispawn`. The base SQL files still say `id1`,
so anything written by reading them gets the old name. The new basic SQL
uses `id`. **Beta's E012 (`sql/beta/db_world.src/12-drop-creatures-keep-essential.apply.sql`)
still joins on `c.id1`,** so on a fresh beta database it fails and stops the
worldserver's database update at boot. It is not changed here: editing a
destructive SQL file changes its hash, and the server then re-runs it
against beta's existing database. Waiting on the owner.

Still open: the owner's install run.

`patches/patches.sh` holds two per-profile tables: the **source patches**
stamped onto the C++ tree before compiling, and the **setup steps** run
after compiling, which write SQL files into `sql/<profile>/db_world/` or
`db_characters/`. The server's own update machinery runs those SQL files on
next boot. Neither table has a `basic` row, so basic would compile with no
fixes and boot with a stock world.

Each SQL-writing setup step copies its content from a source file in
`sql/<profile>/db_world.src/`. Only `sql/vanilla/` has those source files.

## Intended Behavior

### Source patches (before compile)

Basic takes vanilla's list minus the one head-start patch:

| Patch | Basic | Why |
|---|---|---|
| B001 B002 B004 B009 B012–B023 B026 B027 | yes | compile fixes, Lua-engine thread safety, playerbots×Lua login hook, bot-login crash guards; none change gameplay |
| B005 accuracy level cap | **yes** (user directive 2026-09-23: "implement the patch that removes the accuracy penalty for level gaps") | beyond a 3-level gap, hit and miss chances stop getting worse (issue 803). It caps the penalty at ±3 levels rather than removing it. Beta already carries it, so it is known to apply to `source-beta`. It pairs with 155f: a level-60 party in a level-64 dungeon fights at a 3-level penalty, not 4 |
| B025 bots start in the vanilla starter kit | **no** | head-start; it is self-scoping on kit data basic's world database will not contain, so leaving it in would do nothing, but "does nothing because the data is absent" is exactly the silent mode to avoid |

### Setup steps (after compile)

| Step | What it does | Basic |
|---|---|---|
| E001 | links `src/lua-basic/` into the install tree | yes |
| E004, E006 | log directory, config generation | yes |
| E007 | **moves each race's spawn point** from its level-1 tutorial valley (Northshire, Valley of Trials, …) to a level-20 town across the world (Menethil Harbor, Ratchet, Astranaar, Tarren Mill, Sun Rock, Darkshire) | **no** — basic starts at level 1, and the stock valleys are the level-1 content |
| E008 | removes the flightmaster function from every NPC; flightmasters in Eastern Kingdoms and Kalimdor get a two-sentence flavor line instead | **yes** (user decision) |
| E009 | class starter kit | no — head-start |
| E010 | pretrained abilities | no — head-start |
| E018 | cloned starter-kit items tuned to level 20 | no — only exists to serve E009 |
| E019 | skips the race intro cinematic on first login (a trigger in the characters database) | **yes** (user decision) |
| E020 | riding gates: Apprentice Riding at 40, Journeyman at 60 | **yes** (user directive). On basic's cap of 60 this is the Classic arrangement exactly: 60% mount at 40, 100% mount at the cap. On vanilla the 100% mount was an unreachable horizon; on basic it is the cap reward. |
| E021 | starting professions at skill 125 | no — user directive |

### Where basic's SQL sources live

E008, E019 and E020 contain no database names and no vanilla-specific
values (checked 2026-09-23), so basic uses the same content. There is one
source of truth: for basic, those three steps read vanilla's source files
(the `_shared_sql_src` table in `patches/E-patches.sh`), not copies. A
tuning change to riding gates or flavor lines then lands on both profiles.
If basic later diverges from vanilla on one of them, it gets its own file
under `sql/basic/` and leaves the table, and the commit says so.

The comments inside those source files say "vanilla" throughout. They get
a line noting that basic shares the file.

## Suggested Implementation Steps

1. Add the `basic` rows to both tables in `patches/patches.sh`, with a
   trailing comment in the house style naming this issue and the skipped
   patches.
2. Point E008, E019 and E020 at vanilla's sources for basic (the sharing
   table).
3. Add the "shared with basic" note to each linked source file's header.
4. After the user's install and first boot of basic, check against the live
   `acore_world_basic` database:
   - a human's `playercreateinfo` row still points at Northshire;
   - `trainer_spell` requires 40 for spell 33388 and 60 for 33391;
   - no creature template carries the flightmaster flag;
   - `playercreateinfo_item` has no rows tagged `vanilla-148h-`, and
     `playercreateinfo_spell_custom` none tagged `vanilla-148j-`.
   These checks become a script beside `scripts/validate-vanilla-starter-state`,
   named for basic.

## Related Issues

- **155** parent; **155a** blocks this
- **148i** flight-path removal, **148l** riding gates, **148n** starting zones,
  **148h**/**148j**/**148q**/**148s** the head-start patches basic leaves out

### Outland

Outland stays open (user decision 2026-09-23: "raid quality gear from
questing"). The Dark Portal opens at 58 as stock. E008 removes flight paths
there too. Its Outland flightmasters had no flavor line because vanilla
never reached Outland; they have one now (see Current Behavior). The
Outland lines do not name each NPC's outpost, because which outpost each one
serves was not verified.

Because basic's source-patch list differs from vanilla's (B005 in, B025
out), basic compiles into its own build directory and binary; the compile
script already names the build directory by profile.

## Open Questions

- (Answered 2026-09-23) Outland items keep their stock required level; a
  level-60 character cannot equip the ones above 60.
