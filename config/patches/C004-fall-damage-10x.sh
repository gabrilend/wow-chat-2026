#!/usr/bin/env bash
# C004 - Fall Damage 10x
# Increase fall damage to 10x (encourages careful movement)
# Profiles: beta release vanilla basic (basic per issue 155, user decision 2026-09-23)
# vanilla added 2026-06-02 per 148 — vanilla's deliberate-travel design
# (80% movement speed, no flight paths, level cap 40) pairs with falls
# that hurt. Players respect terrain.

# -- {{{ config_fall_damage_10x
config_fall_damage_10x() {
    local FALL_DAMAGE_MULTIPLIER=10.0
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^Rate\.Damage\.Fall.*=.*|Rate.Damage.Fall = '"${FALL_DAMAGE_MULTIPLIER}"'|' "${conf}"
}
CONFIG_PROFILES[config_fall_damage_10x]="beta release vanilla basic"
CONFIG_DESCRIPTIONS[config_fall_damage_10x]="Fall damage 10x (careful movement)"
# -- }}}
