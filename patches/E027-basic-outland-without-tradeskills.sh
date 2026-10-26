#!/usr/bin/env bash

patch_E027_basic_outland_without_tradeskills() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/12-outland-without-tradeskills.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/12-outland-without-tradeskills.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E027] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E027] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E027] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E027_basic_outland_without_tradeskills() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/12-outland-without-tradeskills.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/12-outland-without-tradeskills.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E027_REVERT" "${SQL_FILE}"; then
        echo "  [E027] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E027] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E027] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
