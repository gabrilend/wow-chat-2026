#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E074
# profiles:   basic
# priority:   3040
# kind:       sql
# about:      Camp Narache's leather merchant sells the Thin Cloth set too, as Cloth & Leather Merchant (issue 617a4a)
# carries:    43-cloth-in-mulgore.apply.sql 43-cloth-in-mulgore.revert.sql
# ==== end of header ====
# E074-basic-cloth-in-mulgore.sh - one install step, a patch that is a
# directory (issue 189e), loaded by patches/E-patches.sh. Its helpers
# (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.
#
# For a general audience: on basic any race of a side may start in any of
# its starting valleys (issue 155d), and Mulgore's Camp Narache alone had no
# one selling cloth armour (in this game's version tauren could not be
# priests, mages or warlocks). This gives its leather merchant, Varia
# Hardhide, the level-1 Thin Cloth set every other zone sells, and the
# title "Cloth & Leather Merchant" (issue 617a4a; found by
# scripts/generate-valley-vendor-report, docs/reports/valley-vendor-gear.md).
# This step hands the server's updater the SQL that does it; undone, the SQL
# that takes it back. The SQL is written by hand, beside this file.
#
# What it carries (each beside this file):
#   43-cloth-in-mulgore.apply.sql     the six wares and the title
#   43-cloth-in-mulgore.revert.sql    the wares taken out, the old title back

E074_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E074_basic_cloth_in_mulgore
# Same cp-apply / cp-revert idiom as E072, on the world database.
patch_E074_basic_cloth_in_mulgore() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/43-cloth-in-mulgore.sql"
    local SRC_FILE="${E074_DIR}/43-cloth-in-mulgore.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E074] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E074] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E074] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E074_basic_cloth_in_mulgore() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/43-cloth-in-mulgore.sql"
    local SRC_FILE="${E074_DIR}/43-cloth-in-mulgore.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E074_REVERT" "${SQL_FILE}"; then
        echo "  [E074] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E074] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E074] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E074 ====
# lines:      71
# ==== end of footer ====
