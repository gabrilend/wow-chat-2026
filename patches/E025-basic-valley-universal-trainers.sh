#!/usr/bin/env bash

patch_E025_basic_valley_universal_trainers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/10-valley-universal-trainers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/10-valley-universal-trainers.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E025] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E025] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E025] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E025_basic_valley_universal_trainers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/10-valley-universal-trainers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/10-valley-universal-trainers.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E025_REVERT" "${SQL_FILE}"; then
        echo "  [E025] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E025] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E025] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
