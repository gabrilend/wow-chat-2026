#!/usr/bin/env bash

config_max_level_20() {
    local MAX_LEVEL=20
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^MaxPlayerLevel.*=.*|MaxPlayerLevel = '"${MAX_LEVEL}"'|' "${conf}"
}
CONFIG_PROFILES[config_max_level_20]="beta release"
CONFIG_DESCRIPTIONS[config_max_level_20]="Max level 20"
