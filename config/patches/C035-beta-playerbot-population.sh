#!/usr/bin/env bash

config_beta_playerbot_population() {
    local BOT_FLOOR=200
    local BOT_CEIL=200
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.MinRandomBots[[:space:]]*=.*|AiPlayerbot.MinRandomBots = '"${BOT_FLOOR}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.MaxRandomBots[[:space:]]*=.*|AiPlayerbot.MaxRandomBots = '"${BOT_CEIL}"'|' "${conf}"
}
CONFIG_PROFILES[config_beta_playerbot_population]="beta"
CONFIG_DESCRIPTIONS[config_beta_playerbot_population]="Playerbot population 200 (beta)"
