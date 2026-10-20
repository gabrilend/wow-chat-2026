#!/usr/bin/env bash

config_starting_level_40() {
    local START_LEVEL=40
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^StartPlayerLevel.*=.*|StartPlayerLevel = '"${START_LEVEL}"'|' "${conf}"
}
CONFIG_PROFILES[config_starting_level_40]="alpha"
CONFIG_DESCRIPTIONS[config_starting_level_40]="Starting level 40"
