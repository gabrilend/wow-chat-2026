#!/usr/bin/env bash

patch_E023_basic_starting_valley_rotation() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/02-starting-valley-rotation.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/02-starting-valley-rotation.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E023] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E023] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E023] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E023_basic_starting_valley_rotation() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/02-starting-valley-rotation.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/02-starting-valley-rotation.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E023_REVERT" "${SQL_FILE}"; then
        echo "  [E023] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E023] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E023] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
