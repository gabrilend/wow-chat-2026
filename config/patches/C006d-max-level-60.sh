#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C006d
# profiles:   basic
# priority:   1140
# kind:       settings
# about:      Max Level 60 (Basic)
# ==== end of header ====
# C006d - Max Level 60 (Basic)
# Set maximum player level to 60 for the basic profile (issue 155): the
# classic 1-60 ladder, with Outland open at the cap (Dark Portal at 58).
# C017 reads this value afterward to pin the level-correlated caps.
# Profiles: basic

# -- {{{ config_max_level_60
config_max_level_60() {
    local MAX_LEVEL=60
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^MaxPlayerLevel.*=.*|MaxPlayerLevel = '"${MAX_LEVEL}"'|' "${conf}"
}
CONFIG_DESCRIPTIONS[config_max_level_60]="Max level 60"
# -- }}}
# ==== footer of C006d ====
# lines:      25
# ==== end of footer ====
