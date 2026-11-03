#!/usr/bin/env bash

E074_DIR="${BASH_SOURCE[0]%/*}"

patch_E074_basic_cloth_in_mulgore() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/43-cloth-in-mulgore.sql"
    local SRC_FILE="${E074_DIR}/43-cloth-in-mulgore.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E074] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E074] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E074] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E074_basic_cloth_in_mulgore() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/43-cloth-in-mulgore.sql"
    local SRC_FILE="${E074_DIR}/43-cloth-in-mulgore.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E074_REVERT" "${SQL_FILE}"; then
        echo "  [E074] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E074] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E074] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
