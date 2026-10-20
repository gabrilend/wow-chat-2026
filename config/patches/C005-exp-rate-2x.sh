#!/usr/bin/env bash
# C005 - Experience Rate 2x
# Double experience rate (faster testing/iteration)
# Profiles: release. Beta had it too until 2026-10-20; beta has no quests
# (E012 removes their givers), so its kill rate is 3, set by C037 with the
# rest of wow-chat-1's settings (the owner: "for servers that don't have
# any quests ... we should have kill experience set to 3").

# -- {{{ config_exp_rate_2x
config_exp_rate_2x() {
    local XP_RATE=2.0
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    # Use [[:space:]] anchor to avoid matching Rate.XP.Quest.DF
    sed -i 's|^Rate\.XP\.Kill[[:space:]]*=.*|Rate.XP.Kill = '"${XP_RATE}"'|' "${conf}"
    sed -i 's|^Rate\.XP\.Quest[[:space:]]*=.*|Rate.XP.Quest = '"${XP_RATE}"'|' "${conf}"
}
CONFIG_PROFILES[config_exp_rate_2x]="release"
CONFIG_DESCRIPTIONS[config_exp_rate_2x]="Experience rate 2x"
# -- }}}
