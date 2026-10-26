#!/usr/bin/env bash

config_basic_monster_drops() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local pair key val
    for pair in "Basic.Drops.GreenBlueRate=2" "Basic.Drops.EpicRate=5" "Basic.Drops.RareRolls=2"; do
        key="${pair%%=*}" val="${pair#*=}"
        if grep -qE "^${key//./\\.}[[:space:]]*=" "${conf}"; then
            sed -i "s|^${key//./\\.}[[:space:]]*=.*|${key} = ${val}|" "${conf}"
        else
            printf '\n# C040 (basic, 181): richer monster drops (read by basic_rules.cpp)\n%s = %s\n' "${key}" "${val}" >> "${conf}"
        fi
    done
}
CONFIG_DESCRIPTIONS[config_basic_monster_drops]="Richer monster drops: greens and blues x2, epics x5, rares' loot rolled twice (read by basic_rules.cpp)"
