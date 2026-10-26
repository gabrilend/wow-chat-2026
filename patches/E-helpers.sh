#!/usr/bin/env bash

DIR="${DIR:-/mnt/kaun/wow-chat-2026}"
declare -gA STAGED_SQL_DIRS=()

_register_with_updatefetcher() {
    local DIR_PATH="$1"
    local DB="$2"
    local MYSQL_DIR="${DIR}/mysql/installed-files"
    local MYSQL_SOCKET="${DIR}/mysql/databases/mysql.sock"

    mkdir -p "${DIR_PATH}"

    DIR_PATH="$(readlink -f "${DIR_PATH}")"

    local STAGING="${DIR_PATH}"
    STAGED_SQL_DIRS["${STAGING}"]="${DB}"
    DIR_PATH="${STAGING}.updater"
    mkdir -p "${DIR_PATH}"

    if [[ ! -S "${MYSQL_SOCKET}" ]]; then
        echo "    NOTICE: MySQL not running — ${DIR_PATH} NOT registered in ${DB}.updates_include"
        echo "            (re-run install/apply-patches with MySQL up, or this SQL never applies)"
        return 0
    fi

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

_unregister_from_updatefetcher() {
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

place_carried() {
    local from="$1" to="$2"
    [[ -e "${from}" ]] || { echo "    ERROR: the carried ${from} is missing (is it in the patch's directory, and in git?)"; return 1; }
    [[ -d "$(dirname "${to}")" ]] || { echo "    ERROR: ${to%/*}/ does not exist, so ${from##*/} has nowhere to go"; return 1; }
    rm -rf "${to:?}"
    cp -r "${from}" "${to}" || { echo "    ERROR: could not copy ${from} to ${to}"; return 1; }
}

remove_carried() {
    rm -rf "${1:?}"
}

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

apply_settings_patch() {
    local id="$1" files file func desc
    files=( "${DIR}/config/patches/${id}-"*.sh )
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

_beta_two_side_step() {
    local step="$1" stem="$2" form="$3"
    local MARK; MARK=$(echo "${form}" | tr '[:lower:]' '[:upper:]')
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_auth/${stem}.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_auth.src/${stem}.${form}.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [${step}] ${form} source missing: ${SRC_FILE} (scripts/generate-beta-two-side-sql writes it)"; return 1; }
    mkdir -p "${DIR}/sql/${PROFILE}/db_auth"

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_auth" "acore_auth" || return 1

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_${step}_${MARK}" "${SQL_FILE}"; then
        echo "  [${step}] Active file already holds ${form}-form content"
        return 0
    fi

    echo "  [${step}] Copying ${form}-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
