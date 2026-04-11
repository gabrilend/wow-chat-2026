# 334 - Patch System Improvements

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
| ale-calculate-talents-hook.md | 120 | "Implementation 2026-04-06" | ❌ No (mod-talent-bonus exists locally but not linked to source-beta) |

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
4. [x] 120 ale-calculate-talents - Added as `patch_B008_mod_talent_bonus()`

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

## Notes

- Build failures should still revert (use trap or finally-equivalent)
- Consider adding `--keep-patches` flag for debugging
- Patch status could be part of `./scripts/azerothcore status` output
