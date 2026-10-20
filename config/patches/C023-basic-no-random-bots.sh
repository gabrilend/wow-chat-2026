#!/usr/bin/env bash

config_basic_no_random_bots() {
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.RandomBotAutologin[[:space:]]*=.*|AiPlayerbot.RandomBotAutologin = 0|' "${conf}"
    sed -i 's|^AiPlayerbot\.MinRandomBots[[:space:]]*=.*|AiPlayerbot.MinRandomBots = 0|' "${conf}"
    sed -i 's|^AiPlayerbot\.MaxRandomBots[[:space:]]*=.*|AiPlayerbot.MaxRandomBots = 0|' "${conf}"
}
CONFIG_PROFILES[config_basic_no_random_bots]="basic cc-test"
CONFIG_DESCRIPTIONS[config_basic_no_random_bots]="No random bots (buddies only): autologin off, population 0"
