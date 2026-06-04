#!/usr/bin/env bash
# C012 - Playerbot Level Cap (Beta/Release)
# Pin random-bot level range to match the player level cap (1..20).
# The .dist default is 1..80; without this, randombots would still try to
# spawn up through level 80 even though players cap at 20.
# Profiles: beta release

# -- {{{ config_playerbot_level_cap
config_playerbot_level_cap() {
    local BOT_MIN_LEVEL=1
    local BOT_MAX_LEVEL=20
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.RandomBotMinLevel.*=.*|AiPlayerbot.RandomBotMinLevel = '"${BOT_MIN_LEVEL}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotMaxLevel.*=.*|AiPlayerbot.RandomBotMaxLevel = '"${BOT_MAX_LEVEL}"'|' "${conf}"
}
CONFIG_PROFILES[config_playerbot_level_cap]="beta release"
CONFIG_DESCRIPTIONS[config_playerbot_level_cap]="Playerbot level cap 1..20"
# -- }}}
