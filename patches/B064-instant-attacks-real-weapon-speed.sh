#!/usr/bin/env bash

B064_TAG='B064-real-weapon-speed'
B064_ENUM_ANCHOR='    CONFIG_ENABLE_DAZE,'
B064_READ_ANCHOR='    SetConfigValue<bool>(CONFIG_ENABLE_DAZE, "Daze.Enabled", true);'
B064_UNIT_ANCHOR='    if (!normalized || !IsPlayer())'
B064_CONF_ANCHOR='Daze.Enabled = 1'

b064_insert() {
    local file="$1" anchor="$2" block="$3" where="$4"
    local count
    count=$(grep -cxF -- "${anchor}" "${file}" || true)
    if [[ "${count}" -ne 1 ]]; then
        echo "  [B064] ERROR: expected exactly one '${anchor}' in ${file}, found ${count} (stale patch)"
        echo "         to debug: has upstream renamed or moved it? grep -n in ${file}"
        return 1
    fi
    ANCHOR="${anchor}" BLOCK="${block}" WHERE="${where}" awk '
        $0 == ENVIRON["ANCHOR"] && ENVIRON["WHERE"] == "before" { print ENVIRON["BLOCK"] }
        { print }
        $0 == ENVIRON["ANCHOR"] && ENVIRON["WHERE"] == "after" { print ENVIRON["BLOCK"] }' \
        "${file}" > "${file}.b064" && mv "${file}.b064" "${file}"
}

patch_B064_instant_attacks_real_weapon_speed() {
    local ENUMF="${AC_CODE_DIR}/src/server/game/World/WorldConfig.h"
    local READF="${AC_CODE_DIR}/src/server/game/World/WorldConfig.cpp"
    local UNITF="${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp"
    local CONF="${AC_CODE_DIR}/src/server/apps/worldserver/worldserver.conf.dist"
    local f
    for f in "${ENUMF}" "${READF}" "${UNITF}" "${CONF}"; do
        [[ -f "${f}" ]] || { echo "  [B064] ERROR: ${f} missing"; return 1; }
    done
    grep -qF "${B064_TAG}" "${UNITF}" && return 0                # witness guard

    b064_insert "${ENUMF}" "${B064_ENUM_ANCHOR}" \
"    // >>> ${B064_TAG} BEGIN
    CONFIG_INSTANT_ATTACKS_REAL_WEAPON_SPEED,   // Combat.InstantAttacks.RealWeaponSpeed (issue 813)
    // <<< ${B064_TAG} END" after || return 1

    b064_insert "${READF}" "${B064_READ_ANCHOR}" \
"    // >>> ${B064_TAG} BEGIN
    SetConfigValue<bool>(CONFIG_INSTANT_ATTACKS_REAL_WEAPON_SPEED, \"Combat.InstantAttacks.RealWeaponSpeed\", false);
    // <<< ${B064_TAG} END" after || return 1

    b064_insert "${UNITF}" "${B064_UNIT_ANCHOR}" \
"    // >>> ${B064_TAG} BEGIN
    // Combat.InstantAttacks.RealWeaponSpeed = 1: the instant attacks that
    // stock counts at a fixed speed per weapon kind (below) count the real
    // speed instead, as ordinary swings do (issue 813)
    if (normalized && sWorld->getBoolConfig(CONFIG_INSTANT_ATTACKS_REAL_WEAPON_SPEED))
        normalized = false;
    // <<< ${B064_TAG} END" before || return 1

    b064_insert "${CONF}" "${B064_CONF_ANCHOR}" \
"# >>> ${B064_TAG} BEGIN

#
#    Combat.InstantAttacks.RealWeaponSpeed
#        Description: How instant attacks with \"normalized\" weapon damage (Mortal
#                     Strike, Sinister Strike, Backstab, Crusader Strike, Obliterate,
#                     Aimed Shot and others) count attack power.
#        Default:     0 - (Blizzlike: a fixed speed per weapon kind, 1.7 daggers,
#                          2.4 other one-handers, 3.3 two-handers, 2.8 ranged)
#                     1 - (the weapon's real speed, as for ordinary swings)

Combat.InstantAttacks.RealWeaponSpeed = 0
# <<< ${B064_TAG} END" after || return 1
    echo "  [B064] Applied: Combat.InstantAttacks.RealWeaponSpeed (off unless set)"
}

unpatch_B064_instant_attacks_real_weapon_speed() {
    local f reverted=0
    for f in "${AC_CODE_DIR}/src/server/game/World/WorldConfig.h" \
             "${AC_CODE_DIR}/src/server/game/World/WorldConfig.cpp" \
             "${AC_CODE_DIR}/src/server/game/Entities/Unit/Unit.cpp" \
             "${AC_CODE_DIR}/src/server/apps/worldserver/worldserver.conf.dist"; do
        [[ -f "${f}" ]] || continue
        grep -qF "${B064_TAG}" "${f}" || continue                 # nothing of ours
        awk '
            /(\/\/|#) >>> B064-real-weapon-speed BEGIN/ { inblock = 1; next }
            inblock && /(\/\/|#) <<< B064-real-weapon-speed END/ { inblock = 0; next }
            inblock { next }
            { print }' "${f}" > "${f}.b064" && mv "${f}.b064" "${f}"
        reverted=1
    done
    [[ ${reverted} -eq 1 ]] && echo "  [B064] Reverted"
    return 0
}
