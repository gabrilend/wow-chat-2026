#!/usr/bin/env bash

E042_DIR="${BASH_SOURCE[0]%/*}"

patch_E042_basic_buddy_roster() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/04-buddy-roster.sql"
    local SRC_FILE="${E042_DIR}/04-buddy-roster.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E042] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E042] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E042] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E042_basic_buddy_roster() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/04-buddy-roster.sql"
    local SRC_FILE="${E042_DIR}/04-buddy-roster.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E042_REVERT" "${SQL_FILE}"; then
        echo "  [E042] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E042] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E042] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
