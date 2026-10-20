#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E038
# profiles:   basic
# priority:   2680
# kind:       sql
# about:      The Dark Portal as the only door into Outland (issue 155l): Shattrath's
# ==== end of header ====
# E038-basic-outland-one-door.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E038_basic_outland_one_door
# The Dark Portal as the only door into Outland (issue 155l): Shattrath's
# capital portals, the Stair of Destiny portals, Dalaran's Shattrath portals
# and the capitals' Blasted Lands portals removed. Same cp-apply / cp-revert
# idiom as E022.
patch_E038_basic_outland_one_door() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/23-outland-one-door.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/23-outland-one-door.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E038] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E022 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E038] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E038] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E038_basic_outland_one_door() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/23-outland-one-door.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/23-outland-one-door.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E038_REVERT" "${SQL_FILE}"; then
        echo "  [E038] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E038] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E038] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E038 ====
# lines:      56
# ==== end of footer ====
