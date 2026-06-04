#!/usr/bin/env bash
# C009 - Instant Teleport (Beta)
# Instant teleport cooldowns for beta testing
# Profiles: beta

# -- {{{ config_instant_teleport_beta
config_instant_teleport_beta() {
    local INSTANT_TAXI=1
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^Instant\.Taxi.*=.*|Instant.Taxi = '"${INSTANT_TAXI}"'|' "${conf}"
}
CONFIG_PROFILES[config_instant_teleport_beta]="beta"
CONFIG_DESCRIPTIONS[config_instant_teleport_beta]="Instant taxi travel"
# -- }}}
