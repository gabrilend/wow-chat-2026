#!/usr/bin/env bash

E068_DIR="${BASH_SOURCE[0]%/*}"

patch_E068_basic_profession_mentors() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/39-profession-mentors.sql"
    local SRC_FILE="${E068_DIR}/39-profession-mentors.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E068] Apply source missing: ${SRC_FILE} (run scripts/generate-basic-profession-mentors-sql)"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E068] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E068] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E068_basic_profession_mentors() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/39-profession-mentors.sql"
    local SRC_FILE="${E068_DIR}/39-profession-mentors.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E068_REVERT" "${SQL_FILE}"; then
        echo "  [E068] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E068] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E068] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
