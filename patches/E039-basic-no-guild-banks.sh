#!/usr/bin/env bash

patch_E039_basic_no_guild_banks() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/24-no-guild-banks.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/24-no-guild-banks.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E039] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E039] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E039] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E039_basic_no_guild_banks() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/24-no-guild-banks.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/24-no-guild-banks.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E039_REVERT" "${SQL_FILE}"; then
        echo "  [E039] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E039] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E039] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
