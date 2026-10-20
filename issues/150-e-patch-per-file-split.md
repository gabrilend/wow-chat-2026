# 150 - E-Patch Per-File Split

## Status
- Created: 2026-06-03
- Phase: 1 (Foundation)
- Priority: Medium (cleanup; system works without this, but pipeline isn't uniform)
- Related: 189 (2026-10-20: each patch's header names its profiles and
  priority, read from the folder; the split here is part of that)
- State: split 2026-10-20 (the owner: "let's work on this issue file
  then"); waits on the owner's next install of a profile to see the steps
  run from their own files (step 5), then completed

## Current Behavior (2026-10-20)

Split by `scripts/split-install-steps` (a one-time tool): the 63 install
steps are one file each, `patches/E0NN-<name>.sh`, named after their
functions; the 10 helpers they share (`_register_with_updatefetcher`,
`_unregister_from_updatefetcher`, `_profile_db_name`, `_mirror_staged_sql`,
`_sql_install_stamp`, `_forget_unprefixed_updates`, `_shared_sql_src`,
`_buddy_sql_src`, `_beta_two_side_step`, `apply_config_values`) and the two
globals (`DIR`, `STAGED_SQL_DIRS`) are in `patches/E-helpers.sh`; and
`patches/E-patches.sh` is a 17-line loader that sources the helpers and
then every `E[0-9][0-9][0-9]-*.sh`. It was kept rather than deleted (step 6)
because `patches/patches.sh` and five tests source it, and the runner
finds each step's functions by name once loaded, so nothing that loads
it changed. The tool proved the split changed no code: the old file and
the loader were each sourced in a clean shell and every function's code
and both globals compared (2,249 lines of definitions, identical).

Found while splitting: E057's block was written inside E054's (E054's
closing fold marker sat after E057's); the markers were moved first.

Three scripts read the old file's text and were pointed at the new files:
`scripts/check-issue-references` (a step is live when its
`patches/E0NN-*.sh` file exists), `scripts/test-forget-unprefixed-updates`
(lifts its helper out of `E-helpers.sh`); comments naming the old file for
a helper or a step now name the new one. Tests run after the split, all
passing: the profile settings test (three profiles), the SQL mirror, the
old-names tidy-up, beta's permissions, basic's and beta's SQL in RAM, and
beta's Lua loading.

Which steps a profile runs, and their order, are still its lists in
`patches/patches.sh`; issue 189 replaces those with a header in each file.

The split tool is kept for one commit as a record, then renamed
`scripts/split-install-steps-done` and removed the commit after: it
refuses to run on the loader, so it has no further use.

## Overview

`patches/E-patches.sh` is a single 1071-line file containing ~15
individual `patch_E###` functions, two shared helpers
(`_register_with_updatefetcher`, `_unregister_from_updatefetcher`), and
the `apply_config_values` function that sources C-patches.

The B and C patch families have already moved to per-file shape (one
file per patch, glob-sourced by the orchestrator). The E family is the
last holdout. Aligning E with B and C makes the pipeline uniform across
all three families.

## Current Behavior

```
patches/
├── patches.sh              ← orchestrator (glob-sources B-patches, sources E-patches.sh)
├── B001-aoe-loot.sh        ← one file per B-patch ✓
├── B002-playerbots.sh
├── ... (B003 through B024)
└── E-patches.sh            ← MONOLITHIC: 1071 lines, 15 patches + helpers
    ├── _register_with_updatefetcher    (helper)
    ├── _unregister_from_updatefetcher  (helper)
    ├── apply_config_values             (sources C-patches from config/patches/)
    ├── patch_E001_lua_script_symlinks
    ├── patch_E004_log_directory_setup
    ├── patch_E005_dk_levelstats
    ├── patch_E006_initialize_config_files
    ├── patch_E007_vanilla_starting_zones
    ├── patch_E008_vanilla_remove_flight_paths
    ├── patch_E009_vanilla_starting_equipment
    ├── patch_E010_vanilla_pretrain_abilities
    ├── patch_E011_beta_dk_class_system
    ├── patch_E012_beta_drop_creatures_keep_essential
    ├── patch_E013_beta_quest_spells_to_trainers
    ├── patch_E014_beta_trainer_spell_level_cap
    ├── patch_E015_beta_class_selector_npcs
    ├── patch_E016_beta_empty_loot_chests
    └── patch_E017_beta_relocate_logout_texts
```

Problems:
- Editing one E-patch shows the whole 1071-line file in git history
- Cross-patch merge conflicts when two changes touch the same file
- The B/C/E layout is asymmetric, which makes the pipeline harder to
  reason about for new contributors
- The shared helpers and `apply_config_values` are buried inside what's
  otherwise a per-patch file

## Intended Behavior

After this issue lands:

```
patches/
├── patches.sh              ← orchestrator
├── _helpers.sh             ← _register_with_updatefetcher,
│                             _unregister_from_updatefetcher,
│                             apply_config_values (all moved here from E-patches.sh)
├── B001-aoe-loot.sh        ← unchanged
├── B###-*.sh               ← unchanged
├── E001-lua-script-symlinks.sh
├── E004-log-directory-setup.sh
├── E005-dk-levelstats.sh
├── E006-initialize-config-files.sh
├── E007-vanilla-starting-zones.sh
├── E008-vanilla-remove-flight-paths.sh
├── E009-vanilla-starting-equipment.sh
├── E010-vanilla-pretrain-abilities.sh
├── E011-beta-dk-class-system.sh
├── E012-beta-drop-creatures-keep-essential.sh
├── E013-beta-quest-spells-to-trainers.sh
├── E014-beta-trainer-spell-level-cap.sh
├── E015-beta-class-selector-npcs.sh
├── E016-beta-empty-loot-chests.sh
└── E017-beta-relocate-logout-texts.sh
```

And `patches.sh` glob-sources E-patches the same way it does B-patches:

```bash
for f in "${PATCHES_DIR}"/E[0-9][0-9][0-9]-*.sh; do
    [[ -f "${f}" ]] && source "${f}"
done
```

`apply_config_values` (currently inside E-patches.sh) moves up to either
`patches.sh` or `_helpers.sh`, called from the build script directly.

## Implementation Steps

1. Create `patches/_helpers.sh` with `_register_with_updatefetcher`,
   `_unregister_from_updatefetcher`, and `apply_config_values` (copied
   from E-patches.sh)
2. Source `_helpers.sh` from `patches.sh` early (before any patch file
   sourcing)
3. For each `patch_E###` function in E-patches.sh, create a new file
   `patches/E###-name.sh` with just that function and its surrounding
   comments
4. Update `patches.sh` to glob-source `patches/E[0-9][0-9][0-9]-*.sh`
5. Verify each E-patch fires correctly on a test profile build
6. Delete `E-patches.sh` once all patches are split out
7. Commit as a single refactor with reference to 119

## Risks

- Bash sourcing order matters if any E-patch depends on a helper defined
  in a sibling. Walk the existing file carefully to identify any cross-
  references before splitting.
- The `patch_needs_applying_*` and `unpatch_*` companion functions (if
  any) need to move with their patch.
- E-patch ordering in the profile registry (`PHASE_END_PATCHES`) must
  continue to apply in the declared order, not the glob order. Verify
  the orchestrator walks the profile's declared list rather than the
  glob result.

## Related

- [119 - Config Value Orchestrator](completed/119-config-value-orchestrator.md)
  — established the per-file pattern for C-patches; this issue extends
  it to E-patches
- B-patch layout (in `patches/B###*.sh`) is the reference shape this
  follows
