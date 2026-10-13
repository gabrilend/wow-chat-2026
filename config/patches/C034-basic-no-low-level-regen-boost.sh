#!/usr/bin/env bash
# C034 - Basic: No Faster Healing Below Level 15
# Stock AzerothCore heals characters under level 15 faster out of combat,
# health and mana both (EnableLowLevelRegenBoost, on by default; Player.cpp
# adds a share of the maximum divided by the level). The owner, 2026-10-12:
# "can we turn off the mechanic that makes levels 1-5 or 10 I forget heal
# faster? They should heal at the normal rate." Basic's own healing rule
# (spirit by stamina, B049, issue 167) is untouched.
#
# Knob written into worldserver.conf:
#   EnableLowLevelRegenBoost = 0
# A config without the key stops the step with an error rather than
# leaving the boost on unnoticed.
# Profiles: basic

# -- {{{ config_basic_no_low_level_regen_boost
config_basic_no_low_level_regen_boost() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    if ! grep -qE "^EnableLowLevelRegenBoost[[:space:]]*=" "${conf}"; then
        echo "    ERROR: C034 found no 'EnableLowLevelRegenBoost' line in ${conf}; the low-level healing boost stays ON"
        echo "           to debug: grep -n RegenBoost ${conf} - did upstream rename the key?"
        return 1
    fi
    sed -i "s|^EnableLowLevelRegenBoost[[:space:]]*=.*|EnableLowLevelRegenBoost = 0|" "${conf}"
}
CONFIG_PROFILES[config_basic_no_low_level_regen_boost]="basic"
CONFIG_DESCRIPTIONS[config_basic_no_low_level_regen_boost]="No faster healing below level 15 (EnableLowLevelRegenBoost off)"
# -- }}}
