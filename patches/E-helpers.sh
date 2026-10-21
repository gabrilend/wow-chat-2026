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
    # of the SQL stage with every file under its own name, stamped with the
    # commits it was installed against (so a pin move runs it again).
    # Remembered here for the mirror. (Until issue 189d the copies were
    # renamed z_<name>, to sort after every upstream update; since, the
    # build's gate 2000 starts the server once before our SQL is placed, so
    # upstream's are applied first by time, not by name.)
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
# the updater scans (issue 183): each staged foo.sql under its own name, the
# stamp first, the file after it, written only when it differs; a twin file
# whose staged one is gone is removed (so are the z_ copies of before issue
# 189d, whose staged files never had that name). Run at the end of the SQL
# stage (and of its reverts), so it sees whatever the steps wrote; the
# server's next start, the build's validation, applies them.
_mirror_staged_sql() {
    local staging twin stamp f name wrote=0 kept=0 removed=0
    stamp="$(_sql_install_stamp)"
    for staging in "${!STAGED_SQL_DIRS[@]}"; do
        twin="${staging}.updater"
        mkdir -p "${twin}"
        for f in "${staging}"/*.sql; do
            [[ -f "${f}" ]] || continue
            name="$(basename "${f}")"
            if [[ -f "${twin}/${name}" ]] && cmp -s <(echo "${stamp}"; cat "${f}") "${twin}/${name}"; then
                kept=$((kept + 1))
            else
                { echo "${stamp}"; cat "${f}"; } > "${twin}/${name}"
                wrote=$((wrote + 1))
            fi
        done
        for f in "${twin}"/*.sql; do
            [[ -f "${f}" ]] || continue
            [[ -f "${staging}/$(basename "${f}")" ]] && continue
            rm "${f}"
            removed=$((removed + 1))
        done
        _forget_z_prefixed_updates "${staging}" "${STAGED_SQL_DIRS[${staging}]}" || return 1
    done
    echo "  SQL for the updater (issue 183): ${wrote} written, ${kept} unchanged, ${removed} removed, in ${#STAGED_SQL_DIRS[@]} folders"
}
# -- }}}

# -- {{{ _forget_z_prefixed_updates
# The switch-over from issue 183's z_ names (issue 189d; the owner chose it
# to happen on the next install by itself). From 183 to 189d the updater
# read each file as z_<name> and recorded it so; since 189d it reads the
# file under its own name. A z_ record left behind would make the server
# warn at every start that a file it applied "is missing in your update
# directory now" (a warning is an error by the house rules), so this
# forgets, from the folder's database, the z_ record of each of THIS
# folder's files. The file is then applied once more under its own name at
# the next start (every one of our files is written to be safe to run
# again; a pin move has always run them all again). Upstream's records are
# never named here (none of them is z_ plus one of our names). Once the
# switch is done there is nothing left to forget, and it says nothing.
# (It replaced _forget_unprefixed_updates, which did the reverse for 183's
# own switch: it forgot the old plain names where a z_ record stood.)
#   staging  path    a staging folder (its *.sql are the names)
#   db       string  the database its updater rows live in
_forget_z_prefixed_updates() {
    local staging=$1 db=$2
    local MYSQL_DIR="${DIR}/mysql/installed-files"
    local MYSQL_SOCKET="${DIR}/mysql/databases/mysql.sock"
    local names="" f
    for f in "${staging}"/*.sql; do
        [[ -f "${f}" ]] || continue
        names+="${names:+,}'z_$(basename "${f}")'"
    done
    [[ -n "${names}" ]] || return 0
    # MySQL down: an error, not a notice. The SQL stage comes after gate
    # 2000, where the server has just started against these databases, so
    # MySQL is up unless something broke in between.
    if [[ ! -S "${MYSQL_SOCKET}" ]]; then
        echo "    ERROR: MySQL is not running, so the z_ records in ${db} could not be forgotten (${staging#${DIR}/})"
        return 1
    fi
    local gone
    gone="$("${MYSQL_DIR}/bin/mysql" --no-defaults --socket="${MYSQL_SOCKET}" -u ritz -pmenardi -N "${db}" -e \
        "DELETE FROM updates WHERE name IN (${names}); SELECT ROW_COUNT();" 2> >(grep -v "Using a password on the command line" >&2))" ||
        { echo "    ERROR: could not forget the z_ update records in ${db} (${staging#${DIR}/})"; return 1; }
    [[ "${gone}" == "0" ]] || echo "    ${db}: ${gone} z_ update record(s) forgotten; those files apply again under their own names at the next start (issue 189d)"
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

# -- {{{ place_carried
# A patch that is a directory (issue 189e) carries the files it applies;
# its bash file places them with this when applied. The templates stay in
# the patch's directory in git; the placed copies, in the install (or the
# source tree), never are. A copy already there is replaced whole, so an
# edited template, or a file taken out of the patch, is never left stale.
#   $1 = what is placed: a file or folder inside the patch's directory
#   $2 = where it goes: the full path of the copy
place_carried() {
    local from="$1" to="$2"
    [[ -e "${from}" ]] || { echo "    ERROR: the carried ${from} is missing (is it in the patch's directory, and in git?)"; return 1; }
    # the copy's folder must exist (the install's lua_scripts/, say): a
    # missing one means the step runs too early, or the path is wrong
    [[ -d "$(dirname "${to}")" ]] || { echo "    ERROR: ${to%/*}/ does not exist, so ${from##*/} has nowhere to go"; return 1; }
    rm -rf "${to:?}"
    cp -r "${from}" "${to}" || { echo "    ERROR: could not copy ${from} to ${to}"; return 1; }
}
# -- }}}

# -- {{{ remove_carried
# The undo of place_carried: the placed copy goes; the template stays.
#   $1 = the full path of the copy
remove_carried() {
    rm -rf "${1:?}"
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

# -- {{{ apply_settings_patch
# One settings patch (config/patches/C*.sh, issue 119) into the installed
# server's config files: the install stage runs these at their own
# priorities since issue 189c (before, E006 ran them all inside itself).
# The function's name comes from the file's: C006b-max-level-20.sh holds
# config_max_level_20 (the id and its dash dropped, dashes made underscores).
# The files were sourced by patches/patches.sh when it loaded.
# Writes into TARGET_INSTALL_DIR when the build sets it (the shadow install
# being built) and INSTALL_DIR otherwise, as E006 did for them; the patches
# themselves read INSTALL_DIR, so it is shadowed here for the call.
# Prints "[✓] about" or "[✗] about - FAILED"; returns the patch's status.
#   $1 = the patch's id (C006b)
apply_settings_patch() {
    local id="$1" files file func desc
    files=( "${DIR}/config/patches/${id}-"*.sh )
    # one file, or the id names nothing (or two files share it): an error,
    # since the headers said this profile takes it
    if [[ ${#files[@]} -ne 1 || ! -f "${files[0]}" ]]; then
        echo "    [✗] ${id} - FAILED: expected one file ${DIR}/config/patches/${id}-*.sh, found ${#files[@]}"
        return 1
    fi
    file="$(basename "${files[0]}" .sh)"
    func="config_${file#"${id}"-}"
    func="${func//-/_}"
    if ! declare -F "${func}" > /dev/null; then
        echo "    [✗] ${id} - FAILED: ${file}.sh defines no function ${func} (was it sourced? patches/patches.sh does that)"
        return 1
    fi
    desc="${CONFIG_DESCRIPTIONS[$func]:-${func}}"
    local INSTALL_DIR="${TARGET_INSTALL_DIR:-${INSTALL_DIR}}"
    if ${func}; then
        echo "    [✓] ${desc}"
    else
        echo "    [✗] ${desc} - FAILED"
        return 1
    fi
}
# -- }}}

# -- {{{ apply_config_values
# Every settings patch the current profile takes, in the order the build
# runs them (lowest priority first, from the patches' headers by way of
# patches/patches.sh's install list), and nothing else. The build itself no
# longer calls this: apply_patches_end runs each settings patch in its turn
# among the install steps. scripts/test-profile-config-gates calls it to lay
# a profile's settings over stock config files, so the test applies exactly
# the patches, and the order, that an install does.
# Unlike the build, a failure does not stop the rest: every patch is tried
# so the report names every failure; the return is 1 if any failed.
# Needs patches/patches.sh loaded (it builds the lists and sources the files).
apply_config_values() {
    if ! declare -p PHASE_END_PATCHES > /dev/null 2>&1; then
        echo "  ERROR: no install list is loaded (source patches/patches.sh first)"
        return 1
    fi
    echo "  Applying for profile '${PROFILE}':"
    local id applied_count=0 failed_count=0
    for id in ${PHASE_END_PATCHES[$PROFILE]:-}; do
        [[ "${id}" == C* ]] || continue                  # an install step, not a settings patch
        if apply_settings_patch "${id}"; then
            ((applied_count++)) || true
        else
            ((failed_count++)) || true
        fi
    done
    echo "  Applied ${applied_count} config patches"
    if [[ ${failed_count} -gt 0 ]]; then
        echo "  ERROR: ${failed_count} config patches failed"
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
