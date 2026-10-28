# 189h - One-Time Database Patches

## Status
- Created: 2026-10-26
- Phase: 1
- Parent: 189 (the patch priority queue)
- Related: 189d (SQL as patches: what stays applied and is reverted),
  `scripts/change-character-class`, `scripts/teach-character-lessons`
  (the one-off character changes made by hand so far), `backups/`
- Priority: Medium
- State: plan only; nothing built

## Origin

The owner, 2026-10-26:

> can we add some functionality architecture to support a directory that
> has "one-time patches" - stuff that we want applied to the database
> immediately, but then removed afterwards? Stuff like the character
> updates and things that we accept to be updated automatically or
> intentionally.

## Current Behavior

Every SQL patch today is lasting (189d): applied at each install, reverted
by its revert file, part of the profile's build. A change meant to happen
once (a class change, lessons taught, a buddy's roster row mended, a
character's gear fixed) is made by running a tool or typing SQL by hand
while the server is down, and leaves no record in the project beyond the
tool's backup file and the conversation.

## Intended Behavior

- **A folder of one-time patches**, `patches/once/` (per profile, by the
  file's header as other patches are), each an SQL file or a script, named
  `<date>-<what>.sql` (or `.sh`), with the usual header (189a) saying its
  profile, database and what it is for.
- **Applied once, as soon as possible**: by the install, or by a command of
  its own while the server is stopped (`scripts/apply-once`), each patch
  that has not been applied to that profile's database yet: a backup of
  every row it touches first (as the class-change tool keeps), then the
  patch in one transaction.
- **Then removed from the folder**: moved to `patches/once/applied/` with a
  line saying when, to which database, and where its backup is; kept in
  git there, so what was done stays in the story, and never run again.
- **A ledger in the database** (a table of applied one-time patches: name,
  checksum, when), so a patch is never applied twice even if the folder is
  restored from git, and a changed file with an old name is refused.
- The class-change and lessons tools can write their changes as one-time
  patches instead of applying them directly, so "fix Lariadel" becomes a
  file that is reviewed, applied once and kept.

## Suggested Implementation Steps

1. The folder, the header fields (`kind: once`, the database), and the
   ledger table (a lasting SQL patch of its own, 189d).
2. `scripts/apply-once [PROFILE]`: server-stopped check, backup, apply,
   ledger row, move to `applied/`; a dry run that rolls back.
3. The install step that runs it, after the gate where the databases are
   ready (patches/gates, 2000).
4. A quick test: a pretend database and folder; a patch applied once, moved,
   not applied a second time, refused when changed under its old name.
5. Optional: the class-change and lessons tools write a one-time patch.

## Open Questions

1. (Answered 2026-10-27) **When**: as part of the patching process. The
   owner: "it is part of the patching process. A new patch is written, or
   one is modified. We need to adjust the database to suit it, so we should
   show how exactly for this purpose the database is modified." So a
   one-time patch belongs to the lasting patch it serves: written with it
   (or with the change to it), naming it in its header, applied by the
   patch runner in that patch's turn, and saying exactly what it changes
   in the database and why. Its first use (2026-10-27, by hand, before
   this was built): four bags for Feldowinn and her buddies and all seven
   moved to The Bulwark, kept as
   `backups/one-time/bags-and-bulwark-2026-10-27.backup.sql` (the rows
   before) and the SQL that did it.
2. **Scripts too**, or SQL only? A script (like the lessons tool) can do
   what SQL alone cannot (read the client's data), but is harder to back up.
3. **Removed from git, or kept in `applied/`?** "removed afterwards" could
   mean out of the folder (kept as history), or deleted.
