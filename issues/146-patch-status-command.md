# 146 - Patch Status Command

## Status
- Created: 2026-05-14
- Phase: 1 (Foundation — patch system tooling)
- Priority: Medium (improves debuggability; not a blocker for any build)

## Problem

Currently there is no way to ask the build system *"which patches are in the
build that's running right now?"* When something behaves oddly — a setting
not taking effect, a feature missing, a bug returning — the operator has to
read the patch registry by hand and infer state from `git status`, file
timestamps, and `grep` against the source tree. That works but it's slow and
error-prone.

The patch system has three application times (PHASE_BEGIN / PHASE_END /
PHASE_CONFIG — see issue 127). A status command should report, for the
**currently active profile**, which patches in each tier are scheduled to
apply and (where detectable) whether they appear to be applied right now.

## Intended Behavior

A new subcommand on the existing patch orchestrator:

```bash
./scripts/apply-patches --status
```

…or as a sibling script:

```bash
./scripts/patch-status
```

The output should be **short, scannable, and grouped by tier**. Names are
sufficient — we don't need to dump every patch's full diff. The point is to
let a human (or another script) ask: *"is B007 in this build?"* and get a
one-line answer.

### Example output

```
=== Patches for profile 'release' ===

PHASE_BEGIN (12 patches scheduled, source modifications):
  B004  upstream-warning-fixes
  B009  playerbots-equipment-slots-enum
  B010  playerbots-arena-type-none
  B011  ale-resurrect-signature
  B012  player-equipment-slot-sign
  B013  playerbots-logical-op-parentheses
  B014  playerbots-switch-enum-default
  B015  playerbots-implicit-float-conversion
  B016  playerbots-constructor-reorder
  B017  playerbots-unused-variables
  B018  playerbots-sign-compare
  B019  playerbots-unused-parameter

PHASE_END (2 patches scheduled, shadow install setup):
  E004  log-directory-setup
  E006  initialize-config-files

PHASE_CONFIG (10 patches scheduled, runtime config tuning):
  C001  database-connections
  C002  directory-paths
  C003  run-speed-80-percent
  C004  fall-damage-10x
  C005  exp-rate-2x
  C006a max-level-80
  C007a starting-level-40
  C008  gm-login-state
  C010  network-ports
  C011  realmlist-setup

Total: 24 patches across 3 application times for profile 'release'.
```

### Minimum viable subset

The first version doesn't need to detect *whether each patch is currently
applied to the tree* (that's harder — requires running each patch's
`needs_applying` check). The minimum useful behavior is simpler:

1. Iterate `PHASE_BEGIN_PATCHES[$PROFILE]`, print patch ID + name.
2. Iterate `PHASE_END_PATCHES[$PROFILE]`, print patch ID + name.
3. Iterate `PHASE_CONFIG_PATCHES[$PROFILE]` (or the C-patches array — naming
   subject to the orchestrator design landing in 127), print patch ID +
   name.
4. Print totals.

That's "what patches are *scheduled* for this profile." A future
enhancement could mark each line with `[applied]` / `[pending]` by running
the per-patch `patch_needs_applying_*` check (see issue 127 Phase E), but
the scheduled view alone is the load-bearing 80% of the value.

## Current Behavior

No status command exists. Operator inspects the patch lists by reading the
arrays in `patches/patches.sh` and `config/patches/` directly, then runs
`git status` on `source-{profile}/` to guess at applied state.

## Suggested Implementation Steps

1. **Decide on the surface.** Either:
   - Add `--status` flag to existing `scripts/apply-patches`, or
   - Create a new `scripts/patch-status` script.
   Recommendation: a sibling script, since the existing
   `scripts/apply-patches` is action-oriented and the status command is
   read-only.

2. **Source the patch definitions.** `source patches/patches.sh` to get the
   `PHASE_BEGIN_PATCHES` / `PHASE_END_PATCHES` associative arrays. Source
   the C-patches via the orchestrator path once it's established (depends
   on 127 Phase E work landing).

3. **Iterate and print.** Walk the active profile's patch ID list for each
   tier. For each ID, look up the patch's display name. Patch files
   conventionally embed their human-readable name in the second line
   comment (e.g., `# B009 - Playerbots Equipment Slots Enum`); a `grep + sed`
   on `patches/B###-*.sh` recovers it without parsing the full file.

4. **Format output.** Use the three-tier grouping shown above. Keep lines
   short. Pad patch IDs (`B009` vs `B019`) for visual alignment.

5. **Exit code.** Always 0 in MVP — status reporting doesn't fail. Reserve
   non-zero for "couldn't find patches.sh" or similar setup errors.

## Affected Files

- New: `scripts/patch-status` (recommended) OR addition to
  `scripts/apply-patches`
- No changes to: `patches/patches.sh`, `patches/B###-*.sh`,
  `config/patches/C###-*.sh` — this is a read-only consumer of those.

## Related Issues

- **127** patch-system-improvements — establishes the three-tier patch
  model that this command reports on. Phase E of 127 also references this
  status command as a downstream consumer.
- **145** playerbots-compile-fix-patches-B009-B010 — verifying that B009
  and B010 land in the scheduled set after activation is a natural use case
  for the status command.

## Notes

This is the kind of small piece of tooling that becomes invisible once it
works — operators stop wondering "is B007 in this build?" because they can
just *ask* and get an immediate answer. It also reduces a category of
support-style questions to a single command, which composes well with the
project's broader "tools beat manual inspection" preference.

A future enhancement: emit JSON when called with `--json`, so other tools
(an in-game admin panel, an HTML status page, a CI job that fails when an
unexpected patch lands) can consume the same information programmatically.
