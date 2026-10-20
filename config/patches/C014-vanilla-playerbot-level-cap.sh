#!/usr/bin/env bash

config_vanilla_playerbot_level_cap() {
    local BOT_MIN=20
    local BOT_MAX=40
    local BOT_MAPS=0   # 0 = Eastern Kingdoms (the 20-40 content band)
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.RandomBotMinLevel[[:space:]]*=.*|AiPlayerbot.RandomBotMinLevel = '"${BOT_MIN}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotMaxLevel[[:space:]]*=.*|AiPlayerbot.RandomBotMaxLevel = '"${BOT_MAX}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.DisableRandomLevels.*=.*|AiPlayerbot.DisableRandomLevels = 1|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotXPRate.*=.*|AiPlayerbot.RandomBotXPRate = 1.0|' "${conf}"
    sed -i 's|^AiPlayerbot\.EquipAndSpecPersistence[[:space:]]*=.*|AiPlayerbot.EquipAndSpecPersistence = 1|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotMaps.*=.*|AiPlayerbot.RandomBotMaps = '"${BOT_MAPS}"'|' "${conf}"
}
CONFIG_PROFILES[config_vanilla_playerbot_level_cap]="vanilla"
CONFIG_DESCRIPTIONS[config_vanilla_playerbot_level_cap]="Playerbot progression 20→40 (organic XP leveling)"
