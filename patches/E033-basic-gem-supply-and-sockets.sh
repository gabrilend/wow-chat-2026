#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E033
# profiles:   basic
# priority:   1630
# kind:       install
# about:      Gem supply (issue 155p, stage 1): prospecting yields, Wrath and epic gem
# ==== end of header ====
# E033-basic-gem-supply-and-sockets.sh - one install step, loaded by patches/E-patches.sh.
# Joined by scripts/merge-install-steps (2026-10-20) from steps that were always
# taken together: E033, E034, E035 (the owner: "sure that's fine I guess. We
# can split them later if we need to."). Each old step is a part below, its code
# unchanged (only the name: _E0NN_<old name>_apply / _revert); its log lines still
# say its old number. The step applies the parts in order and undoes them in
# reverse. To split again: each part is a whole function; copy it back into a
# step of its own. Helpers are in patches/E-helpers.sh, loaded first.

# -- {{{ _E033_basic_gem_supply (a part of E033)
# Gem supply (issue 155p, stage 1): prospecting yields, Wrath and epic gem
# drops, the Wrath cutting recipes (at skill 300) and where they drop, and
# Onyxia's hoard. Reads E024's and E032's template lists and follows E027,
# so it comes after all three. Same cp-apply / cp-revert idiom as E022.
_E033_basic_gem_supply_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/18-gem-supply.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/18-gem-supply.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E033] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E022 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E033] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E033] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E033_basic_gem_supply_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/18-gem-supply.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/18-gem-supply.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E033_REVERT" "${SQL_FILE}"; then
        echo "  [E033] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E033] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E033] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}

# -- {{{ _E034_basic_titan_jewelers (a part of E033)
# Titan-site jewelcrafters (issue 155p, stage 2): an Earthen crystal trader
# and masterwork jewelcrafter at Uldaman, the Gate of Uldum and Un'Goro's
# pylons (the Un'Goro pair a set of game events the Lua script swaps). Reads
# E033's gem-cut list and E027's saved trainer rows, so it comes after
# both. Same cp-apply / cp-revert idiom as E022.
_E034_basic_titan_jewelers_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/19-titan-jewelers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/19-titan-jewelers.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E034] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E022 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E034] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E034] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E034_basic_titan_jewelers_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/19-titan-jewelers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/19-titan-jewelers.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E034_REVERT" "${SQL_FILE}"; then
        echo "  [E034] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E034] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E034] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}

# -- {{{ _E035_basic_sockets (a part of E033)
# Sockets (issue 155p, stage 3): gem sockets on the capitals' white gear
# and on vanilla dungeon blues (whose fixed stats shrink in exchange), with
# honest one-stat socket bonuses. Same cp-apply / cp-revert idiom as E022.
_E035_basic_sockets_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/20-sockets.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/20-sockets.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E035] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E022 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E035] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E035] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E035_basic_sockets_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/20-sockets.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/20-sockets.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E035_REVERT" "${SQL_FILE}"; then
        echo "  [E035] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E035] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E035] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}


# -- {{{ patch_E033_basic_gem_supply_and_sockets
patch_E033_basic_gem_supply_and_sockets() {
    _E033_basic_gem_supply_apply || return 1
    _E034_basic_titan_jewelers_apply || return 1
    _E035_basic_sockets_apply || return 1
}
unpatch_E033_basic_gem_supply_and_sockets() {
    _E035_basic_sockets_revert || return 1
    _E034_basic_titan_jewelers_revert || return 1
    _E033_basic_gem_supply_revert || return 1
}
# -- }}}
# ==== footer of E033 ====
# lines:      156
# ==== end of footer ====
