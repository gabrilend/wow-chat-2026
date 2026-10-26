#!/usr/bin/env bash

config_max_level_60() {
    local MAX_LEVEL=60
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^MaxPlayerLevel.*=.*|MaxPlayerLevel = '"${MAX_LEVEL}"'|' "${conf}"
}
CONFIG_DESCRIPTIONS[config_max_level_60]="Max level 60"
