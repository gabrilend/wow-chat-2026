#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C007a
# profiles:   alpha
# priority:   1145
# kind:       settings
# about:      Starting Level 40 (Alpha)
# ==== end of header ====
# C007a - Starting Level 40 (Alpha)
# Set starting level to 40 (testing different values per profile)
# Profiles: alpha

# -- {{{ config_starting_level_40
config_starting_level_40() {
    local START_LEVEL=40
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^StartPlayerLevel.*=.*|StartPlayerLevel = '"${START_LEVEL}"'|' "${conf}"
}
CONFIG_PROFILES[config_starting_level_40]="alpha"
CONFIG_DESCRIPTIONS[config_starting_level_40]="Starting level 40"
# -- }}}
# ==== footer of C007a ====
# lines:      24
# ==== end of footer ====
