#!/usr/bin/env bash

patch_E055_basic_buddy_subareas() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/36-buddy-subareas.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/36-buddy-subareas.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E055] Apply source missing: ${SRC_FILE} (run scripts/generate-buddy-subareas)"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E055] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E055] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E055_basic_buddy_subareas() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/36-buddy-subareas.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/36-buddy-subareas.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E055_REVERT" "${SQL_FILE}"; then
        echo "  [E055] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E055] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E055] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
