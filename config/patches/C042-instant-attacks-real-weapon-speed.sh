#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C042
# profiles:   none
# priority:   1340
# kind:       settings
# about:      Instant attacks count attack power at the real weapon speed (off until a profile is named)
# ==== end of header ====
# C042 - Instant Attacks at the Real Weapon Speed
# Issue 813. B064 adds the setting, off by default; this turns it on. The
# owner, 2026-10-30, on whether every player on basic gets it or only the
# bots: "everyone." Built and on are separate decisions (the design target
# in CLAUDE.md): the profiles line says "none" until the owner names basic
# there after the compile, then `scripts/generate-patch-lists`.
#
# Knob written into worldserver.conf:
#   Combat.InstantAttacks.RealWeaponSpeed = 1
# A config without the key (B064 not built in) stops the step with an
# error naming it.

# -- {{{ config_instant_attacks_real_weapon_speed
config_instant_attacks_real_weapon_speed() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local key="Combat.InstantAttacks.RealWeaponSpeed"
    local pattern="${key//./\\.}"
    if ! grep -qE "^${pattern}[[:space:]]*=" "${conf}"; then
        echo "    ERROR: C042 found no '${key}' line in ${conf}; instant attacks stay at the fixed speeds"
        echo "           to debug: was B064 applied in this build? grep -n 'RealWeaponSpeed' ${conf}"
        return 1
    fi
    sed -i "s|^${pattern}[[:space:]]*=.*|${key} = 1|" "${conf}"
}
CONFIG_DESCRIPTIONS[config_instant_attacks_real_weapon_speed]="Instant attacks count attack power at the real weapon speed"
# -- }}}
# ==== footer of C042 ====
# lines:      37
# ==== end of footer ====
