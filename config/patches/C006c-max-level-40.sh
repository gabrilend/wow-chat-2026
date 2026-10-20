#!/usr/bin/env bash

config_max_level_40() {
    local MAX_LEVEL=40
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^MaxPlayerLevel.*=.*|MaxPlayerLevel = '"${MAX_LEVEL}"'|' "${conf}"
}
CONFIG_PROFILES[config_max_level_40]="vanilla"
CONFIG_DESCRIPTIONS[config_max_level_40]="Max level 40"
