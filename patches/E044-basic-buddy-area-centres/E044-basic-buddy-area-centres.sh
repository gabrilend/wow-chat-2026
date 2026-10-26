#!/usr/bin/env bash

E044_DIR="${BASH_SOURCE[0]%/*}"

patch_E044_basic_buddy_area_centres() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/27-buddy-area-centres.sql"
    local SRC_FILE="${E044_DIR}/27-buddy-area-centres.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E044] Apply source missing: ${SRC_FILE} (run scripts/generate-buddy-area-centres)"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E044] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E044] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E044_basic_buddy_area_centres() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/27-buddy-area-centres.sql"
    local SRC_FILE="${E044_DIR}/27-buddy-area-centres.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E044_REVERT" "${SQL_FILE}"; then
        echo "  [E044] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E044] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E044] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
