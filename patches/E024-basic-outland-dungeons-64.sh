#!/usr/bin/env bash

patch_E024_basic_outland_dungeons_64() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/09-outland-dungeons-64.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/09-outland-dungeons-64.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E024] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E024] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E024] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E024_basic_outland_dungeons_64() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/09-outland-dungeons-64.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/09-outland-dungeons-64.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E024_REVERT" "${SQL_FILE}"; then
        echo "  [E024] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E024] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E024] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
