# 191 - Guard the Disks Against Bit Rot

## Status
- Created: 2026-10-20
- Phase: 1 (Foundation & Tooling)
- Related: 188 (the move to /mnt/kaun), 190 (the intuition copy, which
  also goes to GitHub)
- Priority: Medium; a standing reminder in CLAUDE.md until the owner starts it
- State: open, not started

## Origin

The owner, 2026-10-19: "sometimes it feels like the files on my computer
get strategically deleted sometimes. It's a little frustrating watching the
machinery you built up over years succumb to bit rot." Then, 2026-10-20, on
a filesystem that checksums file contents and checksums kept on GitHub:
"we need to work on this eventually. Can you put it on the todo list? even
if we never get around to it here, I want to be reminded about it until I
go work on it."

And on recovering what changed, 2026-10-19: "can we append a second half
of the checksum to a "private key" that we store in triple duplicate? We
can have 9 things that all agree on something, like a triforce, if we need
to. Then, it should be a reversible checksum, that we can use to calculate
backwards when we know that something has changed."

## Current Behavior

Both disks are ext4 (`df -T`, 2026-10-19): `/mnt/mtwo`, 822 GB, 96% full;
`/mnt/kaun`, 3.8 TB, 40% used. ext4 checksums its own bookkeeping, not the
contents of files, so a file whose bytes change on the disk reads back
wrong with no error. What git tracks is guarded already: every file is
stored under a fingerprint of its contents, and `git fsck` finds any that
no longer match; the projects push to GitHub. What git does not track
(the databases, the game data, the built servers, the cut books, files
ignored on purpose) has no check and no second copy.

## Intended Behavior

1. **Damage is noticed.** Every file that matters can be checked against
   a fingerprint taken when it was known good, on a schedule, and a
   mismatch is reported, never silently read.
2. **Damage can be undone.** For the files that matter most, recovery data
   (Reed-Solomon codes, as the `par2` tool makes) lets the original bytes
   be worked out again from the damaged file, up to the share of damage the
   recovery data was made for (10% recovery data mends up to about 10%
   damage). This is the owner's "reversible checksum": a plain fingerprint
   can't be reversed, recovery data can.
3. **Agreement decides.** The fingerprint lists and recovery data are kept
   in three places; where they disagree, what two of three say is taken
   (majority voting, the owner's "9 things that all agree"). A fingerprint
   made with a secret key (a keyed hash, or git's signed commits) also
   shows whether a file was changed on purpose, which a plain fingerprint,
   recomputable by anyone after an edit, can't.
4. **A deletion doesn't spread.** Backups keep earlier versions
   (snapshots), so a file deleted or damaged today is still whole in
   yesterday's copy.

## Suggested Implementation Steps

1. List what matters and where it lives: the projects (git), the
   databases (`mysql/databases/`), the game data (`data-files/`), the built
   servers (rebuildable), the cut books (rebuildable by E059).
2. Fingerprints first, as they cost little: a tool that writes a list of
   every untracked file's fingerprint (sha256) and size, and checks it; the
   list committed to the project (so on GitHub), refreshed when files are
   meant to change.
3. Recovery data for what can't be rebuilt (the databases' backups, the
   game data): `par2` at a chosen share, kept on both disks and one more
   place. GitHub can hold it only for small sets (it limits file and
   repository size).
4. A filesystem that checksums contents: btrfs or ZFS. Either detects
   damage on every read and on a "scrub"; either repairs it only from a
   second copy (a second disk, or stored twice on one, which halves the
   space). Moving `/mnt/kaun` means copying its 1.4 TB somewhere first;
   `btrfs-convert` changes ext4 in place but is safe only with a backup.
5. Snapshots of the projects and databases on a schedule.

## Open Questions

1. Which first: fingerprints and recovery data on the disks as they are,
   or the move to btrfs or ZFS?
2. A third place for the copies: a third disk, another computer, or a
   service?
3. The private key for keyed fingerprints: where is it kept, and in how
   many copies?
