#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E071
# profiles:   basic
# priority:   3010
# kind:       sql
# about:      The level-60 fights' multipliers and rewritten boss spells (issues 155i, 155f1, 155j)
# carries:    fights.lua 40-fight-multipliers.apply.sql 40-fight-multipliers.revert.sql
# ==== end of header ====
# E071-basic-fight-multipliers.sh - one install step, a patch that is a
# directory (issue 189e), loaded by patches/E-patches.sh. Its helpers
# (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.
#
# For a general audience: on basic, bosses built for level-70 raids are
# tuned for level-60 players by multipliers on their melee, spells,
# healing and health (the table install step E026 made, issue 155i), and
# some of their spells are rewritten (Doom Lord Kazzak's Berserk removed,
# his Frenzy turned into a six-second channelled volley storm, 155j). The
# tuning is a readable list beside this file (fights.lua); this step hands
# the server's updater the SQL made from it, and undone, the SQL that takes
# exactly those rows away. The SQL is generated, beside this file, by
# scripts/generate-basic-fight-multipliers-sql (re-run it after changing
# fights.lua). The server reads the multipliers at start and on
# ".basic reload multipliers", the rewritten spells only at start.
#
# What it carries (each beside this file):
#   fights.lua                            the tuning, with each entry's reason (the generator's input)
#   40-fight-multipliers.apply.sql        the creature rows and the rewritten spell rows
#   40-fight-multipliers.revert.sql       removes exactly those

E071_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E071_basic_fight_multipliers
# Same cp-apply / cp-revert idiom as E067, on the world database.
patch_E071_basic_fight_multipliers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/40-fight-multipliers.sql"
    local SRC_FILE="${E071_DIR}/40-fight-multipliers.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E071] Apply source missing: ${SRC_FILE} (run scripts/generate-basic-fight-multipliers-sql)"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E071] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E071] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E071_basic_fight_multipliers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/40-fight-multipliers.sql"
    local SRC_FILE="${E071_DIR}/40-fight-multipliers.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E071_REVERT" "${SQL_FILE}"; then
        echo "  [E071] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E071] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E071] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E071 ====
# lines:      74
# ==== end of footer ====
