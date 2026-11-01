#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E077
# profiles:   buddy-set
# priority:   3070
# kind:       sql
# about:      The way back from a mage's city teleport (issue 723): one spot per caster and spell
# carries:    08-teleport-way-back.apply.sql 08-teleport-way-back.revert.sql
# ==== end of header ====
# E077-basic-teleport-way-back.sh - one install step, loaded by patches/E-patches.sh
# (made in the shape of E056, the steps split by issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# Its SQL is carried beside this file (issue 189e), for every profile that
# takes it (basic and cc-test, the buddy set).
E077_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E077_basic_teleport_way_back
# The way back (issue 723): where each caster stood before their latest
# city teleport, per spell, written and read by
# src/lua-basic/buddy-hearth.lua, so a cast inside the city takes them one
# step back, across a restart too. Characters database, per-realm runtime
# state (as E042). The revert drops the table: the ways back are
# forgotten, nothing else is touched. Same cp-apply / cp-revert idiom as
# E042.
patch_E077_basic_teleport_way_back() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/08-teleport-way-back.sql"
    local SRC_FILE="${E077_DIR}/08-teleport-way-back.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E077] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E077] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E077] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E077_basic_teleport_way_back() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/08-teleport-way-back.sql"
    local SRC_FILE="${E077_DIR}/08-teleport-way-back.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E077_REVERT" "${SQL_FILE}"; then
        echo "  [E077] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E077] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E077] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E077 ====
# lines:      65
# ==== end of footer ====
