#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E075
# profiles:   none
# priority:   3050
# kind:       sql
# about:      No shield carries stamina: its worth comes back as armour, spirit or mana every 5 seconds (issue 155z18)
# carries:    44-shields-without-stamina.apply.sql 44-shields-without-stamina.revert.sql
# ==== end of header ====
# E075-basic-shields-without-stamina.sh - one install step, a patch that is
# a directory (issue 189e), loaded by patches/E-patches.sh. Its helpers
# (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.
#
# For a general audience: a shield's stamina competes with an off-hand
# item's, so a paladin who wants stamina need not carry a shield. On basic
# every shield's stamina is taken off and its worth given back by what the
# shield already carries: spirit for a holy one, mana every 5 seconds for a
# magic one, bonus armour for any other (issue 155z18). This step hands the
# server's updater the SQL that does it, saving each changed shield's stats
# and armour first; undone, the SQL that puts them back exactly. The SQL is
# generated, beside this file, by scripts/generate-basic-shield-stats-sql
# (which prints how many shields of each kind changed); it was applied
# twice and reverted on a scratch copy of basic's shields on 2026-10-30:
# none kept stamina, and the revert left the table as it was. It comes
# after E072 (155k2's spirit step, which never touches shields).
#
# Built and on are separate decisions: the profiles line says "none" until
# the owner names basic.
#
# What it carries (each beside this file):
#   44-shields-without-stamina.apply.sql     the saved copy and the changes
#   44-shields-without-stamina.revert.sql    the stats put back, the copy dropped

E075_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E075_basic_shields_without_stamina
# Same cp-apply / cp-revert idiom as E072, on the world database.
patch_E075_basic_shields_without_stamina() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/44-shields-without-stamina.sql"
    local SRC_FILE="${E075_DIR}/44-shields-without-stamina.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E075] Apply source missing: ${SRC_FILE} (run scripts/generate-basic-shield-stats-sql)"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E075] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E075] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E075_basic_shields_without_stamina() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/44-shields-without-stamina.sql"
    local SRC_FILE="${E075_DIR}/44-shields-without-stamina.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E075_REVERT" "${SQL_FILE}"; then
        echo "  [E075] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E075] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E075] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E075 ====
# lines:      77
# ==== end of footer ====
