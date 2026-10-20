#!/usr/bin/env bash

config_run_speed_80_percent() {
    local RUN_SPEED=0.85
    local conf="${INSTALL_DIR}/etc/worldserver.conf"

    local -A SPEED_KEY_BY_PROFILE=(
        [release]="Rate.MoveSpeed.Player"
        [beta]="Rate.MoveSpeed.Player"
        [vanilla]="Rate.MoveSpeed.Player"
        [basic]="Rate.MoveSpeed.Player"
        [alpha]="Rate.MoveSpeed"
    )
    local key="${SPEED_KEY_BY_PROFILE[${PROFILE}]:-}"
    if [[ -z "${key}" ]]; then
        echo "    ERROR: C003 has no move-speed key for profile '${PROFILE}' (add a row to SPEED_KEY_BY_PROFILE)"
        return 1
    fi

    local key_re="${key//./\\.}"
    if ! grep -qE "^${key_re}[[:space:]]*=" "${conf}"; then
        echo "    ERROR: C003 found no '${key}' line in ${conf}; run speed NOT set"
        echo "           to debug: grep -n MoveSpeed ${conf} — did upstream rename the key?"
        return 1
    fi
    sed -i "s|^${key_re}[[:space:]]*=.*|${key} = ${RUN_SPEED}|" "${conf}"
}
CONFIG_PROFILES[config_run_speed_80_percent]="release beta vanilla basic alpha"
CONFIG_DESCRIPTIONS[config_run_speed_80_percent]="Run speed 85% (slower exploration)"
