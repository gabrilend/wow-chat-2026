#!/usr/bin/env bash

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
