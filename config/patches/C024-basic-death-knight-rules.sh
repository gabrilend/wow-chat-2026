#!/usr/bin/env bash

config_basic_death_knight_rules() {
    local conf_world="${INSTALL_DIR}/etc/worldserver.conf"
    local conf_bots="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^CharacterCreating\.MinLevelForHeroicCharacter[[:space:]]*=.*|CharacterCreating.MinLevelForHeroicCharacter = 55|' "${conf_world}"
    sed -i 's|^CharacterCreating\.Disabled\.ClassMask[[:space:]]*=.*|CharacterCreating.Disabled.ClassMask = 0|' "${conf_world}"
    sed -i 's|^AiPlayerbot\.DisableDeathKnightLogin[[:space:]]*=.*|AiPlayerbot.DisableDeathKnightLogin = 1|' "${conf_bots}"
}
CONFIG_DESCRIPTIONS[config_basic_death_knight_rules]="Death knights: need a level-55 character; no DK bots"
