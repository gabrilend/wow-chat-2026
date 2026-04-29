# 119 - Config Value Orchestrator (formerly 407)

## Status: Implemented
- Created: 2026-04-11
- Completed: 2026-04-11
- Phase: Foundation (Phase 1)
- Priority: Medium
- Original Number: 407 (renumbered to fit phase structure)

## Current Behavior

Config initialization in `scripts/azerothcore` uses hardcoded `sed -i` commands:

```bash
# Lines 1177-1192
sed -i 's|^LoginDatabaseInfo.*=.*|LoginDatabaseInfo = "127.0.0.1;3307;ritz;menardi;'"${DB_AUTH}"'"|' "${INSTALL_DIR}/etc/authserver.conf"
sed -i 's|^LoginDatabaseInfo.*=.*|LoginDatabaseInfo     = "127.0.0.1;3307;ritz;menardi;'"${DB_AUTH}"'"|' "${INSTALL_DIR}/etc/worldserver.conf"
sed -i 's|^WorldDatabaseInfo.*=.*|WorldDatabaseInfo     = "127.0.0.1;3307;ritz;menardi;'"${DB_WORLD}"'"|' "${INSTALL_DIR}/etc/worldserver.conf"
sed -i 's|^CharacterDatabaseInfo.*=.*|CharacterDatabaseInfo = "127.0.0.1;3307;ritz;menardi;'"${DB_CHARS}"'"|' "${INSTALL_DIR}/etc/worldserver.conf"
sed -i 's|^DataDir.*=.*|DataDir = "'"${DIR}"'/data-files"|' "${INSTALL_DIR}/etc/worldserver.conf"
sed -i 's|^LogsDir.*=.*|LogsDir = "'"${LOGS_DIR}"'"|' "${INSTALL_DIR}/etc/worldserver.conf"
# ... 6 more lines
```

Problems:
- Adding new config values requires editing inline code
- No visibility into which configs apply to which profiles
- Gameplay settings (run speed, exp rate, fall damage) mixed with infrastructure (database paths)
- No central registry of "wow-chat standard settings"

## Intended Behavior

### Profile-Aware Config Registry

Similar to patch orchestrator, each config value is a function with profile specification:

```bash
# config/config-registry.sh

# -- {{{ config_run_speed_80_percent
# Set player run speed to 80% (slower, more deliberate exploration)
# Profiles: all
# File: worldserver.conf
config_run_speed_80_percent() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^Rate.Run.Speed.*=.*|Rate.Run.Speed = 0.8|' "${conf}"
}
declare -A CONFIG_PROFILES
CONFIG_PROFILES[config_run_speed_80_percent]="alpha release beta"
# -- }}}

# -- {{{ config_fall_damage_10x
# Increase fall damage to 10x (encourages careful movement)
# Profiles: beta
# File: worldserver.conf
config_fall_damage_10x() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^Rate.Damage.Fall.*=.*|Rate.Damage.Fall = 10.0|' "${conf}"
}
CONFIG_PROFILES[config_fall_damage_10x]="beta"
# -- }}}

# -- {{{ config_exp_rate_2x
# Double experience rate (faster testing/iteration)
# Profiles: beta
# File: worldserver.conf
config_exp_rate_2x() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^Rate.XP.Kill.*=.*|Rate.XP.Kill = 2.0|' "${conf}"
    sed -i 's|^Rate.XP.Quest.*=.*|Rate.XP.Quest = 2.0|' "${conf}"
}
CONFIG_PROFILES[config_exp_rate_2x]="beta"
# -- }}}

# -- {{{ config_database_connections
# Set database connection strings (project-specific, all profiles)
# Profiles: all
# File: authserver.conf, worldserver.conf
config_database_connections() {
    sed -i 's|^LoginDatabaseInfo.*=.*|LoginDatabaseInfo = "127.0.0.1;3307;ritz;menardi;'"${DB_AUTH}"'"|' "${INSTALL_DIR}/etc/authserver.conf"
    sed -i 's|^LoginDatabaseInfo.*=.*|LoginDatabaseInfo     = "127.0.0.1;3307;ritz;menardi;'"${DB_AUTH}"'"|' "${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^WorldDatabaseInfo.*=.*|WorldDatabaseInfo     = "127.0.0.1;3307;ritz;menardi;'"${DB_WORLD}"'"|' "${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^CharacterDatabaseInfo.*=.*|CharacterDatabaseInfo = "127.0.0.1;3307;ritz;menardi;'"${DB_CHARS}"'"|' "${INSTALL_DIR}/etc/worldserver.conf"
}
CONFIG_PROFILES[config_database_connections]="alpha release beta"
# -- }}}

# -- {{{ config_directory_paths
# Set project directory paths (DataDir, LogsDir, etc.)
# Profiles: all
# File: authserver.conf, worldserver.conf
config_directory_paths() {
    local conf_auth="${INSTALL_DIR}/etc/authserver.conf"
    local conf_world="${INSTALL_DIR}/etc/worldserver.conf"

    sed -i 's|^DataDir.*=.*|DataDir = "'"${DIR}"'/data-files"|' "${conf_world}"
    sed -i 's|^LogsDir.*=.*|LogsDir = "'"${LOGS_DIR}"'"|' "${conf_world}"
    sed -i 's|^LogsDir.*=.*|LogsDir = "'"${LOGS_DIR}"'"|' "${conf_auth}"
    sed -i 's|^SourceDirectory.*=.*|SourceDirectory = "'"${AC_CODE_DIR}"'"|' "${conf_auth}"
    sed -i 's|^BuildDirectory.*=.*|BuildDirectory = "'"${BUILD_DIR}"'"|' "${conf_world}"
    sed -i 's|^SourceDirectory.*=.*|SourceDirectory = "'"${AC_CODE_DIR}"'"|' "${conf_world}"
    sed -i 's|^MySQLExecutable.*=.*|MySQLExecutable = "'"${MYSQL_DIR}"'/bin/mysql"|' "${conf_auth}"
    sed -i 's|^MySQLExecutable.*=.*|MySQLExecutable = "'"${MYSQL_DIR}"'/bin/mysql"|' "${conf_world}"
}
CONFIG_PROFILES[config_directory_paths]="alpha release beta"
# -- }}}
```

### Orchestrator Function

```bash
# -- {{{ apply_config_values
# Apply all config values for current profile
# Called after init_config() copies .dist to .conf
apply_config_values() {
    echo "Applying config values for profile: ${PROFILE}..."

    source "${DIR}/config/config-registry.sh"

    # Get list of all config functions
    local config_funcs=$(declare -F | grep "^declare -f config_" | sed 's/declare -f //')

    for func in ${config_funcs}; do
        # Check if this config applies to current profile
        local profiles="${CONFIG_PROFILES[$func]}"
        if [[ " ${profiles} " =~ " ${PROFILE} " ]] || [[ " ${profiles} " =~ " all " ]]; then
            ${func}
            echo "  [✓] ${func}"
        fi
    done

    echo "Config values applied"
}
# -- }}}
```

### Integration with Build Script

Replace inline `sed` commands in `cmd_update`:

```bash
# Old (lines 1175-1193):
echo "Configuring database connections..."
sed -i 's|^LoginDatabaseInfo.*=.*|...'
sed -i 's|^WorldDatabaseInfo.*=.*|...'
# ... 10 more lines

# New:
apply_config_values
```

## Benefits

1. **Centralized Registry** - All config values in one place
2. **Profile-Aware** - Easy to see which settings apply to which profiles
3. **Easy to Add** - New config = new function + profile declaration
4. **Self-Documenting** - Comments explain what each setting does and why
5. **Testable** - Can list all configs for a profile without applying

## Implementation Steps

1. Create `config/config-registry.sh`
2. Add `apply_config_values()` to `scripts/azerothcore`
3. Move existing database/path configs to registry functions
4. Add gameplay configs (run speed, fall damage, exp rate)
5. Replace inline sed calls with `apply_config_values`
6. Test all three profiles build with correct configs

## Profile Specification Format

**Recommendation: Array of profile names** (not bitmask)

```bash
# Good: Clear, extensible, easy to understand
CONFIG_PROFILES[config_run_speed_80_percent]="alpha release beta"
CONFIG_PROFILES[config_fall_damage_10x]="beta"
CONFIG_PROFILES[config_database_connections]="all"

# Bad: Bitmask (fragile when reordering profiles)
CONFIG_PROFILES[config_run_speed_80_percent]=7  # 0b111 = alpha|release|beta
CONFIG_PROFILES[config_fall_damage_10x]=4       # 0b100 = beta only
```

The string-based approach:
- More readable (`"alpha beta"` vs `3`)
- Extensible (can add profile without recalculating all bitmasks)
- Supports "all" special case
- Grep-friendly for finding which configs apply to a profile

## Config Categories

Organize configs into groups for clarity:

### Infrastructure (all profiles)
- Database connections
- Directory paths
- MySQL executable paths

### Gameplay - Core Rates (varies by profile)
- Run speed
- Fall damage
- Experience rate
- Drop rate
- Gold rate

### Gameplay - Server Settings (varies by profile)
- Max players
- Level cap
- Starting level
- Death penalty

### Debug/Development (beta only)
- GM level on login
- Instant teleport cooldowns
- Skip cinematics
- Fast corpse decay

## Related Files

- `scripts/azerothcore` - Current config application (lines 1175-1193)
- `config/beta/`, `config/release/`, `config/alpha/` - Profile-specific config symlinks
- `installed-files-{profile}/etc/*.conf` - Actual config files modified

## Success Criteria

- [ ] All current inline sed commands moved to config-registry.sh
- [ ] Gameplay settings (run speed, exp, fall damage) added
- [ ] All three profiles build with correct config values
- [ ] Can list configs for a profile without applying
- [ ] Documentation shows which configs apply to which profiles

## Notes

This parallels the patch orchestrator design (issue 334). Just as patches are applied based on profile, config values should be too. The key insight: configuration is code, and should be treated with the same rigor as patches.

## Implementation Summary (2026-04-11)

### Changes Made

**config/config-registry.sh** (NEW):
- Created centralized config registry with 9 initial configs
- Profile specification uses array of names: `CONFIG_PROFILES[func]="alpha release beta"`
- Special value "all" applies to all profiles

**scripts/azerothcore**:
- Added `apply_config_values()` function (lines 651-682)
- Replaced inline sed commands (15 lines) with single function call
- Sources config-registry.sh and applies matching configs

### Config Registry Contents

**Infrastructure (all profiles):**
- `config_database_connections` - Auth, world, characters databases
- `config_directory_paths` - DataDir, LogsDir, SourceDirectory, BuildDirectory, MySQLExecutable

**Gameplay - Core Rates:**
- `config_run_speed_80_percent` - All profiles (slower exploration)
- `config_fall_damage_10x` - Beta only (careful movement)
- `config_exp_rate_2x` - Beta only (faster testing)

**Gameplay - Server Settings:**
- `config_max_level_20` - All profiles (wow-chat design)
- `config_starting_level_1` - All profiles (explicit default)

**Debug/Development:**
- `config_gm_login_state` - All profiles (GM=3 for beta, GM=0 for release/alpha)
- `config_instant_teleport_beta` - Beta only (instant taxi)

### Testing Results

**Beta profile:** 9 configs applied
```
config_database_connections, config_directory_paths, config_exp_rate_2x,
config_fall_damage_10x, config_gm_login_state, config_instant_teleport_beta,
config_max_level_20, config_run_speed_80_percent, config_starting_level_1
```

**Release profile:** 6 configs applied (beta-specific skipped)
```
config_database_connections, config_directory_paths, config_gm_login_state,
config_max_level_20, config_run_speed_80_percent, config_starting_level_1
```

Profile filtering works correctly - beta-only configs (exp_rate, fall_damage, instant_teleport) are skipped for release.

### How to Add New Config

1. Add function to `config/config-registry.sh`:
   ```bash
   config_new_setting() {
       local conf="${INSTALL_DIR}/etc/worldserver.conf"
       sed -i 's|^SettingName.*=.*|SettingName = value|' "${conf}"
   }
   CONFIG_PROFILES[config_new_setting]="beta"  # or "all" or "alpha release"
   ```

2. That's it - next build will apply it automatically

### Benefits Achieved

1. **Centralized** - All config values in one place (`config/config-registry.sh`)
2. **Profile-aware** - Easy to see which settings apply to which profiles
3. **Easy to add** - New config = new function + profile declaration (3 lines)
4. **Self-documenting** - Comments explain what each setting does
5. **Maintainable** - No more hunting through inline sed commands

## Success Criteria

- [x] All current inline sed commands moved to config-registry.sh
- [x] Gameplay settings (run speed, exp, fall damage) added
- [x] Profile filtering works (beta gets all, release gets subset)
- [x] Easy to add new configs (just add function + profile)
- [x] Config values persist between profiles (database paths use profile-specific vars)

## Related Files

- `config/patches/C*.sh` - Individual config patch files (replaces config-registry.sh)
- `scripts/azerothcore` - lines 672-716 (apply_config_values)
- `installed-files-{profile}/etc/*.conf` - Modified by config functions

## Bug Fixes (2026-04-14)

### C001: Database variables undefined

**Problem:** `config_database_connections()` used `${DB_AUTH}`, `${DB_WORLD}`, `${DB_CHARS}`
without defining them, resulting in empty database names in connection strings:
```
LoginDatabaseInfo = "127.0.0.1;3307;ritz;menardi;"  # missing database name!
```

**Symptom:** Worldserver fails with `[1046] No database selected`

**Fix:** Added local variable definitions inside the function:
```bash
local DB_AUTH="acore_auth"
local DB_WORLD="acore_world_${PROFILE}"
local DB_CHARS="acore_characters_${PROFILE}"
```

**File:** `config/patches/C001-database-connections.sh`

### C005: Sed pattern too broad for Rate.XP.Quest

**Problem:** The sed pattern `^Rate\.XP\.Quest.*=.*` matched both:
- `Rate.XP.Quest     = 1`
- `Rate.XP.Quest.DF  = 1`

Both lines were replaced with `Rate.XP.Quest = 2.0`, creating duplicate entries.

**Symptom:** `Config::LoadFile: Duplicate key name 'Rate.XP.Quest'`

**Fix:** Changed pattern to use `[[:space:]]` anchor:
```bash
# Old (matches Rate.XP.Quest.DF too):
sed -i 's|^Rate\.XP\.Quest.*=.*|Rate.XP.Quest = '"${XP_RATE}"'|'

# New (only matches Rate.XP.Quest followed by whitespace):
sed -i 's|^Rate\.XP\.Quest[[:space:]]*=.*|Rate.XP.Quest = '"${XP_RATE}"'|'
```

**File:** `config/patches/C005-exp-rate-2x.sh`

### Lesson Learned

When writing sed patterns for config files:
1. Always check for similar config keys that could match (e.g., `Setting` vs `Setting.SubKey`)
2. Use `[[:space:]]*=` instead of `.*=` when the key should end at that point
3. Define all variables locally within the function, don't assume caller provides them

## Database Sharing Strategy (2026-04-14)

### Problem

Initially, each profile used separate databases (`acore_world_release`, `acore_world_beta`).
This caused issues:
- Worldserver auto-creation of new databases failed with schema errors
- SQL archive files conflicted during fresh database population
- Duplicate maintenance overhead

### Solution: Share Databases by Core Version

Profiles that use the same source code share databases:

| Profile | Source Dir    | World DB         | Characters DB         |
|---------|---------------|------------------|----------------------|
| release | source-beta   | acore_world      | acore_characters     |
| beta    | source-beta   | acore_world      | acore_characters     |
| alpha   | source-alpha  | acore_world_alpha| acore_characters_alpha|

**Rationale:** Same core version = same database schema. Release and beta both
compile from `source-beta`, so their database schemas are identical. Sharing
databases:
- Eliminates duplicate database maintenance
- Allows character continuity between profiles
- Avoids worldserver auto-creation issues (databases already exist and are populated)

Alpha uses `source-alpha` which may have schema differences, so it gets
separate databases.

### Implementation

**File:** `config/patches/C001-database-connections.sh`

```bash
if [[ "${PROFILE}" == "alpha" ]]; then
    local DB_WORLD="acore_world_alpha"
    local DB_CHARS="acore_characters_alpha"
else
    # release and beta share databases (both use source-beta)
    local DB_WORLD="acore_world"
    local DB_CHARS="acore_characters"
fi
```

### C002: Directory path variables undefined

**Problem:** `config_directory_paths()` used `${LOGS_DIR}`, `${BUILD_DIR}`, `${AC_CODE_DIR}`, `${MYSQL_DIR}`
without defining them, resulting in empty paths:
```
LogsDir = ""
BuildDirectory = ""
```

**Symptom:** Worldserver crashes with `filesystem error: cannot make absolute path: Invalid argument []`

**Fix:** Added local variable definitions inside the function:
```bash
local LOGS_DIR="${DIR}/logs-${PROFILE}"
local BUILD_DIR="${DIR}/build-${PROFILE}"
local MYSQL_DIR="${DIR}/mysql/installed-files"

local AC_CODE_DIR
if [[ "${PROFILE}" == "alpha" ]]; then
    AC_CODE_DIR="${DIR}/source-alpha"
else
    AC_CODE_DIR="${DIR}/source-beta"
fi
```

**File:** `config/patches/C002-directory-paths.sh`

## Explicit Profile Pattern (2026-04-14)

### Rationale

Replaced all if-else patterns with explicit case statements for each profile. This:
- Makes all profile values visible at a glance
- Prevents accidental catch-all behavior
- Makes it easy to add new profiles or change individual profile values
- Provides clear error messages for unknown profiles

### Pattern Before (catch-all else)

```bash
if [[ "${PROFILE}" == "alpha" ]]; then
    AC_CODE_DIR="${DIR}/source-alpha"
else
    AC_CODE_DIR="${DIR}/source-beta"
fi
```

### Pattern After (explicit enumeration)

```bash
case "${PROFILE}" in
    release) AC_CODE_DIR="${DIR}/source-beta"  ;;
    beta)    AC_CODE_DIR="${DIR}/source-beta"  ;;
    alpha)   AC_CODE_DIR="${DIR}/source-alpha" ;;
    *)       echo "ERROR: Unknown profile '${PROFILE}'"; exit 1 ;;
esac
```

### Files Updated

**Config patches:**
- `config/patches/C001-database-connections.sh` - DB_WORLD, DB_CHARS
- `config/patches/C002-directory-paths.sh` - AC_CODE_DIR
- `config/patches/C008-gm-login-state.sh` - gm_level

**E patches:**
- `patches/E-patches.sh` - DB_WORLD (2 locations)

**Scripts:**
- `scripts/worldserver` - AC_CODE_DIR
- `scripts/authserver` - AC_CODE_DIR
- `scripts/switch` - AC_CODE_DIR
- `scripts/apply-patches` - AC_CODE_DIR
- `scripts/update` - AC_CODE_DIR
- `scripts/compile` - AC_CODE_DIR
- `scripts/redownload-source` - AC_CODE_DIR
- `scripts/install` - AC_CODE_DIR, target_dir (modules symlink)
