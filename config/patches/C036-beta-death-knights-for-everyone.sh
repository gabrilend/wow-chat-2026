#!/usr/bin/env bash

config_beta_death_knights_for_everyone() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^CharacterCreating\.MinLevelForHeroicCharacter[[:space:]]*=.*|CharacterCreating.MinLevelForHeroicCharacter = 0|' "${conf}"
}
CONFIG_PROFILES[config_beta_death_knights_for_everyone]="beta"
CONFIG_DESCRIPTIONS[config_beta_death_knights_for_everyone]="Death knights need no level-55 character first (beta)"
