#!/usr/bin/env bash

C044_CELLS=(
)

config_basic_drops_by_rank_and_quality() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local cell rank quality rate quantity key val part
    for cell in "${C044_CELLS[@]}"; do
        read -r rank quality rate quantity <<< "${cell}"
        if [[ -z "${quantity}" ]]; then
            echo "    ERROR: C044 cell '${cell}' needs four words: Rank Quality Rate Quantity"
            return 1
        fi
        for part in "Rate=${rate}" "Quantity=${quantity}"; do
            key="Basic.Drop.${rank}.${quality}.${part%%=*}" val="${part#*=}"
            if grep -qE "^${key//./\\.}[[:space:]]*=" "${conf}"; then
                sed -i "s|^${key//./\\.}[[:space:]]*=.*|${key} = ${val}|" "${conf}"
            else
                printf '\n# C044 (basic, 155z10): drops by rank and quality (read by basic_rules.cpp)\n%s = %s\n' "${key}" "${val}" >> "${conf}"
            fi
        done
    done
}
CONFIG_DESCRIPTIONS[config_basic_drops_by_rank_and_quality]="Drops by monster rank and item quality: the knobs turned (read by basic_rules.cpp)"
