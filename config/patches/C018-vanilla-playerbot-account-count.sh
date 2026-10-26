#!/usr/bin/env bash

config_vanilla_playerbot_account_count() {
    local ACCOUNT_COUNT=110
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.RandomBotAccountCount.*=.*|AiPlayerbot.RandomBotAccountCount = '"${ACCOUNT_COUNT}"'|' "${conf}"
}
CONFIG_DESCRIPTIONS[config_vanilla_playerbot_account_count]="Playerbot RandomBotAccountCount = 110 (cold-boot pre-provision)"
