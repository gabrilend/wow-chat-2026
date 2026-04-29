# 127 - Patch System Improvements

## Status
- Created: 2026-04-09
- **Implemented: 2026-04-09**
- Phase: 3
- Priority: Medium

## Current Behavior

### 1. Patches Are Not Reverted After Build
Patches are applied to source before compile but never reverted. This causes:
- Source directory accumulates patches over time
- `git status` shows modified files
- Unclear if a file is "clean upstream" or "patched"
- Re-applying patches relies on idempotent checks (grep before sed)

### 2. Documented Patches Not In Source
Four patches exist in `docs/patches/` with issues marked "Implemented" but **source changes are missing**:

| Patch | Issue | Issue Claims | Actually In Source? |
|-------|-------|--------------|---------------------|
| accuracy-level-cap.md | 156 | "Implemented 2026-04-05" | ❌ No (no ACCURACY_LEVEL_CAP in Unit.h) |
| ale-sell-item-hook.md | 150 | "Implemented 2026-04-05" | ❌ No (no ON_SELL_ITEM in Hooks.h) |
| ale-unit-setwalk.md | 332 | "Resolved 2026-04-08" | ❌ No (no SetWalk in UnitMethods.h) |
| ale-calculate-talents-hook.md | 205 | "Implementation 2026-04-06" | ❌ No (mod-talent-bonus exists locally but not linked to source-beta) |

**Root Cause:** Issue files were updated to "Implemented" but:
- Source changes were made in a session but never committed
- Or source was reset/re-cloned and changes were lost
- Or module created locally but never linked to source-beta/modules/
- The patch docs and issue files survived but the actual code didn't (or wasn't compiled)

### 3. No Patch Verification
No way to verify which patches are applied vs which should be.

## Intended Behavior

### 1. Clean Source After Build
```
Before build:  git stash (save any manual changes)
               apply patches
               compile
After build:   git checkout -- . (revert patches)
               git stash pop (restore manual changes)
```

Alternative: Use `git diff` to generate patches, apply with `git apply`, revert with `git checkout`.

### 2. All Documented Patches Implemented
Every patch in `docs/patches/` should have a corresponding function in `scripts/azerothcore`.

### 3. Patch Status Command
```bash
./scripts/azerothcore patch-status
# Output:
# B001 aoe-loot-item-namespace    [applied]
# B002 playerbots-ale-login-hook  [applied]
# B003 ale-gameobject-wildcard    [pending]  <- source not patched
# B004 upstream-warning-fixes     [partial]  <- 5/7 applied
```

## Implementation Steps

### Phase A: Re-implement Missing Patches ✓ (2026-04-09)
These patches were marked "Implemented" but source changes are missing:
1. [x] 156 accuracy-level-cap - Added as `patch_B005_accuracy_level_cap()`
2. [x] 150 ale-sell-item-hook - Added as `patch_B006_ale_sell_item_hook()`
3. [x] 332 ale-unit-setwalk - Added as `patch_B007_ale_unit_methods()`
4. [x] 205 ale-calculate-talents - Added as `patch_B008_mod_talent_bonus()`

### Phase B: Add Unpatch Functions ✓ (2026-04-09)
1. [x] Write `unpatch_B001_*` through `unpatch_B008_*`
2. [x] Create `unapply_patches_begin()` that calls all unpatches
3. [x] Add bash trap to ensure unpatches run on failure
4. [x] Integrated with cmd_update and cmd_compile

### Phase C: Reorganize Into Separate Files ✓ (2026-04-09)
Patches moved from inline in `scripts/azerothcore` to individual files:

**Directory structure:**
```
patches/
├── patches.sh                      # Loader: sources all B###-*.sh files
├── B001-aoe-loot-item-namespace.sh # patch + unpatch functions
├── B002-playerbots-ale-login-hook.sh
├── B003-ale-gameobject-wildcard.sh
├── B004-upstream-warning-fixes.sh
├── B005-accuracy-level-cap.sh
├── B006-ale-sell-item-hook.sh
├── B007-ale-unit-methods.sh
└── B008-mod-talent-bonus.sh
```

**patches.sh provides:**
- `apply_patches_begin()` - Apply all PHASE_BEGIN patches in parallel
- `unapply_patches_begin()` - Reverse all PHASE_BEGIN patches
- `patches_need_applying()` - Check if any patches need to be applied

**scripts/azerothcore now:**
- Sources `patches/patches.sh` instead of inline definitions
- Cleaner separation of concerns
- Easier to maintain individual patches

## Design Considerations

### Reverse Patch Approach (Preferred)
Each patch function should have a corresponding unpatch function that reverses its operations:

```bash
# Example: B004 patch and unpatch
patch_B004_upstream_warning_fixes() {
    # Apply: Add operator= default
    sed -i '/NextAction(NextAction const& o).*/{
        a\    NextAction\& operator=(NextAction const\&) = default;
    }' "${FILE}"
}

unpatch_B004_upstream_warning_fixes() {
    # Reverse: Remove operator= default
    sed -i '/NextAction\& operator=(NextAction const\&) = default;/d' "${FILE}"
}
```

**Build workflow:**
```bash
apply_patches_begin    # Apply all patches
do_build               # Compile
unapply_patches_begin  # Reverse all patches (whether build succeeded or failed)
```

**Benefits:**
- No git operations needed
- Source stays clean after build
- Each patch is self-contained with its reverse
- Works even if user has manual changes

**Caveat:** Unpatch operations must be idempotent (safe to run even if patch wasn't applied).

### Trap for Build Failures
Use bash trap to ensure patches are reversed even on error:
```bash
apply_patches_begin
trap 'unapply_patches_begin' EXIT
do_build
trap - EXIT  # Clear trap on success
unapply_patches_begin
```

## Related Files

- `scripts/azerothcore` - Sources patches.sh, uses patch functions
- `patches/patches.sh` - Loader script, orchestration functions
- `patches/B###-*.sh` - Individual patch files (patch + unpatch)
- `docs/patches/patch-registry.md` - Patch documentation index
- `docs/patches/*.md` - Individual patch documentation

## Phase D: Profile-Specific Patch Lists

### Current Behavior (2026-04-13)

Patch application is controlled by hardcoded conditionals:

**PHASE_BEGIN patches:** Completely disabled in patches/patches.sh
```bash
apply_patches_begin() {
    echo "PHASE_BEGIN patches DISABLED (vanilla baseline mode)"
}
```

**PHASE_END patches:** Hardcoded conditionals in scripts/azerothcore:785-803
```bash
apply_patches_end() {
    # All profiles: Log directory setup and config initialization
    patch_E004_log_directory_setup
    patch_E006_initialize_config_files

    # Beta only: Custom features
    if [[ "${PROFILE}" == "beta" ]]; then
        patch_E001_lua_script_symlinks &
        wait
        patch_E005_dk_levelstats
    fi
}
```

**Problems:**
1. Cannot enable specific patches per profile declaratively
2. Logic mixed with orchestration code
3. Adding new profile requires editing orchestration functions
4. Cannot test "what patches would apply for profile X"

### Intended Behavior

Declarative patch lists defined in patches/patches.sh:

```bash
# patches/patches.sh

# PHASE_BEGIN patches (pre-compile source modifications)
declare -A PHASE_BEGIN_PATCHES=(
    ["release"]=""                                    # Vanilla, no patches
    ["beta"]="B001 B002 B003 B004 B005 B006 B007 B008"  # All experimental patches
    ["alpha"]="B001 B004"                            # Minimal compatibility patches
)

# PHASE_END patches (post-compile setup)
declare -A PHASE_END_PATCHES=(
    ["release"]="E004 E006"              # Logs + configs (minimal)
    ["beta"]="E001 E004 E005 E006"       # Lua symlinks + DK stats + logs + configs
    ["alpha"]="E004 E006"                # Logs + configs (same as release)
)

apply_patches_begin() {
    local patches="${PHASE_BEGIN_PATCHES[$PROFILE]:-}"

    if [[ -z "${patches}" ]]; then
        echo "PHASE_BEGIN: No patches for profile '${PROFILE}'"
        return 0
    fi

    echo "Applying PHASE_BEGIN patches for profile '${PROFILE}'..."
    for patch_id in ${patches}; do
        local func="patch_${patch_id}_*"
        # Find and call the patch function
        local patch_func=$(declare -F | grep "patch_${patch_id}_" | sed 's/declare -f //')
        if [[ -n "${patch_func}" ]]; then
            ${patch_func}
            echo "  [${patch_id}] ${patch_func}"
        else
            echo "  [${patch_id}] WARNING: No function found for patch ${patch_id}"
        fi
    done
}

unapply_patches_begin() {
    local patches="${PHASE_BEGIN_PATCHES[$PROFILE]:-}"

    if [[ -z "${patches}" ]]; then
        return 0
    fi

    echo "Reverting PHASE_BEGIN patches for profile '${PROFILE}'..."
    for patch_id in ${patches}; do
        local unpatch_func=$(declare -F | grep "unpatch_${patch_id}_" | sed 's/declare -f //')
        if [[ -n "${unpatch_func}" ]]; then
            ${unpatch_func}
            echo "  [${patch_id}] Reverted"
        fi
    done
}

apply_patches_end() {
    local patches="${PHASE_END_PATCHES[$PROFILE]:-}"

    if [[ -z "${patches}" ]]; then
        echo "PHASE_END: No patches for profile '${PROFILE}'"
        return 0
    fi

    echo "Applying PHASE_END patches for profile '${PROFILE}'..."
    for patch_id in ${patches}; do
        local patch_func=$(declare -F | grep "patch_${patch_id}_" | sed 's/declare -f //')
        if [[ -n "${patch_func}" ]]; then
            ${patch_func}
        fi
    done
}
```

**Benefits:**
1. Single source of truth for patch→profile mapping
2. Easy to see which patches apply to which profiles
3. Adding new profile = add entry to arrays
4. Can query `${PHASE_BEGIN_PATCHES[beta]}` to see what would be applied
5. Patch orchestration becomes data-driven, not code-driven

### Implementation Notes

- PHASE_BEGIN patches MUST have corresponding unpatch functions
- PHASE_END patches are setup operations (idempotent, no unpatch needed)
- Empty string for a profile = no patches applied (valid for vanilla builds)
- Patch IDs (B001, E004) are more maintainable than full function names
- Function lookup via `declare -F | grep` finds the full function name dynamically

## Notes

- Build failures should still revert (use trap or finally-equivalent)
- Consider adding `--keep-patches` flag for debugging
- Patch status could be part of `./scripts/azerothcore status` output
- Profile-specific patch lists enable declarative control over build variations
