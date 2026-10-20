#!/usr/bin/env bash

config_starting_level_20() {
    local START_LEVEL=20
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^StartPlayerLevel.*=.*|StartPlayerLevel = '"${START_LEVEL}"'|' "${conf}"
}
CONFIG_PROFILES[config_starting_level_20]="vanilla"
CONFIG_DESCRIPTIONS[config_starting_level_20]="Starting level 20"
