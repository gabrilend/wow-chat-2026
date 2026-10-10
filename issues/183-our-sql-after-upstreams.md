# 183 - Our SQL Runs After Upstream's, and Again After Each Pin Move

## Status
- Created: 2026-10-09
- Phase: 1
- Related: 155c (basic's world database patches), 150 (the E-patches),
  308 and the pin move of 2026-10-09 (core 2a2211cd8f3d)
- Priority: High (the next boot after a pin move applies ~1,200 upstream
  updates over databases our steps changed)

## Origin

The owner, 2026-10-09, on the risk that upstream's updates change rows
ours had changed: "What's the order of operations here? I thought we
resolved this by putting our SQL updates after the upstream's?" and:

> For the SQL updates, Azerothcore handles it's own updates. We should use
> their mechanism when we can, with our patches placed after theirs. Our
> "database patches" which is a particular stage in the pipeline I think,
> or maybe part of another stage? Anyway there's a stage where SQL updates
> go. Our SQL patches should create SQL files which are picked up by the
> Azerothcore SQL management system.

## Current Behavior

In progress (2026-10-09): built and checked without a server
(`scripts/test-sql-mirror`, 8 checks, in the compile's quick tests); not
yet run through an install and a boot, and question 1 is open.

- `patches/E-patches.sh`: `_register_with_updatefetcher` remembers each
  staging folder (`STAGED_SQL_DIRS`), registers its twin
  `<folder>.updater/` and removes the staging folder's own row;
  `_unregister_from_updatefetcher` removes both rows; `_sql_install_stamp`
  is the first line (core and module commits); `_mirror_staged_sql` writes
  `z_<name>` = stamp + file into the twin when it differs, and removes
  twins of files gone.
- `patches/patches.sh`: the mirror runs at the end of the install steps
  (a failure stops the install) and of their reverts.
- `.gitignore`: the twins, as the staging folders, are derived.

Before this:

Our install steps (E-patches, `patches/E-patches.sh`) already use the
core's own update system: each writes its SQL into an active folder
(`sql/<profile>/db_world/`, `db_characters/`, ...) and registers that
folder in the database's `updates_include` table (`_register_with_
updatefetcher`), so the server's updater applies the files as CUSTOM
updates at its start. What that system does (`UpdateFetcher.cpp`):
- every update file from every registered folder goes into one list sorted
  by file name, and runs in that order;
- a file runs once; its SHA1 is remembered in `updates`, and it runs again
  only when its contents change.

So two gaps:
1. **Order:** upstream names its files by date (`2026_09_23_00.sql`);
   ours are `04-...` to `36-...`, and everything from `0` to `29-` sorts
   before `2026_`: on a fresh install most of ours run first and
   upstream's after them.
2. **Re-running:** on a database our files already ran on, a pin move
   brings upstream's new updates, which run; ours are unchanged, so they
   don't. Where upstream changes a row ours changed, upstream's stays.

## Intended Behavior

- **After upstream's:** every file our steps install is seen by the
  updater under a name that sorts after every upstream update: `z_` and
  its own name (`z_35-legendaries.sql`), so ours keep their own order
  among themselves and all come after upstream's dated ones (`z` sorts
  after every digit, and every upstream and module name starts with one).
- **Again after a pin move:** each file's first line names the commits
  the server is built from (the core's and each module's, read from their
  source folders at install). A pin move changes that line, so the file's
  fingerprint changes and the updater runs it again, after upstream's new
  ones. Our files can run again: each is written to give the same result
  applied twice (the install tests apply them twice).
- **One place:** the install steps keep writing where they write today;
  those folders become staging. One finishing step, after all of a
  profile's install steps, mirrors each staging folder into a twin the
  updater scans (`<folder>.updater/`): every file renamed and stamped,
  files no longer in staging removed. The updater is pointed at the twins
  instead of the staging folders.

## Suggested Implementation Steps

1. The stamp: one line, `-- installed against <core sha> <module>=<sha> ...`,
   from `git -C` of the source tree and each module with a `.git`.
2. `_register_with_updatefetcher` registers the twin folder and removes
   the staging folder's row.
3. The finishing step, run once at the end of the install steps
   (patches.sh's PHASE_END runner): for each registered staging folder,
   write `z_<name>` = stamp + file into the twin, remove twins of files
   gone, report what it wrote.
4. A test: a staging folder of three files mirrored; names sort after a
   dated upstream name; a changed stamp changes every hash; a removed file
   leaves the twin; a second run with nothing changed writes nothing.
5. The first boot after this: every one of our files runs once more under
   its new name (new name, new hash), after upstream's: what we want after
   this pin move anyway. The old names' rows in `updates` stay as dead
   references, which the updater lists and can clean
   (`Updates.CleanDeadRefMaxCount`).

## Open Questions

1. **Our files and the old names:** the first boot sees every file under a
   new name and runs it again. Is a full re-run of everything ours, once,
   acceptable (it is meant to be safe), or should the twins start with the
   old files' hashes recorded so nothing runs until the next pin move?
