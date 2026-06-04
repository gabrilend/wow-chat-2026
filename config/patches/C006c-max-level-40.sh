#!/usr/bin/env bash
# C006c - Max Level 40 (Vanilla)
# Set maximum player level to 40 for the vanilla profile.
# Halfway between retail vanilla (60) and the wow-chat custom 20, picked
# in 148 as the vanilla cap so playerbots have meaningful spread.
# Profiles: vanilla

# -- {{{ config_max_level_40
config_max_level_40() {
    local MAX_LEVEL=40
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^MaxPlayerLevel.*=.*|MaxPlayerLevel = '"${MAX_LEVEL}"'|' "${conf}"
}
CONFIG_PROFILES[config_max_level_40]="vanilla"
CONFIG_DESCRIPTIONS[config_max_level_40]="Max level 40"
# -- }}}
