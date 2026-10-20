#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E039
# profiles:   basic
# priority:   2690
# kind:       sql
# about:      No guild banks (issue 617l): every Guild Vault spawn removed. Same
# ==== end of header ====
# E039-basic-no-guild-banks.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E039_basic_no_guild_banks
# No guild banks (issue 617l): every Guild Vault spawn removed. Same
# cp-apply / cp-revert idiom as E022.
patch_E039_basic_no_guild_banks() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/24-no-guild-banks.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/24-no-guild-banks.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E039] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E022 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E039] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E039] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E039_basic_no_guild_banks() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/24-no-guild-banks.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/24-no-guild-banks.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E039_REVERT" "${SQL_FILE}"; then
        echo "  [E039] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E039] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E039] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E039 ====
# lines:      54
# ==== end of footer ====
