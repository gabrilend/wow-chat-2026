#!/usr/bin/env bash
# E046-basic-world-boss-respawn.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E046_basic_world_boss_respawn
# The world bosses' respawn taken off the server's timer (issue 155j): the
# list of world boss spawns (basic_155j_world_bosses, read by
# src/lua-basic/world-boss-respawn.lua and src/cpp-basic/basic_rules.cpp)
# and their stock delay set to a year, saved for the revert. World
# database. Same cp-apply / cp-revert idiom as E045.
patch_E046_basic_world_boss_respawn() {
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

unpatch_E046_basic_world_boss_respawn() {
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
# -- }}}
