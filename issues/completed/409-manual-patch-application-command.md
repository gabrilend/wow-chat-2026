# 409 - Manual Patch Application Command

## Status
- Created: 2026-04-13
- **Implemented: 2026-04-14**
- Phase: 3
- Priority: Medium

## Problem

Currently, patches are only applied during the build process:
- PHASE_BEGIN patches: Applied before cmake, reverted after make
- PHASE_END patches: Applied after successful build to shadow directory

There's no way to:
1. Apply PHASE_END patches to an existing installation manually
2. Test patch functions without rebuilding
3. Re-apply patches if config files are corrupted
4. Apply patches to main directory after promotion

## Intended Behavior

New command: `./scripts/azerothcore apply-patches [--begin|--end|--all] [--target shadow|main]`

```bash
# Apply PHASE_END patches to shadow (default)
./scripts/azerothcore apply-patches

# Apply PHASE_END patches to main installation
./scripts/azerothcore apply-patches --target main

# Apply PHASE_BEGIN patches to source (for testing)
./scripts/azerothcore apply-patches --begin

# Revert PHASE_BEGIN patches from source
./scripts/azerothcore apply-patches --begin --revert

# Show what patches would be applied without applying
./scripts/azerothcore apply-patches --dry-run
```

## Implementation

### Location
`scripts/azerothcore` - add `cmd_apply_patches()` function

### Function Design

```bash
# {{{ cmd_apply_patches
cmd_apply_patches() {
    local phase="end"      # Default: PHASE_END
    local target="shadow"  # Default: shadow directory
    local revert=false
    local dry_run=false

    # Parse arguments
    for arg in "$@"; do
        case "${arg}" in
            --begin) phase="begin" ;;
            --end)   phase="end" ;;
            --all)   phase="all" ;;
            --target)
                shift
                target="${1:-shadow}"
                ;;
            --revert) revert=true ;;
            --dry-run) dry_run=true ;;
        esac
    done

    get_profile_paths

    # Set TARGET_INSTALL_DIR based on --target
    if [[ "${target}" == "main" ]]; then
        TARGET_INSTALL_DIR="${INSTALL_DIR}"
    else
        TARGET_INSTALL_DIR="${INSTALL_DIR_SHADOW}"
    fi

    echo "Profile: ${PROFILE}"
    echo "Target: ${target} (${TARGET_INSTALL_DIR})"
    echo ""

    if [[ "${dry_run}" == "true" ]]; then
        echo "DRY RUN - Would apply:"
        if [[ "${phase}" == "begin" || "${phase}" == "all" ]]; then
            echo "  PHASE_BEGIN: ${PHASE_BEGIN_PATCHES[$PROFILE]:-none}"
        fi
        if [[ "${phase}" == "end" || "${phase}" == "all" ]]; then
            echo "  PHASE_END: ${PHASE_END_PATCHES[$PROFILE]:-none}"
        fi
        return 0
    fi

    # Apply patches
    if [[ "${phase}" == "begin" || "${phase}" == "all" ]]; then
        if [[ "${revert}" == "true" ]]; then
            unapply_patches_begin
        else
            apply_patches_begin
        fi
    fi

    if [[ "${phase}" == "end" || "${phase}" == "all" ]]; then
        apply_patches_end
    fi

    unset TARGET_INSTALL_DIR
}
# }}}
```

## Common Issues and Fixes

### Issue: "No function found for patch E00X"
**Cause:** Patch function not defined in scripts/azerothcore
**Fix:** Check that `patch_E00X_*` function exists and is properly named

### Issue: "Config files not created"
**Cause:** .dist files missing from target directory
**Fix:** Run cmake install first, or copy .dist files manually

### Issue: "Permission denied" on config files
**Cause:** Running as wrong user or files owned by different user
**Fix:** Check file permissions, use sudo if necessary

### Issue: "TARGET_INSTALL_DIR not set"
**Cause:** apply_patches_end called without setting TARGET_INSTALL_DIR
**Fix:** Always set TARGET_INSTALL_DIR before calling, unset after

### Issue: "Patches applied to wrong directory"
**Cause:** Using --target main when shadow was intended (or vice versa)
**Fix:** Always verify target with --dry-run first

### Issue: "apply_config_values fails"
**Cause:** Config patches in config/patches/ have errors
**Fix:** Check config patch files for syntax errors

## Testing

### Test 1: Dry run shows correct patches
```bash
./scripts/azerothcore apply-patches --dry-run
# Should show:
#   PHASE_END: E004 E006 (for release)
```

### Test 2: Apply to shadow creates configs
```bash
./scripts/azerothcore apply-patches
ls installed-files-shadow/etc/worldserver.conf
# Should exist
```

### Test 3: Apply to main creates configs
```bash
./scripts/azerothcore apply-patches --target main
ls installed-files-release/etc/worldserver.conf
# Should exist
```

### Test 4: PHASE_BEGIN patches (beta profile only)
```bash
./scripts/azerothcore apply-patches --begin --profile beta --dry-run
# Should show B001-B008
```

## Related Files

- `scripts/azerothcore` - Command implementation
- `patches/patches.sh` - Patch orchestration and lists
- `issues/408-release-profile-build-fixes.md` - Shadow-run workflow

## Notes

- PHASE_BEGIN patches modify source code - use with caution
- PHASE_END patches are idempotent - safe to run multiple times
- Always use --dry-run first to verify what will happen
- TARGET_INSTALL_DIR must be exported for patch functions to use
- Incremental compilation: When PHASE_BEGIN patches modify source, cmake/make
  only recompiles affected object files. Use `--force` only when cmake
  reconfiguration is needed.

## Implementation Notes (2026-04-14)

### Files Modified

1. **scripts/azerothcore:1691-1770** - Added `cmd_apply_patches()` function
   - Parses --begin, --end, --all, --target, --revert, --dry-run arguments
   - Sets TARGET_INSTALL_DIR based on --target parameter
   - Sources patches.sh for patch function definitions
   - Calls apply_patches_begin/end or unapply_patches_begin

2. **scripts/azerothcore:2004-2007** - Added CLI dispatcher case
   - Sources patches/patches.sh before calling cmd_apply_patches
   - Passes COMMAND_ARGS to the function

3. **scripts/azerothcore:177-183** - Added help text for apply-patches command

4. **scripts/azerothcore:214-218** - Added usage examples

### Test Results

```
$ ./scripts/azerothcore apply-patches --dry-run
Apply Patches (Issue 409)
  Profile: release
  Phase:   end
  Target:  shadow (/home/ritz/games/azeroth-core/wow-chat-2026/installed-files-shadow)

DRY RUN - Would apply:
  PHASE_END: E004 E006

$ ./scripts/azerothcore apply-patches --dry-run --begin --profile beta
Apply Patches (Issue 409)
  Profile: beta
  Phase:   begin
  Target:  shadow (/home/ritz/games/azeroth-core/wow-chat-2026/installed-files-shadow)

DRY RUN - Would apply:
  PHASE_BEGIN: B001 B002 B003 B004 B005 B006 B007 B008
```
