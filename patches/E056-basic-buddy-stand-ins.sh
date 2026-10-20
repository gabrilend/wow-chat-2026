#!/usr/bin/env bash
# E056-basic-buddy-stand-ins.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E056_basic_buddy_stand_ins
# The kept stand-ins (issue 617t1): one row per stand-in character the buddy
# module has made for a scene, a dungeon or a game master, kept for the next
# asker. Characters database, per-realm runtime state (as E042). cc-test
# reads basic's file (_buddy_sql_src). The revert drops the table; the
# stand-in characters and their STANDIN<n> accounts are left alone. Same
# cp-apply / cp-revert idiom as E042.
patch_E056_basic_buddy_stand_ins() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/06-buddy-stand-ins.sql"
    local SRC_FILE="$(_buddy_sql_src db_characters)/06-buddy-stand-ins.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E056] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E056] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E056] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E056_basic_buddy_stand_ins() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/06-buddy-stand-ins.sql"
    local SRC_FILE="$(_buddy_sql_src db_characters)/06-buddy-stand-ins.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E056_REVERT" "${SQL_FILE}"; then
        echo "  [E056] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E056] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E056] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
