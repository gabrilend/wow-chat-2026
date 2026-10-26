#!/usr/bin/env bash

patch_E021_vanilla_starting_professions() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/07-starting-professions.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/07-starting-professions.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E021_APPLY" "${SQL_FILE}"; then
        echo "  [E021] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E021] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E021] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E021_vanilla_starting_professions() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/07-starting-professions.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/07-starting-professions.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E021_REVERT" "${SQL_FILE}"; then
        echo "  [E021] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E021] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E021] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
