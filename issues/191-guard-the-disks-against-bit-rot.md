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

And, 2026-10-26, when the public game was planned onto rented Linode
machines (157g): "to that end, we should create a tool or utility that
allows us to push them and their filesystem protection to the cloud
location, storing the discrepancies and checksums of the two
filesystems."

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

### The mirror to the cloud (2026-10-26)

One tool, `scripts/mirror-to-cloud [DIR] <set>`, pushes a chosen set of
files from the disks to the cloud location together with their
protection, and keeps a record of where the two copies disagree:

| It sends | Why |
|---|---|
| the files of the set, only those whose fingerprint changed since the last push | the cloud copy is the second copy a repair needs |
| the set's fingerprint list (path, size, BLAKE2b, time it was fingerprinted) | the cloud side can be checked without the disks |
| the recovery data (`par2`) for the set | damage on either side can be mended without the other |

On each run, before sending, it fingerprints both sides (the disk, and
the cloud copy, fingerprinted where it is stored so its bytes need not
come back) and writes `discrepancies/<date>.tsv`, one line per path whose
two fingerprints differ or that exists on one side only:

| Column | Meaning |
|---|---|
| path | relative to the set's root |
| disk fingerprint, disk size, disk time | what the disk holds now |
| cloud fingerprint, cloud size, cloud time | what the cloud holds now |
| last agreed fingerprint | from the previous run's list, where both matched |
| verdict | which side still matches the last agreed fingerprint: "disk changed", "cloud changed", "both changed", "missing on disk", "missing in the cloud" |

The tool never overwrites a disagreeing file in either direction by
itself. A file that changed on purpose (the person edited it, git
committed it) is pushed when its set is marked as meant to change; a
file that changed with nobody asking (the verdict says one side drifted
from the agreed fingerprint) is reported, and its repair, from the other
side or from the recovery data, is a separate command the person runs
after reading the report. The discrepancy files are themselves kept, in
three places (point 3 above), so the history of disagreements survives
the damage it describes.

**The third witness is an observer.** Asked what decides when both
copies changed since they last agreed, the owner, 2026-10-26: "any
observer looking and thinking 'hmmm, that's not right...'". So the
discrepancy report is put where people and agents look (a page in the
project's documentation, and an rmail message to the owner), and any
observer can mark a line "that's not right", or "that's right", with
who and when. The marks are kept with the report; a repair names the
marks it acted on.

The run ends with a goodbye receipt: files fingerprinted on each side,
files sent, bytes sent, discrepancies by verdict.

Sizes today, for choosing the first sets: `du -sh` of each candidate
(the databases' folder and the game data are a few gigabytes each; the
whole of `/mnt/kaun` is over a terabyte).

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
6. `scripts/mirror-to-cloud` as described above: the set definitions
   (`config/mirror-sets.lua`: a name, a root folder, what to leave out),
   the two-sided fingerprinting, the discrepancy file, then the push.
   Test against a "cloud" that is a scratch folder in RAM: a byte changed
   on one side is reported with the right verdict and not copied over; a
   file deleted on one side is reported as missing; an unchanged set
   sends nothing.

## Open Questions

1. ~~Which first~~. Answered 2026-10-28: "I guess btrfs or ZFS or
   similar." The filesystem that checksums file contents comes first;
   which one is chosen when it is built (both need a full copy of a
   disk's contents elsewhere first, step 4).
2. ~~A third place for the copies~~. Answered in part 2026-10-26: "the
   cloud location". Which kind: Linode's object storage (files kept by
   Linode, paid by the gigabyte, fingerprinting there means reading them
   back unless the storage reports its own checksums), or a disk on a
   rented machine of our own (the tool runs its fingerprinting there,
   nothing is read back)? And which sets go first: this project's
   databases and game data, or whole disks? The owner, 2026-10-28:
   "let's talk about this when it's time to build it."
3. The private key for keyed fingerprints: where is it kept, and in how
   many copies?
