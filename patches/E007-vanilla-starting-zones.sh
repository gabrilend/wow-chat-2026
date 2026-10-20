#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E007
# profiles:   vanilla
# priority:   1370
# kind:       install
# about:      Override playercreateinfo so vanilla characters spawn at the
# ==== end of header ====
# E007-vanilla-starting-zones.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E007_vanilla_starting_zones
# Override playercreateinfo so vanilla characters spawn at the
# canonical level-20 contested zones (Darkshire for Alliance, Tarren
# Mill for Horde) instead of the per-race level-1 tutorial enclaves.
# Issue 148 (R3 supplied the coordinates).
#
# Reference implementation of the project's merged SQL-patch idiom
# (see B-patches for the analogue with C++ source). The E-patch writes
# apply-form OR revert-form SQL into a single file at the active dir;
# AC's UpdateFetcher hashes the file on next worldserver boot and
# applies (or re-applies on hash change) the new content. Both
# directions are explicit and hardcode their target values inline.
#
# Idempotence: each direction starts with a marker grep against the
# current file content. If the marker shows the file already holds
# that direction's content, no work is done. Apply twice in a row →
# the second is a no-op. Apply, then unpatch, then apply again → each
# transition rewrites and AC re-runs on the next boot.
patch_E007_vanilla_starting_zones() {
    # Vanilla-only — the SQL would scribble over release/beta/alpha
    # starting zones, which is wrong for those profiles.
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/01-starting-zones.sql"

    # Idempotence guard: if the active file already holds the apply
    # marker, the content matches what we'd write and there's nothing
    # to do.
    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E007_APPLY" "${SQL_FILE}"; then
        echo "  [E007] Active file already holds apply-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    echo "  [E007] Writing apply-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E007_APPLY vanilla-starting-zones
-- Apply-form (148n/148o): per-race spawn assignment, anchored at each
-- town's innkeeper NPC (coords measured live from the creature table,
-- so the spawn tile is guaranteed walkable ground rather than a
-- copied-from-memory town-center guess). Each row sends a (race, non-DK) pair to a specific
-- town across the world rather than bucketing every Alliance/Horde
-- character into one Darkshire/Tarren Mill pair.
--
--   Human + Dwarf      → Wetlands / Menethil Harbor (map 0, zone 38)
--   Draenei            → Duskwood / Darkshire       (map 0, zone 10)
--   Night Elf + Gnome  → Ashenvale / Astranaar      (map 1, zone 331)
--   Orc                → Northern Barrens / Ratchet (map 1, zone 17)
--   Undead + Troll     → Hillsbrad / Tarren Mill    (map 0, zone 267)
--   Tauren + Blood Elf → Stonetalon / Sun Rock      (map 1, zone 406)
--
-- DK rows (class=6) left alone so a re-enabled DK still lands at
-- Ebon Hold (assumes WotLK opener).
UPDATE `playercreateinfo` SET `map`=0, `zone`=38,  `position_x`=-3827.93, `position_y`=-831.9,   `position_z`=10.09,  `orientation`=0.4014 WHERE `race` IN (1,3)  AND `class` != 6;
UPDATE `playercreateinfo` SET `map`=0, `zone`=10,  `position_x`=-10516.0, `position_y`=-1161.21, `position_z`=28.12,  `orientation`=4.0317 WHERE `race` = 11      AND `class` != 6;
UPDATE `playercreateinfo` SET `map`=1, `zone`=331, `position_x`=2781.16,  `position_y`=-433.0,   `position_z`=116.67, `orientation`=2.5831 WHERE `race` IN (4,7)  AND `class` != 6;
UPDATE `playercreateinfo` SET `map`=1, `zone`=17,  `position_x`=-1050.04, `position_y`=-3664.8,  `position_z`=23.97,  `orientation`=6.0039 WHERE `race` = 2       AND `class` != 6;
UPDATE `playercreateinfo` SET `map`=0, `zone`=267, `position_x`=-5.97,    `position_y`=-942.28,  `position_z`=57.16,  `orientation`=2.7415 WHERE `race` IN (5,8)  AND `class` != 6;
UPDATE `playercreateinfo` SET `map`=1, `zone`=406, `position_x`=893.65,   `position_y`=927.95,   `position_z`=106.36, `orientation`=5.7072 WHERE `race` IN (6,10) AND `class` != 6;
SQL
}

unpatch_E007_vanilla_starting_zones() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/01-starting-zones.sql"

    # Idempotence guard for the revert direction.
    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E007_REVERT" "${SQL_FILE}"; then
        echo "  [E007] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    # Revert-form hardcodes the literal upstream per-race default
    # coordinates pulled directly from
    # source-beta/data/sql/base/db_world/playercreateinfo.sql so the
    # restored state is exactly what AzerothCore ships. DK rows
    # (class=6, all at Ebon Hold) untouched in both directions.
    echo "  [E007] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E007_REVERT vanilla-starting-zones
-- Revert-form: restore each race's upstream default starting zone.
-- Values are literal from source-beta/data/sql/base/db_world/playercreateinfo.sql.
UPDATE `playercreateinfo` SET `map`=0,   `zone`=12,   `position_x`=-8949.95, `position_y`=-132.493,  `position_z`=83.5312, `orientation`=0       WHERE `race`=1  AND `class` != 6;  -- Human   → Northshire Valley
UPDATE `playercreateinfo` SET `map`=1,   `zone`=14,   `position_x`=-618.518, `position_y`=-4251.67,  `position_z`=38.718,  `orientation`=0       WHERE `race`=2  AND `class` != 6;  -- Orc     → Valley of Trials
UPDATE `playercreateinfo` SET `map`=0,   `zone`=1,    `position_x`=-6240.32, `position_y`=331.033,   `position_z`=382.758, `orientation`=6.17716 WHERE `race`=3  AND `class` != 6;  -- Dwarf   → Coldridge Valley
UPDATE `playercreateinfo` SET `map`=1,   `zone`=141,  `position_x`=10311.3,  `position_y`=832.463,   `position_z`=1326.41, `orientation`=5.69632 WHERE `race`=4  AND `class` != 6;  -- NElf    → Shadowglen
UPDATE `playercreateinfo` SET `map`=0,   `zone`=85,   `position_x`=1676.71,  `position_y`=1678.31,   `position_z`=121.67,  `orientation`=2.70526 WHERE `race`=5  AND `class` != 6;  -- Undead  → Deathknell
UPDATE `playercreateinfo` SET `map`=1,   `zone`=215,  `position_x`=-2917.58, `position_y`=-257.98,   `position_z`=52.9968, `orientation`=0       WHERE `race`=6  AND `class` != 6;  -- Tauren  → Camp Narache
UPDATE `playercreateinfo` SET `map`=0,   `zone`=1,    `position_x`=-6240.32, `position_y`=331.033,   `position_z`=382.758, `orientation`=0       WHERE `race`=7  AND `class` != 6;  -- Gnome   → Coldridge Valley (shared w/ Dwarves)
UPDATE `playercreateinfo` SET `map`=1,   `zone`=14,   `position_x`=-618.518, `position_y`=-4251.67,  `position_z`=38.718,  `orientation`=0       WHERE `race`=8  AND `class` != 6;  -- Troll   → Valley of Trials (shared w/ Orcs)
UPDATE `playercreateinfo` SET `map`=530, `zone`=3431, `position_x`=10349.6,  `position_y`=-6357.29,  `position_z`=33.4026, `orientation`=5.31605 WHERE `race`=10 AND `class` != 6;  -- BElf    → Sunstrider Isle
UPDATE `playercreateinfo` SET `map`=530, `zone`=3526, `position_x`=-3961.64, `position_y`=-13931.2,  `position_z`=100.615, `orientation`=2.08364 WHERE `race`=11 AND `class` != 6;  -- Draenei → Ammen Vale
SQL
}
# -- }}}
# ==== footer of E007 ====
# lines:      111
# ==== end of footer ====
