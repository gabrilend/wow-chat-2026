#!/usr/bin/env bash
# C023 - Basic: No Random Bots
# The basic profile (issue 155) has no ambient bot population: the only bots
# in the world are each player's own buddies (issue 617), which are ordinary
# bot characters on an account linked to their player, not "random bots".
# Ritz, 2026-09-24: "no random bots in basic. Just playerbot buddies."
# This patch switches the bot module's random-bot system off.
#
# Knobs written into playerbots.conf:
#   RandomBotAutologin=0   random bots never log in. This is the switch that
#                          holds even if something later raises the counts
#                          (the bot-governor script rewrites Min/MaxRandomBots
#                          when it is run by hand; with autologin off, the
#                          raised counts log nobody in).
#   MinRandomBots=0        floor of online random bots
#   MaxRandomBots=0        ceiling of online random bots
#
# Until issue 617 builds buddies, a basic world has no bots at all.
#
# History: until 2026-09-24 this file was C023-basic-playerbot-progression,
# which grew random bots from level 1 to 60 across Eastern Kingdoms,
# Kalimdor and Outland; basic also shared vanilla's population band (C020)
# and account count (C018). Those gates no longer include basic.
# Profiles: basic

# -- {{{ config_basic_no_random_bots
config_basic_no_random_bots() {
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    # Keys anchored with [[:space:]]*= so a key can't match a longer key that
    # starts with the same name (MinRandomBots vs MinRandomBotsPriceChangeInterval,
    # the C020 lesson).
    sed -i 's|^AiPlayerbot\.RandomBotAutologin[[:space:]]*=.*|AiPlayerbot.RandomBotAutologin = 0|' "${conf}"
    sed -i 's|^AiPlayerbot\.MinRandomBots[[:space:]]*=.*|AiPlayerbot.MinRandomBots = 0|' "${conf}"
    sed -i 's|^AiPlayerbot\.MaxRandomBots[[:space:]]*=.*|AiPlayerbot.MaxRandomBots = 0|' "${conf}"
}
CONFIG_PROFILES[config_basic_no_random_bots]="basic"
CONFIG_DESCRIPTIONS[config_basic_no_random_bots]="No random bots (buddies only): autologin off, population 0"
# -- }}}
