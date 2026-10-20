#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E015
# profiles:   beta
# priority:   2450
# kind:       sql
# about:      Race-specific selector NPCs for the custom class selection system
# ==== end of header ====
# E015-beta-class-selector-npcs.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E015_beta_class_selector_npcs
# Race-specific selector NPCs for the custom class selection system
# (issue 155). Custom entries 900001-900011 in creature_template and
# creature_template_model.
patch_E015_beta_class_selector_npcs() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/15-class-selector-npcs.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/15-class-selector-npcs.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E015_APPLY" "${SQL_FILE}"; then
        echo "  [E015] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E015] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E015] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E015_beta_class_selector_npcs() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/15-class-selector-npcs.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E015_REVERT" "${SQL_FILE}"; then
        echo "  [E015] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E015] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E015_REVERT beta-class-selector-npcs
-- Revert-form: drop the project's custom selector NPCs and models.
-- Entry IDs 900001-900011 are project-owned (900009 skipped — Goblin,
-- absent in WotLK; see apply source for rationale).
DELETE FROM `creature_template`       WHERE `entry`      IN (900001, 900002, 900003, 900004, 900005, 900006, 900007, 900008, 900010, 900011);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (900001, 900002, 900003, 900004, 900005, 900006, 900007, 900008, 900010, 900011);
SQL
}
# -- }}}
# ==== footer of E015 ====
# lines:      58
# ==== end of footer ====
