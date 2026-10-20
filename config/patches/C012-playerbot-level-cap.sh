#!/usr/bin/env bash

config_playerbot_level_cap() {
    local BOT_MIN_LEVEL=1
    local BOT_MAX_LEVEL=20
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.RandomBotMinLevel[[:space:]]*=.*|AiPlayerbot.RandomBotMinLevel = '"${BOT_MIN_LEVEL}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotMaxLevel[[:space:]]*=.*|AiPlayerbot.RandomBotMaxLevel = '"${BOT_MAX_LEVEL}"'|' "${conf}"
}
CONFIG_PROFILES[config_playerbot_level_cap]="beta release"
CONFIG_DESCRIPTIONS[config_playerbot_level_cap]="Playerbot level cap 1..20"
