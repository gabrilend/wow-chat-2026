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
    # Anchor the key with [[:space:]]*= so the sed cannot bleed past the key
    # name. The old `.*=.*` was greedy: it also matched RandomBotMinLevel*Chance*
    # = 0.1 (the `.*` swallowed "Chance"), rewriting that line into a second
    # RandomBotMinLevel entry — which both duplicated the level key AND deleted
    # RandomBotMinLevelChance, surfacing it as a "Missing property" at boot.
    sed -i 's|^AiPlayerbot\.RandomBotMinLevel[[:space:]]*=.*|AiPlayerbot.RandomBotMinLevel = '"${BOT_MIN_LEVEL}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotMaxLevel[[:space:]]*=.*|AiPlayerbot.RandomBotMaxLevel = '"${BOT_MAX_LEVEL}"'|' "${conf}"
}
CONFIG_PROFILES[config_playerbot_level_cap]="beta release"
CONFIG_DESCRIPTIONS[config_playerbot_level_cap]="Playerbot level cap 1..20"
# -- }}}
