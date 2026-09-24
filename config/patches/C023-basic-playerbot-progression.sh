#!/usr/bin/env bash
# C023 - Basic Playerbot Progression (enter at 1, climb to the 60 cap)
# The basic profile (issue 155) is the full 1-60 ladder, so the random-bot
# fleet walks the whole ladder too: bots enter at level 1, where players
# start, and earn their way to 60 through play, keeping the gear they earn.
# Same shape as vanilla's C014 (20→40, Eastern Kingdoms only); only the
# band and the map pool differ.
#
# Knobs written into playerbots.conf:
#   RandomBotMinLevel=1     enter at the player start level (C007b)
#   RandomBotMaxLevel=60    may climb to the basic cap (C006d)
#   DisableRandomLevels=1   no random level assignment: bots start at
#                           min and level by XP, not re-rolled per cycle
#   RandomBotXPRate=1.0     player-parity XP pace
#   EquipAndSpecPersistence=1  earned gear persists across randomize cycles
#                           (upstream's current name for the old
#                           EquipmentPersistence knob)
#   RandomBotMaps=0,1,530   Eastern Kingdoms, Kalimdor, Outland. Outland is
#                           open at basic's cap (user decision 2026-09-23);
#                           Northrend (571) is left out because it is
#                           level 68+ content no basic character can use.
#
# Counterparts: C014 (vanilla band), C012 (beta/release band),
# C020 (how many bots exist at once — shared with vanilla).
# Profiles: basic

# -- {{{ config_basic_playerbot_progression
config_basic_playerbot_progression() {
    local BOT_MIN=1
    local BOT_MAX=60
    local BOT_MAPS="0,1,530"
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    # Keys anchored with [[:space:]]*= (see C014: an unanchored .*=.* also
    # rewrote RandomBotMinLevelChance and dropped it from the file).
    sed -i 's|^AiPlayerbot\.RandomBotMinLevel[[:space:]]*=.*|AiPlayerbot.RandomBotMinLevel = '"${BOT_MIN}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotMaxLevel[[:space:]]*=.*|AiPlayerbot.RandomBotMaxLevel = '"${BOT_MAX}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.DisableRandomLevels[[:space:]]*=.*|AiPlayerbot.DisableRandomLevels = 1|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotXPRate[[:space:]]*=.*|AiPlayerbot.RandomBotXPRate = 1.0|' "${conf}"
    sed -i 's|^AiPlayerbot\.EquipAndSpecPersistence[[:space:]]*=.*|AiPlayerbot.EquipAndSpecPersistence = 1|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotMaps[[:space:]]*=.*|AiPlayerbot.RandomBotMaps = '"${BOT_MAPS}"'|' "${conf}"
}
CONFIG_PROFILES[config_basic_playerbot_progression]="basic"
CONFIG_DESCRIPTIONS[config_basic_playerbot_progression]="Playerbot progression 1→60 (organic XP leveling, EK+Kalimdor+Outland)"
# -- }}}
