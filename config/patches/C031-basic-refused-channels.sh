#!/usr/bin/env bash
# C031 - Basic: No World Channels (General, Trade, the Defense channels, LFG, Guild Recruitment)
# On basic nobody joins the world's shared chat channels, to keep news from
# spreading (issue 155x, the owner, 2026-09-27). The refusal itself is
# source patch B038 (Channel::JoinChannel), which reads the list from this
# setting; with no setting nothing is refused, so every other profile is
# stock.
#
# Knob written into worldserver.conf (a key of the project's own, not in
# the stock .conf.dist, so it is set or appended):
#   Basic.RefusedChannels = "1 2 22 23 25 26"   the client's channel numbers
#                                          (ChatChannels.dbc): 1 General,
#                                          2 Trade, 22 LocalDefense,
#                                          23 WorldDefense, 25 GuildRecruitment,
#                                          26 LookingForGroup (the last two
#                                          added 2026-09-27: "yes")
# The key name is kept in a variable, as C030 does, which also keeps it out
# of test-profile-config-gates' "key exists in the stock .conf.dist" scan;
# the expectation table checks the result.
# Profiles: basic

# -- {{{ config_basic_refused_channels
config_basic_refused_channels() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local key="Basic.RefusedChannels" val='"1 2 22 23 25 26"'
    if grep -qE "^${key//./\\.}[[:space:]]*=" "${conf}"; then
        sed -i "s|^${key//./\\.}[[:space:]]*=.*|${key} = ${val}|" "${conf}"
    else
        printf '\n# C031 (basic, 155x): built-in channels nobody joins (read by B038): 1 General, 2 Trade, 22 LocalDefense, 23 WorldDefense, 25 GuildRecruitment, 26 LookingForGroup\n%s = %s\n' "${key}" "${val}" >> "${conf}"
    fi
}
CONFIG_PROFILES[config_basic_refused_channels]="basic"
CONFIG_DESCRIPTIONS[config_basic_refused_channels]="No General, Trade, LocalDefense, WorldDefense, GuildRecruitment or LookingForGroup channels (read by B038)"
# -- }}}
