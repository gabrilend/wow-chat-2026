#!/usr/bin/env bash
# C014 - Vanilla Playerbot Level Cap
# Pin random-bot level range to the vanilla 1..40 spread so randombots
# don't keep trying to spawn up through the .dist default of 80, which
# would put them well above the vanilla cap pinned in 148.
# Counterpart to C012 (1..20 for beta/release).
# Profiles: vanilla

# -- {{{ config_vanilla_playerbot_level_cap
config_vanilla_playerbot_level_cap() {
    local BOT_MIN_LEVEL=1
    local BOT_MAX_LEVEL=40
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.RandomBotMinLevel.*=.*|AiPlayerbot.RandomBotMinLevel = '"${BOT_MIN_LEVEL}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotMaxLevel.*=.*|AiPlayerbot.RandomBotMaxLevel = '"${BOT_MAX_LEVEL}"'|' "${conf}"
}
CONFIG_PROFILES[config_vanilla_playerbot_level_cap]="vanilla"
CONFIG_DESCRIPTIONS[config_vanilla_playerbot_level_cap]="Playerbot level cap 1..40"
# -- }}}
