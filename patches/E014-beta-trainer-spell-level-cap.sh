#!/usr/bin/env bash

patch_E014_beta_trainer_spell_level_cap() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/14-trainer-spell-level-cap.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/14-trainer-spell-level-cap.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E014_APPLY" "${SQL_FILE}"; then
        echo "  [E014] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E014] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E014] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E014_beta_trainer_spell_level_cap() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/14-trainer-spell-level-cap.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/14-trainer-spell-level-cap.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E014_REVERT" "${SQL_FILE}"; then
        echo "  [E014] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E014] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E014] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
