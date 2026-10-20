#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E037
# profiles:   basic
# priority:   2670
# kind:       sql
# about:      Class books for the level 61-80 abilities (issue 155q): one stock-style
# ==== end of header ====
# E037-basic-ability-tomes.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E037_basic_ability_tomes
# Class books for the level 61-80 abilities (issue 155q): one stock-style
# class book per rank, dropping in Ahn'Qiraj, from the Emerald Dragons and in
# Naxxramas. Same cp-apply / cp-revert idiom as E022.
patch_E037_basic_ability_tomes() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/22-ability-tomes.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/22-ability-tomes.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E037] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E022 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E037] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E037] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E037_basic_ability_tomes() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/22-ability-tomes.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/22-ability-tomes.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E037_REVERT" "${SQL_FILE}"; then
        echo "  [E037] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E037] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E037] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E037 ====
# lines:      55
# ==== end of footer ====
