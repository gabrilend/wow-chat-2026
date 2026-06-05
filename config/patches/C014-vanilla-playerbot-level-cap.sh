#!/usr/bin/env bash
# C014 - Vanilla Playerbot Level Lock + EK-only Maps
# Pin every random bot to level 20 (no spread) and restrict the spawn
# pool to Eastern Kingdoms (map 0) so bots cluster around the same
# level-20 zones the player population starts in (Duskwood / Tarren
# Mill per E007). Older form of this patch used a 1..40 spread; we
# collapsed to a single level so the bot fleet is uniformly the
# vanilla-cap power level the player faces at endgame.
# Counterpart to C012 (1..20 spread for beta/release).
# Profiles: vanilla

# -- {{{ config_vanilla_playerbot_level_cap
config_vanilla_playerbot_level_cap() {
    local BOT_LEVEL=20
    local BOT_MAPS=0   # 0 = Eastern Kingdoms (Hillsbrad zone 267, Duskwood zone 10)
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.RandomBotMinLevel.*=.*|AiPlayerbot.RandomBotMinLevel = '"${BOT_LEVEL}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotMaxLevel.*=.*|AiPlayerbot.RandomBotMaxLevel = '"${BOT_LEVEL}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotMaps.*=.*|AiPlayerbot.RandomBotMaps = '"${BOT_MAPS}"'|' "${conf}"
}
CONFIG_PROFILES[config_vanilla_playerbot_level_cap]="vanilla"
CONFIG_DESCRIPTIONS[config_vanilla_playerbot_level_cap]="Playerbot fixed-level 20 + EK-only spawn pool"
# -- }}}
