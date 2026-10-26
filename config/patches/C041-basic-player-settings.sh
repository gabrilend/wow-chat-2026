#!/usr/bin/env bash

config_basic_player_settings() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    if grep -qE "^EnablePlayerSettings[[:space:]]*=" "${conf}"; then
        sed -i "s|^EnablePlayerSettings[[:space:]]*=.*|EnablePlayerSettings = 1|" "${conf}"
    else
        printf '\n# C041 (basic, 720): per-character settings, for hidden shoulders\nEnablePlayerSettings = 1\n' >> "${conf}"
    fi
}
CONFIG_DESCRIPTIONS[config_basic_player_settings]="Per-character player settings on (hidden shoulders keep there)"
