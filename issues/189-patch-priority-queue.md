# 189 - A Priority Number for Every Patch, Run Lowest First

## Status
- Created: 2026-10-19
- Phase: 1 (Foundation & Tooling)
- Related: 183 (our SQL after upstream's: the `z_` names this would replace),
  127 (patch system improvements: apply and revert), 150 (the install
  steps), `patches/patches.sh` (the per-profile lists)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, the owner, 2026-10-19, on the 35 start-up warnings left by
issue 183's renaming:

> we need to make a better sorting system. Can you create a "priority"
> queue that each patch has a simple integer, and we start with the lowest
> integers first and then move up to the largest?

And on the fix that removed the old names' records:

> this seems a little convoluted. Why remove files? Why not unpatch, as
> we're supposed to do, instead?

## Current Behavior

Two orders, each decided somewhere different:

- **Patches** (`B*` source patches, `C*` settings, `E*` install steps) run
  in the order each profile's list writes them in `patches/patches.sh`
  (`PHASE_BEGIN_PATCHES`, `PHASE_END_PATCHES`), reverts in reverse. A
  patch's place is a position in a string, repeated per profile, kept
  right by hand: inserting one means editing every list that has it.
- **Our SQL** is applied by the server's own database updater, which runs
  every file of every folder it knows in file-name order. Upstream's files
  are named by date (`2026_09_23_00.sql`); ours (`04-buddy-roster.sql`)
  sorted before them, so issue 183 renamed every one with a `z_` prefix in
  a mirror folder. The updater remembers what it applied by name, so the
  rename left each file recorded twice, and the server warned 35 times at
  every start. `_forget_unprefixed_updates` (2026-10-18) deletes the old
  records; it treats the symptom, and any later rename would do it again.

## Intended Behavior

Every patch declares one integer, its **priority**, in its own file
(`PRIORITY=40` near the top, beside its description). The runner gathers
the patches a profile uses, sorts them by priority, and applies the lowest
first; reverts run highest first. Equal numbers keep a fixed order (by
patch id), so a run is always the same. A profile's list says **which**
patches it uses, no longer **in what order**.

Numbering leaves gaps (10, 20, 30, ...) so a patch fits between two
without renumbering. A small tool lists every patch with its number and
the profiles that use it, and flags two patches that must not share one.

For SQL (open question 1), the priority also decides when a step's SQL
runs relative to upstream's and to our other steps, without the name
carrying the order. And a rename, or a priority change, is handled the
house way, by **unpatching** the old and patching the new (the revert SQL
runs, then the new file), never by editing the updater's records.

## Suggested Implementation Steps

1. Answer the open questions.
2. `PRIORITY=` in every patch file, first set from today's order in the
   basic profile's lists (gaps of 10), so nothing changes order on day
   one; a check that every patch has one.
3. The runner in `patches/patches.sh` sorts by it; the lists become sets.
   A test runs a pretend set of patches out of order and checks they run
   lowest first and revert highest first.
4. `scripts/list-patch-priorities`: number, id, profiles, description.
5. SQL, per the answer to question 1.
6. With the unpatch rule in place, remove `_forget_unprefixed_updates`.

## Open Questions

1. **Which patches does the number order?** (a) the patches only (B, C,
   E), with our SQL keeping the updater's name order; (b) the patches and
   their SQL, our SQL run by our own step in priority order and recorded
   in a table of ours, after the server has applied upstream's; or (c)
   only our SQL. (b) is what removes the `z_` names; it is the largest.
2. **Separate scales or one?** One number line for B, C and E together,
   or one per kind (source patches before building, settings and install
   steps after)? They already run at different times, so one per kind
   reads more simply.
3. **Keep the old-names tidy-up until this lands?** It works and is
   tested; or revert it now and accept the 35 warnings until the unpatch
   rule replaces it.
