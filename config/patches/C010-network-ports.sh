#!/usr/bin/env bash
# C010 - Network Ports
# Set custom server ports (non-default to avoid conflicts)
# Profiles: all

# -- {{{ config_network_ports
config_network_ports() {
    local conf_auth="${INSTALL_DIR}/etc/authserver.conf"
    local conf_world="${INSTALL_DIR}/etc/worldserver.conf"

    # Port isolation policy (revised by 136a — unified-realmlist):
    #   release/beta/vanilla:  authserver 4362, worldserver 4462 (shared)
    #   alpha:                 authserver 4363, worldserver 4463
    # Release, beta, and vanilla share the auth+world ports so the user's
    # realmlist.wtf never has to change between profile flips. Only one of
    # {release, beta, vanilla} can run at a time, owning the shared ports;
    # the realm select screen surfaces which one is up via the `flag`
    # column on acore_auth.realmlist. Alpha keeps its own port pair because
    # it has its own MySQL instance (3308) and its own auth DB — fully
    # isolated stack, can coexist with the other three.
    local WORLDSERVER_PORT
    local AUTHSERVER_PORT
    case "${PROFILE}" in
        release|beta|vanilla)  WORLDSERVER_PORT=4462; AUTHSERVER_PORT=4362 ;;
        alpha)                 WORLDSERVER_PORT=4463; AUTHSERVER_PORT=4363 ;;
        *)                     echo "ERROR: Unknown profile '${PROFILE}' in config_network_ports"; return 1 ;;
    esac

    # Worldserver port
    sed -i 's|^WorldServerPort.*=.*|WorldServerPort = '"${WORLDSERVER_PORT}"'|' "${conf_world}"

    # Authserver port (RealmServerPort)
    sed -i 's|^RealmServerPort.*=.*|RealmServerPort = '"${AUTHSERVER_PORT}"'|' "${conf_auth}"
}
CONFIG_PROFILES[config_network_ports]="all"
CONFIG_DESCRIPTIONS[config_network_ports]="Network ports (4362/4462)"
# -- }}}
