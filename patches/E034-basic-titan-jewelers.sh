#!/usr/bin/env bash
# E034-basic-titan-jewelers.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E034_basic_titan_jewelers
# Titan-site jewelcrafters (issue 155p, stage 2): an Earthen crystal trader
# and masterwork jewelcrafter at Uldaman, the Gate of Uldum and Un'Goro's
# pylons (the Un'Goro pair a set of game events the Lua script swaps). Reads
# E033's gem-cut list and E027's saved trainer rows, so it comes after
# both. Same cp-apply / cp-revert idiom as E022.
patch_E034_basic_titan_jewelers() {
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

unpatch_E034_basic_titan_jewelers() {
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
