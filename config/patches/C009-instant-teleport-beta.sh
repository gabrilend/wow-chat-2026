#!/usr/bin/env bash

config_instant_teleport_beta() {
    local INSTANT_TAXI=1
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    if ! grep -qE '^InstantFlightPaths[[:space:]]*=' "${conf}"; then
        echo "    ERROR: C009 found no InstantFlightPaths line in ${conf}; instant flights NOT set"
        return 1
    fi
    sed -i 's|^InstantFlightPaths[[:space:]]*=.*|InstantFlightPaths = '"${INSTANT_TAXI}"'|' "${conf}"
}
CONFIG_DESCRIPTIONS[config_instant_teleport_beta]="Instant taxi travel"
