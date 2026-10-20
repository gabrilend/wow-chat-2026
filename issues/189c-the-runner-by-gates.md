# 189c - The Runner by Gates

## Status
- Created: 2026-10-20
- Phase: 1 (Foundation & Tooling)
- Parent: 189
- Blocked by: 189b
- Blocks: 189d, 189e, 192
- State: built 2026-10-20; waits on the owner compiling each profile once
  (step 7), the only way to see the whole build run from the headers

## Current Behavior

Built 2026-10-20. Nothing lists a profile's patches by hand any more; each
patch's header is what puts it on a profile and says when it runs.

- **The planner**, `scripts/plan-patches`, reads every patch's header
  (`patches/B*.sh`, `patches/E*.sh`, `config/patches/C*.sh`, through
  `scripts/lib/patch-header.lua`) and writes, for a profile, the patches
  it takes, lowest priority first, ties in id order (same-priority patches
  may run in any order, so a fixed one keeps runs alike). A header's
  profiles are names from `scripts/profiles`, groups from `patches/groups`,
  `all` or `none`. It stops, naming every fault, on: a broken header; a
  patch file with no header; a profile name that is none of those; a
  priority that sits on a gate. `--stage source|install|sql` gives the
  part below the first gate, between the first and second, between the
  second and third; `--every-profile` gives all of them as
  `stage|profile|ids` lines (30 ms for every profile).
- **The gates**, `patches/gates`: 1000 compile and install, 2000 the
  databases brought to upstream's state, 9000 the server may start. One
  for each stage the build already had (the owner: "However many sections
  we have now, that's how many we should have").
- **The runner**, `patches/patches.sh`, asks the planner once as it loads
  and fills the lists every script already reads (source patches; install
  stage; and the SQL stage's, empty until 189d). A planner fault stops the
  load with the planner's message. It also sources every settings patch,
  so their functions are there for the install stage.
- **Settings patches are install-stage patches.** They used to run all
  together inside E006 (`apply_config_values`); now each runs at its own
  priority (1100-1300, after E006 at 1060 has made the config files),
  through `apply_settings_patch` in `patches/E-helpers.sh`, which finds
  the function from the file's name and writes into the install being
  built. A failing one stops the install like any step (inside E006 a
  failure was lost: E006's last line was an assignment, which always
  succeeds). Their undo is E006's (it removes the config files); the undo
  walk skips them. `apply_config_values` stays, for
  `scripts/test-profile-config-gates`: it runs the profile's settings
  patches from the same list, trying every one so all failures are named.
- **Undo is the exact reverse** of the apply, both stages (done before
  189c; `scripts/test-patch-undo-order`).
- **The layering check**, in `scripts/test-source-patches`: as each source
  patch applies, the files whose content it really changed are written
  down; two patches of one priority that change the same file are an
  error naming both and the file. Today every source patch has its own
  priority, so none clash; the overlaps that exist (B002 and B026 in the
  bot manager, B026 and B027 in the bot engine) are at different
  priorities, in the order they are laid.
- **Removed:** the hand-written lists (kept word for word, with their
  notes, in `docs/patches/profile-patch-history.md`) and the settings
  patches' `CONFIG_PROFILES` lines.
- **New patches** get their header from `scripts/add-patch-header FILE
  --profiles "..."` (the id from the name, the kind from the folder, the
  priority by the numbering rule unless given). `scripts/merge-install-steps`
  gives a joined step the first step's header, and refuses steps not
  taken by the same profiles.

Checked: the planner reproduces the old lists exactly for all six
profiles; the settings each profile's install writes are identical to the
old runner's (config files compared line by line, all six profiles);
the source patches apply, pass the layering check and round-trip on
beta, basic, cc-test, vanilla and release (alpha takes none); the
layering check, given a clash on purpose in a copy (B026 at B002's
priority), fails naming both and the bot manager's file; the merge tool,
on a copy, joined two of beta's steps and the plan ran the joined one in
the first's place; all 50 quick tests pass.

**Not done here:** patches of one priority run one after another in id
order, not at the same time: allowed by the design ("at the same time, or
in an arbitrary order"), and the install steps share files and MySQL, so
running them at once would need more than this. The SQL stage between
gates 2000 and 9000 is planned and empty until 189d.

## Intended Behavior

The runner reads the headers of every patch a profile takes (by name or
through a group), sorts them by priority and runs them through the gates
(`patches/gates`): at each gate it finishes every patch below it, then
does the gate's action (compile and install; databases to upstream's
state; the server may start). Patches of one priority may run in any
order. Undo is the exact reverse. Two patches that touch the same file
may not share a priority (an error naming both). A broken header stops
the run; skipped files are listed. The lists in `patches/patches.sh` and
the settings patches' `CONFIG_PROFILES` lines are removed.

## Suggested Implementation Steps

1. `patches/gates`.
2. `scripts/plan-patches`, reading headers through
   `scripts/lib/patch-header.lua`; the runner fills its lists from it.
3. The settings patches into the install stage: `apply_settings_patch`,
   E006 no longer running them, `apply_config_values` from the plan.
4. Remove the `CONFIG_PROFILES` lines (a `sed` over the settings files,
   then `scripts/check-patch-headers --fix-lines`).
5. The readers of the old list text: `scripts/test-ale-method-names` asks
   the planner; `scripts/merge-install-steps` carries headers.
6. Tests: `scripts/test-patch-plan` (a pretend project in RAM: order by
   priority across kinds, ties by id, stages between gates, a group, a
   test never planned, `add-patch-header`'s rules, every fault named, the
   real project's plans; and the compile's quick tests are those marked
   so); the layering check in `scripts/test-source-patches`.
7. The owner compiles each profile once; the build's report lists every
   patch as before, the settings now among the install steps.

## Files retired

- `scripts/write-patch-headers` → `-done`: it wrote headers from the
  lists, which no longer exist; `scripts/add-patch-header` writes one for
  a new patch. Remove after one commit.
- `scripts/test-patch-headers-match-lists` → `-done`: it compared headers
  with the lists; its last live check (the quick tests marked in headers
  are the compile's list) moved into `scripts/test-patch-plan`. Remove
  after one commit.
