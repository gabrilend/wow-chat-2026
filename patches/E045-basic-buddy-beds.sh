#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E045
# profiles:   buddy-set
# priority:   2750
# kind:       sql
# about:      The beds buddies sleep on in towns (issue 617e4), placed by hand in game
# ==== end of header ====
# E045-basic-buddy-beds.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E045_basic_buddy_beds
# The beds buddies sleep on in towns (issue 617e4), placed by hand in game
# with ".buddy bed add" and carried into the project by
# scripts/export-buddy-beds. World database. The apply never drops the table
# (placed beds live in it); the revert does (export first). Same cp-apply /
# cp-revert idiom as E040.
patch_E045_basic_buddy_beds() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/28-buddy-beds.sql"
    local SRC_FILE="$(_buddy_sql_src db_world)/28-buddy-beds.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E045] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E045] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E045] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E045_basic_buddy_beds() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/28-buddy-beds.sql"
    local SRC_FILE="$(_buddy_sql_src db_world)/28-buddy-beds.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E045_REVERT" "${SQL_FILE}"; then
        echo "  [E045] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E045] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E045] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E045 ====
# lines:      56
# ==== end of footer ====
