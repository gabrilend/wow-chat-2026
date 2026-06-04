#!/usr/bin/env bash
# C006a - Max Level 80 (Alpha)
# Set maximum player level to 80 (testing different values per profile)
# Profiles: alpha

# -- {{{ config_max_level_80
config_max_level_80() {
    local MAX_LEVEL=80
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^MaxPlayerLevel.*=.*|MaxPlayerLevel = '"${MAX_LEVEL}"'|' "${conf}"
}
CONFIG_PROFILES[config_max_level_80]="alpha"
CONFIG_DESCRIPTIONS[config_max_level_80]="Max level 80"
# -- }}}
