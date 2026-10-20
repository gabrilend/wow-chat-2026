#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E040
# profiles:   basic
# priority:   1700
# kind:       install
# about:      Sargobras at the gate of Acherus (issue 718): the gossip NPC in the Ebon
# ==== end of header ====
# E040-basic-death-knight-story-at-acherus.sh - one install step, loaded by patches/E-patches.sh.
# Joined by scripts/merge-install-steps (2026-10-20) from steps that were always
# taken together: E040, E041, E051 (the owner: "sure that's fine I guess. We
# can split them later if we need to."). Each old step is a part below, its code
# unchanged (only the name: _E0NN_<old name>_apply / _revert); its log lines still
# say its old number. The step applies the parts in order and undoes them in
# reverse. To split again: each part is a whole function; copy it back into a
# step of its own. Helpers are in patches/E-helpers.sh, loaded first.

# -- {{{ _E040_basic_death_knight_sargobras (a part of E040)
# Sargobras at the gate of Acherus (issue 718): the gossip NPC in the Ebon
# Hold who takes a new death knight's soul. His menu is Lua
# (src/lua-basic/death-knight-souls.lua). Same cp-apply / cp-revert idiom as
# E022.
_E040_basic_death_knight_sargobras_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/25-death-knight-sargobras.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/25-death-knight-sargobras.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E040] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E022 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E040] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E040] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E040_basic_death_knight_sargobras_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/25-death-knight-sargobras.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/25-death-knight-sargobras.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E040_REVERT" "${SQL_FILE}"; then
        echo "  [E040] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E040] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E040] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}

# -- {{{ _E041_basic_death_knight_souls (a part of E040)
# The soul ledger (issue 718): which character each death knight was made
# from, and where that character is held. Characters database, because it
# is per-realm runtime state (as E023). The revert returns every held soul
# to its own account before dropping the table. Same cp-apply / cp-revert
# idiom as E023.
_E041_basic_death_knight_souls_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/03-death-knight-souls.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/03-death-knight-souls.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E041] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E041] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E041] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E041_basic_death_knight_souls_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_characters/03-death-knight-souls.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_characters.src/03-death-knight-souls.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E041_REVERT" "${SQL_FILE}"; then
        echo "  [E041] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E041] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_characters" "$(_profile_db_name acore_characters)" || return 1

    echo "  [E041] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}

# -- {{{ _E051_basic_acherus_choice_vendors (a part of E040)
# Acherus sells the death knight story's reward choices (issue 718): Lady
# Alistra the three cloaks, Instructor Razuvious the two two-handers, 1 gold
# each, worth nothing to any other vendor. For death knights who skipped the
# story and want the item the server didn't pick. World database. Same
# cp-apply / cp-revert idiom as E050.
_E051_basic_acherus_choice_vendors_apply() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/32-acherus-choice-vendors.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/32-acherus-choice-vendors.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E051] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E051] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E051] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

_E051_basic_acherus_choice_vendors_revert() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/32-acherus-choice-vendors.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/32-acherus-choice-vendors.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E051_REVERT" "${SQL_FILE}"; then
        echo "  [E051] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E051] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E051] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}


# -- {{{ patch_E040_basic_death_knight_story_at_acherus
patch_E040_basic_death_knight_story_at_acherus() {
    _E040_basic_death_knight_sargobras_apply || return 1
    _E041_basic_death_knight_souls_apply || return 1
    _E051_basic_acherus_choice_vendors_apply || return 1
}
unpatch_E040_basic_death_knight_story_at_acherus() {
    _E051_basic_acherus_choice_vendors_revert || return 1
    _E041_basic_death_knight_souls_revert || return 1
    _E040_basic_death_knight_sargobras_revert || return 1
}
# -- }}}
# ==== footer of E040 ====
# lines:      157
# ==== end of footer ====
