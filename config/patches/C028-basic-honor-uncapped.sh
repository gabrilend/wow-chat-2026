#!/usr/bin/env bash

config_basic_honor_uncapped() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^MaxHonorPoints[[:space:]]*=.*|MaxHonorPoints = 2147483647|' "${conf}"
}
CONFIG_PROFILES[config_basic_honor_uncapped]="basic"
CONFIG_DESCRIPTIONS[config_basic_honor_uncapped]="Honor effectively uncapped (glyphs cost more than the stock 75,000)"
