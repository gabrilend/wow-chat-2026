#!/usr/bin/env bash

patch_E026_basic_creature_multipliers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/11-creature-multipliers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/11-creature-multipliers.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E026] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E026] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E026] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E026_basic_creature_multipliers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/11-creature-multipliers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/11-creature-multipliers.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E026_REVERT" "${SQL_FILE}"; then
        echo "  [E026] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E026] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E026] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
