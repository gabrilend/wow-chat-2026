#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E030
# profiles:   basic
# priority:   2600
# kind:       sql
# about:      Darkmoon cards (issue 155o): nothing from a Darkmoon deck binds, and the
# ==== end of header ====
# E030-basic-darkmoon-cards.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E030_basic_darkmoon_cards
# Darkmoon cards (issue 155o): nothing from a Darkmoon deck binds, and the
# Burning Crusade decks' cards drop from Tempest Keep (1), Magisters' Terrace
# (2) and Kael'thas (3). Same cp-apply / cp-revert idiom as E022.
patch_E030_basic_darkmoon_cards() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/15-darkmoon-cards.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/15-darkmoon-cards.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E030] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E022 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E030] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E030] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E030_basic_darkmoon_cards() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/15-darkmoon-cards.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/15-darkmoon-cards.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E030_REVERT" "${SQL_FILE}"; then
        echo "  [E030] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E030] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E030] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E030 ====
# lines:      55
# ==== end of footer ====
