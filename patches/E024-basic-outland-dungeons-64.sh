#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E024
# profiles:   basic
# priority:   2540
# kind:       sql
# about:      Basic's Outland dungeon ladder (issue 155f): sixteen dungeons open at 60,
# ==== end of header ====
# E024-basic-outland-dungeons-64.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E024_basic_outland_dungeons_64
# Basic's Outland dungeon ladder (issue 155f): sixteen dungeons open at 60,
# each dungeon's creatures raised by its own level step (Kael'thas 78), two
# attunements removed, their gear wearable at 60; the open world, quests and
# the heroic modes are left stock. (Named for its first, flat-64 version.)
# Same cp-apply / cp-revert idiom and content-comparison idempotence as E022.
patch_E024_basic_outland_dungeons_64() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/09-outland-dungeons-64.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/09-outland-dungeons-64.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E024] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E022 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E024] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E024] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E024_basic_outland_dungeons_64() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/09-outland-dungeons-64.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/09-outland-dungeons-64.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E024_REVERT" "${SQL_FILE}"; then
        echo "  [E024] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E024] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E024] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E024 ====
# lines:      57
# ==== end of footer ====
