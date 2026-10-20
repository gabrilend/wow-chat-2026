#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         E008
# profiles:   basic vanilla
# priority:   1380
# kind:       install
# about:      Clear the flightmaster bit network-wide and replace gossip with
# ==== end of header ====
# E008-vanilla-remove-flight-paths.sh - one install step, loaded by patches/E-patches.sh
# (split out of that file by scripts/split-install-steps, issue 150). Its
# helpers (_register_with_updatefetcher, _profile_db_name, ...) are in
# patches/E-helpers.sh, loaded first.

# -- {{{ patch_E008_vanilla_remove_flight_paths
# Clear the flightmaster bit network-wide and replace gossip with
# per-NPC vanilla flavor lines (issue 148i).
#
# Merged SQL-patch idiom (same shape as E007 and E009). The apply-form
# is the hand-written 426-line SQL at
# sql/vanilla/db_world.src/03-remove-flight-paths.apply.sql; the
# E-patch copies it into the AC-watched active dir. The revert is
# inline because it's small: re-set the npcflag bit on the 163
# entries that previously had it (entry list pulled from R8), then
# drop the 90000-range gossip and text rows the apply inserted.
#
# Earlier shape (pre-2026-06-02-merged-pattern): E008 registered the
# include row in updates_include and treated the static SQL file as
# canonical. That worked but had no inverse — switching away from
# vanilla left the schema changes in place. The merged shape gives
# back full apply/unpatch symmetry: each direction overwrites the
# active file, AC re-runs on hash change, the DB state matches the
# patch direction.
#
# Revert limitation (carry-forward from R8): for flightmasters that
# originally had a non-zero gossip_menu_id (very rare — a handful of
# class trainer + flightmaster hybrids), the apply overwrote the
# original ID and the revert resets to 0, not to the original.
# Acceptable for the 156-NPC set since none of the spawned vanilla
# flightmasters have a confirmed hybrid role.
patch_E008_vanilla_remove_flight_paths() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/03-remove-flight-paths.sql"
    local SRC_FILE="$(_shared_sql_src db_world)/03-remove-flight-paths.apply.sql"

    [[ ! -f "${SRC_FILE}" ]] && { echo "  [E008] Apply source missing: ${SRC_FILE}"; return 1; }

    # Register first, on every run: INSERT IGNORE makes it a no-op once the
    # row exists, and a run that found MySQL down must not be the last word
    # (the early return below would otherwise skip registration forever).
    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    # Idempotence by content comparison, not by marker: a marker check left
    # the active file stale whenever the source was edited (new flavor lines,
    # retuned values), so an existing install never picked the edit up.
    # Same shape as E018. On a change AC's UpdateFetcher sees a new hash and
    # re-runs the file, which is written to be re-applicable.
    if [[ -f "${SQL_FILE}" ]] && cmp -s "${SRC_FILE}" "${SQL_FILE}"; then
        echo "  [E008] Active file already matches apply-form content"
        return 0
    fi

    echo "  [E008] Copying apply-form source → ${SQL_FILE}"
    cp "${SRC_FILE}" "${SQL_FILE}"
}

unpatch_E008_vanilla_remove_flight_paths() {
    local SQL_FILE="${DIR}/sql/${PROFILE}/db_world/03-remove-flight-paths.sql"

    if [[ -f "${SQL_FILE}" ]] && grep -q "^-- MARKER_E008_REVERT" "${SQL_FILE}"; then
        echo "  [E008] Active file already holds revert-form content"
        return 0
    fi

    _register_with_updatefetcher "${DIR}/sql/${PROFILE}/db_world" "$(_profile_db_name acore_world)" || return 1

    # Revert restores the flightmaster bit (0x2000 = 8192) on the 163
    # entries that R8 enumerated as having the flag before the apply
    # cleared it. Hardcoded as a literal IN list so revert is exact —
    # see R8 Results in tmp/148-parallelization-roadmap.md and the raw
    # data at tmp/r8-flightmasters.tsv. The 156 spawned templates and
    # the 7 unused/UNUSED templates are all included so a future GM
    # re-spawn doesn't surface a flightmaster without the flag set.
    echo "  [E008] Writing revert-form SQL to ${SQL_FILE}"
    cat > "${SQL_FILE}" <<'SQL'
-- MARKER_E008_REVERT vanilla-remove-flight-paths
-- Revert-form: restore flightmaster bit on the 163 entries R8 enumerated,
-- reset gossip_menu_id for our 90000-range entries (limitation: original
-- non-zero values for hybrid trainer+flightmaster NPCs are lost), drop
-- the 90000-range gossip_menu and npc_text rows.

UPDATE `creature_template` SET `npcflag` = `npcflag` | 8192
WHERE `entry` IN (
    352,353,523,931,1233,1387,1571,1572,1573,1574,1575,2226,2299,2389,2409,2432,2835,2851,2858,
    2859,2861,2941,2995,3305,3310,3615,3838,3841,4267,4312,4314,4317,4319,4321,4407,4551,6026,
    6706,6726,7823,7824,8018,8019,8020,8609,8610,10378,10583,10897,11138,11139,11899,11900,
    11901,12577,12578,12596,12616,12617,12636,12740,13177,14242,15177,15178,16189,16192,16227,
    16587,16822,17554,17555,18785,18788,18789,18791,18807,18808,18809,18930,18931,18937,18938,
    18939,18940,18942,18953,19317,19558,19581,19583,20234,20515,20762,21107,21766,22216,22455,
    22485,22931,22935,23612,23736,23859,24032,24061,24155,24366,24795,24851,25288,26560,26566,
    26602,26842,26844,26845,26846,26847,26848,26850,26851,26852,26853,26876,26877,26878,26879,
    26880,26881,27046,27344,28037,28195,28196,28197,28574,28615,28618,28623,28624,28674,29480,
    29721,29750,29757,29762,29950,29951,30269,30271,30314,30433,30569,30869,30870,31069,31078,
    31426,32571,33849,37888,37915
);

UPDATE `creature_template` SET `gossip_menu_id` = 0
WHERE `gossip_menu_id` BETWEEN 90001 AND 90999;

DELETE FROM `gossip_menu` WHERE `MenuID` BETWEEN 90000 AND 90999;
DELETE FROM `npc_text`    WHERE `ID`     BETWEEN 90000 AND 90999;
SQL
}
# -- }}}
# ==== footer of E008 ====
# lines:      115
# ==== end of footer ====
