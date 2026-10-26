#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E073
# profiles:   basic
# priority:   3030
# kind:       sql
# about:      Shared loot tables that mix qualities split into one table per quality (issue 181)
# carries:    42-split-loot-tables.apply.sql 42-split-loot-tables.revert.sql
# ==== end of header ====
# E073-basic-split-loot-tables.sh - one install step, a patch that is a
# directory (issue 189e), loaded by patches/E-patches.sh. Its helpers
# (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.
#
# For a general audience: basic boosts greens, blues and epics from ordinary
# monsters by raising the chance on loot entries that point at a table of a
# single quality (issue 181). Some old shared tables mix whites with greens
# under one equal chance, so their greens could not be boosted. This step
# hands the server's updater the SQL that splits each into one table per
# quality (the same items), and points every entry that used the old table
# at the new ones with the old chance shared out by each quality's count,
# so unboosted the drops are exactly as before; undone, the SQL that puts
# the saved entries back and removes the new tables. The SQL is generated,
# beside this file, by scripts/generate-basic-split-loot-sql.
#
# What it carries (each beside this file):
#   42-split-loot-tables.apply.sql    the new tables, the saved and rewritten entries
#   42-split-loot-tables.revert.sql   the entries put back, the new tables removed

E073_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E073_basic_split_loot_tables
# Same cp-apply / cp-revert idiom as E071, on the world database.
patch_E073_basic_split_loot_tables() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/42-split-loot-tables.sql"
    local SRC_FILE="${E073_DIR}/42-split-loot-tables.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E073] Apply source missing: ${SRC_FILE} (run scripts/generate-basic-split-loot-tables-sql)"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E073] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E073] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E073_basic_split_loot_tables() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/42-split-loot-tables.sql"
    local SRC_FILE="${E073_DIR}/42-split-loot-tables.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E073_REVERT" "${SQL_FILE}"; then
        echo "  [E073] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E073] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E073] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E073 ====
# lines:      72
# ==== end of footer ====
