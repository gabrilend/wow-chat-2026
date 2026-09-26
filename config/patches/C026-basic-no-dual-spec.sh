#!/usr/bin/env bash
# C026 - Basic: No Dual Spec
# The basic profile (issue 155r) has no dual talent specialization. Ritz,
# 2026-09-25: "we should remove dual spec from the game."
#
# The server offers dual spec at class trainers (a "learn dual
# specialization" dialogue option) only to characters at or above
# MinDualSpecLevel, and it refuses the purchase below it
# (PlayerGossip.cpp, GOSSIP_OPTION_LEARNDUALSPEC). Basic's characters stop
# at 60, so a level of 255 means no character ever sees the option or can
# buy it. No data is changed.
#
# Knob written into worldserver.conf:
#   MinDualSpecLevel=255   above basic's cap: dual spec never offered
#
# (The respec price, the other half of 155r, is source patch B035.)
# Profiles: basic

# -- {{{ config_basic_no_dual_spec
config_basic_no_dual_spec() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^MinDualSpecLevel[[:space:]]*=.*|MinDualSpecLevel = 255|' "${conf}"
}
CONFIG_PROFILES[config_basic_no_dual_spec]="basic"
CONFIG_DESCRIPTIONS[config_basic_no_dual_spec]="No dual spec: MinDualSpecLevel above the level cap"
# -- }}}
