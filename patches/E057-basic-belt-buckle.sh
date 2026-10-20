#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E057
# profiles:   basic
# priority:   2870
# kind:       sql
# about:      The Eternal Belt Buckle usable from level 60 (issue 624): one item's
# ==== end of header ====
# E057-basic-belt-buckle.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E057_basic_belt_buckle
# The Eternal Belt Buckle usable from level 60 (issue 624): one item's
# required level, in sql/basic/db_world.src/37-belt-buckle.{apply,revert}.sql.
# Same cp-apply / cp-revert idiom as E054.
patch_E057_basic_belt_buckle() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/37-belt-buckle.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/37-belt-buckle.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E057] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E057] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E057] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
unpatch_E057_basic_belt_buckle() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/37-belt-buckle.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/37-belt-buckle.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E057_REVERT" "${SQL_FILE}"; then
        echo "  [E057] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E057] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E057] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E057 ====
# lines:      53
# ==== end of footer ====
