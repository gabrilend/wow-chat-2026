#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E011
# profiles:   beta
# priority:   1410
# kind:       install
# about:      Death Knight class system for beta profile (issue 206/167). Wires DK
# ==== end of header ====
# E011-beta-dk-class-system.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E011_beta_dk_class_system
# Death Knight class system for beta profile (issue 206/167). Wires DK
# from level 1 with progressive ability training: the kit is its own
# trainer list (2060001) and trainers 29194/29195/29196 are pointed at it.
# Source: sql/beta/db_world.src/11-dk-class-system.apply.sql, undone by
# its .revert.sql (both on the current trainer tables since 2026-10-17;
# before, both wrote npc_trainer, which the server no longer reads).
patch_E011_beta_dk_class_system() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/11-dk-class-system.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/11-dk-class-system.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E011_APPLY" "${SQL_FILE}"; then
        echo "  [E011] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E011] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E011] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E011_beta_dk_class_system() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/11-dk-class-system.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/11-dk-class-system.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E011_REVERT" "${SQL_FILE}"; then
        echo "  [E011] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E011] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E011] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E011 ====
# lines:      57
# ==== end of footer ====
