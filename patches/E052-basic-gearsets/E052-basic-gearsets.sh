#!/usr/bin/env bash

E052_DIR="${BASH_SOURCE[0]%/*}"

patch_E052_basic_gearsets() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/33-gearsets.sql"
    local SRC_FILE="${E052_DIR}/33-gearsets.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E052] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E052] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E052] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E052_basic_gearsets() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/33-gearsets.sql"
    local SRC_FILE="${E052_DIR}/33-gearsets.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E052_REVERT" "${SQL_FILE}"; then
        echo "  [E052] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E052] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E052] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
