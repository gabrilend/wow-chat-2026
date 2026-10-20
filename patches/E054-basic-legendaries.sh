#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E054
# profiles:   basic
# priority:   1840
# kind:       install
# about:      The game's legendaries as level-60 raid drops (issue 182): level-60 copies
# ==== end of header ====
# E054-basic-legendaries.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E054_basic_legendaries
# The game's legendaries as level-60 raid drops (issue 182): level-60 copies
# of the Warglaives, Thori'dal, Val'anyr and Shadowmourne (items 1820002-),
# Atiesh as one drop that turns into its bearer's (1820001, with
# src/lua-basic/legendaries.lua), the effects only those items use scaled in
# place in spell_dbc, and one shared legendary roll on every boss of Zul'Gurub,
# Molten Core, Blackwing Lair and both Ahn'Qiraj raids, about one legendary
# per ten runs. Written by scripts/generate-basic-legendaries-sql. Same
# cp-apply / cp-revert idiom as E050.
patch_E054_basic_legendaries() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/35-legendaries.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/35-legendaries.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E054] Apply source missing: ${SRC_FILE} (run scripts/generate-basic-legendaries-sql)"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E054] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E054] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E054_basic_legendaries() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/35-legendaries.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/35-legendaries.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E054_REVERT" "${SQL_FILE}"; then
        echo "  [E054] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E054] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E054] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E054 ====
# lines:      59
# ==== end of footer ====
