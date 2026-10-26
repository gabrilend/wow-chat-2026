#!/usr/bin/env bash

E067_DIR="${BASH_SOURCE[0]%/*}"

patch_E067_basic_boss_enchant_scrolls() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/38-boss-enchant-scrolls.sql"
    local SRC_FILE="${E067_DIR}/38-boss-enchant-scrolls.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E067] Apply source missing: ${SRC_FILE} (run scripts/generate-basic-boss-scrolls-sql)"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E067] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E067] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E067_basic_boss_enchant_scrolls() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/38-boss-enchant-scrolls.sql"
    local SRC_FILE="${E067_DIR}/38-boss-enchant-scrolls.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E067_REVERT" "${SQL_FILE}"; then
        echo "  [E067] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E067] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E067] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
