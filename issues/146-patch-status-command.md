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
**currently active profile**, which patches in each tier were **actually
applied to the currently running build** — not which ones are scheduled to
apply on the next rebuild.

The difference matters: scheduled = "what `patches.sh` would do if compile
ran right now," applied = "what actually ran into the live binaries and
configs." If a patch was added to the array yesterday but you haven't
rebuilt since, scheduled vs applied diverge. The operator usually wants
**applied** — that's what describes the system they're staring at.

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

### The build manifest — source of truth for "applied"

To know what's actually applied (not just scheduled), the build itself
needs to **write a manifest** at the moment of promotion. The manifest is
a plain text file produced once per successful build, capturing the exact
patch set that crossed the validate gate and landed in the profile dir.

**Location:** `installed-files-{profile}/etc/build-manifest.txt`

**Written by:** `scripts/promote` (and/or `scripts/compile` after
PHASE_CONFIG completes), at the moment the shadow tree becomes the live
profile tree.

**Format:**

```
# Build Manifest
# Profile: release
# Built:   2026-05-14T18:42:13-04:00
# Source:  source-beta @ dd2672641 (Merge pull request #195 from mod-playerbots/test-staging)
# Boost:   1.81.0

[PHASE_BEGIN]   12 patches applied
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

[PHASE_END]     2 patches applied
E004  log-directory-setup
E006  initialize-config-files

[PHASE_CONFIG]  10 patches applied
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

Total: 24 patches applied for profile 'release'.
```

The patch-status command then becomes **a simple reader** of this file:

```bash
./scripts/patch-status               # prints the manifest as-is
./scripts/patch-status --tier=BEGIN  # prints just the PHASE_BEGIN block
./scripts/patch-status --diff        # diffs manifest against current
                                     # patches.sh scheduling — shows
                                     # "what would change on next rebuild"
```

This split has nice properties:

- **The manifest is permanent record** — it stays in `etc/` between builds,
  travels with the deployment, can be committed if you want history (the
  manifest itself is small enough that committing it is reasonable).
- **No live inspection needed.** The status command doesn't have to run
  `grep` against source trees or check file timestamps. It reads a text
  file. Fast and reliable.
- **The diff feature is the upgrade path** — if scheduled ≠ applied, the
  operator immediately sees *which* patches are pending and can decide
  whether to rebuild.

### Minimum viable subset

The MVP splits cleanly into two halves:

**Half A — write the manifest** (in `scripts/promote` and/or
`scripts/compile`):

1. After PHASE_CONFIG completes, gather the lists of patches that ran in
   each tier (the orchestrator already iterates these — capture as it
   goes).
2. Write the manifest text to `installed-files-{profile}/etc/build-manifest.txt`.
3. Include a header with profile, build timestamp, source commit, boost
   version.

**Half B — read the manifest** (new `scripts/patch-status`):

1. Locate the manifest for the active profile (`installed-files-{profile}/etc/build-manifest.txt`).
2. Print it. Optionally accept `--tier=<NAME>` to filter.
3. Fall back to a clear "no manifest — has a build been promoted yet?"
   message if the file is absent.

The `--diff` mode is a follow-up enhancement: compare manifest patch lists
against the current `patches.sh` arrays for the same profile, report any
patches scheduled-but-not-applied or applied-but-no-longer-scheduled.

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

- **New:** `scripts/patch-status` — the reader, prints the manifest.
- **Modified:** `scripts/promote` (or `scripts/compile` post-PHASE_CONFIG) —
  writes `installed-files-{profile}/etc/build-manifest.txt` at promote time.
- **New file produced at build time:** `installed-files-{profile}/etc/build-manifest.txt`
  — the manifest itself; written by the build, read by the status command.
- **No changes to:** `patches/patches.sh`, `patches/B###-*.sh`,
  `config/patches/C###-*.sh` — these are unmodified producers of patch
  application; the manifest captures *what they did*, not what they are.

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
