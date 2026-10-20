#!/usr/bin/env bash
# E055-basic-buddy-subareas.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E055_basic_buddy_subareas
# The smaller places buddies roam (issue 617e12, the first cut): every named
# area cut into parts by which monsters live where and by steep ground, so
# the Valley of Trials is three places (boars, scorpids, the demons by the
# cave) instead of one. Two tables: buddy_subarea (one row per part: its
# named area, size in map squares, a centre inside it, levels, leading
# monsters) and buddy_subarea_square (which part each square of a split area
# belongs to). Written by scripts/generate-buddy-subareas and checked by
# scripts/test-buddy-subareas. Nothing reads them yet: the buddy roaming
# code that will is the next step of the same issue. Same cp-apply /
# cp-revert idiom as E050.
patch_E055_basic_buddy_subareas() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/36-buddy-subareas.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/36-buddy-subareas.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E055] Apply source missing: ${SRC_FILE} (run scripts/generate-buddy-subareas)"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E055] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E055] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E055_basic_buddy_subareas() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/36-buddy-subareas.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/36-buddy-subareas.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E055_REVERT" "${SQL_FILE}"; then
        echo "  [E055] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E055] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E055] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
