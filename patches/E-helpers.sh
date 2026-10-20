#!/usr/bin/env bash
# E-helpers.sh - what the install steps share, loaded first by patches/E-patches.sh
#
# For a general audience: the install steps (one file each, patches/E0NN-*.sh)
# lean on a few shared tools: registering an SQL folder with the server's
# database updater, naming a profile's databases, applying the settings
# patches (config/patches/C*.sh). They live here, split out of the old
# single E-patches.sh by scripts/split-install-steps (issue 150).

DIR="${DIR:-/mnt/kaun/wow-chat-2026}"
declare -gA STAGED_SQL_DIRS=()

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

    # Canonicalize before registering. ${DIR} defaults to the
    # /home/ritz spelling, which is a symlink to /mnt/mtwo; a run under
    # one ${DIR} and a run under the other insert two include rows for
    # the SAME physical directory (path is the PRIMARY KEY, so both
    # rows survive). AC's UpdateFetcher then scans both, finds every
    # .sql twice, and aborts the whole DB update with "Duplicate
    # filename ... every name needs to be unique" — a hard boot crash.
    # Resolving to the real path keeps a single canonical include row
    # no matter which ${DIR} spelling ran the install.
    DIR_PATH="$(readlink -f "${DIR_PATH}")"

    # Issue 183: the folder the steps write is staging; the updater scans
    # its twin, <folder>.updater/, which _mirror_staged_sql fills at the end
    # of the install steps with every file renamed z_<name> (after every
    # upstream update) and stamped with the commits it was installed
    # against (so a pin move runs it again). Remembered here for the mirror.
    local STAGING="${DIR_PATH}"
    STAGED_SQL_DIRS["${STAGING}"]="${DB}"
    DIR_PATH="${STAGING}.updater"
    mkdir -p "${DIR_PATH}"

    # If MySQL isn't up the include row can be inserted on a later
    # install pass. Worldserver picks it up on next boot regardless
    # of when the row was added. This is a deferral, so say so: until a
    # pass runs with MySQL up, this directory's SQL is never applied.
    if [[ ! -S "${MYSQL_SOCKET}" ]]; then
        echo "    NOTICE: MySQL not running — ${DIR_PATH} NOT registered in ${DB}.updates_include"
        echo "            (re-run install/apply-patches with MySQL up, or this SQL never applies)"
        return 0
    fi

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
    # MySQL is up, so a failure here is real (database missing, bad
    # credentials): report it and fail the calling step. Errors used to be
    # discarded (2>/dev/null || true), which hid exactly the "include row
    # never lands" failure described above.
    "${MYSQL_DIR}/bin/mysql" --no-defaults --socket="${MYSQL_SOCKET}" \
        -u ritz -pmenardi "${DB}" <<SQL || { echo "    ERROR: could not register ${DIR_PATH} in ${DB}.updates_include (database=${DB}, socket=${MYSQL_SOCKET})"; return 1; }
CREATE TABLE IF NOT EXISTS \`updates_include\` (
  \`path\` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'directory to include. \$ means relative to the source directory.',
  \`state\` enum('RELEASED','ARCHIVED','CUSTOM','PENDING') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'RELEASED' COMMENT 'defines if the directory contains released or archived updates.',
  PRIMARY KEY (\`path\`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='List of directories where we want to include sql updates.';
INSERT IGNORE INTO \`updates_include\` (\`path\`, \`state\`) VALUES ('${DIR_PATH}', 'CUSTOM');
DELETE FROM \`updates_include\` WHERE \`path\` = '${STAGING}';
SQL
}
# -- }}}

# -- {{{ _sql_install_stamp
# The first line of every mirrored file (issue 183): the commits the server
# is built from, the core's and each module's with a git history. A pin move
# changes it, so every mirrored file's hash changes and the updater runs it
# again, after upstream's new updates. Computed once per install run.
_sql_install_stamp() {
    if [[ -z "${SQL_INSTALL_STAMP:-}" ]]; then
        local parts="core=$(git -C "${AC_CODE_DIR}" rev-parse --short=12 HEAD 2>/dev/null || echo none)"
        local mod
        for mod in "${AC_CODE_DIR}"/modules/*/; do
            [[ -d "${mod}.git" ]] || continue
            parts+=" $(basename "${mod}")=$(git -C "${mod}" rev-parse --short=8 HEAD)"
        done
        SQL_INSTALL_STAMP="-- installed against ${parts} (issue 183: a pin move changes this line, so the updater runs the file again, after upstream's)"
    fi
    echo "${SQL_INSTALL_STAMP}"
}
# -- }}}

# -- {{{ _mirror_staged_sql
# Every staging folder the steps registered this run, mirrored into the twin
# the updater scans (issue 183): each staged foo.sql as z_foo.sql, the stamp
# first, the file after it, written only when it differs; a twin file whose
# staged one is gone is removed. Run at the end of the install steps (and of
# their reverts), so it sees whatever they wrote.
_mirror_staged_sql() {
    local staging twin stamp f name wrote=0 kept=0 removed=0
    stamp="$(_sql_install_stamp)"
    for staging in "${!STAGED_SQL_DIRS[@]}"; do
        twin="${staging}.updater"
        mkdir -p "${twin}"
        for f in "${staging}"/*.sql; do
            [[ -f "${f}" ]] || continue
            name="z_$(basename "${f}")"
            if [[ -f "${twin}/${name}" ]] && cmp -s <(echo "${stamp}"; cat "${f}") "${twin}/${name}"; then
                kept=$((kept + 1))
            else
                { echo "${stamp}"; cat "${f}"; } > "${twin}/${name}"
                wrote=$((wrote + 1))
            fi
        done
        for f in "${twin}"/z_*.sql; do
            [[ -f "${f}" ]] || continue
            [[ -f "${staging}/$(basename "${f}" | sed 's/^z_//')" ]] && continue
            rm "${f}"
            removed=$((removed + 1))
        done
        _forget_unprefixed_updates "${staging}" "${STAGED_SQL_DIRS[${staging}]}"
    done
    echo "  SQL for the updater (issue 183): ${wrote} written, ${kept} unchanged, ${removed} removed, in ${#STAGED_SQL_DIRS[@]} folders"
}
# -- }}}

# -- {{{ _forget_unprefixed_updates
# Before issue 183 the updater read the staging folders themselves, so the
# database recorded each file by its own name (04-buddy-roster.sql); since,
# it reads the twin and records z_04-buddy-roster.sql. The old record stays,
# and at every start the server warns that the file "was applied to the
# database, but is missing in your update directory now" (35 such warnings
# on basic, 2026-10-18; a warning is an error by the house rules). This
# removes, from the folder's database, the record of each of THIS folder's
# files under its old name, and only where its z_ record is there too: the
# file is still recorded as applied, once, under the name the updater now
# uses, so nothing runs again. Upstream's records are never named here.
#   staging  path    a staging folder (its *.sql are the names to forget)
#   db       string  the database its updater rows live in
_forget_unprefixed_updates() {
    local staging=$1 db=$2
    local MYSQL_DIR="${DIR}/mysql/installed-files"
    local MYSQL_SOCKET="${DIR}/mysql/databases/mysql.sock"
    local names="" f
    for f in "${staging}"/*.sql; do
        [[ -f "${f}" ]] || continue
        names+="${names:+,}'$(basename "${f}")'"
    done
    [[ -n "${names}" ]] || return 0
    if [[ ! -S "${MYSQL_SOCKET}" ]]; then
        echo "    NOTICE: MySQL not running: old update names in ${db} not tidied (the next install will)"
        return 0
    fi
    local gone
    gone="$("${MYSQL_DIR}/bin/mysql" --no-defaults --socket="${MYSQL_SOCKET}" -u ritz -pmenardi -N "${db}" -e \
        "DELETE o FROM updates o JOIN updates z ON z.name = CONCAT('z_', o.name) WHERE o.name IN (${names}); SELECT ROW_COUNT();" 2>/dev/null)" ||
        { echo "    ERROR: could not tidy the old update names in ${db} (${staging#${DIR}/})"; return 1; }
    [[ "${gone}" == "0" ]] || echo "    ${db}: ${gone} old update name(s) forgotten (their z_ records stay)"
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
    # Canonicalize to match how _register stores it (real path, not the
    # /home/ritz symlink spelling) so the DELETE actually hits the row.
    # Both the staging folder's row (from before issue 183) and its twin's.
    local DIR_PATH; DIR_PATH="$(readlink -f "$1")"
    _unregister_one "${DIR_PATH}.updater" "$2" || return 1
    _unregister_one "${DIR_PATH}" "$2"
}
_unregister_one() {
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
# release and beta share the unsuffixed namespace; vanilla, alpha, basic and
# cc-test carry _vanilla / _alpha / _basic / _cc_test suffixes for data isolation.
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
        release)      echo "${base}" ;;
        beta)         echo "${base}_beta" ;;   # its own since 2026-10-17 (issue 136b): it used to share release's, so installing beta emptied release's world
        vanilla)      echo "${base}_vanilla" ;;
        basic)        echo "${base}_basic" ;;
        cc-test)      echo "${base}_cc_test" ;;   # underscore: a hyphen is not allowed in an unquoted database name
        alpha)        echo "${base}_alpha" ;;
        *)
            echo "ERROR: _profile_db_name called for unknown profile '${PROFILE}'" >&2
            return 1
            ;;
    esac
}
# -- }}}

# -- {{{ _shared_sql_src
# Folder holding a profile's source SQL for the steps it shares with another
# profile. basic (issue 155) runs vanilla's flight-path removal (E008), skipped
# intro cinematic (E019) and riding levels (E020) with exactly vanilla's
# content, so it reads vanilla's source files instead of keeping copies (one
# source of truth: a tuning change lands on both). Only those three steps use
# this; everything basic owns lives in sql/basic/.
# (Symbolic links under sql/basic/ did the same job first; they were replaced
# by this table so the sharing is visible in code and the links do not have
# to survive every tool that copies or commits the tree.)
# Args: $1 = database folder name (db_world, db_characters)
_shared_sql_src() {
    local -A SHARED_SQL_FROM=( [basic]="vanilla" )
    local from="${SHARED_SQL_FROM[${PROFILE}]:-${PROFILE}}"
    echo "${DIR}/sql/${from}/${1}.src"
}
# -- }}}

# -- {{{ _buddy_sql_src
# Folder holding the source SQL of the buddy module's data steps (E042 roster
# tables, E044 area centres, E045 beds and boardings, E050 town circles, E052
# gearsets). basic owns these files; cc-test (issue 176) builds the buddy
# module too (owner, 2026-10-08: "cc-test should include it", for the Alterac
# Valley stand-ins) and reads basic's sources rather than keeping copies, so a
# change to a bed or a gearset lands on both. The active copy each step writes
# stays in the profile's own sql/<profile>/db_*/ folder, registered against
# the profile's own database. Every other profile reads its own folder.
# Args: $1 = database folder name (db_world, db_characters)
_buddy_sql_src() {
    local -A BUDDY_SQL_FROM=( [cc-test]="basic" )
    local from="${BUDDY_SQL_FROM[${PROFILE}]:-${PROFILE}}"
    echo "${DIR}/sql/${from}/${1}.src"
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
    # Config functions in the order their files were loaded (C001 first).
    # Application order matters: C017 reads the MaxPlayerLevel that a
    # C006* patch writes, so it must run after it. `declare -F` lists
    # functions alphabetically by name, which put config_level_correlated_caps
    # (C017) ahead of config_max_level_60 (C006d) -- C017 then read the
    # stock 80 and pinned StartHeroicPlayerLevel and RecruitAFriend.MaxLevel
    # to 80, which fail the server's "<= MaxPlayerLevel" check at boot.
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

    # Output grouped by profile: "all" first, then every profile name some
    # gate mentions, sorted. This used to be a hard-coded "all alpha beta
    # release", which silently left vanilla-only (and later basic-only)
    # patches out of the printed summary even though they were applied.
    local listed_profiles
    listed_profiles=$(printf '%s\n' "${!patches_by_profile[@]}" | grep -vx 'all' | sort)
    for profile in all ${listed_profiles}; do
        [[ -z "${patches_by_profile[$profile]:-}" ]] && continue
        echo "    ${profile}:"
        while IFS= read -r p; do
            [[ -n "$p" ]] && echo "      $p"
        done <<< "${patches_by_profile[$profile]}"
    done

    # Sort every config_ function by the file that defined it, then by its
    # line in that file. With extdebug on, `declare -F name` answers
    # "name line file"; the file names carry the C001, C002... order.
    local config_funcs_in_file_order
    config_funcs_in_file_order=$(
        shopt -s extdebug
        for fn in $(declare -F | sed -n 's/^declare -f \(config_.*\)/\1/p'); do
            declare -F "${fn}"
        done | sort -k3,3 -k2,2n | cut -d' ' -f1
    )

    echo "  Applying for profile '${PROFILE}':"
    local applied_count=0
    local failed_count=0
    for func in ${config_funcs_in_file_order}; do
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

# -- {{{ _beta_two_side_step
# Beta's four cross-faction permissions (issue 193): trading, mail, the /who
# list and adding friends across the factions are permissions in the
# accounts database in today's server, not settings. Each of E062-E065
# grants one to every account level on beta's realm only, through the
# server's database updater, from SQL that scripts/generate-beta-two-side-sql
# writes (it reads beta's realm number from C019). The accounts database is
# shared by every realm (acore_auth, never a per-profile name), so every
# realm's server reads this folder too and applies the same rows; the realm
# number in them keeps them beta's. The revert form removes that one
# permission's rows for beta's realm. Same cp-apply / cp-revert idiom as E061.
#   $1 = the step (E062), $2 = the files' stem (01-two-side-trade),
#   $3 = apply or revert
_beta_two_side_step() {
    local step="$1" stem="$2" form="$3"
    local MARK; MARK=$(echo "${form}" | tr '[:lower:]' '[:upper:]')
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_auth/${stem}.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_auth.src/${stem}.${form}.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [${step}] ${form} source missing: ${SRC_FILE} (scripts/generate-beta-two-side-sql writes it)"; return 1; }
    mkdir -p "${DIR}/sql/${PROFILE}/db_auth"

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_auth" "acore_auth" || return 1

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_${step}_${MARK}" "${SQL_FILE}"; then
        echo "  [${step}] Active file already holds ${form}-form content"
        return 0
    fi

    echo "  [${step}] Copying ${form}-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
