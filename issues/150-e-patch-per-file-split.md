# 150 - E-Patch Per-File Split

## Status
- Created: 2026-06-03
- Phase: 1 (Foundation)
- Priority: Medium (cleanup; system works without this, but pipeline isn't uniform)

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
