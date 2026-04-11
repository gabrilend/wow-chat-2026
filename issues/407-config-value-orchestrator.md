# 407 - Config Value Orchestrator

## Status
- Created: 2026-04-11
- Phase: Foundation
- Priority: Medium

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
