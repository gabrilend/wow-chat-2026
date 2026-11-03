#!/usr/bin/env bash

E075_DIR="${BASH_SOURCE[0]%/*}"

patch_E075_basic_shields_without_stamina() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/44-shields-without-stamina.sql"
    local SRC_FILE="${E075_DIR}/44-shields-without-stamina.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E075] Apply source missing: ${SRC_FILE} (run scripts/generate-basic-shield-stats-sql)"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E075] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E075] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E075_basic_shields_without_stamina() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/44-shields-without-stamina.sql"
    local SRC_FILE="${E075_DIR}/44-shields-without-stamina.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E075_REVERT" "${SQL_FILE}"; then
        echo "  [E075] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E075] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E075] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
