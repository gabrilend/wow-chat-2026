#!/usr/bin/env bash

patch_E057_basic_belt_buckle() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/37-belt-buckle.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/37-belt-buckle.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E057] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E057] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E057] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
unpatch_E057_basic_belt_buckle() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/37-belt-buckle.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/37-belt-buckle.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E057_REVERT" "${SQL_FILE}"; then
        echo "  [E057] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E057] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E057] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
