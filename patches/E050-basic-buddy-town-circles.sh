#!/usr/bin/env bash
# E050-basic-buddy-town-circles.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E050_basic_buddy_town_circles
# The world's little towns as circles (issue 617e4a): every cluster of
# helpful people, found by scripts/generate-buddy-town-circles, and the
# circles placed by hand in game as they stood when it last ran. World
# database. Same cp-apply / cp-revert idiom as E048.
patch_E050_basic_buddy_town_circles() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/31-buddy-town-circles.sql"
    local SRC_FILE="$(_buddy_sql_src db_world)/31-buddy-town-circles.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E050] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E050] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E050] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E050_basic_buddy_town_circles() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/31-buddy-town-circles.sql"
    local SRC_FILE="$(_buddy_sql_src db_world)/31-buddy-town-circles.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E050_REVERT" "${SQL_FILE}"; then
        echo "  [E050] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E050] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E050] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
