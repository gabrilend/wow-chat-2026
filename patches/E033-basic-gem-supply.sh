#!/usr/bin/env bash
# E033-basic-gem-supply.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E033_basic_gem_supply
# Gem supply (issue 155p, stage 1): prospecting yields, Wrath and epic gem
# drops, the Wrath cutting recipes (at skill 300) and where they drop, and
# Onyxia's hoard. Reads E024's and E032's template lists and follows E027,
# so it comes after all three. Same cp-apply / cp-revert idiom as E022.
patch_E033_basic_gem_supply() {
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

unpatch_E033_basic_gem_supply() {
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
