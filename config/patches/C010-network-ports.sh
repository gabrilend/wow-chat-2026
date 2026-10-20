#!/usr/bin/env bash

config_network_ports() {
    local conf_auth="${INSTALL_DIR}/etc/authserver.conf"
    local conf_world="${INSTALL_DIR}/etc/worldserver.conf"

    local WORLDSERVER_PORT
    local AUTHSERVER_PORT
    case "${PROFILE}" in
        release|beta|vanilla|basic|cc-test)  WORLDSERVER_PORT=4462; AUTHSERVER_PORT=4362 ;;
        alpha)                 WORLDSERVER_PORT=4463; AUTHSERVER_PORT=4363 ;;
        *)                     echo "ERROR: Unknown profile '${PROFILE}' in config_network_ports"; return 1 ;;
    esac

    sed -i 's|^WorldServerPort.*=.*|WorldServerPort = '"${WORLDSERVER_PORT}"'|' "${conf_world}"

    sed -i 's|^RealmServerPort.*=.*|RealmServerPort = '"${AUTHSERVER_PORT}"'|' "${conf_auth}"
}
CONFIG_PROFILES[config_network_ports]="all"
CONFIG_DESCRIPTIONS[config_network_ports]="Network ports (4362/4462)"
