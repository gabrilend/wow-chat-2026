#!/usr/bin/env bash

E072_DIR="${BASH_SOURCE[0]%/*}"

patch_E072_basic_spirit_on_gear() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/41-spirit-on-gear.sql"
    local SRC_FILE="${E072_DIR}/41-spirit-on-gear.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E072] Apply source missing: ${SRC_FILE} (run scripts/generate-basic-spirit-on-gear-sql)"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E072] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E072] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E072_basic_spirit_on_gear() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/41-spirit-on-gear.sql"
    local SRC_FILE="${E072_DIR}/41-spirit-on-gear.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E072_REVERT" "${SQL_FILE}"; then
        echo "  [E072] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E072] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E072] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
