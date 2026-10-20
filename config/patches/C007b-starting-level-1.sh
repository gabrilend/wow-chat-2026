#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C007b
# profiles:   basic beta release
# priority:   1150
# kind:       settings
# about:      Starting Level 1 (Beta/Release/Basic)
# ==== end of header ====
# C007b - Starting Level 1 (Beta/Release/Basic)
# Set starting level to 1 (default, but make explicit)
# Profiles: beta release basic (basic added by issue 155: no head-start)

# -- {{{ config_starting_level_1
config_starting_level_1() {
    local START_LEVEL=1
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^StartPlayerLevel.*=.*|StartPlayerLevel = '"${START_LEVEL}"'|' "${conf}"
}
CONFIG_DESCRIPTIONS[config_starting_level_1]="Starting level 1"
# -- }}}
# ==== footer of C007b ====
# lines:      23
# ==== end of footer ====
