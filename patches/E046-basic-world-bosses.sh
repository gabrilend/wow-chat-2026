#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E046
# profiles:   basic
# priority:   1760
# kind:       install
# about:      The world bosses' respawn taken off the server's timer (issue 155j): the
# ==== end of header ====
# E046-basic-world-bosses.sh - one install step, loaded by patches/E-patches.sh.
# Joined by scripts/merge-install-steps (2026-10-20) from steps that were always
# taken together: E046, E047 (the owner: "sure that's fine I guess. We
# can split them later if we need to."). Each old step is a part below, its code
# unchanged (only the name: _E0NN_<old name>_apply / _revert); its log lines still
# say its old number. The step applies the parts in order and undoes them in
# reverse. To split again: each part is a whole function; copy it back into a
# step of its own. Helpers are in patches/E-helpers.sh, loaded first.

# -- {{{ _E046_basic_world_boss_respawn (a part of E046)
# The world bosses' respawn taken off the server's timer (issue 155j): the
# list of world boss spawns (basic_155j_world_bosses, read by
# src/lua-basic/world-boss-respawn.lua and src/cpp-basic/basic_rules.cpp)
# and their stock delay set to a year, saved for the revert. World
# database. Same cp-apply / cp-revert idiom as E045.
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
# -- }}}

# -- {{{ _E047_basic_world_boss_timers (a part of E046)
# Each world boss's state and countdown (issue 155j), so a restart keeps
# them. Characters database, per-realm runtime state (as E023, E042). Same
# cp-apply / cp-revert idiom as E042.
_E047_basic_world_boss_timers_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/05-world-boss-timers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/05-world-boss-timers.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E047] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
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
# -- }}}


# -- {{{ patch_E046_basic_world_bosses
patch_E046_basic_world_bosses() {
    _E046_basic_world_boss_respawn_apply || return 1
    _E047_basic_world_boss_timers_apply || return 1
}
unpatch_E046_basic_world_bosses() {
    _E047_basic_world_boss_timers_revert || return 1
    _E046_basic_world_boss_respawn_revert || return 1
}
# -- }}}
# ==== footer of E046 ====
# lines:      112
# ==== end of footer ====
