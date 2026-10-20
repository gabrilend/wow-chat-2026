#!/usr/bin/env bash
# E041-basic-death-knight-souls.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E041_basic_death_knight_souls
# The soul ledger (issue 718): which character each death knight was made
# from, and where that character is held. Characters database, because it
# is per-realm runtime state (as E023). The revert returns every held soul
# to its own account before dropping the table. Same cp-apply / cp-revert
# idiom as E023.
patch_E041_basic_death_knight_souls() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/03-death-knight-souls.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/03-death-knight-souls.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E041] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E041] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E041] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E041_basic_death_knight_souls() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/03-death-knight-souls.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/03-death-knight-souls.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E041_REVERT" "${SQL_FILE}"; then
        echo "  [E041] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E041] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E041] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
