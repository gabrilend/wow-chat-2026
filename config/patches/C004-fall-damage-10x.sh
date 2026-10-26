#!/usr/bin/env bash

config_fall_damage_10x() {
    local FALL_DAMAGE_MULTIPLIER=10.0
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^Rate\.Damage\.Fall.*=.*|Rate.Damage.Fall = '"${FALL_DAMAGE_MULTIPLIER}"'|' "${conf}"
}
CONFIG_DESCRIPTIONS[config_fall_damage_10x]="Fall damage 10x (careful movement)"
