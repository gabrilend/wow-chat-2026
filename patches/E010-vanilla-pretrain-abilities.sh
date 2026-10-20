#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E010
# profiles:   vanilla
# priority:   2400
# kind:       sql
# about:      Grant every newly-created vanilla character the full set of
# ==== end of header ====
# E010-vanilla-pretrain-abilities.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E010_vanilla_pretrain_abilities
# Grant every newly-created vanilla character the full set of
# class-trainer spells they'd normally learn by level 20 (issue 148j).
# 287 (classmask, spell) rows go into playercreateinfo_spell_custom
# with a 'vanilla-148j-' Note tag prefix.
#
# Merged SQL-patch idiom (same shape as E007/E008/E009). Apply source
# is 338 lines of generated SQL at
# sql/vanilla/db_world.src/04-pretrain-abilities.apply.sql (originally
# emitted by scripts/generate-148j-pretrain-sql; column names
# corrected on intake — schema is racemask/classmask, not race/class).
# Revert is a single DELETE-by-tag, inline.
#
# Dependency note: E009's off-hand kit items (Orc Hunter axes, every
# Rogue's twin daggers) need spell 674 "Dual Wield" to equip. This
# patch grants it, so E009's off-hand items become equippable only
# once both E009 and E010 have applied.
patch_E010_vanilla_pretrain_abilities() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/04-pretrain-abilities.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/04-pretrain-abilities.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E010_APPLY" "${SQL_FILE}"; then
        echo "  [E010] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E010] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E010] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E010_vanilla_pretrain_abilities() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/04-pretrain-abilities.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E010_REVERT" "${SQL_FILE}"; then
        echo "  [E010] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    # Revert drops exactly the 287 rows tagged with the 'vanilla-148j-'
    # Note prefix. Default rows in playercreateinfo_spell_custom (the
    # DK starter Blood Strike from death-knights.sql, any other class
    # defaults) stay intact.
    echo "  [E010] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E010_REVERT vanilla-pretrain-abilities
-- Revert-form: drop every pretrain row tagged 'vanilla-148j-'.
DELETE FROM `playercreateinfo_spell_custom` WHERE `Note` LIKE 'vanilla-148j-%';
SQL
}
# -- }}}
# ==== footer of E010 ====
# lines:      72
# ==== end of footer ====
