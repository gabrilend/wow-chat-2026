#!/usr/bin/env bash
# C027 - Basic: Buddies Spend Their Own Talents
# On basic, a buddy's talents are chosen by the project's own script
# (src/lua-basic/buddy-talents.lua, issue 617g): a fixed shape per buddy,
# random talents inside it, re-rolled when the owner respecs. The bot
# module has one path that would overwrite those picks on a bot owned by a
# player: its maintenance routine refills the talent tree from the module's
# premade full-WotLK orders (PlayerbotFactory::InitTalentsTree, reached from
# the maintenance action when this switch is on). This patch turns that
# one part of maintenance off; the rest of maintenance (food, reagents,
# spells, and so on) is untouched.
#
# The module's level-up talent picking needs no switch: it only runs for
# random bots, which basic doesn't have (C023).
#
# Knob written into playerbots.conf:
#   AiPlayerbot.AltMaintenanceTalentTree=0   maintenance leaves talents alone
# Profiles: basic

# -- {{{ config_basic_buddy_own_talents
config_basic_buddy_own_talents() {
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.AltMaintenanceTalentTree[[:space:]]*=.*|AiPlayerbot.AltMaintenanceTalentTree = 0|' "${conf}"
}
CONFIG_PROFILES[config_basic_buddy_own_talents]="basic"
CONFIG_DESCRIPTIONS[config_basic_buddy_own_talents]="Buddies' talents by the project's script: bot maintenance leaves talents alone"
# -- }}}
