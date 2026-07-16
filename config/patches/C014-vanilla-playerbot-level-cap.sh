#!/usr/bin/env bash
# C014 - Vanilla Playerbot Progression (enter at 20, climb to the 40 cap)
# The random-bot fleet enters at level 20 — the same place players start
# — and levels up the way a player does: earning XP through play and
# climbing toward the 40 cap, gear upgrading as it goes. This replaces
# the older "pin every bot at level 20" lock, which froze the ambient
# population at the floor of the progression band instead of letting it
# mirror the players moving through the same zones.
#
# Knobs written into playerbots.conf:
#   RandomBotMinLevel=20    enter at the player start level
#   RandomBotMaxLevel=40    may climb to the vanilla cap
#   DisableRandomLevels=1   no random level assignment — bots start at
#                           min and progress organically via XP instead
#                           of being re-rolled to a random level in the
#                           band on each randomize cycle
#   RandomBotXPRate=1.0     player-parity XP pace
#   EquipmentPersistence=1  earned gear persists across randomize cycles
#                           so "upgrade as they go" sticks
#   RandomBotMaps=0         Eastern Kingdoms pool (the 20-40 content the
#                           player population also travels)
#
# Gear note: the module auto-gears rndbots to their level on level-up
# (IncrementalGearInit=1, AutoUpgradeEquip=1), which is the "geared and
# upgrading as they go" behaviour. Making bots wear the specific 148h
# white starter kit at level 20 is NOT config-expressible — it would
# require overriding the bot auto-gear — so it is left as a separate
# decision, not wired here.
#
# DisableRandomLevels semantics are inferred from the knob name + module
# docs; confirm in-world by sampling the fleet's level histogram after a
# randomize cycle (want a 20-heavy distribution climbing toward 40, not
# a flat random spread). Tune in docs/balance-updates.md.
#
# Counterpart to C012 (1..20 spread for beta/release).
# Profiles: vanilla

# -- {{{ config_vanilla_playerbot_level_cap
config_vanilla_playerbot_level_cap() {
    local BOT_MIN=20
    local BOT_MAX=40
    local BOT_MAPS=0   # 0 = Eastern Kingdoms (the 20-40 content band)
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.RandomBotMinLevel.*=.*|AiPlayerbot.RandomBotMinLevel = '"${BOT_MIN}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotMaxLevel.*=.*|AiPlayerbot.RandomBotMaxLevel = '"${BOT_MAX}"'|' "${conf}"
    sed -i 's|^AiPlayerbot\.DisableRandomLevels.*=.*|AiPlayerbot.DisableRandomLevels = 1|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotXPRate.*=.*|AiPlayerbot.RandomBotXPRate = 1.0|' "${conf}"
    sed -i 's|^AiPlayerbot\.EquipmentPersistence.*=.*|AiPlayerbot.EquipmentPersistence = 1|' "${conf}"
    sed -i 's|^AiPlayerbot\.RandomBotMaps.*=.*|AiPlayerbot.RandomBotMaps = '"${BOT_MAPS}"'|' "${conf}"
}
CONFIG_PROFILES[config_vanilla_playerbot_level_cap]="vanilla"
CONFIG_DESCRIPTIONS[config_vanilla_playerbot_level_cap]="Playerbot progression 20→40 (organic XP leveling)"
# -- }}}
