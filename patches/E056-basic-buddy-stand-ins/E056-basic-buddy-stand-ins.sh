#!/usr/bin/env bash

E056_DIR="${BASH_SOURCE[0]%/*}"

patch_E056_basic_buddy_stand_ins() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/06-buddy-stand-ins.sql"
    local SRC_FILE="${E056_DIR}/06-buddy-stand-ins.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E056] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E056] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E056] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E056_basic_buddy_stand_ins() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/06-buddy-stand-ins.sql"
    local SRC_FILE="${E056_DIR}/06-buddy-stand-ins.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E056_REVERT" "${SQL_FILE}"; then
        echo "  [E056] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E056] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E056] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
