#!/usr/bin/env bash

E077_DIR="${BASH_SOURCE[0]%/*}"

patch_E077_basic_teleport_way_back() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/08-teleport-way-back.sql"
    local SRC_FILE="${E077_DIR}/08-teleport-way-back.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E077] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E077] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E077] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E077_basic_teleport_way_back() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/08-teleport-way-back.sql"
    local SRC_FILE="${E077_DIR}/08-teleport-way-back.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E077_REVERT" "${SQL_FILE}"; then
        echo "  [E077] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E077] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E077] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
