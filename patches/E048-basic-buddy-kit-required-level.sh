#!/usr/bin/env bash
# E048-basic-buddy-kit-required-level.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E048_basic_buddy_kit_required_level
# RETIRED 2026-10-05 (issue 617r2), and undoing itself. It lowered the
# buddies' level-20 tier items (the vanilla starter kit's) to required level
# 20, originals saved. Buddies are now dressed from gearsets whose items
# already fit their level, and nothing else needs the lowered levels, so on
# every install it now applies its own revert form: the saved levels are put
# back (a database it never touched is left as it is). Once every database
# has been through an install, E048 can leave the basic list for good.
# (The owner, 2026-10-05, asked whether copies of those items without a
# level requirement could replace it: new item numbers aren't in the
# original client's own item table, Item.dbc, so worn copies are drawn
# as nothing until the client has asked about them; see 148v and 175.
# Not needed now anyway.)
patch_E048_basic_buddy_kit_required_level() {
    unpatch_E048_basic_buddy_kit_required_level
}

unpatch_E048_basic_buddy_kit_required_level() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/30-buddy-kit-required-level.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/30-buddy-kit-required-level.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E048_REVERT" "${SQL_FILE}"; then
        echo "  [E048] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E048] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E048] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
