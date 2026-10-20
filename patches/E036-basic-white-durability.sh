#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E036
# profiles:   basic
# priority:   2660
# kind:       sql
# about:      White gear durability (issue 155p): white weapons and armor last twice as
# ==== end of header ====
# E036-basic-white-durability.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E036_basic_white_durability
# White gear durability (issue 155p): white weapons and armor last twice as
# long; B033 makes them never repaired. Same cp-apply / cp-revert idiom as
# E022.
patch_E036_basic_white_durability() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/21-white-durability.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/21-white-durability.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E036] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E022 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E036] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E036] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E036_basic_white_durability() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/21-white-durability.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/21-white-durability.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E036_REVERT" "${SQL_FILE}"; then
        echo "  [E036] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E036] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E036] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E036 ====
# lines:      55
# ==== end of footer ====
