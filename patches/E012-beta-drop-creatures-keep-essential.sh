#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E012
# profiles:   beta
# priority:   1420
# kind:       install
# about:      Removes all creature spawns except critters and spirit healers
# ==== end of header ====
# E012-beta-drop-creatures-keep-essential.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E012_beta_drop_creatures_keep_essential
# Removes all creature spawns except critters and spirit healers
# (issue 203). Beta-profile clean slate for the ambush-spawn system —
# the world is empty by default and monsters spawn around players.
#
# Snapshot-based revert: the apply source captures the full pre-apply
# `creature` table into `wow_chat_e012_snapshot_creature` BEFORE
# destruction. The unpatch's revert reads from that snapshot to
# restore the pre-apply state, then drops the snapshot table.
patch_E012_beta_drop_creatures_keep_essential() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/12-drop-creatures-keep-essential.sql"
    local SRC_FILE="${DIR}/sql/${PROFILE}/db_world.src/12-drop-creatures-keep-essential.apply.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E012_APPLY" "${SQL_FILE}"; then
        echo "  [E012] Active file already holds apply-form content"
        return 0
    fi

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E012] Apply source missing: ${SRC_FILE}"; return 1; }

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E012] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E012_beta_drop_creatures_keep_essential() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/12-drop-creatures-keep-essential.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E012_REVERT" "${SQL_FILE}"; then
        echo "  [E012] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E012] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E012_REVERT beta-drop-creatures-keep-essential
-- Revert-form: restore the `creature` table from the snapshot the
-- apply captured before its DELETEs ran, then drop the snapshot.
-- If the snapshot table is missing (e.g. apply never ran), the
-- restore is a no-op; the orphan-cleanup at the bottom is safe.
DELETE FROM `creature`;
INSERT INTO `creature` SELECT * FROM `wow_chat_e012_snapshot_creature`;
DROP TABLE IF EXISTS `wow_chat_e012_snapshot_creature`;

-- Drop the apply's working temp tables in case they were left behind.
DROP TABLE IF EXISTS `_essential_creatures`;
DROP TABLE IF EXISTS `_keep_guids`;
SQL
}
# -- }}}
# ==== footer of E012 ====
# lines:      69
# ==== end of footer ====
