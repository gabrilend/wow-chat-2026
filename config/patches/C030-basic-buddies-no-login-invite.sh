#!/usr/bin/env bash

config_basic_buddies_no_login_invite() {
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    local key="AiPlayerbot.InviteAltsOnLogin" val="0"
    if grep -qE "^${key//./\\.}[[:space:]]*=" "${conf}"; then
        sed -i "s|^${key//./\\.}[[:space:]]*=.*|${key} = ${val}|" "${conf}"
    else
        printf '\n# C030 (basic, 617c2): no group invite at a buddy'"'"'s login (switch added by B037)\n%s = %s\n' "${key}" "${val}" >> "${conf}"
    fi
}
CONFIG_DESCRIPTIONS[config_basic_buddies_no_login_invite]="No group invite at a buddy's login: buddies are grouped by distance (switch from B037)"
