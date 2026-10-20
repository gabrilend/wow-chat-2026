#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C006b
# profiles:   beta release
# priority:   1130
# kind:       settings
# about:      Max Level 20 (Beta/Release)
# ==== end of header ====
# C006b - Max Level 20 (Beta/Release)
# Set maximum player level to 20 (wow-chat design)
# Profiles: beta release

# -- {{{ config_max_level_20
config_max_level_20() {
    local MAX_LEVEL=20
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^MaxPlayerLevel.*=.*|MaxPlayerLevel = '"${MAX_LEVEL}"'|' "${conf}"
}
CONFIG_PROFILES[config_max_level_20]="beta release"
CONFIG_DESCRIPTIONS[config_max_level_20]="Max level 20"
# -- }}}
# ==== footer of C006b ====
# lines:      24
# ==== end of footer ====
