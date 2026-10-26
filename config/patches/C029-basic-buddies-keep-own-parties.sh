#!/usr/bin/env bash

config_basic_buddies_keep_own_parties() {
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.KeepAltsInGroup[[:space:]]*=.*|AiPlayerbot.KeepAltsInGroup = 1|' "${conf}"
}
CONFIG_DESCRIPTIONS[config_basic_buddies_keep_own_parties]="Buddies' far parties survive a login: the bot module keeps a bot in a group of alts"
