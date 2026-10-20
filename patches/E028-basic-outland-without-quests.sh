#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E028
# profiles:   basic
# priority:   2580
# kind:       sql
# about:      Outland without quests (issue 155l): every Outland, Shattrath, Isle and
# ==== end of header ====
# E028-basic-outland-without-quests.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E028_basic_outland_without_quests
# Outland without quests (issue 155l): every Outland, Shattrath, Isle and
# Outland-instance quest disabled (givers stay), and the Shattrath portal to
# the Isle removed; the kept flights live in src/lua-basic/outland-flights.lua.
# Same cp-apply / cp-revert idiom and content-comparison idempotence as E022.
patch_E028_basic_outland_without_quests() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/13-outland-without-quests.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/13-outland-without-quests.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E028] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E022 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E028] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E028] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E028_basic_outland_without_quests() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/13-outland-without-quests.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/13-outland-without-quests.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E028_REVERT" "${SQL_FILE}"; then
        echo "  [E028] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E028] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E028] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E028 ====
# lines:      56
# ==== end of footer ====
