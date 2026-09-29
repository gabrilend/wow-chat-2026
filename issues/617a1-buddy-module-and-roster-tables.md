# 617a1 - Buddy Module and Roster Tables

## Status
- Created: 2026-09-26
- Phase: 6
- Parent: 617a
- Blocked by: none
- Priority: High (every other 617a part is built in this module and reads these tables)

## Current Behavior

**Built 2026-09-26; tested offline; waits on the owner's build and a
server start** (the only thing left: the startup line "roster tables
present; buddies are ON" in the worldserver log).

- `modules/mod-buddies/` (new; the project had no `modules/` folder):
  `src/buddies_loader.cpp` (the module's entry point) and
  `src/buddies_roster.cpp` (at startup, checks both tables exist; if
  either is missing it logs an error naming install step E042 and keeps
  buddies off). `README.md` beside them.
- `patches/B036-mod-buddies.sh`: copies the module into
  `source-beta/modules/` before a build (a copy, not B008's link: whether
  the build's folder scan follows a link was never tested), with a marker
  file; the revert removes only a folder carrying the marker. Its witness
  in `patches/patches.sh` asks for a fresh copy whenever the project's
  module differs from the build's. On basic's list only.
- `sql/basic/db_characters.src/04-buddy-roster.apply.sql` / `.revert.sql`
  and install step E042 (`patches/E-patches.sh`, E041's shape; basic's
  list): `buddy_clan` and `buddy_roster` as in 617a's data model. The
  revert drops both tables and leaves any buddy characters and accounts
  alone.
- Tests, 2026-09-26: `scripts/test-source-patches <dir> basic` (B036
  applies; round trip byte-identical); `scripts/test-basic-sql-in-ram`
  (E042 applied, re-applied, reverted, applied; all checks pass, including
  the new `scripts/validate-basic-state` check that every column the
  module and `src/lua-basic/buddy-talents.lua` read exists).
- **Compile check**: `scripts/test-patched-syntax` checks only files the
  patches change inside the tree and that the last build recorded, so it
  skips a module that has never been built. The two module files were
  checked by hand with the recorded flags of a sibling module file
  (mod-aoe-loot's) and `-fsyntax-only`: both pass. Teaching the syntax
  test to do this for new module files is a small follow-up (open
  question below).

## Intended Behavior

- **`modules/mod-buddies/`** in the project: the C++ home of 617a (and
  later 617c and the rest), with the stock module layout (a loader
  function, `src/`, `conf/` if it needs config).
- **Source patch B036** links it into `source-beta/modules/` before a
  build and removes the link after, like B008, failing loudly when the
  folder is missing. Added to basic's list only.
- **Two characters-database tables**, from 617a's data model (the other
  tables there belong to the issues that use them: `buddy_draw` 617c,
  `buddy_task` 617m, `buddy_price` 617h):
  - `buddy_clan`: owner character guid (key), companion account id, clan
    guild id (0 until 617l).
  - `buddy_roster`: owner guid and slot (key; slot 1 at creation, 2 at
    level 10, ... 7 at 60), buddy character guid (0 while owed), class,
    race, profile (talent shape 1-10, 617g), role (0 damage, 1 tank, 2
    healer), talents_reroll (0/1, 617g), created (unix time).
- **The roster row is the handoff between Lua and C++.** The selector
  (617b, Lua) writes the choice into the owed row (class, race, profile,
  role); the module (C++) sees a chosen row without a buddy and creates
  it (617a3). Neither side calls the other directly.

## Suggested Implementation Steps

1. `modules/mod-buddies/` skeleton: loader registering an empty world
   script; builds with nothing else.
2. `patches/B036-mod-buddies.sh` (apply/unapply) and basic's list in
   `patches/patches.sh`; `scripts/test-source-patches <dir> basic`.
3. `sql/basic/db_characters.src/04-buddy-roster.apply.sql` / `.revert.sql`
   and an E-step (E042) in `patches/E-patches.sh`, in E041's shape.
4. `scripts/test-basic-sql-in-ram`: apply, re-apply, revert, apply;
   `scripts/validate-basic-state`: both tables exist with their columns.
5. Compile check of the module's files with the build's recorded flags.

## Related Issues

- **617a** parent; **617a2**, **617a3** build on this
- **617g** reads `buddy_roster` (profile, talents_reroll)
- **155d** / E023, **718** / E041: the characters-database SQL pattern

## Open Questions

- Should `scripts/test-patched-syntax` check a new module's files by
  borrowing a sibling module's recorded flags (what was done by hand
  here), so B036's module is covered on every run?
