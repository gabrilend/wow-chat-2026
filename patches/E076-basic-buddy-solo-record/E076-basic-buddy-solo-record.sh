#!/usr/bin/env bash

E076_DIR="${BASH_SOURCE[0]%/*}"

patch_E076_basic_buddy_solo_record() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/07-buddy-solo-record.sql"
    local SRC_FILE="${E076_DIR}/07-buddy-solo-record.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E076] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E076] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E076] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E076_basic_buddy_solo_record() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/07-buddy-solo-record.sql"
    local SRC_FILE="${E076_DIR}/07-buddy-solo-record.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E076_REVERT" "${SQL_FILE}"; then
        echo "  [E076] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E076] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E076] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
