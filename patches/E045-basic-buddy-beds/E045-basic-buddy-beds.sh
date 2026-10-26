#!/usr/bin/env bash

E045_DIR="${BASH_SOURCE[0]%/*}"

patch_E045_basic_buddy_beds() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/28-buddy-beds.sql"
    local SRC_FILE="${E045_DIR}/28-buddy-beds.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E045] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E045] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E045] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E045_basic_buddy_beds() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/28-buddy-beds.sql"
    local SRC_FILE="${E045_DIR}/28-buddy-beds.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E045_REVERT" "${SQL_FILE}"; then
        echo "  [E045] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E045] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E045] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
