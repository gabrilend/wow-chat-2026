#!/usr/bin/env bash

patch_E013_beta_quest_spells_to_trainers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/13-quest-spells-to-trainers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/13-quest-spells-to-trainers.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E013_APPLY" "${SQL_FILE}"; then
        echo "  [E013] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E013] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E013] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E013_beta_quest_spells_to_trainers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/13-quest-spells-to-trainers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/13-quest-spells-to-trainers.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E013_REVERT" "${SQL_FILE}"; then
        echo "  [E013] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E013] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E013] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
