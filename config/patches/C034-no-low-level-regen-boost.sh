#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C034
# profiles:   all
# priority:   1285
# kind:       settings
# about:      No Faster Healing Below Level 15, on Every Server
# ==== end of header ====
# C034 - No Faster Healing Below Level 15, on Every Server
# Stock AzerothCore heals characters under level 15 faster out of combat,
# health and mana both (EnableLowLevelRegenBoost, on by default; Player.cpp
# adds a share of the maximum divided by the level). The owner, 2026-10-12,
# for basic: "can we turn off the mechanic that makes levels 1-5 or 10 I
# forget heal faster? They should heal at the normal rate." And 2026-10-20,
# for the rest: "we should remove the low level regen boost on all servers.
# It feels cheap!" Basic's own healing rule (spirit by stamina, B049, issue
# 167) is untouched. (Until 2026-10-20 this was
# C034-basic-no-low-level-regen-boost, basic only.)
#
# Knob written into worldserver.conf:
#   EnableLowLevelRegenBoost = 0
# A config without the key stops the step with an error rather than
# leaving the boost on unnoticed (alpha's older server has the key too).
# Profiles: all

# -- {{{ config_no_low_level_regen_boost
config_no_low_level_regen_boost() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    if ! grep -qE "^EnableLowLevelRegenBoost[[:space:]]*=" "${conf}"; then
        echo "    ERROR: C034 found no 'EnableLowLevelRegenBoost' line in ${conf}; the low-level healing boost stays ON"
        echo "           to debug: grep -n RegenBoost ${conf} - did upstream rename the key?"
        return 1
    fi
    sed -i "s|^EnableLowLevelRegenBoost[[:space:]]*=.*|EnableLowLevelRegenBoost = 0|" "${conf}"
}
CONFIG_DESCRIPTIONS[config_no_low_level_regen_boost]="No faster healing below level 15 (EnableLowLevelRegenBoost off)"
# -- }}}
# ==== footer of C034 ====
# lines:      40
# ==== end of footer ====
