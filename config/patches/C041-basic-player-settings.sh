#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C041
# profiles:   basic
# priority:   1320
# kind:       settings
# about:      Basic: per-character player settings on (for hidden shoulders)
# ==== end of header ====
# C041 - Basic: per-character player settings on (for hidden shoulders)
# The server can keep small per-character choices (its "player settings",
# saved in the characters database), but only when EnablePlayerSettings is
# on, which it is not by default. Basic's ".shoulders" command (issue 720,
# src/cpp-basic/basic_rules.cpp) keeps each character's hidden or shown
# shoulders there, so basic turns it on. Side effect, stock: players may
# also turn off the server's announcements for themselves.
#
# Knob written into worldserver.conf (a stock key):
#   EnablePlayerSettings = 1
# Profiles: basic

# -- {{{ config_basic_player_settings
config_basic_player_settings() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    if grep -qE "^EnablePlayerSettings[[:space:]]*=" "${conf}"; then
        sed -i "s|^EnablePlayerSettings[[:space:]]*=.*|EnablePlayerSettings = 1|" "${conf}"
    else
        printf '\n# C041 (basic, 720): per-character settings, for hidden shoulders\nEnablePlayerSettings = 1\n' >> "${conf}"
    fi
}
CONFIG_DESCRIPTIONS[config_basic_player_settings]="Per-character player settings on (hidden shoulders keep there)"
# -- }}}
# ==== footer of C041 ====
# lines:      34
# ==== end of footer ====
