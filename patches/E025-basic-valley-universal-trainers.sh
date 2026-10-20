#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E025
# profiles:   basic
# priority:   1550
# kind:       install
# about:      One "Visiting Mentor" per starting valley that teaches exactly the classes
# ==== end of header ====
# E025-basic-valley-universal-trainers.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E025_basic_valley_universal_trainers
# One "Visiting Mentor" per starting valley that teaches exactly the classes
# of its faction the valley's own trainers do not (issue 155e), so a
# character born in a foreign valley (155d) can train. Same cp-apply /
# cp-revert idiom and content-comparison idempotence as E022.
patch_E025_basic_valley_universal_trainers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/10-valley-universal-trainers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/10-valley-universal-trainers.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E025] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E022 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E025] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E025] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E025_basic_valley_universal_trainers() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/10-valley-universal-trainers.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/10-valley-universal-trainers.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E025_REVERT" "${SQL_FILE}"; then
        echo "  [E025] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E025] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E025] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E025 ====
# lines:      56
# ==== end of footer ====
