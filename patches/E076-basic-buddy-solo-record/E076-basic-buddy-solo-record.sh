#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E076
# profiles:   buddy-set
# priority:   3060
# kind:       sql
# about:      The solo record (issue 623): each buddy's hardest fight won alone, per
# carries:    07-buddy-solo-record.apply.sql 07-buddy-solo-record.revert.sql
# ==== end of header ====
# E076-basic-buddy-solo-record.sh - one install step, loaded by patches/E-patches.sh
# (made in the shape of E056, the steps split by issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# Its SQL is carried beside this file (issue 189e), for every profile that
# takes it (basic and cc-test, the buddy set).
E076_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E076_basic_buddy_solo_record
# The solo record (issue 623): for each buddy, the hardest fight it has won
# alone against each kind of foe, written by the buddy module
# (buddies_solo.cpp) and read when it weighs a foe. Characters database,
# per-realm runtime state (as E042). The revert drops the table: the
# records are forgotten, nothing else is touched. Same cp-apply / cp-revert
# idiom as E042.
patch_E076_basic_buddy_solo_record() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/07-buddy-solo-record.sql"
    local SRC_FILE="${E076_DIR}/07-buddy-solo-record.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E076] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E076] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E076] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E076_basic_buddy_solo_record() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/07-buddy-solo-record.sql"
    local SRC_FILE="${E076_DIR}/07-buddy-solo-record.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E076_REVERT" "${SQL_FILE}"; then
        echo "  [E076] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E076] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E076] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E076 ====
# lines:      64
# ==== end of footer ====
