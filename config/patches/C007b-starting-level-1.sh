#!/usr/bin/env bash
# C007b - Starting Level 1 (Beta/Release)
# Set starting level to 1 (default, but make explicit)
# Profiles: beta release

# -- {{{ config_starting_level_1
config_starting_level_1() {
    local START_LEVEL=1
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^StartPlayerLevel.*=.*|StartPlayerLevel = '"${START_LEVEL}"'|' "${conf}"
}
CONFIG_PROFILES[config_starting_level_1]="beta release"
CONFIG_DESCRIPTIONS[config_starting_level_1]="Starting level 1"
# -- }}}
