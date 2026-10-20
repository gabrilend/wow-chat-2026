#!/usr/bin/env bash

config_no_low_level_regen_boost() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    if ! grep -qE "^EnableLowLevelRegenBoost[[:space:]]*=" "${conf}"; then
        echo "    ERROR: C034 found no 'EnableLowLevelRegenBoost' line in ${conf}; the low-level healing boost stays ON"
        echo "           to debug: grep -n RegenBoost ${conf} - did upstream rename the key?"
        return 1
    fi
    sed -i "s|^EnableLowLevelRegenBoost[[:space:]]*=.*|EnableLowLevelRegenBoost = 0|" "${conf}"
}
CONFIG_PROFILES[config_no_low_level_regen_boost]="all"
CONFIG_DESCRIPTIONS[config_no_low_level_regen_boost]="No faster healing below level 15 (EnableLowLevelRegenBoost off)"
