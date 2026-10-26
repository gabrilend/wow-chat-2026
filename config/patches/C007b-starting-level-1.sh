#!/usr/bin/env bash

config_starting_level_1() {
    local START_LEVEL=1
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^StartPlayerLevel.*=.*|StartPlayerLevel = '"${START_LEVEL}"'|' "${conf}"
}
CONFIG_DESCRIPTIONS[config_starting_level_1]="Starting level 1"
