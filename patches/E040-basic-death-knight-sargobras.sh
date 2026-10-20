#!/usr/bin/env bash
# E040-basic-death-knight-sargobras.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E040_basic_death_knight_sargobras
# Sargobras at the gate of Acherus (issue 718): the gossip NPC in the Ebon
# Hold who takes a new death knight's soul. His menu is Lua
# (src/lua-basic/death-knight-souls.lua). Same cp-apply / cp-revert idiom as
# E022.
patch_E040_basic_death_knight_sargobras() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/25-death-knight-sargobras.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/25-death-knight-sargobras.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E040] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E022 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E040] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E040] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E040_basic_death_knight_sargobras() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/25-death-knight-sargobras.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/25-death-knight-sargobras.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E040_REVERT" "${SQL_FILE}"; then
        echo "  [E040] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E040] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E040] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
