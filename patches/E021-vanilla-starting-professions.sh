#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E021
# profiles:   vanilla
# priority:   2510
# kind:       sql
# about:      Grant every level-20 vanilla character a gathering + a production profession
# ==== end of header ====
# E021-vanilla-starting-professions.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E021_vanilla_starting_professions
# Grant every level-20 vanilla character a gathering + a production profession
# (148q): skill lines at Journeyman (cap 150), every trainer recipe usable at
# skill <= 125, and the profession's tool. Skill VALUE (125) is set by the
# first-login ALE hook; this migration seeds the tier, recipes, and tools.
# Same cp-apply / cp-revert idiom as E008/E018/E020.
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
# -- }}}
# ==== footer of E021 ====
# lines:      56
# ==== end of footer ====
