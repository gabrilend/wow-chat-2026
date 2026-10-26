#!/usr/bin/env bash

config_vanilla_playerbot_population() {
    local BOT_FLOOR=128
    local BOT_CEIL=256
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.MinRandomBots[[:space:]]*=.*|AiPlayerbot.MinRandomBots = '"${BOT_FLOOR}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.MaxRandomBots[[:space:]]*=.*|AiPlayerbot.MaxRandomBots = '"${BOT_CEIL}"'|' "${conf}"
}
CONFIG_DESCRIPTIONS[config_vanilla_playerbot_population]="Playerbot population band 128–256 active"
