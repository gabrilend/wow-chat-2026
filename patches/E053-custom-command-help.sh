#!/usr/bin/env bash
# E053-custom-command-help.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E053_custom_command_help
# The `command` rows for the game master commands the project compiles in
# (the buddy module, basic's rules): their ".help" text, and the GM level
# that may run each one. A row's level overrides the code's, which matters:
# basic's rules name a permission number (rbac::...) no account reaches, so
# until these rows existed ".basic reload multipliers" and ".basic worldboss"
# ran from the server console only (2026-10-08). Written by
# scripts/generate-custom-command-help-sql from config/custom-gm-commands.lua,
# one file per profile (basic has 20, cc-test the 17 buddy ones). Same
# cp-apply / cp-revert idiom as E050.
patch_E053_custom_command_help() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/34-custom-command-help.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/34-custom-command-help.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E053] Apply source missing: ${SRC_FILE} (run scripts/generate-custom-command-help-sql)"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E053] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E053] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E053_custom_command_help() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/34-custom-command-help.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/34-custom-command-help.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E053_REVERT" "${SQL_FILE}"; then
        echo "  [E053] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E053] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E053] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
