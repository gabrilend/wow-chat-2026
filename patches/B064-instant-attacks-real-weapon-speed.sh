#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         B064
# profiles:   basic beta cc-test release vanilla
# priority:   740
# kind:       source
# about:      a setting: instant attacks count attack power at the real weapon speed (issue 813)
# ==== end of header ====
# B064 - instant attacks at the real weapon speed, as a setting
#
# For a general audience: some instant attacks (Mortal Strike, Sinister
# Strike, Backstab, Crusader Strike, Obliterate, Aimed Shot and others:
# every spell with the "normalized weapon damage" effect) count attack power
# as if the weapon had a fixed speed for its kind: 1.7 for a dagger, 2.4
# for another one-hander, 3.3 for a two-hander, 2.8 for a ranged weapon.
# The owner, 2026-10-30: "that seems dumb and wrong. We should use the
# actual weapon speed." This adds a setting that does so, off by default
# (stock play unchanged), shaped so it can be offered upstream as it is
# (the owner: "obviously once we've tested it and make it rockhard and
# bulletproof"):
#
#   Combat.InstantAttacks.RealWeaponSpeed = 0
#     0: stock, the fixed speeds above; 1: the weapon's real speed, as for
#     ordinary swings. Turned on per profile by a settings patch (C042,
#     basic; on only when its header names the profile).
#
# Where: WorldConfig.h names the setting, WorldConfig.cpp reads it (beside
# Daze.Enabled, another combat rule), Unit::GetAPMultiplier (Unit.cpp) asks
# for the real speed when it is on, worldserver.conf.dist documents it.
# One change at the multiplier covers every use of the fixed speed: the
# spell damage of the normalized effect and the stat code's two uses.
#
# Mechanics: pure insertions between ">>> B064-real-weapon-speed BEGIN" /
# "<<< ... END" marker comments (// in code, # in the config template),
# after anchors that must each occur exactly once (else the patch stops);
# the revert deletes the blocks.

B064_TAG='B064-real-weapon-speed'
B064_ENUM_ANCHOR='    CONFIG_ENABLE_DAZE,'
B064_READ_ANCHOR='    SetConfigValue<bool>(CONFIG_ENABLE_DAZE, "Daze.Enabled", true);'
B064_UNIT_ANCHOR='    if (!normalized || !IsPlayer())'
B064_CONF_ANCHOR='Daze.Enabled = 1'

# {{{ b064_insert
# Insert the lines of $3 after (where=after) or before (where=before) the
# one line equal to $2 in file $1. Stops if the anchor is not there exactly
# once.
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
# }}}

# {{{ patch_B064_instant_attacks_real_weapon_speed
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
# }}}

# {{{ unpatch_B064_instant_attacks_real_weapon_speed
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
# }}}
# ==== footer of B064 ====
# lines:      136
# ==== end of footer ====
