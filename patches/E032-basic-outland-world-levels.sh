#!/usr/bin/env bash

patch_E032_basic_outland_world_levels() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/17-outland-world-levels.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/17-outland-world-levels.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E032] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E032] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E032] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E032_basic_outland_world_levels() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/17-outland-world-levels.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/17-outland-world-levels.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E032_REVERT" "${SQL_FILE}"; then
        echo "  [E032] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E032] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E032] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
