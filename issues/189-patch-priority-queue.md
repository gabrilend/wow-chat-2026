# 189 - Every Patch Says Its Own Priority, Run Through Gates

## Status
- Created: 2026-10-19
- Phase: 1 (Foundation & Tooling)
- Related: 183 (our SQL after upstream's: the `z_` names this replaces),
  127 (patch system improvements: apply and revert), 150 (the install
  steps, one file each since 2026-10-20), `patches/patches.sh` (the
  per-profile lists this replaces)
- Blocks: 192 (the econ profile layers its patches on basic's)
- Sub-issues: 189a-189f (below)
- Priority: Medium
- State: in progress (2026-10-20); the undo order is fixed, 189a under way

## Origin

Verbatim, the owner, 2026-10-19, on the 35 start-up warnings left by
issue 183's renaming:

> we need to make a better sorting system. Can you create a "priority"
> queue that each patch has a simple integer, and we start with the lowest
> integers first and then move up to the largest?

And on the fix that removed the old names' records:

> this seems a little convoluted. Why remove files? Why not unpatch, as
> we're supposed to do, instead?

On a folder instead of lists, 2026-10-20:

> it's fine if the patch lists are one file. Though, it would be better to
> have a directory for them, and to parse everything from that directory
> (except files which don't have a specific header, length in lines in the
> header and footer, and footer)

and of the compile's quick-test list: "should be the same system". Shown
the header and footer below, and asked whether a broken header should stop
the run while a missing one is only listed: "Sure."

On what the number orders, 2026-10-20:

> all patches should be treated the same. Only their destinations and
> contents may differ, alongside their priority. Right now we have several
> stages - instead, we should have "gates" where a certain priority number
> is specified, and once we pass that threshold then all the patches with a
> higher priority number can be run. For example, let's say we have patches
> 1-5 which have to run in the first stage, we'd set the next gate to be 6
> so that any patch that is greater than 6 won't run until all the patches
> 1-5 have run (there could be multiple per priority, so like 3 patches for
> priority 1, then 2 for priority 2, then 17 for priority 3, etc) patches
> in the same priority number should be able to run at the same time, or
> in an arbitrary order.

On undoing (to wow-chat-2026-ae, for issue 192): "We definitely need to
undo them the same order we applied them, but reversed."

What the econ profile (192) needs, from wow-chat-2026-ae, 2026-10-20: a
profile taking a subset of basic's patches (its buddy and Sargobras ones
and a few stock fixes), perhaps through a named group several profiles
list; its own patches laid over basic's, at higher priorities, with a
check that two patches touching the same file are not left at the same
priority; and a patch that carries its own files (Sargobras's Lua, the
buddy SQL), placing them into each profile that takes it and removing them
on undo.

## Current Behavior

Since 189c (2026-10-20) every patch carries a header (189a, 189b) and the
headers alone say which profiles take it and when it runs:
`scripts/plan-patches` reads them and the runner (`patches/patches.sh`)
builds its lists from that; the hand-written lists are gone. Today's
build, in order (`scripts/compile`, `patches/patches.sh`):

1. the quick tests (each test whose header says so, 189f);
2. the source patches (`B*`), by priority, below gate 1000;
3. the compile and the install (gate 1000);
4. the install-stage patches by priority, between gates 1000 and 2000:
   install steps (`E*`) and settings patches (`C*`) mixed, the settings
   each in its own turn after E006 has made the config files;
5. the source patches undone; since 2026-10-20 last first
   (`_reversed_list`, `scripts/test-patch-undo-order`; until then front to
   back, found by wow-chat-2026-ae for 192), and the install steps' undo
   likewise;
6. later, at the server's start, its database updater applies upstream's
   SQL and then ours: our steps copy SQL into folders registered with the
   updater, renamed `z_` (183) so they sort after upstream's by name; the
   updater remembers files by name, so a rename leaves two records, which
   `_forget_unprefixed_updates` removes (the symptom, not the cause).

Since 189d (built, not yet compiled), step 6 is split by gate 2000: the
compile starts the shadow server once after step 4, so upstream's updates
are applied; then the SQL steps place ours under their own names, and the
validation start applies them. Not yet: carried files (189e).

## Intended Behavior

**One kind of thing, a patch.** A source edit, a setting, an install step
and an SQL file are all patches: a file with a header and a footer saying
what it is, which profiles take it and its priority. They differ only in
their contents and where they go (189a).

**One number line, with gates.** Every patch has one integer priority on a
single line shared by all kinds. A gate is a priority number with an action
the build takes when it is reached; no patch at or above a gate runs until
every patch below it has finished and the gate's action is done. Patches of
the same priority may run at once or in any order. The gates, in a file of
their own (`patches/gates`), one for each of today's stages, no more (the
owner, 2026-10-20: "However many sections we have now, that's how many we
should have with the newly numbered system"):

| gate | action when reached | patches below it |
|---:|---|---|
| 1000 | compile and install | source patches (they come off again once the compile is through) |
| 2000 | the databases brought to upstream's state (the shadow server started once, its own updater running; 189d) | settings, links, files |
| 9000 | the server may start | the steps handing our SQL to that updater, by priority |

**Undo is the exact reverse**: last priority first, back through the
gates, a source patch's undo after the compile gate as today.

**Which profiles.** A header names its profiles, or a group a file of
groups defines (for example a `buddy-set` taken by basic, cc-test and
econ), so adding a profile to a set of patches is one line.

**Layering, checked.** Two patches that touch the same file may not share
a priority, so which lies over which is never left to chance.

**Carried files.** A patch may carry files of its own, kept beside it in
git, placed into each taking profile's install when applied and removed
when undone.

**Our SQL after upstream's, by time.** The SQL steps run after the gate
where upstream's are applied, in priority order, and hand our files to the
server's own updater, which applies them at the next start (the owner,
2026-10-20: "we should use their updater since I think they're quite
proud of it"; this replaced a first plan of our own record table). The
`z_` names and `_forget_unprefixed_updates` go (189d).

**Lists made from the headers.** The quick tests are gathered from their
headers; the English lists that can drift today (`docs/patches/patch-registry.md`,
the patch sections of `docs/profiles/*.md`) are written from the headers.
The settings test's expected-values table stays as it is: it is the
independent second statement the test checks the patches against.

## Sub-issues

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 189a | the-header-and-its-reader | None | The header and footer's exact shape; a reader that parses a file's header, telling whole, broken and absent apart; a checker listing every patch and every skipped file; tests |
| 189b | headers-on-every-patch | 189a | A tool writes a header into every patch and quick test from today's lists (priorities keeping today's order, gaps between), with the groups file; a test that the headers say what the lists say |
| 189c | the-runner-by-gates | 189b | The runner reads headers instead of lists, runs by priority through the gates, same priority in any order, undo exactly reversed, the layering check; the lists are removed |
| 189d | sql-as-patches | 189c | Our SQL run by our runner after upstream's, by priority, recorded in our table; the registrations, `z_` names and the old-names tidy-up removed |
| 189e | carried-files | 189c | Patches carry files (Sargobras's Lua, the buddy SQL, the buddy module) and place and remove them per profile |
| 189f | lists-from-headers | 189b | The quick tests gathered by header; the patch registry and the profile pages' patch lists written from the headers |

Order: 189a → 189b → 189c → 189d, 189e (either order), with 189f any
time after 189b.

## Suggested Implementation Steps

The sub-issues, in the order above. Done ahead of them, 2026-10-20: the
undo of both stages runs last first (`_reversed_list` in
`patches/patches.sh`; `scripts/test-patch-undo-order`, a quick test),
which 189c's exact-reverse undo keeps.

## Open Questions

1. (Answered 2026-10-20) What the number orders: everything, one line,
   gates between ("all patches should be treated the same").
2. (Answered 2026-10-20, by the same answer) One scale for all kinds.
3. **Keep the old-names tidy-up until 189d lands?** It works and is
   tested; 189d removes it with the rest of the updater registration.
   Proposed: keep it until then.
4. (Answered 2026-10-20: "Sure.") The header and footer's shape: 189a.
