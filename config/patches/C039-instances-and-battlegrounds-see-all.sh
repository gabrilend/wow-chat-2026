#!/usr/bin/env bash

config_instances_and_battlegrounds_see_all() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local key pattern missing=0
    for key in Visibility.Distance.Instances Visibility.Distance.BGArenas; do
        pattern="${key//./\\.}"
        if ! grep -qE "^${pattern}[[:space:]]*=" "${conf}"; then
            echo "    ERROR: C039 found no '${key}' line in ${conf}; it stays at stock"
            missing=$((missing + 1))
            continue
        fi
        sed -i "s|^${pattern}[[:space:]]*=.*|${key} = 250|" "${conf}"
    done
    if [[ ${missing} -gt 0 ]]; then
        echo "           to debug: grep -n 'Visibility.Distance' ${conf} - did upstream rename them?"
        return 1
    fi
}
CONFIG_DESCRIPTIONS[config_instances_and_battlegrounds_see_all]="Instances and battlegrounds seen to 250 yards, the server's most"
