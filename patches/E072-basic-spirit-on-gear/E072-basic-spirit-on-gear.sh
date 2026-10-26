#!/usr/bin/env bash
# ==== header: 8 lines, footer: 3 lines ====
# id:         E072
# profiles:   basic
# priority:   3020
# kind:       sql
# about:      Some gear trades its stamina for spirit: two fifths of each kind, all or half (issue 155k2)
# carries:    41-spirit-on-gear.apply.sql 41-spirit-on-gear.revert.sql
# ==== end of header ====
# E072-basic-spirit-on-gear.sh - one install step, a patch that is a
# directory (issue 189e), loaded by patches/E-patches.sh. Its helpers
# (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.
#
# For a general audience: since spirit heals health by stamina (issue 167),
# spirit is worth having on any character, but almost no armour carries it.
# On basic, two fifths of the gear that has stamina and no spirit, within
# each kind (leather, plate, mail without caster stats, rings, necklaces,
# cloaks), trade it: one fifth all of it, another fifth half (issue 155k2).
# This step hands the server's updater the SQL that does it, saving each
# changed item's stats first; undone, the SQL that puts them back exactly.
# The SQL is generated, beside this file, by
# scripts/generate-basic-spirit-gear-sql (which prints how many items each
# kind changed). It comes after E031's rescale of Outland gear, whose
# results it starts from.
#
# What it carries (each beside this file):
#   41-spirit-on-gear.apply.sql     the saved copy and the changes
#   41-spirit-on-gear.revert.sql    the stats put back, the copy dropped

E072_DIR="${BASH_SOURCE[0]%/*}"

# -- {{{ patch_E072_basic_spirit_on_gear
# Same cp-apply / cp-revert idiom as E071, on the world database.
patch_E072_basic_spirit_on_gear() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/41-spirit-on-gear.sql"
    local SRC_FILE="${E072_DIR}/41-spirit-on-gear.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E072] Apply source missing: ${SRC_FILE} (run scripts/generate-basic-spirit-on-gear-sql)"; return 1; }

    # Register on every run (see E023 for why this comes before the check).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E072] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E072] Copying apply-form source → ${SQL_FILE}"
    mkdir -p "$(dirname "${SQL_FILE}")"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E072_basic_spirit_on_gear() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/41-spirit-on-gear.sql"
    local SRC_FILE="${E072_DIR}/41-spirit-on-gear.revert.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E072_REVERT" "${SQL_FILE}"; then
        echo "  [E072] Active file already holds revert-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E072] Revert source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E072] Copying revert-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}
# -- }}}
# ==== footer of E072 ====
# lines:      73
# ==== end of footer ====
