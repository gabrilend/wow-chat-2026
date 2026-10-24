#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E069
# profiles:   basic
# priority:   2990
# kind:       sql
# about:      The Dark Portal's wave demons halfway down toward level 60, a stopgap before the front (issue 155z)
# carries:    40-portal-demons-halfway.apply.sql 40-portal-demons-halfway.revert.sql
# ==== end of header ====
# E069-basic-portal-demons-halfway.sh - one install step, a patch that is a
# directory (issue 189e), loaded by patches/E-patches.sh. Its helpers
# (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.
#
# For a general audience: the Dark Portal's demon waves come up the Stair of
# Destiny at levels 70 to 76, against players of 58 to 60. Until the front
# (issue 155z) replaces that event, this step brings the four wave demons
# halfway down toward level 60 (the owner, 2026-10-23: "let's bring them
# down halfway"), saving their levels so the revert puts them back.
#
# What it carries (each beside this file):
#   40-portal-demons-halfway.apply.sql   saves the four demons' levels, then halves the gap to 60
#   40-portal-demons-halfway.revert.sql  puts the saved levels back

E069_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E069_basic_portal_demons_halfway
# Same cp-apply / cp-revert idiom as E056, on the world database.
patch_E069_basic_portal_demons_halfway() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/40-portal-demons-halfway.sql"
    local SRC_FILE="${E069_DIR}/40-portal-demons-halfway.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E069] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E069] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E069] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E069_basic_portal_demons_halfway() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/40-portal-demons-halfway.sql"
    local SRC_FILE="${E069_DIR}/40-portal-demons-halfway.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E069_REVERT" "${SQL_FILE}"; then
        echo "  [E069] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E069] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E069] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E069 ====
# lines:      67
# ==== end of footer ====
