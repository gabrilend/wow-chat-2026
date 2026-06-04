#!/usr/bin/env bash
# C008 - GM Login State
# Set GM level on login (0 = player, 3 = admin)
# Profiles: all (vanilla=3, beta=3, release=0, alpha=0)

# -- {{{ config_gm_login_state
# vanilla logs in as admin per issue 148: the ruleset is a personal
# test/baseline server, so testing and intervention should be
# immediate. Release stays at 0 because it's the public-facing
# guaranteed-working build where admin powers should be opt-in.
config_gm_login_state() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"

    # GM level on login: 0=player, 3=admin (can use .commands)
    local gm_level
    case "${PROFILE}" in
        release) gm_level=0 ;;
        beta)    gm_level=3 ;;
        alpha)   gm_level=0 ;;
        vanilla) gm_level=3 ;;
        *)       echo "ERROR: Unknown profile '${PROFILE}' in config_gm_login_state"; return 1 ;;
    esac

    sed -i 's|^GM\.LoginState.*=.*|GM.LoginState = '"${gm_level}"'|' "${conf}"
}
CONFIG_PROFILES[config_gm_login_state]="all"
CONFIG_DESCRIPTIONS[config_gm_login_state]="GM login state (vanilla/beta=admin, release/alpha=player)"
# -- }}}
