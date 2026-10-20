#!/usr/bin/env bash

config_basic_buddy_own_talents() {
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.AltMaintenanceTalentTree[[:space:]]*=.*|AiPlayerbot.AltMaintenanceTalentTree = 0|' "${conf}"
}
CONFIG_PROFILES[config_basic_buddy_own_talents]="basic cc-test"
CONFIG_DESCRIPTIONS[config_basic_buddy_own_talents]="Buddies' talents by the project's script: bot maintenance leaves talents alone"
