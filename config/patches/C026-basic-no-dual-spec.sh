#!/usr/bin/env bash

config_basic_no_dual_spec() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^MinDualSpecLevel[[:space:]]*=.*|MinDualSpecLevel = 255|' "${conf}"
}
CONFIG_DESCRIPTIONS[config_basic_no_dual_spec]="No dual spec: MinDualSpecLevel above the level cap"
