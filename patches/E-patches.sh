#!/usr/bin/env bash
# E-patches.sh - PHASE_END patches (post-compile setup)
# Sourced by patches.sh
#
# E001: Lua script symlinks
# E004: Log directory setup
# E005: DK levelstats (database)
# E006: Initialize config files

# Get DIR from parent script
DIR="${DIR:-/home/ritz/games/azeroth-core/wow-chat-2026}"

# -- {{{ _register_with_updatefetcher
# Idempotently register a project-local SQL directory with AzerothCore's
# UpdateFetcher. Once a row exists in `<db>.updates_include` pointing at
# the absolute directory path, AC will scan that directory on every
# worldserver boot, hash each .sql file inside it, and apply (or
# re-apply on hash change) via its native Updates pipeline.
#
# This is the project's single SQL-patch idiom (mirrors the B-patch
# shape — B-patches sed C++ source files in place and let the compiler
# pick up changes; E-patches write SQL files in place and let AC's
# UpdateFetcher pick them up). The watched dir holds derived artifacts
# the E-patch writes; AC reads them as if they were ordinary CUSTOM
# updates. The active dirs are gitignored.
#
# Args:
#   $1 = absolute directory path on disk (must already be mkdir-ed)
#   $2 = database name to register against
#
# Shared-DB note: when two profiles share a database (currently
# release+beta share acore_world / acore_playerbots), an include row
# registered by one profile's install will be read by the OTHER
# profile's worldserver on boot, causing it to scan the same dir and
# apply the same SQL. This is inherent to DB sharing — not specific to
# this helper. If beta-only data isolation is required, the fix is
# splitting beta into acore_world_beta, not avoiding UpdateFetcher.
_register_with_updatefetcher() {
    local DIR_PATH="$1"
    local DB="$2"
    local MYSQL_DIR="${DIR}/mysql/installed-files"
    local MYSQL_SOCKET="${DIR}/mysql/databases/mysql.sock"

    mkdir -p "${DIR_PATH}"

    # If MySQL isn't up the include row can be inserted on a later
    # install pass. Worldserver picks it up on next boot regardless
    # of when the row was added.
    [[ ! -S "${MYSQL_SOCKET}" ]] && return 0

    # CREATE TABLE IF NOT EXISTS first, then INSERT IGNORE. The CREATE
    # handles the install-time race where E-patches run before the
    # worldserver's first boot — at that point the DB exists (install
    # created it) but `updates_include` does not (AC's worldserver
    # creates content tables on first DatabaseLoader::Populate()).
    # Without this, the INSERT below silently fails against the missing
    # table, the include row never lands, UpdateFetcher never sees our
    # SQL dir, and our E-patch's apply form is never applied. The
    # schema mirrors the one AC creates on first boot — both CREATEs
    # are no-ops once a row from either side is in place, so they can't
    # fight.
    #
    # INSERT IGNORE keeps a second call a clean no-op once the row exists
    # (path is PRIMARY KEY).
    "${MYSQL_DIR}/bin/mysql" --no-defaults --socket="${MYSQL_SOCKET}" \
        -u ritz -pmenardi "${DB}" <<SQL 2>/dev/null || true
CREATE TABLE IF NOT EXISTS \`updates_include\` (
  \`path\` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'directory to include. \$ means relative to the source directory.',
  \`state\` enum('RELEASED','ARCHIVED','CUSTOM','PENDING') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'RELEASED' COMMENT 'defines if the directory contains released or archived updates.',
  PRIMARY KEY (\`path\`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='List of directories where we want to include sql updates.';
INSERT IGNORE INTO \`updates_include\` (\`path\`, \`state\`) VALUES ('${DIR_PATH}', 'CUSTOM');
SQL
}
# -- }}}

# -- {{{ _unregister_from_updatefetcher
# Inverse of _register_with_updatefetcher: removes the include row so
# AC's UpdateFetcher stops scanning the directory on subsequent boots.
# Called from unpatch_*() at the END (after writing revert SQL into the
# active dir) so the revert SQL runs ONCE on the next boot, AC sees the
# orphan-cleanup warning for the missing file, and the include row is
# gone — leaving the DB in revert state with no further scans.
#
# Profile-switch hygiene: this is what makes "switch profiles cleanly"
# work without the OLD profile's SQL re-running under the NEW profile's
# worldserver. Unapply_patches_end runs every unpatch in
# PHASE_END_PATCHES[$PROFILE]; each removes its own include row.
_unregister_from_updatefetcher() {
    local DIR_PATH="$1"
    local DB="$2"
    local MYSQL_DIR="${DIR}/mysql/installed-files"
    local MYSQL_SOCKET="${DIR}/mysql/databases/mysql.sock"

    [[ ! -S "${MYSQL_SOCKET}" ]] && return 0

    "${MYSQL_DIR}/bin/mysql" --no-defaults --socket="${MYSQL_SOCKET}" \
        -u ritz -pmenardi "${DB}" \
        -e "DELETE FROM updates_include WHERE path = '${DIR_PATH}';" 2>/dev/null || true
}
# -- }}}

# -- {{{ _profile_db_name
# Compose a profile-suffixed database name. Mirrors the database
# isolation policy in config/patches/C001-database-connections.sh:
# release and beta share the unsuffixed namespace; vanilla and alpha
# carry _vanilla / _alpha suffixes for data isolation.
#
# Use this anywhere an E-patch wires a sql directory to a database.
# The patch function stays profile-anonymous; the dispatcher
# (patches.sh:PHASE_END_PATCHES[$PROFILE]) is the single source of
# truth for which patches run under which profile.
#
# Args:
#   $1 = base name (without profile suffix; e.g. acore_world, acore_playerbots)
# Echoes the composed name; returns 1 on unknown profile.
_profile_db_name() {
    local base="$1"
    case "${PROFILE}" in
        release|beta) echo "${base}" ;;
        vanilla)      echo "${base}_vanilla" ;;
        alpha)        echo "${base}_alpha" ;;
        *)
            echo "ERROR: _profile_db_name called for unknown profile '${PROFILE}'" >&2
            return 1
            ;;
    esac
}
# -- }}}

# -- {{{ apply_config_values
# Apply all config values for current profile (Issue 119)
# Called after init_config() copies .dist to .conf
# Sources all config patch files from config/patches/
apply_config_values() {
    # Check if config patches directory exists
    if [[ ! -d "${DIR}/config/patches" ]]; then
        echo "  Warning: config/patches/ directory not found, using defaults"
        return 0
    fi

    # Declare profile and description mapping arrays
    declare -A CONFIG_PROFILES
    declare -A CONFIG_DESCRIPTIONS

    # Load and syntax-check all config patch files
    echo "  Loading config patches:"
    local patch_count=0
    declare -A patches_by_profile
    for patch_file in "${DIR}/config/patches"/C*.sh; do
        [[ -f "${patch_file}" ]] || continue
        local patch_name=$(basename "${patch_file}" .sh)
        source "${patch_file}" || {
            echo "    [✗] ${patch_name} - syntax error"
            return 1
        }
        # Extract function name from filename (C001-foo-bar -> config_foo_bar)
        local func_name="config_${patch_name#C[0-9]*-}"
        func_name="${func_name//-/_}"
        local profiles="${CONFIG_PROFILES[$func_name]:-?}"
        # Add patch to each individual profile (expand "alpha release" -> alpha, release)
        for profile in ${profiles}; do
            patches_by_profile["${profile}"]+="${patch_name}"$'\n'
        done
        ((patch_count++)) || true
    done

    if [[ ${patch_count} -eq 0 ]]; then
        echo "    (none found)"
        return 0
    fi

    # Output grouped by profile (all first, then alpha/beta/release sorted)
    for profile in all alpha beta release; do
        [[ -z "${patches_by_profile[$profile]:-}" ]] && continue
        echo "    ${profile}:"
        while IFS= read -r p; do
            [[ -n "$p" ]] && echo "      $p"
        done <<< "${patches_by_profile[$profile]}"
    done

    # Get list of all config functions
    local config_funcs=$(declare -F | grep "^declare -f config_" | sed 's/declare -f //')

    echo "  Applying for profile '${PROFILE}':"
    local applied_count=0
    local failed_count=0
    for func in ${config_funcs}; do
        local profiles="${CONFIG_PROFILES[$func]:-}"
        local desc="${CONFIG_DESCRIPTIONS[$func]:-${func}}"

        # Only process patches that apply to this profile
        if [[ " ${profiles} " =~ " ${PROFILE} " ]] || [[ " ${profiles} " =~ " all " ]]; then
            if ${func}; then
                echo "    [✓] ${desc}"
                ((applied_count++)) || true
            else
                echo "    [✗] ${desc} - FAILED"
                ((failed_count++)) || true
            fi
        fi
    done

    echo "  Applied ${applied_count} config patches"
    if [[ ${failed_count} -gt 0 ]]; then
        echo "  WARNING: ${failed_count} config patches failed"
        return 1
    fi
    return 0
}
# -- }}}

# -- {{{ patch_E001_lua_script_symlinks
# Create symlinks from install dir to the profile-specific Lua source
# directory. Each profile owns its own Lua corpus:
#   src/lua-vanilla/ — minimal vanilla scripts (148k starter-equip hook etc.)
#   src/lua-beta/    — wow-chat design corpus (ambush, travel, custom classes,
#                      the disabled-prefixed experiments). Was formerly just
#                      src/lua/ before the 2026-06-02 per-profile rename.
#   src/lua-alpha/   — placeholder for alpha-profile (mod-eluna) scripts.
# Symlink target resolves from ${PROFILE} at apply time, so each
# installed-files-${PROFILE}/bin/lua_scripts/custom points at the
# correct per-profile source.
#
# Idempotent: every call tears down whatever previously occupied the
# target paths and re-creates them fresh. This lets the patch run on
# every compile and handle three distinct squatters:
#   1. A symlink left by a prior E001 apply (most common — profile
#      rotation or repeat builds).
#   2. A broken symlink pointing at a no-longer-existing source
#      (e.g. the 2026-06-02 src/lua → src/lua-${profile} rename left
#      May-21 links pointing at the renamed-away src/lua/extensions).
#      [[ -L ... ]] matches even broken links, so they're cleaned.
#   3. A real directory unpacked at lua_scripts/extensions/ by mod-ale's
#      upstream install rule
#        install(DIRECTORY .../LuaEngine/extensions DESTINATION lua_scripts/)
#      in source-beta/modules/CMakeLists.txt. cmake's
#      file(INSTALL TYPE DIRECTORY) refuses to clobber a non-directory
#      at its destination, so squatter (1)/(2) must be cleared BEFORE
#      cmake --install; squatter (3) must be cleared AFTER, so the
#      project's extensions/ superset (incl. GetFreeBagSlots.ext,
#      StackTracePlus.disabled) overrides mod-ale's bundled set.
#
# Parallelizable: Yes (unique directory)
# Uses TARGET_INSTALL_DIR (defaults to INSTALL_DIR, can be set to INSTALL_DIR_SHADOW)
patch_E001_lua_script_symlinks() {
    local TARGET="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    local LUA_SRC="${DIR}/src/lua-${PROFILE}"
    if [[ ! -d "${LUA_SRC}" ]]; then
        echo "  [E001] WARNING: ${LUA_SRC} does not exist — creating empty dir"
        mkdir -p "${LUA_SRC}"
    fi
    mkdir -p "${TARGET}/bin/lua_scripts"

    # custom/ is only ever a symlink (cmake never installs there). Tear
    # down any prior link — well-formed or broken — and recreate.
    [[ -L "${TARGET}/bin/lua_scripts/custom" ]] && rm "${TARGET}/bin/lua_scripts/custom"
    ln -sfn "${LUA_SRC}" "${TARGET}/bin/lua_scripts/custom"

    # extensions/ needs heavier handling because cmake --install can
    # leave a real directory here (see header comment, squatter #3).
    #
    # Branch (a): this profile ships its own extensions/ source. Blow
    # away whatever's at the path (symlink OR real dir) and override
    # with a project symlink.
    #
    # Branch (b): this profile has no extensions/ source. Only clear a
    # stale symlink (leftover from a prior profile that had one). Leave
    # a cmake-installed real directory alone so mod-ale's bundled
    # StackTracePlus / _Misc / ObjectVariables stay loadable.
    if [[ -d "${LUA_SRC}/extensions" ]]; then
        if [[ -L "${TARGET}/bin/lua_scripts/extensions" ]]; then
            rm "${TARGET}/bin/lua_scripts/extensions"
        elif [[ -d "${TARGET}/bin/lua_scripts/extensions" ]]; then
            rm -rf "${TARGET}/bin/lua_scripts/extensions"
        fi
        ln -sfn "${LUA_SRC}/extensions" "${TARGET}/bin/lua_scripts/extensions"
    else
        [[ -L "${TARGET}/bin/lua_scripts/extensions" ]] && rm "${TARGET}/bin/lua_scripts/extensions"
    fi

    echo "  [E001] Lua script symlinks (profile=${PROFILE}, src=${LUA_SRC#${DIR}/})"
}

# Tear down whatever E001 may have created. Only removes symlinks (the
# project's contribution) — never touches a real directory at the
# extensions/ path, because that was placed by cmake --install and
# belongs to mod-ale, not to E001. [[ -L ... ]] matches broken symlinks
# too, so the May-21-era links pointing at the renamed-away src/lua/
# get cleaned on the first call.
unpatch_E001_lua_script_symlinks() {
    local TARGET="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    [[ -L "${TARGET}/bin/lua_scripts/custom" ]] && rm "${TARGET}/bin/lua_scripts/custom"
    [[ -L "${TARGET}/bin/lua_scripts/extensions" ]] && rm "${TARGET}/bin/lua_scripts/extensions"
    echo "  [E001] Removed Lua script symlinks"
}
# -- }}}

# -- {{{ patch_E004_log_directory_setup
# Create RAM-backed log directory symlink
# Parallelizable: Yes (unique target)
patch_E004_log_directory_setup() {
    local TMP_BASE="/tmp/wow-chat-2"
    local TMP_LOGS="${TMP_BASE}/logs-${PROFILE}"
    mkdir -p "${TMP_BASE}"
    mkdir -p "${TMP_LOGS}"
    [[ -L "${DIR}/tmp" ]] || ln -s "${TMP_BASE}" "${DIR}/tmp"
    [[ -L "${DIR}/logs-${PROFILE}" ]] || ln -s "${TMP_LOGS}" "${DIR}/logs-${PROFILE}"
    echo "  [E004] Log directory setup"
}

unpatch_E004_log_directory_setup() {
    [[ -L "${DIR}/tmp" ]] && rm "${DIR}/tmp"
    [[ -L "${DIR}/logs-${PROFILE}" ]] && rm "${DIR}/logs-${PROFILE}"
    echo "  [E004] Removed log directory symlinks"
}
# -- }}}

# -- {{{ patch_E005_dk_levelstats
# Apply Death Knight level 1-20 stats to the beta-profile DB (issue
# 206). Required before worldserver first start so DK characters
# can be created at level 1 with sensible stats.
#
# Single-idiom (UpdateFetcher). Apply cp's the source file into
# sql/beta/db_world/01-dk-levelstats.sql; unpatch overwrites with a
# revert heredoc; AC's UpdateFetcher hashes and runs whichever is
# current on next worldserver boot.
#
# Shared-DB note: beta+release share acore_world. Once the beta
# install registers sql/beta/db_world/, the release worldserver also
# scans it. That is a DB-sharing consequence; address by splitting
# into acore_world_beta if beta-only isolation is required.
patch_E005_dk_levelstats() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/01-dk-levelstats.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/01-dk-levelstats.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E005_APPLY" "${SQL_FILE}"; then
        echo "  [E005] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E005] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E005] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E005_dk_levelstats() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/01-dk-levelstats.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E005_REVERT" "${SQL_FILE}"; then
        echo "  [E005] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E005] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E005_REVERT beta-dk-levelstats
-- Revert-form: drop the DK level 1..20 rows from player_levelstats.
-- Table itself is preserved (release shares this DB).
DELETE FROM `player_levelstats` WHERE `class` = 6 AND `level` BETWEEN 1 AND 20;
SQL
}
# -- }}}

# -- {{{ patch_E007_vanilla_starting_zones
# Override playercreateinfo so vanilla characters spawn at the
# canonical level-20 contested zones (Darkshire for Alliance, Tarren
# Mill for Horde) instead of the per-race level-1 tutorial enclaves.
# Issue 148 (R3 supplied the coordinates).
#
# Reference implementation of the project's merged SQL-patch idiom
# (see B-patches for the analogue with C++ source). The E-patch writes
# apply-form OR revert-form SQL into a single file at the active dir;
# AC's UpdateFetcher hashes the file on next worldserver boot and
# applies (or re-applies on hash change) the new content. Both
# directions are explicit and hardcode their target values inline.
#
# Idempotence: each direction starts with a marker grep against the
# current file content. If the marker shows the file already holds
# that direction's content, no work is done. Apply twice in a row →
# the second is a no-op. Apply, then unpatch, then apply again → each
# transition rewrites and AC re-runs on the next boot.
patch_E007_vanilla_starting_zones() {
    # Vanilla-only — the SQL would scribble over release/beta/alpha
    # starting zones, which is wrong for those profiles.
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/01-starting-zones.sql"

    # Idempotence guard: if the active file already holds the apply
    # marker, the content matches what we'd write and there's nothing
    # to do.
    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E007_APPLY" "${SQL_FILE}"; then
        echo "  [E007] Active file already holds apply-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E007] Writing apply-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E007_APPLY vanilla-starting-zones
-- Apply-form: Alliance races → Darkshire (Duskwood, zone 10),
--             Horde races → Tarren Mill (Hillsbrad, zone 267).
-- Both towns on Eastern Kingdoms (map 0). DK rows (class=6) left alone
-- so a re-enabled DK still lands at Ebon Hold (assumes WotLK opener).
UPDATE `playercreateinfo` SET `map`=0, `zone`=10,  `position_x`=-10573.0, `position_y`=-1182.51, `position_z`=28.0148, `orientation`=0.309022 WHERE `race` IN (1,3,4,7,11) AND `class` != 6;
UPDATE `playercreateinfo` SET `map`=0, `zone`=267, `position_x`=-34.1467, `position_y`=-923.366, `position_z`=54.5576, `orientation`=0.15019  WHERE `race` IN (2,5,6,8,10) AND `class` != 6;
SQL
}

unpatch_E007_vanilla_starting_zones() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/01-starting-zones.sql"

    # Idempotence guard for the revert direction.
    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E007_REVERT" "${SQL_FILE}"; then
        echo "  [E007] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    # Revert-form hardcodes the literal upstream per-race default
    # coordinates pulled directly from
    # source-beta/data/sql/base/db_world/playercreateinfo.sql so the
    # restored state is exactly what AzerothCore ships. DK rows
    # (class=6, all at Ebon Hold) untouched in both directions.
    echo "  [E007] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E007_REVERT vanilla-starting-zones
-- Revert-form: restore each race's upstream default starting zone.
-- Values are literal from source-beta/data/sql/base/db_world/playercreateinfo.sql.
UPDATE `playercreateinfo` SET `map`=0,   `zone`=12,   `position_x`=-8949.95, `position_y`=-132.493,  `position_z`=83.5312, `orientation`=0       WHERE `race`=1  AND `class` != 6;  -- Human   → Northshire Valley
UPDATE `playercreateinfo` SET `map`=1,   `zone`=14,   `position_x`=-618.518, `position_y`=-4251.67,  `position_z`=38.718,  `orientation`=0       WHERE `race`=2  AND `class` != 6;  -- Orc     → Valley of Trials
UPDATE `playercreateinfo` SET `map`=0,   `zone`=1,    `position_x`=-6240.32, `position_y`=331.033,   `position_z`=382.758, `orientation`=6.17716 WHERE `race`=3  AND `class` != 6;  -- Dwarf   → Coldridge Valley
UPDATE `playercreateinfo` SET `map`=1,   `zone`=141,  `position_x`=10311.3,  `position_y`=832.463,   `position_z`=1326.41, `orientation`=5.69632 WHERE `race`=4  AND `class` != 6;  -- NElf    → Shadowglen
UPDATE `playercreateinfo` SET `map`=0,   `zone`=85,   `position_x`=1676.71,  `position_y`=1678.31,   `position_z`=121.67,  `orientation`=2.70526 WHERE `race`=5  AND `class` != 6;  -- Undead  → Deathknell
UPDATE `playercreateinfo` SET `map`=1,   `zone`=215,  `position_x`=-2917.58, `position_y`=-257.98,   `position_z`=52.9968, `orientation`=0       WHERE `race`=6  AND `class` != 6;  -- Tauren  → Camp Narache
UPDATE `playercreateinfo` SET `map`=0,   `zone`=1,    `position_x`=-6240.32, `position_y`=331.033,   `position_z`=382.758, `orientation`=0       WHERE `race`=7  AND `class` != 6;  -- Gnome   → Coldridge Valley (shared w/ Dwarves)
UPDATE `playercreateinfo` SET `map`=1,   `zone`=14,   `position_x`=-618.518, `position_y`=-4251.67,  `position_z`=38.718,  `orientation`=0       WHERE `race`=8  AND `class` != 6;  -- Troll   → Valley of Trials (shared w/ Orcs)
UPDATE `playercreateinfo` SET `map`=530, `zone`=3431, `position_x`=10349.6,  `position_y`=-6357.29,  `position_z`=33.4026, `orientation`=5.31605 WHERE `race`=10 AND `class` != 6;  -- BElf    → Sunstrider Isle
UPDATE `playercreateinfo` SET `map`=530, `zone`=3526, `position_x`=-3961.64, `position_y`=-13931.2,  `position_z`=100.615, `orientation`=2.08364 WHERE `race`=11 AND `class` != 6;  -- Draenei → Ammen Vale
SQL
}
# -- }}}

# -- {{{ patch_E006_initialize_config_files
# Initialize config files (.dist -> .conf) and apply profile-specific values
# Runs after build completes (PHASE_END)
# Parallelizable: No (sequential file operations)
# Uses TARGET_INSTALL_DIR (defaults to INSTALL_DIR, can be set to INSTALL_DIR_SHADOW)
patch_E006_initialize_config_files() {
    local TARGET="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    echo "  [E006] Initializing config files..."

    # Copy .dist files to .conf
    if [[ -f "${TARGET}/etc/authserver.conf.dist" ]]; then
        cp -f "${TARGET}/etc/authserver.conf.dist" "${TARGET}/etc/authserver.conf"
    fi

    if [[ -f "${TARGET}/etc/worldserver.conf.dist" ]]; then
        cp -f "${TARGET}/etc/worldserver.conf.dist" "${TARGET}/etc/worldserver.conf"
    fi

    if [[ -f "${TARGET}/etc/dbimport.conf.dist" ]]; then
        cp -f "${TARGET}/etc/dbimport.conf.dist" "${TARGET}/etc/dbimport.conf"
    fi

    # Copy module configs from source (cmake doesn't install them)
    # Module configs live in source/modules/mod-*/conf/*.conf.dist
    mkdir -p "${TARGET}/etc/modules"
    for mod_conf_dir in "${AC_CODE_DIR}/modules"/*/conf; do
        if [[ -d "${mod_conf_dir}" ]]; then
            for conf_dist in "${mod_conf_dir}"/*.conf.dist; do
                if [[ -f "${conf_dist}" ]]; then
                    local conf_name=$(basename "${conf_dist}")
                    cp -f "${conf_dist}" "${TARGET}/etc/modules/${conf_name}"
                    echo "    Copied ${conf_name}"
                fi
            done
        fi
    done

    # Initialize module configs (.dist -> .conf)
    if [[ -d "${TARGET}/etc/modules" ]]; then
        for conf_dist in "${TARGET}/etc/modules/"*.conf.dist; do
            if [[ -f "${conf_dist}" ]]; then
                cp -f "${conf_dist}" "${conf_dist%.dist}"
            fi
        done
    fi

    # Apply profile-specific config values (database, paths, gameplay settings)
    # Temporarily override INSTALL_DIR for config patches
    local ORIG_INSTALL_DIR="${INSTALL_DIR}"
    INSTALL_DIR="${TARGET}"
    apply_config_values
    INSTALL_DIR="${ORIG_INSTALL_DIR}"
}

unpatch_E006_initialize_config_files() {
    local TARGET="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    echo "  [E006] Removing config files (keeping .dist)..."

    # Remove .conf files (leave .dist files intact)
    [[ -f "${TARGET}/etc/authserver.conf" ]] && rm "${TARGET}/etc/authserver.conf"
    [[ -f "${TARGET}/etc/worldserver.conf" ]] && rm "${TARGET}/etc/worldserver.conf"
    [[ -f "${TARGET}/etc/dbimport.conf" ]] && rm "${TARGET}/etc/dbimport.conf"

    # Remove module configs
    if [[ -d "${TARGET}/etc/modules" ]]; then
        for conf in "${TARGET}/etc/modules/"*.conf; do
            if [[ -f "${conf}" && -f "${conf}.dist" ]]; then
                rm "${conf}"
            fi
        done
    fi
}
# -- }}}

# -- {{{ patch_E008_vanilla_remove_flight_paths
# Clear the flightmaster bit network-wide and replace gossip with
# per-NPC vanilla flavor lines (issue 148i).
#
# Merged SQL-patch idiom (same shape as E007 and E009). The apply-form
# is the hand-written 426-line SQL at
# sql/vanilla/db_world.src/03-remove-flight-paths.apply.sql; the
# E-patch copies it into the AC-watched active dir. The revert is
# inline because it's small: re-set the npcflag bit on the 163
# entries that previously had it (entry list pulled from R8), then
# drop the 90000-range gossip and text rows the apply inserted.
#
# Earlier shape (pre-2026-06-02-merged-pattern): E008 registered the
# include row in updates_include and treated the static SQL file as
# canonical. That worked but had no inverse — switching away from
# vanilla left the schema changes in place. The merged shape gives
# back full apply/unpatch symmetry: each direction overwrites the
# active file, AC re-runs on hash change, the DB state matches the
# patch direction.
#
# Revert limitation (carry-forward from R8): for flightmasters that
# originally had a non-zero gossip_menu_id (very rare — a handful of
# class trainer + flightmaster hybrids), the apply overwrote the
# original ID and the revert resets to 0, not to the original.
# Acceptable for the 156-NPC set since none of the spawned vanilla
# flightmasters have a confirmed hybrid role.
patch_E008_vanilla_remove_flight_paths() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/03-remove-flight-paths.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/03-remove-flight-paths.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E008_APPLY" "${SQL_FILE}"; then
        echo "  [E008] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E008] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E008] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E008_vanilla_remove_flight_paths() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/03-remove-flight-paths.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E008_REVERT" "${SQL_FILE}"; then
        echo "  [E008] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    # Revert restores the flightmaster bit (0x2000 = 8192) on the 163
    # entries that R8 enumerated as having the flag before the apply
    # cleared it. Hardcoded as a literal IN list so revert is exact —
    # see R8 Results in tmp/148-parallelization-roadmap.md and the raw
    # data at tmp/r8-flightmasters.tsv. The 156 spawned templates and
    # the 7 unused/UNUSED templates are all included so a future GM
    # re-spawn doesn't surface a flightmaster without the flag set.
    echo "  [E008] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E008_REVERT vanilla-remove-flight-paths
-- Revert-form: restore flightmaster bit on the 163 entries R8 enumerated,
-- reset gossip_menu_id for our 90000-range entries (limitation: original
-- non-zero values for hybrid trainer+flightmaster NPCs are lost), drop
-- the 90000-range gossip_menu and npc_text rows.

UPDATE `creature_template` SET `npcflag` = `npcflag` | 8192
WHERE `entry` IN (
    352,353,523,931,1233,1387,1571,1572,1573,1574,1575,2226,2299,2389,2409,2432,2835,2851,2858,
    2859,2861,2941,2995,3305,3310,3615,3838,3841,4267,4312,4314,4317,4319,4321,4407,4551,6026,
    6706,6726,7823,7824,8018,8019,8020,8609,8610,10378,10583,10897,11138,11139,11899,11900,
    11901,12577,12578,12596,12616,12617,12636,12740,13177,14242,15177,15178,16189,16192,16227,
    16587,16822,17554,17555,18785,18788,18789,18791,18807,18808,18809,18930,18931,18937,18938,
    18939,18940,18942,18953,19317,19558,19581,19583,20234,20515,20762,21107,21766,22216,22455,
    22485,22931,22935,23612,23736,23859,24032,24061,24155,24366,24795,24851,25288,26560,26566,
    26602,26842,26844,26845,26846,26847,26848,26850,26851,26852,26853,26876,26877,26878,26879,
    26880,26881,27046,27344,28037,28195,28196,28197,28574,28615,28618,28623,28624,28674,29480,
    29721,29750,29757,29762,29950,29951,30269,30271,30314,30433,30569,30869,30870,31069,31078,
    31426,32571,33849,37888,37915
);

UPDATE `creature_template` SET `gossip_menu_id` = 0
WHERE `gossip_menu_id` BETWEEN 90001 AND 90999;

DELETE FROM `gossip_menu` WHERE `MenuID` BETWEEN 90000 AND 90999;
DELETE FROM `npc_text`    WHERE `ID`     BETWEEN 90000 AND 90999;
SQL
}
# -- }}}

# -- {{{ patch_E009_vanilla_starting_equipment
# Apply vanilla profile's class-specific starting equipment kit
# (issue 148h). The apply form INSERTs a level-20 white-quality
# armor+weapon kit into playercreateinfo_item for all 51 valid
# non-DK (race, class) combinations, plus weapon-skill overrides.
#
# Merged SQL-patch idiom (same shape as E007). Difference from E007:
# the apply-form SQL is ~780 lines (autogenerated from the race-class
# kit matrix by scripts/generate-vanilla-starting-equipment-sql), so
# instead of heredocing it into this E-patch we keep the apply source
# at sql/vanilla/db_world.src/02-starting-equipment.apply.sql and the
# E-patch copies it into the AC-watched active dir. The revert is
# small enough to inline.
#
# To update the kit: edit scripts/generate-vanilla-starting-equipment-sql,
# regenerate the apply source file, install — AC sees the hash change
# on the active file and re-applies on next worldserver boot.
patch_E009_vanilla_starting_equipment() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/02-starting-equipment.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/02-starting-equipment.apply.sql"

    # Idempotence guard: if the active file already holds the apply
    # marker, the content matches the source and there's nothing to do.
    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E009_APPLY" "${SQL_FILE}"; then
        echo "  [E009] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E009] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E009] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E009_vanilla_starting_equipment() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/02-starting-equipment.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E009_REVERT" "${SQL_FILE}"; then
        echo "  [E009] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    # Revert hardcodes the explicit DELETEs that drop exactly the rows
    # the apply source INSERTed. The generator tags every row with a
    # Note/comment prefix of 'vanilla-148h-' so the wildcard matches
    # the full kit (mail-chest, mainhand-sword, dualwield-daggers, etc.)
    # without touching upstream defaults like the DK [TDB PH] row or
    # any default talent-skill entries.
    echo "  [E009] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E009_REVERT vanilla-starting-equipment
-- Revert-form: drop every row whose Note/comment carries the
-- 'vanilla-148h-' tag prefix. Default rows (upstream DK [TDB PH],
-- per-class talent skill entries) stay intact.
DELETE FROM `playercreateinfo_item`   WHERE `Note`    LIKE 'vanilla-148h-%';
DELETE FROM `playercreateinfo_skills` WHERE `comment` LIKE 'vanilla-148h-%';
SQL
}
# -- }}}

# -- {{{ patch_E010_vanilla_pretrain_abilities
# Grant every newly-created vanilla character the full set of
# class-trainer spells they'd normally learn by level 20 (issue 148j).
# 287 (classmask, spell) rows go into playercreateinfo_spell_custom
# with a 'vanilla-148j-' Note tag prefix.
#
# Merged SQL-patch idiom (same shape as E007/E008/E009). Apply source
# is 338 lines of generated SQL at
# sql/vanilla/db_world.src/04-pretrain-abilities.apply.sql (originally
# emitted by scripts/generate-148j-pretrain-sql; column names
# corrected on intake — schema is racemask/classmask, not race/class).
# Revert is a single DELETE-by-tag, inline.
#
# Dependency note: E009's off-hand kit items (Orc Hunter axes, every
# Rogue's twin daggers) need spell 674 "Dual Wield" to equip. This
# patch grants it, so E009's off-hand items become equippable only
# once both E009 and E010 have applied.
patch_E010_vanilla_pretrain_abilities() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/04-pretrain-abilities.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/04-pretrain-abilities.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E010_APPLY" "${SQL_FILE}"; then
        echo "  [E010] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E010] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E010] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E010_vanilla_pretrain_abilities() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/04-pretrain-abilities.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E010_REVERT" "${SQL_FILE}"; then
        echo "  [E010] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    # Revert drops exactly the 287 rows tagged with the 'vanilla-148j-'
    # Note prefix. Default rows in playercreateinfo_spell_custom (the
    # DK starter Blood Strike from death-knights.sql, any other class
    # defaults) stay intact.
    echo "  [E010] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E010_REVERT vanilla-pretrain-abilities
-- Revert-form: drop every pretrain row tagged 'vanilla-148j-'.
DELETE FROM `playercreateinfo_spell_custom` WHERE `Note` LIKE 'vanilla-148j-%';
SQL
}
# -- }}}

# -- {{{ patch_E019_vanilla_no_intro_cinematic
# Installs a BEFORE INSERT trigger on acore_characters_vanilla.characters
# that sets cinematic = 1 on every new row. AC's first-login flow plays
# the race intro only when cinematic = 0; pre-flipping it to 1 makes
# first login skip straight to gameplay.
#
# Vanilla-scoped — the trigger lives in acore_characters_vanilla only.
# Release/beta read a different characters DB so their race intros stay
# on for anyone who wants them. Requires log_bin_trust_function_creators
# = 1 in mysql/conf/my.cnf so ritz can install the trigger without
# SUPER (project-local MySQL is set that way).
patch_E019_vanilla_no_intro_cinematic() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/01-no-intro-cinematic.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/01-no-intro-cinematic.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E019_APPLY" "${SQL_FILE}"; then
        echo "  [E019] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E019] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)"

    echo "  [E019] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E019_vanilla_no_intro_cinematic() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/01-no-intro-cinematic.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E019_REVERT" "${SQL_FILE}"; then
        echo "  [E019] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)"

    echo "  [E019] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E019_REVERT vanilla-no-intro-cinematic
-- Revert-form: drop the trigger so cinematic defaults back to 0 and
-- race intros play on first login as upstream ships.
DROP TRIGGER IF EXISTS `tr_no_intro_cinematic`;
SQL
}
# -- }}}

# -- {{{ patch_E018_vanilla_kit_required_level_cap
# Lowers item_template.RequiredLevel on every entry that appears in
# the vanilla 148h starter kit so a level-20 character (vanilla's
# StartPlayerLevel per C007c) can actually equip the kit. The kit was
# tuned with Cuirboulli / Polished Scale armor at RequiredLevel 22 —
# without this patch the character spawns "stripped + bagful of
# unequippable kit" because ALE's auto-equip-starter-kit hook calls
# EquipItem and the engine returns ERR_CANT_EQUIP_LEVEL_I.
#
# Vanilla-DB scope only (acore_world_vanilla). Release/beta read a
# different world DB so their item_template stays as upstream
# shipped. ItemLevel column unchanged — tooltips still show the kit
# as item-level-22-ish gear; only the required-to-wear level moves.
patch_E018_vanilla_kit_required_level_cap() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/06-kit-required-level-cap.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/06-kit-required-level-cap.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E018_APPLY" "${SQL_FILE}"; then
        echo "  [E018] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E018] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E018] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E018_vanilla_kit_required_level_cap() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/06-kit-required-level-cap.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E018_REVERT" "${SQL_FILE}"; then
        echo "  [E018] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    # Revert: restore each affected item to its upstream RequiredLevel
    # by re-reading from a snapshot taken at apply time. The apply
    # source above doesn't snapshot today — it just UPDATEs in place —
    # so a clean revert needs the snapshot. Until that's added, this
    # unpatch is a soft revert: re-floor the level back to a baseline
    # of 22 which matches the Cuirboulli/Polished-Scale-armor tier the
    # majority of the kit was drawn from. Imperfect; tracked in 148h
    # follow-up.
    echo "  [E018] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E018_REVERT vanilla-kit-required-level-cap
-- Revert-form: floor RequiredLevel back to 22 for items we lowered.
-- Imperfect (no snapshot) — see 148h follow-up.
UPDATE `item_template`
   SET `RequiredLevel` = 22
 WHERE `entry` IN (
           SELECT DISTINCT `itemid`
             FROM `playercreateinfo_item`
            WHERE `Note` LIKE 'vanilla-148h-%'
       )
   AND `RequiredLevel` = 20;
SQL
}
# -- }}}

# -- {{{ patch_E011_beta_dk_class_system
# Death Knight class system for beta profile (issue 206/167). Wires DK
# from level 1 with progressive ability training via custom trainers
# 29194/29195/29196. Mysql-pipe variant (beta shares acore_world with
# release; cannot use UpdateFetcher without polluting release data).
# Source: sql/beta/db_world.src/11-dk-class-system.apply.sql.
patch_E011_beta_dk_class_system() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/11-dk-class-system.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/11-dk-class-system.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E011_APPLY" "${SQL_FILE}"; then
        echo "  [E011] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E011] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E011] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E011_beta_dk_class_system() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/11-dk-class-system.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E011_REVERT" "${SQL_FILE}"; then
        echo "  [E011] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E011] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E011_REVERT beta-dk-class-system
-- Revert-form: mirror the apply source's idempotence-clear block.
-- Trainer IDs 29194-29196 are project-owned DK trainers; the spell
-- list matches what the apply teaches at those IDs.
DELETE FROM `player_class_stats`            WHERE `Class` = 6 AND `Level` BETWEEN 1 AND 54;
DELETE FROM `playercreateinfo_spell_custom` WHERE `classmask` = 32;
DELETE FROM `playercreateinfo_item`         WHERE `class` = 6;
DELETE FROM `npc_trainer`                   WHERE `ID` IN (29194, 29195, 29196) AND `SpellID` IN (
    45902, 45477, 45462, 47541, 45470, 48263, 48266, 48265, 50842, 48721,
    45524, 56222, 45529, 57330, 48707, 43265, 46584
);
SQL
}
# -- }}}

# -- {{{ patch_E012_beta_drop_creatures_keep_essential
# Removes all creature spawns except critters and spirit healers
# (issue 203). Beta-profile clean slate for the ambush-spawn system —
# the world is empty by default and monsters spawn around players.
#
# Snapshot-based revert: the apply source captures the full pre-apply
# `creature` table into `wow_chat_e012_snapshot_creature` BEFORE
# destruction. The unpatch's revert reads from that snapshot to
# restore the pre-apply state, then drops the snapshot table.
patch_E012_beta_drop_creatures_keep_essential() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/12-drop-creatures-keep-essential.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/12-drop-creatures-keep-essential.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E012_APPLY" "${SQL_FILE}"; then
        echo "  [E012] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E012] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E012] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E012_beta_drop_creatures_keep_essential() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/12-drop-creatures-keep-essential.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E012_REVERT" "${SQL_FILE}"; then
        echo "  [E012] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E012] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E012_REVERT beta-drop-creatures-keep-essential
-- Revert-form: restore the `creature` table from the snapshot the
-- apply captured before its DELETEs ran, then drop the snapshot.
-- If the snapshot table is missing (e.g. apply never ran), the
-- restore is a no-op; the orphan-cleanup at the bottom is safe.
DELETE FROM `creature`;
INSERT INTO `creature` SELECT * FROM `wow_chat_e012_snapshot_creature`;
DROP TABLE IF EXISTS `wow_chat_e012_snapshot_creature`;

-- Drop the apply's working temp tables in case they were left behind.
DROP TABLE IF EXISTS `_essential_creatures`;
DROP TABLE IF EXISTS `_keep_guids`;
SQL
}
# -- }}}

# -- {{{ patch_E013_beta_quest_spells_to_trainers
# Adds quest-learned class abilities to custom trainer NPCs (issue 140).
# Beta has no quest NPCs, so abilities normally taught via quests get
# routed to trainers 200001-200020 instead.
patch_E013_beta_quest_spells_to_trainers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/13-quest-spells-to-trainers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/13-quest-spells-to-trainers.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E013_APPLY" "${SQL_FILE}"; then
        echo "  [E013] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E013] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E013] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E013_beta_quest_spells_to_trainers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/13-quest-spells-to-trainers.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E013_REVERT" "${SQL_FILE}"; then
        echo "  [E013] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E013] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E013_REVERT beta-quest-spells-to-trainers
-- Revert-form: drop every row in the project's custom trainer ID
-- range (200001-200020). All IDs in that range are project-owned.
DELETE FROM `npc_trainer` WHERE `ID` BETWEEN 200001 AND 200020;
SQL
}
# -- }}}

# -- {{{ patch_E014_beta_trainer_spell_level_cap
# Caps each beta trainer's spell list to its assigned maxLevel (issue
# 157). Creates tiered trainer system where different trainers teach
# different level ranges.
#
# Snapshot-based revert: the apply source captures the full pre-apply
# `npc_trainer` table into `wow_chat_e014_snapshot_npc_trainer` BEFORE
# the per-trainer DELETEs run. The unpatch's revert reads from that
# snapshot to restore the pre-apply state, then drops the snapshot.
patch_E014_beta_trainer_spell_level_cap() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/14-trainer-spell-level-cap.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/14-trainer-spell-level-cap.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E014_APPLY" "${SQL_FILE}"; then
        echo "  [E014] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E014] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E014] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E014_beta_trainer_spell_level_cap() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/14-trainer-spell-level-cap.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E014_REVERT" "${SQL_FILE}"; then
        echo "  [E014] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E014] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E014_REVERT beta-trainer-spell-level-cap
-- Revert-form: restore `npc_trainer` from the snapshot the apply
-- captured before its DELETEs ran, then drop the snapshot.
-- This also restores E011's DK-trainer rows and E013's 200xxx rows
-- (the snapshot was taken AFTER they ran, so they're in the snapshot).
DELETE FROM `npc_trainer`;
INSERT INTO `npc_trainer` SELECT * FROM `wow_chat_e014_snapshot_npc_trainer`;
DROP TABLE IF EXISTS `wow_chat_e014_snapshot_npc_trainer`;
SQL
}
# -- }}}

# -- {{{ patch_E015_beta_class_selector_npcs
# Race-specific selector NPCs for the custom class selection system
# (issue 155). Custom entries 900001-900011 in creature_template and
# creature_template_model.
patch_E015_beta_class_selector_npcs() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/15-class-selector-npcs.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/15-class-selector-npcs.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E015_APPLY" "${SQL_FILE}"; then
        echo "  [E015] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E015] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E015] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E015_beta_class_selector_npcs() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/15-class-selector-npcs.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E015_REVERT" "${SQL_FILE}"; then
        echo "  [E015] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E015] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E015_REVERT beta-class-selector-npcs
-- Revert-form: drop the project's custom selector NPCs and models.
-- Entry IDs 900001-900011 are project-owned (900009 skipped — Goblin,
-- absent in WotLK; see apply source for rationale).
DELETE FROM `creature_template`       WHERE `entry`      IN (900001, 900002, 900003, 900004, 900005, 900006, 900007, 900008, 900010, 900011);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (900001, 900002, 900003, 900004, 900005, 900006, 900007, 900008, 900010, 900011);
SQL
}
# -- }}}

# -- {{{ patch_E016_beta_empty_loot_chests
# Custom gameobject templates for empty-loot treasure chests (issue
# 160). Visual clones of vanilla chests with data1=0 so Lua chest
# scripts can inject loot dynamically. Custom entries 900001-900037
# in gameobject_template.
patch_E016_beta_empty_loot_chests() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/16-empty-loot-chests.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/16-empty-loot-chests.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E016_APPLY" "${SQL_FILE}"; then
        echo "  [E016] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E016] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E016] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E016_beta_empty_loot_chests() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/16-empty-loot-chests.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E016_REVERT" "${SQL_FILE}"; then
        echo "  [E016] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)"

    echo "  [E016] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E016_REVERT beta-empty-loot-chests
-- Revert-form: drop the project's custom empty-loot gameobjects.
-- Entry range 900001-900037 is project-owned.
DELETE FROM `gameobject_template` WHERE `entry` BETWEEN 900001 AND 900037;
SQL
}
# -- }}}

# -- {{{ patch_E017_beta_relocate_logout_texts
# Fixes upstream mod-playerbots migration ordering bug (the
# 03_13/03_14/03_26 sequence has an ID conflict on bot_text rows).
# Targets acore_playerbots (shared with release).
#
# Snapshot-based revert: the apply source captures the two named rows
# from ai_playerbot_texts and ai_playerbot_texts_chance before
# renumbering. Revert restores from snapshot and drops the snapshot.
patch_E017_beta_relocate_logout_texts() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_playerbots/17-relocate-logout-texts.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_playerbots.src/17-relocate-logout-texts.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E017_APPLY" "${SQL_FILE}"; then
        echo "  [E017] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E017] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_playerbots" "$(_profile_db_name acore_playerbots)"

    echo "  [E017] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E017_beta_relocate_logout_texts() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_playerbots/17-relocate-logout-texts.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E017_REVERT" "${SQL_FILE}"; then
        echo "  [E017] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_playerbots" "$(_profile_db_name acore_playerbots)"

    echo "  [E017] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E017_REVERT beta-relocate-logout-texts
-- Revert-form: restore the two named rows in ai_playerbot_texts and
-- ai_playerbot_texts_chance from the snapshots the apply captured
-- before renumbering them. Snapshots are small (2-4 rows total).
DELETE FROM `ai_playerbot_texts`        WHERE `name` IN ('bot_not_your_master', 'bot_rndbot_no_logout');
DELETE FROM `ai_playerbot_texts_chance` WHERE `name` IN ('bot_not_your_master', 'bot_rndbot_no_logout');

INSERT INTO `ai_playerbot_texts`        SELECT * FROM `wow_chat_e017_snapshot_texts`;
INSERT INTO `ai_playerbot_texts_chance` SELECT * FROM `wow_chat_e017_snapshot_chance`;

DROP TABLE IF EXISTS `wow_chat_e017_snapshot_texts`;
DROP TABLE IF EXISTS `wow_chat_e017_snapshot_chance`;
SQL
}
# -- }}}

