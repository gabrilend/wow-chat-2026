# 189d - Our SQL as Patches, by Priority

## Status
- Created: 2026-10-20
- Phase: 1 (Foundation & Tooling)
- Parent: 189
- Blocked by: 189c
- State: planned

## Current Behavior

Install steps copy our SQL into folders registered with the server's
database updater, renamed `z_` (issue 183) so they sort after upstream's
by name; the updater records files by name, and `_forget_unprefixed_updates`
removes the double records a rename leaves.

## Intended Behavior

Each SQL file is a patch with its own header (`kind: sql`, and which
database). After the gate where upstream's updates are applied (the
server's own updater, run by `dbimport`), the runner applies our SQL by
priority and records each by id in a table of ours in that database; a
changed or removed one is undone (its revert form) and the new applied,
never by editing the updater's records. The registrations
(`_register_with_updatefetcher`), the mirror folders and `z_` names, and
`_forget_unprefixed_updates` are removed; the start-up warnings 189 began
with cannot come back.

## Suggested Implementation Steps

1. Our record table, one per database, made by the runner.
2. SQL patches: the apply and revert sources gain headers; the install
   steps that only copied SQL go.
3. Tests on a RAM database (as `scripts/test-beta-sql-in-ram`): order,
   repeat-safety, undo, a changed file undone and reapplied.
4. Unregister our folders from the updater, once, on each database.
