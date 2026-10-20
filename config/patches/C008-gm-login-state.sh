#!/usr/bin/env bash

config_gm_login_state() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"

    local gm_level
    case "${PROFILE}" in
        release) gm_level=0 ;;
        beta)    gm_level=3 ;;
        alpha)   gm_level=0 ;;
        vanilla) gm_level=3 ;;
        basic)   gm_level=3 ;;   # basic (155) is the development baseline; same reasoning as vanilla
        cc-test) gm_level=0 ;;   # cc-test (176): a test character sees what a player sees and meets every check a player meets
        *)       echo "ERROR: Unknown profile '${PROFILE}' in config_gm_login_state"; return 1 ;;
    esac

    sed -i 's|^GM\.LoginState.*=.*|GM.LoginState = '"${gm_level}"'|' "${conf}"
}
CONFIG_PROFILES[config_gm_login_state]="all"
CONFIG_DESCRIPTIONS[config_gm_login_state]="GM login state (vanilla/basic/beta=admin, release/alpha/cc-test=player)"
