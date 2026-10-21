#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E044
# profiles:   buddy-set
# priority:   2740
# kind:       sql
# about:      Every named area's borders and middle (issue 617e2), for the buddies'
# carries:    27-buddy-area-centres.apply.sql 27-buddy-area-centres.revert.sql
# ==== end of header ====
# E044-basic-buddy-area-centres.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# Its SQL is carried beside this file (issue 189e), for every profile that
# takes it (basic and cc-test, the buddy set); until then cc-test read it
# from basic's folders.
E044_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E044_basic_buddy_area_centres
# Every named area's borders and middle (issue 617e2), for the buddies'
# roaming: the buddy module loads the table at startup. World database.
# The source is generated from the server's map files by
# scripts/generate-buddy-area-centres. Same cp-apply / cp-revert idiom as E040.
patch_E044_basic_buddy_area_centres() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/27-buddy-area-centres.sql"
    local SRC_FILE="${E044_DIR}/27-buddy-area-centres.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E044] Apply source missing: ${SRC_FILE} (run scripts/generate-buddy-area-centres)"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E044] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E044] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E044_basic_buddy_area_centres() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/27-buddy-area-centres.sql"
    local SRC_FILE="${E044_DIR}/27-buddy-area-centres.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E044_REVERT" "${SQL_FILE}"; then
        echo "  [E044] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E044] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E044] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E044 ====
# lines:      61
# ==== end of footer ====
