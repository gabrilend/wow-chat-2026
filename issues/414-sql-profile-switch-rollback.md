# 414 - SQL Profile-Switch Rollback System

## Status
- Created: 2026-04-28
- Phase: 1 (Foundation)
- Priority: Low (deferred — single-database approach for now)

## Problem

When the active profile changes (alpha ↔ release ↔ beta), custom SQL
files that were applied under one profile may be absent in the new
profile's update directory. AzerothCore's update tracker then warns:

```
>> The file 'drop-all-non-critters.sql' was applied to the database,
   but is missing in your update directory now!
```

This happens because each profile has different custom SQLs, but the
database is shared. Switching profiles leaves DB state from the
previous profile baked in.

## Current Decision

**Stay on a single database for now.** Don't try to roll changes back
on profile switch. Accept that profile-switching is rare and that the
warnings, while ugly, are non-fatal.

## Future Direction (When This Becomes Worth Doing)

Rather than `DROP`/destructive `DELETE` rollbacks, prefer **non-destructive
preservation**: when a profile-switch wants to undo a change, move the
affected rows into a parallel table rather than deleting them.

Example: instead of `drop-all-non-critters.sql.undo` re-inserting
creatures from a backup, the original `drop-all-non-critters.sql` could
move non-critter creatures to `creature_archived` rather than deleting
them. Switching profiles back restores from that table; switching forward
re-archives.

This way:
- No data is ever destroyed
- Rollback becomes a row-move, not a re-insert from backup
- The archive table grows but is bounded by the canonical row set

## Open Questions

- Which custom SQLs are actually destructive (DDL changes vs DELETE)?
  DDL changes are harder to reverse and may need their own approach.
- Is the archive-table approach scalable across all custom SQLs, or just
  the row-deletion ones?
- Should the rollback live in the patch system (`docs/patches/`) or be
  its own subsystem?

## When To Revisit

- When profile switching becomes a regular part of the workflow
- When the "applied but missing" warnings become noise that masks real
  problems
- When release builds need to verifiably match a clean-room state
- When a user/contributor asks for a way to swap profiles without DB
  rebuild

## Related Issues

- 167 recreate-missing-sql-files
- 400 release-to-beta-transition
- 412 canonical-profile-definitions
