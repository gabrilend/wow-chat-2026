#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E070
# profiles:   basic
# priority:   3000
# kind:       sql
# about:      Outland's friendly people +4 levels (+6 on the Isle), as its monsters (issue 155z1)
# carries:    41-outland-folk-plus-four.apply.sql 41-outland-folk-plus-four.revert.sql
# ==== end of header ====
# E070-basic-outland-folk-plus-four.sh - one install step, a patch that is a
# directory (issue 189e), loaded by patches/E-patches.sh. Its helpers
# (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.
#
# For a general audience: Outland's monsters are four levels above stock on
# basic (six on the Isle of Quel'Danas, E032), so its guards, townspeople and
# the Dark Portal's defenders were weaker than what they keep back. This
# step raises Outland's friendly people the same way (issue 155z1; the
# owner, 2026-10-23: "just give it +4 like we do with the other
# creatures"), saving their levels so the revert puts them back.
#
# What it carries (each beside this file):
#   41-outland-folk-plus-four.apply.sql   saves the friendly templates' levels, then raises them
#   41-outland-folk-plus-four.revert.sql  puts the saved levels back

E070_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E070_basic_outland_folk_plus_four
# Same cp-apply / cp-revert idiom as E056, on the world database.
patch_E070_basic_outland_folk_plus_four() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/41-outland-folk-plus-four.sql"
    local SRC_FILE="${E070_DIR}/41-outland-folk-plus-four.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E070] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E070] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E070] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E070_basic_outland_folk_plus_four() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/41-outland-folk-plus-four.sql"
    local SRC_FILE="${E070_DIR}/41-outland-folk-plus-four.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E070_REVERT" "${SQL_FILE}"; then
        echo "  [E070] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E070] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E070] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E070 ====
# lines:      68
# ==== end of footer ====
