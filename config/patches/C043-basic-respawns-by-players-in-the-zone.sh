#!/usr/bin/env bash

C043_RATE=8
C043_MINIMUM=10

config_basic_respawns_by_players_in_the_zone() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local key value pattern missing=0
    for key in Respawn.DynamicRateCreature Respawn.DynamicMinimumCreature; do
        pattern="${key//./\\.}"
        if ! grep -qE "^${pattern}[[:space:]]*=" "${conf}"; then
            echo "    ERROR: C043 found no '${key}' line in ${conf}; respawns stay at stock"
            missing=$((missing + 1))
            continue
        fi
        [[ "${key}" == Respawn.DynamicRateCreature ]] && value="${C043_RATE}" || value="${C043_MINIMUM}"
        sed -i "s|^${pattern}[[:space:]]*=.*|${key} = ${value}|" "${conf}"
    done
    if [[ ${missing} -gt 0 ]]; then
        echo "           to debug: grep -n 'Respawn.Dynamic' ${conf} - did upstream rename them?"
        return 1
    fi
}
CONFIG_DESCRIPTIONS[config_basic_respawns_by_players_in_the_zone]="Respawns quicken past 8 characters in a zone (the server's own rule)"
