#!/usr/bin/env bash

_E046_basic_world_boss_respawn_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/29-world-boss-respawn.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/29-world-boss-respawn.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E046] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E046] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E046] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E046_basic_world_boss_respawn_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/29-world-boss-respawn.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/29-world-boss-respawn.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E046_REVERT" "${SQL_FILE}"; then
        echo "  [E046] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E046] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E046] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E047_basic_world_boss_timers_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/05-world-boss-timers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/05-world-boss-timers.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E047] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E047] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E047] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E047_basic_world_boss_timers_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/05-world-boss-timers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/05-world-boss-timers.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E047_REVERT" "${SQL_FILE}"; then
        echo "  [E047] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E047] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E047] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}


patch_E046_basic_world_bosses() {
    _E046_basic_world_boss_respawn_apply || return 1
    _E047_basic_world_boss_timers_apply || return 1
}
unpatch_E046_basic_world_bosses() {
    _E047_basic_world_boss_timers_revert || return 1
    _E046_basic_world_boss_respawn_revert || return 1
}
