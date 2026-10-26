#!/usr/bin/env bash

config_realm_id() {
    local conf_world="${INSTALL_DIR}/etc/worldserver.conf"

    local REALM_ID
    case "${PROFILE}" in
        release)  REALM_ID=1 ;;
        beta)     REALM_ID=2 ;;
        vanilla)  REALM_ID=3 ;;
        alpha)    REALM_ID=4 ;;
        basic)    REALM_ID=5 ;;
        cc-test)  REALM_ID=6 ;;
        *)
            echo "ERROR: Unknown profile '${PROFILE}' in config_realm_id"
            return 1
            ;;
    esac

    sed -i 's|^RealmID.*=.*|RealmID = '"${REALM_ID}"'|' "${conf_world}"
}
CONFIG_DESCRIPTIONS[config_realm_id]="RealmID per profile (1=release, 2=beta, 3=vanilla, 4=alpha, 5=basic, 6=cc-test)"
