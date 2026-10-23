#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E067
# profiles:   basic
# priority:   2970
# kind:       sql
# about:      One enchanting scroll per classic dungeon boss kill, near the boss's level (issue 812)
# carries:    38-boss-enchant-scrolls.apply.sql 38-boss-enchant-scrolls.revert.sql
# ==== end of header ====
# E067-basic-boss-enchant-scrolls.sh - one install step, a patch that is a
# directory (issue 189e), loaded by patches/E-patches.sh. Its helpers
# (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.
#
# For a general audience: on basic, every boss of the old five-player
# dungeons (up to the level-60 ones, never raids) drops one enchanting
# scroll per kill, on top of its own loot, drawn at random among the
# scrolls near its level (issue 812). This step hands the server's updater
# the SQL that adds those drops; undone, it hands it the SQL that takes
# them away again. The SQL is generated, beside this file, by
# scripts/generate-basic-boss-scrolls-sql (re-run it if the world database's
# bosses or scrolls change).
#
# What it carries (each beside this file):
#   38-boss-enchant-scrolls.apply.sql   the shared scroll lists and each boss's row
#   38-boss-enchant-scrolls.revert.sql  removes exactly those (their ids are this step's own)

E067_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E067_basic_boss_enchant_scrolls
# Same cp-apply / cp-revert idiom as E056, on the world database.
patch_E067_basic_boss_enchant_scrolls() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/38-boss-enchant-scrolls.sql"
    local SRC_FILE="${E067_DIR}/38-boss-enchant-scrolls.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E067] Apply source missing: ${SRC_FILE} (run scripts/generate-basic-boss-scrolls-sql)"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E067] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E067] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E067_basic_boss_enchant_scrolls() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/38-boss-enchant-scrolls.sql"
    local SRC_FILE="${E067_DIR}/38-boss-enchant-scrolls.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E067_REVERT" "${SQL_FILE}"; then
        echo "  [E067] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E067] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E067] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E067 ====
# lines:      70
# ==== end of footer ====
