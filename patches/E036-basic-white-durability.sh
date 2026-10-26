#!/usr/bin/env bash

patch_E036_basic_white_durability() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/21-white-durability.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/21-white-durability.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E036] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E036] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E036] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E036_basic_white_durability() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/21-white-durability.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/21-white-durability.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E036_REVERT" "${SQL_FILE}"; then
        echo "  [E036] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E036] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E036] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
