#!/usr/bin/env bash
# C009 - Instant Teleport (Beta)
# Instant teleport cooldowns for beta testing
# Profiles: beta

# -- {{{ config_instant_teleport_beta
config_instant_teleport_beta() {
    local INSTANT_TAXI=1
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    # The key is InstantFlightPaths (0 off, 1 always, 2 per-player toggle).
    # Until 2026-09-23 this wrote "Instant.Taxi", which the config does not
    # have, so instant flights were never on for beta and nothing said so.
    if ! grep -qE '^InstantFlightPaths[[:space:]]*=' "${conf}"; then
        echo "    ERROR: C009 found no InstantFlightPaths line in ${conf}; instant flights NOT set"
        return 1
    fi
    sed -i 's|^InstantFlightPaths[[:space:]]*=.*|InstantFlightPaths = '"${INSTANT_TAXI}"'|' "${conf}"
}
CONFIG_PROFILES[config_instant_teleport_beta]="beta"
CONFIG_DESCRIPTIONS[config_instant_teleport_beta]="Instant taxi travel"
# -- }}}
