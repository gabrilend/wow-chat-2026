# 327 - Atomic Shadow Builds

## Status
- Created: 2026-04-08
- Phase: 3
- Priority: Medium

## Current Behavior

The `scripts/azerothcore` build system:

1. Compiles directly into `build-{profile}/`
2. Installs directly into `installed-files-{profile}/`
3. If compilation fails mid-way, partial artifacts remain
4. No preservation of failed build state for debugging
5. Cannot continue using old binaries while testing new builds

A failed compile can leave the system in an inconsistent state, requiring manual cleanup or a full rebuild.

## Terminology

**build-{profile}/** - The cmake/make working directory. Contains:
- CMakeCache.txt, Makefile
- Object files (.o) from compilation
- Intermediate build artifacts
- This is WHERE compilation happens

**installed-files-{profile}/** - The result of `make install`. Contains:
- Final binaries (authserver, worldserver)
- Config files (.conf)
- This is WHAT actually runs

The build directory can be rebuilt from source; the installed-files directory is what matters for running the server.

## Intended Behavior

### Two-Slot Shadow System

Only two directories needed per type - current and shadow:

```
build-beta/                   <- last successful build (cmake artifacts)
build-beta-shadow/            <- compilation in progress

installed-files-beta/         <- current working binaries (what runs)
installed-files-beta-shadow/  <- new binaries being tested
```

Servers (authserver, worldserver) ALWAYS launch from `installed-files-{profile}/`. This directory only changes when a new build succeeds.

**On compile start:**
1. Create/clear shadow directories
2. Compile into `build-{profile}-shadow/`
3. Install into `installed-files-{profile}-shadow/`

**On compile success:**
1. Delete `build-{profile}` (old build artifacts)
2. Rename `build-{profile}-shadow` → `build-{profile}`
3. Delete `installed-files-{profile}` (old binaries)
4. Rename `installed-files-{profile}-shadow` → `installed-files-{profile}`
5. Print: "Build successful. New binaries in installed-files-{profile}/"

**On compile failure:**
1. Preserve `build-{profile}-shadow/` with all artifacts
2. Keep `installed-files-{profile}/` untouched (still works!)
3. Print: "Build failed. Debug info: build-{profile}-shadow/"
4. User can continue using existing binaries immediately

### Failure Preservation

When compilation fails, preserve the shadow directory with:

- All `.o` object files (for incremental retry with `make`)
- Full error log with timestamps
- The build can be resumed by fixing the error and re-running

Directory structure for failed builds:

```
build-beta-shadow/
  compile-errors.log          <- full error output with timestamps
  CMakeCache.txt              <- cmake configuration (for debugging)
  modules/CMakeFiles/         <- object files for incremental rebuild
```

On failure, print:
```
===============================================================================
BUILD FAILED
===============================================================================

Debug information preserved at:
  build-beta-shadow/compile-errors.log

Your current working binaries are UNCHANGED:
  installed-files-beta/bin/worldserver
  installed-files-beta/bin/authserver

To retry after fixing:
  ./scripts/azerothcore compile
===============================================================================
```

## Suggested Implementation

### Step 1: Shadow Directory Support

1. Modify `get_profile_paths()` to set `BUILD_DIR_SHADOW` and `INSTALL_DIR_SHADOW`
2. Modify `do_build()` to compile into shadow directories
3. Create `compile-errors.log` with timestamped output

### Step 2: Atomic Swap on Success

1. After successful `make install`:
   - Remove old `build-{profile}` if exists
   - Rename `build-{profile}-shadow` → `build-{profile}`
   - Remove old `installed-files-{profile}` if exists
   - Rename `installed-files-{profile}-shadow` → `installed-files-{profile}`
2. Print success message with path to new binaries

### Step 3: Preserve on Failure

1. On `make` failure (non-zero exit):
   - Keep shadow directories intact
   - Write error output to `compile-errors.log`
   - Print failure message with debug path
2. Current binaries remain usable

## Affected Files

- `scripts/azerothcore` - get_profile_paths, do_build, error handling

## Related Concepts

- Blue-green deployment (web services)
- Atomic operations (rename is atomic on POSIX)
- Incremental compilation (object files preserved for retry)

## Notes

This becomes especially valuable when:
- Testing patches that might break compilation
- Experimenting with cmake options
- Debugging template-heavy C++ errors (playerbots, boost)

The key insight: compilation can take 10+ minutes. Keeping old binaries working while new ones build means zero downtime for testing.

## Implementation Notes

### Functions Added to scripts/azerothcore

- `atomic_swap_dirs()` - Swaps shadow directories to become current after successful build
- `print_build_failure()` - Prints formatted error message with debug paths on failure

### Changes to Existing Functions

- `get_profile_paths()` - Now also sets BUILD_DIR_SHADOW and INSTALL_DIR_SHADOW
- `do_build()` - Rewritten to compile into shadow directories:
  - Creates/reuses shadow build directory (preserves .o files from failed builds)
  - Runs cmake with INSTALL_PREFIX pointing to shadow install dir
  - On success: calls atomic_swap_dirs() to swap shadow → current
  - On failure: preserves shadow, prints debug info, returns 1

### Error Handling

The script uses `set -e` in cmd_install/cmd_update/cmd_compile. When do_build returns 1 on failure, the calling function exits immediately (desired behavior - prevents partial state).

### Tested Scenarios

- [ ] First-time build (no existing directories)
- [ ] Successful rebuild (swap works correctly)
- [ ] Failed build (shadow preserved, old binaries untouched)
- [ ] Retry after fixing error (incremental build from shadow)
