#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C035
# profiles:   beta
# priority:   1290
# kind:       settings
# about:      Beta Playerbot Population (200 random bots)
# ==== end of header ====
# C035 - Beta Playerbot Population (200 random bots)
# How many random bots beta keeps in the world: 200, floor and ceiling
# alike, in place of the module's stock 500.
#
# For a general audience: beta's ambush sends monsters at every bot as well
# as every player (wanted: the bots live in the same dangerous world). So
# each bot is its own stream of monster spawns and chases, and 500 of them
# made about 12 spawns a second across the world. The owner, 2026-10-17:
# "if it's 500 bots now, then we should turn it down to 200." Recorded in
# docs/balance-updates.md.
#
# Knobs written into playerbots.conf:
#   MinRandomBots=200   floor — keep at least this many bots in the world
#   MaxRandomBots=200   ceiling — never more than this at once
# The bot accounts are left to the module's automatic count
# (RandomBotAccountCount = 0, stock), which needs MaxRandomBots / 10 +
# AddClassAccountPoolSize accounts; vanilla pins its count (C018) because
# its automatic count once came up a few accounts short at a cold boot. If
# beta's log says "Try increasing RandomBotAccountCount", give beta the
# same pin.
#
# Profiles: beta

# -- {{{ config_beta_playerbot_population
config_beta_playerbot_population() {
    local BOT_FLOOR=200
    local BOT_CEIL=200
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    # [[:space:]]*= anchors the key: a bare ".*=" also matched
    # MinRandomBotsPriceChangeInterval and overwrote it (see C020).
    sed -i 's|^AiPlayerbot\.MinRandomBots[[:space:]]*=.*|AiPlayerbot.MinRandomBots = '"${BOT_FLOOR}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.MaxRandomBots[[:space:]]*=.*|AiPlayerbot.MaxRandomBots = '"${BOT_CEIL}"'|' "${conf}"
}
CONFIG_PROFILES[config_beta_playerbot_population]="beta"
CONFIG_DESCRIPTIONS[config_beta_playerbot_population]="Playerbot population 200 (beta)"
# -- }}}
# ==== footer of C035 ====
# lines:      47
# ==== end of footer ====
