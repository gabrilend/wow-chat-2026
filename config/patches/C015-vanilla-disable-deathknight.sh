#!/usr/bin/env bash

config_vanilla_disable_deathknight() {
    local CLASS_MASK=32
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^CharacterCreating\.Disabled\.ClassMask.*=.*|CharacterCreating.Disabled.ClassMask = '"${CLASS_MASK}"'|' "${conf}"
}
CONFIG_PROFILES[config_vanilla_disable_deathknight]="vanilla"
CONFIG_DESCRIPTIONS[config_vanilla_disable_deathknight]="Disable Death Knight creation (ClassMask 32)"
