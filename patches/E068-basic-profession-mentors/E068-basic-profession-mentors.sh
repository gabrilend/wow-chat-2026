#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E068
# profiles:   basic
# priority:   2980
# kind:       sql
# about:      A Profession Mentor in each capital, teaching the professions its city lacks (issue 155e1)
# carries:    39-profession-mentors.apply.sql 39-profession-mentors.revert.sql
# ==== end of header ====
# E068-basic-profession-mentors.sh - one install step, a patch that is a
# directory (issue 189e), loaded by patches/E-patches.sh. Its helpers
# (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.
#
# For a general audience: on basic, a visitor from afar stands in each
# capital's crafting quarter and teaches the professions that city has no
# trainer for, one dialogue line each (issue 155e1). It takes the place of
# the six Visiting Jewelcrafters (155p), teaching jewelcrafting where a
# city has no jewelcrafter, and dances about once an hour
# (src/lua-basic/profession-mentors.lua). A capital with every trainer gets
# no mentor. This step hands the server's updater the SQL that puts them
# there; undone, the SQL that takes them away and brings the Visiting
# Jewelcrafters back. The SQL is generated, beside this file, by
# scripts/generate-basic-profession-mentors-sql (re-run it if the capitals'
# trainers change).
#
# What it carries (each beside this file):
#   39-profession-mentors.apply.sql   the mentors, their lists, dialogue and looks; the jewelcrafters removed (saved)
#   39-profession-mentors.revert.sql  removes exactly those and restores the jewelcrafters

E068_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E068_basic_profession_mentors
# Same cp-apply / cp-revert idiom as E056, on the world database.
patch_E068_basic_profession_mentors() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/39-profession-mentors.sql"
    local SRC_FILE="${E068_DIR}/39-profession-mentors.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E068] Apply source missing: ${SRC_FILE} (run scripts/generate-basic-profession-mentors-sql)"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E068] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E068] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E068_basic_profession_mentors() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/39-profession-mentors.sql"
    local SRC_FILE="${E068_DIR}/39-profession-mentors.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E068_REVERT" "${SQL_FILE}"; then
        echo "  [E068] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E068] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E068] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E068 ====
# lines:      73
# ==== end of footer ====
