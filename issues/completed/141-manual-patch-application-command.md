# 141 - Manual Patch Application Command

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

New command: `./scripts/azerothcore apply-patches [--begin] [--end] [--revert] [--dry-run]`

Always operates on shadow directory (main is a generated artifact from promote workflow).

```bash
# Apply PHASE_END patches to shadow (default)
./scripts/azerothcore apply-patches

# Apply PHASE_BEGIN patches to source (for testing)
./scripts/azerothcore apply-patches --begin

# Apply both phases
./scripts/azerothcore apply-patches --begin --end

# Revert PHASE_END patches
./scripts/azerothcore apply-patches --revert

# Revert PHASE_BEGIN patches (also triggers recompilation)
./scripts/azerothcore apply-patches --begin --revert

# Show what patches would be applied without applying
./scripts/azerothcore apply-patches --dry-run
```

## Implementation

### Location
`scripts/azerothcore` - add `cmd_apply_patches()` function

### Function Design

See `scripts/azerothcore:1704-1792` for final implementation.

Key design points:
- Uses `do_begin` and `do_end` booleans that can be combined
- Always targets shadow directory (no --target option)
- For `--begin --revert`: runs `unapply_patches_begin` then triggers `make`
- For `--end --revert`: runs `unapply_patches_end` (removes configs, symlinks, DB entries)

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

### Issue: "Patches applied but worldserver still broken"
**Cause:** Running apply-patches to shadow but running worldserver from main
**Fix:** Run worldserver from shadow, or promote shadow to main first

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

### Test 3: Combine --begin and --end
```bash
./scripts/azerothcore apply-patches --begin --end --dry-run --profile beta
# Should show both PHASE_BEGIN (B001-B008) and PHASE_END (E001 E004 E005 E006)
```

### Test 4: Revert PHASE_END patches
```bash
./scripts/azerothcore apply-patches --revert --dry-run
# Should show E004 E006 would be reverted
```

### Test 5: PHASE_BEGIN revert triggers recompile
```bash
./scripts/azerothcore apply-patches --begin --revert --profile beta
# Should run unapply_patches_begin then make
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

### Revision 2 - Simplified Design

**Changes from initial implementation:**
- Removed `--all` flag - can now combine `--begin` and `--end` flags
- Removed `--target` option - always operates on shadow (main comes from promote)
- Added `--revert` support for PHASE_END patches (via unpatch_E00X functions)
- `--begin --revert` now triggers incremental recompilation after reverting

### Files Modified

1. **scripts/azerothcore:1704-1792** - `cmd_apply_patches()` function
   - Uses `do_begin` and `do_end` booleans (can combine)
   - Always targets shadow directory
   - Triggers `make -j${THREADS}` after PHASE_BEGIN revert

2. **scripts/azerothcore:733-738, 754-758, 788-800, 836-851** - Added unpatch functions
   - `unpatch_E001_lua_script_symlinks` - removes Lua symlinks
   - `unpatch_E004_log_directory_setup` - removes log symlinks
   - `unpatch_E005_dk_levelstats` - deletes DK stats from database
   - `unpatch_E006_initialize_config_files` - removes .conf files

3. **patches/patches.sh:166-190** - Added `unapply_patches_end()` orchestrator
   - Mirrors `unapply_patches_begin()` pattern for PHASE_END patches

4. **scripts/azerothcore:177-182, 213-219** - Updated help text and examples

### Test Results

```
$ ./scripts/azerothcore apply-patches --begin --end --dry-run
Apply Patches (Issue 409)
  Profile: release
  Action:  apply
  Target:  shadow (...)
  Phase:   PHASE_BEGIN
  Phase:   PHASE_END

DRY RUN - Would apply:
  PHASE_BEGIN: none
  PHASE_END: E004 E006

$ ./scripts/azerothcore apply-patches --revert --dry-run
Apply Patches (Issue 409)
  Profile: release
  Action:  revert
  Target:  shadow (...)
  Phase:   PHASE_END

DRY RUN - Would revert:
  PHASE_END: E004 E006
```

## Since then (checked 2026-10-17)

- **Built, as its own command**: `scripts/apply-patches` (the
  `scripts/azerothcore apply-patches` above, split out by issue 142 the
  next day). The patch lists it reads are still `patches/patches.sh`.
- **Testing patches without a build**, item 2 of the problem above, grew
  well past this command: `scripts/test-source-patches` (a profile's source
  patches applied and undone on a RAM copy of the tree),
  `scripts/verify-patches` (each patch's undo returns the tree exactly),
  `scripts/test-patched-syntax` (the patched files still compile), and for
  the install steps `scripts/test-basic-sql-in-ram` and
  `scripts/test-beta-sql-in-ram` (the SQL steps applied, re-applied and
  undone on a RAM database).
- `issues/408-release-profile-build-fixes.md` is
  `issues/135-release-profile-build-fixes.md` since the April renumbering.
- **Number clash**: this issue's number, 141, is also held by an open issue
  (`issues/141-ale-formatquery-dangling-pointer.md`). This one was made on
  2026-04-13 and kept its number through the 2026-04-29 renumbering (which
  moved the older legacy 141, talent-tier-limit, to 802); the other was
  made on 2026-05-20 and took 141 again, the number looking free because
  finished issues live in `completed/`. Both are kept; name them with
  their slugs. New numbers now come from `validate-issues --next`, which
  looks in `completed/` too.
