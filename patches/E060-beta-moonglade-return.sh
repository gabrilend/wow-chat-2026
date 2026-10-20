#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E060
# profiles:   beta
# priority:   1900
# kind:       install
# about:      Each druid's way back from Moonglade, and the visitors they brought there
# ==== end of header ====
# E060-beta-moonglade-return.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E060_beta_moonglade_return
# Each druid's way back from Moonglade, and the visitors they brought there
# with theirs (issue 211a), so a cast inside Moonglade sends them back and a
# restart loses no visitor. Characters database, because it is per-realm
# runtime state (as basic's E041). The revert drops both tables; the druids
# keep the spell. Beta's first characters-database step: its folder
# is registered with the updater here. Same cp-apply / cp-revert idiom as
# E058. Added 2026-10-18.
patch_E060_beta_moonglade_return() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/01-moonglade-return.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/01-moonglade-return.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E060] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E060_APPLY" "${SQL_FILE}"; then
        echo "  [E060] Active file already holds apply-form content"
        return 0
    fi

    echo "  [E060] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E060_beta_moonglade_return() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/01-moonglade-return.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/01-moonglade-return.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E060_REVERT" "${SQL_FILE}"; then
        echo "  [E060] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E060] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E060] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E060 ====
# lines:      59
# ==== end of footer ====
