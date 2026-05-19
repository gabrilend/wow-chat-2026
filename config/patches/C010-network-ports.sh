#!/usr/bin/env bash
# C010 - Network Ports
# Set custom server ports (non-default to avoid conflicts)
# Profiles: all

# -- {{{ config_network_ports
config_network_ports() {
    local conf_auth="${INSTALL_DIR}/etc/authserver.conf"
    local conf_world="${INSTALL_DIR}/etc/worldserver.conf"

    # Port isolation policy: release/beta share a port range; alpha gets a wholly
    # separate one so a running release and a running alpha can coexist on the
    # same box without colliding. The convention is:
    #   release/beta:  authserver 4362, worldserver 4462
    #   alpha:         authserver 4363, worldserver 4463
    # Pairs with C001's database port split (release/beta on 3307, alpha on 3308)
    # so each profile's whole stack is independent.
    local WORLDSERVER_PORT
    local AUTHSERVER_PORT
    case "${PROFILE}" in
        release|beta)  WORLDSERVER_PORT=4462; AUTHSERVER_PORT=4362 ;;
        alpha)         WORLDSERVER_PORT=4463; AUTHSERVER_PORT=4363 ;;
        *)             echo "ERROR: Unknown profile '${PROFILE}' in config_network_ports"; return 1 ;;
    esac

    # Worldserver port
    sed -i 's|^WorldServerPort.*=.*|WorldServerPort = '"${WORLDSERVER_PORT}"'|' "${conf_world}"

    # Authserver port (RealmServerPort)
    sed -i 's|^RealmServerPort.*=.*|RealmServerPort = '"${AUTHSERVER_PORT}"'|' "${conf_auth}"
}
CONFIG_PROFILES[config_network_ports]="all"
CONFIG_DESCRIPTIONS[config_network_ports]="Network ports (4362/4462)"
# -- }}}
