#!/usr/bin/env bash

patch_E043_basic_buddy_selector() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/26-buddy-selector.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/26-buddy-selector.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E043] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E043] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E043] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E043_basic_buddy_selector() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/26-buddy-selector.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/26-buddy-selector.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E043_REVERT" "${SQL_FILE}"; then
        echo "  [E043] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E043] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E043] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
