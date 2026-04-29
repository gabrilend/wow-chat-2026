# 135 - Release Profile Build Fixes

## Status
- Created: 2026-04-13
- **Implemented: 2026-04-13**
- Phase: 3
- Priority: Critical

## Problem

Release profile build completed successfully but worldserver failed to start:

```
> Config::LoadFile: Failed open file '/home/ritz/games/azeroth-core/wow-chat-2026/installed-files-release/etc/worldserver.conf'
```

### Root Causes

#### 1. CMAKE_INSTALL_PREFIX Mismatch

**Location:** scripts/azerothcore:1450

CMake was configured to install to `installed-files-release`:
```bash
-DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"  # Points to installed-files-release
```

But then installation happened to shadow:
```bash
cmake --install . --prefix "${INSTALL_DIR_SHADOW}"  # Points to installed-files-shadow
```

**Effect:** CMake checks if files are "up-to-date" in the final location. When it finds `.dist` files already exist in `installed-files-release` from a previous build, it skips installing them to the shadow directory. Result: `installed-files-release-shadow/etc/` never gets created.

**Build log evidence:**
```
-- Up-to-date: /home/ritz/games/azeroth-core/wow-chat-2026/installed-files-release/etc/authserver.conf.dist
-- Installing: /home/ritz/games/azeroth-core/wow-chat-2026/installed-files-shadow/bin/authserver
```

Notice how `.dist` files show "Up-to-date" in final location, binaries get installed to shadow.

#### 2. PHASE_END Patches Never Run in cmd_install

**Location:** scripts/azerothcore:1206

`apply_patches_end()` was only called in `cmd_update` and `cmd_compile`, but not in `cmd_install`. This meant first-time installation never:
- Created `.conf` files from `.dist` files (E006)
- Set up log directory symlinks (E004)
- Created Lua script symlinks for beta (E001)
- Applied Death Knight levelstats for beta (E005)

Even when MySQL was running, these post-compile setup steps never ran during initial installation.

#### 3. Patch System Disabled for Vanilla Testing

**Location:** patches/patches.sh:22-26

All PHASE_BEGIN patches were disabled:
```bash
apply_patches_begin() {
    echo "PHASE_BEGIN patches DISABLED (vanilla baseline mode)"
}
```

This was correct for testing vanilla release profile, but PHASE_END patches (which create config files and symlinks) should run for ALL profiles.

#### 4. No Profile-Specific Patch Lists

**Location:** Multiple files

Patch orchestration used hardcoded conditionals:
```bash
# Beta only: Custom features
if [[ "${PROFILE}" == "beta" ]]; then
    patch_E001_lua_script_symlinks &
    wait
    patch_E005_dk_levelstats
fi
```

This meant:
- Cannot declaratively see which patches apply to which profiles
- Logic mixed with orchestration code
- Adding new profile requires editing orchestration functions
- Cannot test "what patches would apply for profile X"

## Solution

### Fix 1: CMAKE_INSTALL_PREFIX Points to Shadow

**File:** scripts/azerothcore:1452

Changed:
```bash
-DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
```

To:
```bash
-DCMAKE_INSTALL_PREFIX="${INSTALL_DIR_SHADOW}" \
```

With comment explaining why:
```bash
# IMPORTANT: CMAKE_INSTALL_PREFIX must point to shadow dir
# If it points to final dir, cmake will check if files are up-to-date there
# and skip installing to shadow, leaving shadow incomplete
```

### Fix 2: Call apply_patches_end in cmd_install

**File:** scripts/azerothcore:1207

Added after successful build:
```bash
# Clear trap and revert patches after successful build
trap - EXIT
unapply_patches_begin

# Apply post-compile patches (config files, symlinks, etc.)
apply_patches_end

# -- First-time setup (MySQL, configs, data files) --
```

Now first-time installation properly creates config files and sets up directories.

### Fix 3: Profile-Specific Patch Lists (Issue 334 Phase D)

**File:** patches/patches.sh:19-33

Added declarative patch lists:
```bash
# PHASE_BEGIN patches (pre-compile source modifications)
declare -A PHASE_BEGIN_PATCHES=(
    ["release"]=""                                      # Vanilla, no patches
    ["beta"]="B001 B002 B003 B004 B005 B006 B007 B008"  # All experimental patches
    ["alpha"]="B001 B004"                               # Minimal compatibility patches
)

# PHASE_END patches (post-compile setup: configs, symlinks, database)
declare -A PHASE_END_PATCHES=(
    ["release"]="E004 E006"              # Logs + configs (minimal)
    ["beta"]="E001 E004 E005 E006"       # Lua symlinks + DK stats + logs + configs
    ["alpha"]="E004 E006"                # Logs + configs (same as release)
)
```

### Fix 4: Data-Driven Patch Orchestration

**File:** patches/patches.sh:35-163

Replaced hardcoded conditionals with data-driven loops:

```bash
apply_patches_begin() {
    local patches="${PHASE_BEGIN_PATCHES[$PROFILE]:-}"

    if [[ -z "${patches}" ]]; then
        echo ""
        echo "PHASE_BEGIN: No patches for profile '${PROFILE}'"
        return 0
    fi

    echo ""
    echo "Applying PHASE_BEGIN patches for profile '${PROFILE}'..."
    for patch_id in ${patches}; do
        local patch_func=$(declare -F | grep "^declare -f patch_${patch_id}_" | sed 's/declare -f //')
        if [[ -n "${patch_func}" ]]; then
            ${patch_func}
            echo "  [${patch_id}] Applied: ${patch_func}"
        else
            echo "  [${patch_id}] WARNING: No function found for patch ${patch_id}"
        fi
    done
}
```

Similar for `unapply_patches_begin()` and `apply_patches_end()`.

**File:** scripts/azerothcore:781

Removed old hardcoded `apply_patches_end()` function, replaced with:
```bash
# apply_patches_end is now defined in patches/patches.sh with profile-aware lists
```

## Benefits

1. **Release profile now works** - Config files get created properly
2. **Declarative patch control** - Single source of truth for which patches apply to which profiles
3. **Data-driven orchestration** - Adding new profile = add entry to arrays
4. **Separation of concerns** - Patch lists separate from orchestration logic
5. **First-time install works** - PHASE_END patches run during initial setup
6. **Correct cmake behavior** - Shadow directory gets fully populated before swap

## Testing

### Test 1: Release Profile Clean Build

```bash
# Clean slate
rm -rf /mnt/mtwo/games/azeroth-core/wow-chat-2026/installed-files-release
rm -rf /mnt/mtwo/games/azeroth-core/wow-chat-2026/build-release

# Rebuild
./scripts/azerothcore update --profile release

# Verify
ls /mnt/mtwo/games/azeroth-core/wow-chat-2026/installed-files-release/etc/
# Should show: authserver.conf, worldserver.conf, dbimport.conf

# Start worldserver
./scripts/azerothcore worldserver
# Should start without "Failed open file" error
```

### Test 2: Beta Profile Build

```bash
./scripts/azerothcore update --profile beta --force

# Verify beta-specific patches applied
ls /mnt/mtwo/games/azeroth-core/wow-chat-2026/installed-files-beta/bin/lua_scripts/
# Should show: custom -> symlink to src/lua
```

## Related Files

- `scripts/azerothcore` - Build orchestration (CMAKE_INSTALL_PREFIX fix, apply_patches_end call)
- `patches/patches.sh` - Profile-aware patch lists and orchestration
- `issues/127-patch-system-improvements.md` - Phase D: Profile-Specific Patch Lists (was 334)
- `issues/133-profile-transition-system.md` - Profile system design (was 405; superseded by 136)

## Implementation Notes

### CMAKE_INSTALL_PREFIX Gotcha

CMake's install logic:
1. Checks if destination file exists
2. Compares timestamps with source
3. If destination is newer or equal, prints "Up-to-date" and skips

When `CMAKE_INSTALL_PREFIX` points to final location but install happens to shadow:
- CMake checks final location for up-to-date files
- Finds them, skips installing to shadow
- Shadow directory incomplete
- Atomic swap moves incomplete shadow to final location
- Server crashes on startup due to missing files

**Fix:** Always set `CMAKE_INSTALL_PREFIX` to the actual install destination.

### Patch Phase Execution Order

1. **PHASE_BEGIN** (apply) - Modify source before compile
2. **Compile** - cmake + make
3. **PHASE_BEGIN** (unapply) - Revert source modifications
4. **Atomic swap** - Move shadow to final location
5. **PHASE_END** (apply) - Create configs, symlinks, database setup

PHASE_END must run AFTER atomic swap because it operates on the final install directory.

### Empty String in Patch Lists

```bash
["release"]=""  # Explicitly no patches
```

Empty string is valid and means "no patches for this profile". The orchestration functions handle this gracefully with early return.

## Solution Evolution: Shadow-Run-Promote Workflow

The CMAKE_INSTALL_PREFIX fix revealed a deeper issue: binaries have install paths **baked in at compile time**. This led to the shadow-run-promote workflow:

### Final Implementation (2026-04-13)

**Build to shadow → Validate in shadow → Promote to main**

1. `CMAKE_INSTALL_PREFIX` = shadow directory
2. Build and install to shadow
3. PHASE_END creates configs in shadow/etc/
4. **Validate:** Start worldserver from shadow, verify it initializes
5. **Promote:** Copy shadow → main, tracking non-clobbered files
6. **Manifest:** Record what was preserved vs promoted

### New Commands

```bash
./scripts/azerothcore validate    # Test worldserver from shadow
./scripts/azerothcore promote     # Promote shadow → main after validation
```

### Shadow Validation (validate_shadow_worldserver)

**Location:** scripts/azerothcore:1498-1577

Starts worldserver from shadow directory:
- Checks binary and config exist
- Starts worldserver in background
- Waits up to 30s for "World initialized" message
- Detects crashes or errors
- Kills validation process
- Returns 0 if successful, 1 if failed

**Log:** `tmp/shadow-validation-${PROFILE}.log`

### Shadow Promotion (promote_shadow_to_main)

**Location:** scripts/azerothcore:1579-1668

Copies shadow to main with tracking:
1. Creates timestamped manifest in `build-manifests/`
2. Finds files in main NOT in shadow (user customizations)
3. Lists preserved files in manifest
4. Copies all shadow files to main
5. Copies symlinks with targets
6. Creates `${PROFILE}-latest.txt` symlink to manifest

**Manifest structure:**
```
build-manifests/
├── release-20260413-182345.txt    # Timestamped manifest
├── release-latest.txt -> release-20260413-182345.txt
├── beta-20260413-183012.txt
└── beta-latest.txt -> beta-20260413-183012.txt
```

**Manifest contents:**
```
# Build Manifest
# Profile: release
# Timestamp: 20260413-182345
# Shadow: /path/to/installed-files-release-shadow
# Main: /path/to/installed-files-release

# Files in main NOT in shadow (preserved):
  ./etc/custom-config.conf
  ./bin/my-script.sh

# Preserved files: 2

# Files promoted from shadow:
  ./bin/worldserver
  ./bin/authserver
  ./etc/worldserver.conf
  ...
```

### Workflow

**Automatic (recommended):**
```bash
./scripts/azerothcore compile --profile release
./scripts/azerothcore validate
./scripts/azerothcore promote
```

**Manual testing:**
```bash
# Build
./scripts/azerothcore compile --profile release

# Test from shadow (manual)
cd /path/to/installed-files-release-shadow/bin
./worldserver

# If successful, promote
./scripts/azerothcore promote
```

### Benefits

1. **Binaries have correct paths** - CMAKE_INSTALL_PREFIX = shadow, paths baked in correctly
2. **Validation before promotion** - Catch crashes/errors before affecting main installation
3. **Preserves user customizations** - Files in main but not in shadow are kept
4. **Full audit trail** - Manifests tracked with git commits
5. **Rollback friendly** - Old binaries remain until validation succeeds
6. **No atomic swap needed** - Promotion is explicit, not automatic

### Why Shadow-Run-Promote vs Atomic Swap

**Atomic swap approach (Issue 327):**
- Build to shadow
- Swap shadow → main immediately
- Run from main
- Problem: If binary crashes, main installation is broken

**Shadow-run-promote approach:**
- Build to shadow
- Run from shadow (validation)
- Only promote if validation succeeds
- Main installation never breaks
- User can test extensively in shadow before promoting

## Success Criteria

- [x] CMAKE_INSTALL_PREFIX points to shadow directory
- [x] PHASE_END patches run in cmd_install
- [x] Profile-specific patch lists defined
- [x] Data-driven orchestration implemented
- [x] Old hardcoded apply_patches_end removed
- [x] Shadow validation function implemented
- [x] Shadow promotion with manifest tracking
- [x] CLI commands for validate and promote
- [ ] Release profile builds and validates successfully
- [ ] Beta profile builds and validates successfully
- [ ] All profiles create proper config files

Status: **Implementation complete, validation pending**
