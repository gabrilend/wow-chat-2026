# 189e - A Patch Is a Directory, Carrying Its Own Files

## Status
- Created: 2026-10-20
- Phase: 1 (Foundation & Tooling)
- Parent: 189
- Blocked by: 189c
- Blocks: 192
- Related: 189g (a guard reviews each patch, since a patch may now carry
  anything), 630 (Sargobras the guild master)
- State: built 2026-10-20; waits on the owner's compile of basic and
  cc-test (the moves change what the build copies and from where)

## Origin

wow-chat-2026-ae, for issue 192, 2026-10-20 (the owner's decision that
day): Sargobras's Lua moves out of `src/lua-basic/` into a home owned by
one patch, which copies it into each taking profile's install and removes
it on undo; the same for the buddy SQL cc-test reads from basic
(`_buddy_sql_src`) and the buddy module B036 copies in. The owner: "the
template is in git, the build files are not."

The owner, 2026-10-20, on how Sargobras travels: "he is his own patch. he
deserves all the space to do with as he chooses. for he is the real guild
master." (the rest, a feature of its own, is issue 630). On where a
patch's files live: "patches/ should be a directory, and inside it is the
scripts that apply the thing, and the bash file that runs them. They each
can be in whatever language, convention is that they're the same language
as the thing that they're modifying is written in. But that's not always
possible with things like SQL, so sometimes they're binary data formats
that the patch can reference while implementing them or itself." (The
rest of that answer, a guard reviewing each patch, is 189g.)

## Current Behavior

Built 2026-10-20, every step, not yet compiled:

- **A patch may be a directory**, `patches/<ID>-<name>/<ID>-<name>.sh`
  beside what it carries. The loaders, the planner, the header checker,
  the list generator and `scripts/add-patch-header` all read that form.
- **`carries:`** in the header names what the directory holds
  (`add-patch-header ... --carries "a b"` writes it and refuses a name not
  there); `scripts/test-carried-files` (a quick test) holds that each
  directory patch names exactly what it holds.
- **Placing**: `place_carried` and `remove_carried` (`patches/E-helpers.sh`)
  copy a carried file or folder to where it goes, replacing a copy there
  whole, and remove it on undo.
- **Sargobras is E066**, `patches/E066-sargobras/`, basic's, at 1960 in the
  install stage: `sargobras.lua` (moved from `src/lua-basic/` with git, his
  jokes with him) and `.own/`, his own copies of the six helpers he loads
  that basic's other scripts also load. He loads them from `.own/`. The
  step places both into `bin/lua_scripts/sargobras/`; the undo removes the
  folder. The three generators that write those helpers write his copies
  too, and the test fails if his copies and basic's ever differ. The tests
  that load him (`test-sargobras-follow`, `test-valley-deal`,
  `test-dk-buddies-by-level`) read his patch. `scripts/test-ale-method-names`
  reads carried Lua as its profile's scripts (death-knight-souls calls two
  of his functions). The open issues naming his old path name the new one.

- **The buddy module is B036's**, `patches/B036-mod-buddies/mod-buddies/`
  beside `B036-mod-buddies.sh` (both moved with git from `modules/` and
  `patches/`; `modules/` at the project's top is gone). B036 keeps its own
  copy-in with the marker file that guards the source tree's folder. The
  compile finds a project module as any `mod-*` folder a source patch
  carries (`patches/B###-*/mod-*/`), both where it sets each module on or
  off and where it looks for a new source file the last configure missed;
  the module's tests, the bake, the quest-spell generator and the lessons
  library read the new path; the GM command descriptions name it, and the
  command reference and the in-game help were written again from them by
  their generators (the reference had last been written 2026-10-09, so it
  also took in eleven days of other changes). Open issues naming the old
  path name the new one; completed issues and the append-only balance log
  keep the path of their time.

- **The buddy SQL is its steps'**: E042 (roster), E044 (area centres),
  E045 (beds), E050 (town circles), E052 (gearsets) and E056 (stand-ins)
  are each a directory carrying its apply and revert SQL, moved with git
  from `sql/basic/db_*.src/` by a temporary tool
  (`/tmp/wow-chat-2/move-buddy-sql.lua`, not kept). Each step reads its SQL
  from beside itself, for basic and cc-test alike, so `_buddy_sql_src`
  (cc-test reaching into basic's folders) is gone. The generators that
  write those files (area centres, town circles, gearsets, and the bed and
  boarding exports) and the tests that read them (basic's database in RAM,
  the gearsets, the stand-ins) use the new paths.

Checked: `scripts/test-carried-files` (24 checks: each of the eight
directory patches names exactly what it holds; Sargobras placed byte for
byte, the engine loading only his script, no name clashing with basic's,
twice the same, undone to nothing, his helper copies basic's); the three
Sargobras tests; the module-set test (the compile still finds mod-buddies
for basic and cc-test); the source patches round-trip on basic and cc-test
with B036 from its new home; `scripts/test-basic-sql-in-ram` (basic's
whole database built in RAM, every SQL step and its checks passing, with
the buddy SQL from its new place); all 52 quick tests.

The same reaching-in remains in one more place: `_shared_sql_src`, by which
basic reads vanilla's SQL for the steps the two share (open question 1).

## Intended Behavior

A patch may be a directory, `patches/<ID>-<name>/`: its bash file,
`<ID>-<name>.sh` (with the header, as every patch has), and the files it
applies, each in the language of what it changes (Lua, SQL, a module's
C++) or a data format it reads. The header's `carries:` names them, so
the guard (189g) and the checks see the whole patch. The bash file places
its carried files where they go in the install (or the source tree) when
applied and removes them when undone; the templates are in git, the
placed copies never are. A patch with nothing to carry stays one file.

Sargobras is the first: his own patch carries his script and his own
copies of the helpers he loads, kept in a folder whose name starts with a
dot (the Lua engine loads every script under its folder and refuses two
of one name, but skips dot-names), so his copies never clash with
basic's. Then the buddy module (B036) and the buddy SQL.

## Suggested Implementation Steps

1. The directory form read everywhere a patch is found: the loaders
   (`patches/patches.sh`, `patches/E-patches.sh`), the planner, the
   header checker, the list generator, `scripts/add-patch-header`.
2. The `carries:` field (189a's reader), and a check that each named path
   is in the patch's directory and nothing else is there unnamed.
3. Shared placing and removing for a patch's bash file (E-helpers.sh).
4. Sargobras's patch: `patches/E066-sargobras/`, basic's, placing into
   `bin/lua_scripts/sargobras/`; his script out of `src/lua-basic/`, his
   jokes with it, his own copies of the six shared helpers; the tests
   that load him read his patch.
5. The buddy module into B036's directory (17 files name
   `modules/mod-buddies`).
6. The buddy SQL into its steps' directories, so cc-test no longer reads
   basic's folders (34 scripts, mostly generators, write those folders).
7. Tests: placed on apply, removed on undo, nothing left behind.

## Open Questions

1. **basic reads vanilla's SQL** (`_shared_sql_src` in
   `patches/E-helpers.sh`) for the steps both take, the same reaching-in
   the buddy SQL had. The owner, 2026-10-20, of carrying files: "This is a
   pattern we should examine for other applications in our patches." Make
   those steps directories carrying their SQL too?
