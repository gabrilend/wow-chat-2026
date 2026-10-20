#!/usr/bin/env bash
# E052-basic-gearsets.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E052_basic_gearsets
# Every gearset profile (issue 617r: src/lua-basic/data/gearsets/*.lua) as
# rows of the world database's gearset_item table, written by
# scripts/generate-gearset-sql, so the buddy module (C++) dresses new
# buddies from the same profiles the Lua scripts use (617r2). Same
# cp-apply / cp-revert idiom as E050.
patch_E052_basic_gearsets() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/33-gearsets.sql"
    local SRC_FILE="$(_buddy_sql_src db_world)/33-gearsets.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E052] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E052] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E052] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E052_basic_gearsets() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/33-gearsets.sql"
    local SRC_FILE="$(_buddy_sql_src db_world)/33-gearsets.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E052_REVERT" "${SQL_FILE}"; then
        echo "  [E052] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E052] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E052] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
