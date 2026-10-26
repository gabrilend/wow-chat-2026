#!/usr/bin/env bash

config_basic_refused_channels() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local key="Basic.RefusedChannels" val='"1 2 22 23 25 26"'
    if grep -qE "^${key//./\\.}[[:space:]]*=" "${conf}"; then
        sed -i "s|^${key//./\\.}[[:space:]]*=.*|${key} = ${val}|" "${conf}"
    else
        printf '\n# C031 (basic, 155x): built-in channels nobody joins (read by B038): 1 General, 2 Trade, 22 LocalDefense, 23 WorldDefense, 25 GuildRecruitment, 26 LookingForGroup\n%s = %s\n' "${key}" "${val}" >> "${conf}"
    fi
}
CONFIG_DESCRIPTIONS[config_basic_refused_channels]="No General, Trade, LocalDefense, WorldDefense, GuildRecruitment or LookingForGroup channels (read by B038)"
