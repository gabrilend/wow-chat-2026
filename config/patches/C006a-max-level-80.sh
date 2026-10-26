#!/usr/bin/env bash

config_max_level_80() {
    local MAX_LEVEL=80
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^MaxPlayerLevel.*=.*|MaxPlayerLevel = '"${MAX_LEVEL}"'|' "${conf}"
}
CONFIG_DESCRIPTIONS[config_max_level_80]="Max level 80"
