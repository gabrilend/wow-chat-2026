#!/usr/bin/env bash

patch_E022_basic_faction_quest_gating() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/08-faction-quest-gating.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/08-faction-quest-gating.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E022] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E022] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E022] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E022_basic_faction_quest_gating() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/08-faction-quest-gating.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/08-faction-quest-gating.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E022_REVERT" "${SQL_FILE}"; then
        echo "  [E022] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E022] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E022] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
