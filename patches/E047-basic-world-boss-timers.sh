#!/usr/bin/env bash
# E047-basic-world-boss-timers.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E047_basic_world_boss_timers
# Each world boss's state and countdown (issue 155j), so a restart keeps
# them. Characters database, per-realm runtime state (as E023, E042). Same
# cp-apply / cp-revert idiom as E042.
patch_E047_basic_world_boss_timers() {
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

unpatch_E047_basic_world_boss_timers() {
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
