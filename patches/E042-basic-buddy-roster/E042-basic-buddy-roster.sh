#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E042
# profiles:   buddy-set
# priority:   2720
# kind:       sql
# about:      The buddy clan and roster tables (issue 617a1): each owner's companion
# carries:    04-buddy-roster.apply.sql 04-buddy-roster.revert.sql
# ==== end of header ====
# E042-basic-buddy-roster.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# Its SQL is carried beside this file (issue 189e), for every profile that
# takes it (basic and cc-test, the buddy set); until then cc-test read it
# from basic's folders.
E042_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E042_basic_buddy_roster
# The buddy clan and roster tables (issue 617a1): each owner's companion
# account, and each owed or filled buddy slot. Characters database, per-realm
# runtime state (as E023, E041). The revert drops both tables; the buddy
# characters and accounts they name are left alone. Same cp-apply /
# cp-revert idiom as E023.
patch_E042_basic_buddy_roster() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/04-buddy-roster.sql"
    local SRC_FILE="${E042_DIR}/04-buddy-roster.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E042] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E042] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E042] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E042_basic_buddy_roster() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/04-buddy-roster.sql"
    local SRC_FILE="${E042_DIR}/04-buddy-roster.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E042_REVERT" "${SQL_FILE}"; then
        echo "  [E042] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E042] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E042] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E042 ====
# lines:      63
# ==== end of footer ====
