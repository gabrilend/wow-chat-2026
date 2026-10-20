#!/usr/bin/env bash

config_exp_rate_2x() {
    local XP_RATE=2.0
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^Rate\.XP\.Kill[[:space:]]*=.*|Rate.XP.Kill = '"${XP_RATE}"'|' "${conf}"
    sed -i 's|^Rate\.XP\.Quest[[:space:]]*=.*|Rate.XP.Quest = '"${XP_RATE}"'|' "${conf}"
}
CONFIG_PROFILES[config_exp_rate_2x]="release"
CONFIG_DESCRIPTIONS[config_exp_rate_2x]="Experience rate 2x"
