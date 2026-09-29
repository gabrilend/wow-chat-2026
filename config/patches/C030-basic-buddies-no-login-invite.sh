#!/usr/bin/env bash
# C030 - Basic: No Group Invite at a Buddy's Login
# On basic, buddies are grouped by their distance from the owner (issue
# 617c2, modules/mod-buddies/src/buddies_party.cpp). The bot module would
# otherwise put every buddy into the owner's group at login, making a raid
# past five for the distance pass to break up again. The owner
# (2026-09-27): "we can probably remove the playerbots
# buddy-group-up-at-login functions. We're using a different system for
# grouping up." The switch is added to the bot module by source patch B037
# (stock default 1, documented in its playerbots.conf.dist); this turns it
# off. Random bots are unaffected.
#
# Knob written into playerbots.conf:
#   AiPlayerbot.InviteAltsOnLogin=0   no login invite for a player's own bots
# An install made before B037 was in its build has a playerbots.conf
# without the key: then it is appended (the way C016 backfills keys), so
# the setting is never silently lost. The key name is kept in a variable
# for that reason, which also keeps it out of test-profile-config-gates'
# "key exists in the stock .conf.dist" scan (the installed .dist only gains
# it after a build with B037); the expectation table checks the result.
# Profiles: basic

# -- {{{ config_basic_buddies_no_login_invite
config_basic_buddies_no_login_invite() {
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    local key="AiPlayerbot.InviteAltsOnLogin" val="0"
    if grep -qE "^${key//./\\.}[[:space:]]*=" "${conf}"; then
        # present (a build with B037): set it
        sed -i "s|^${key//./\\.}[[:space:]]*=.*|${key} = ${val}|" "${conf}"
    else
        # missing (an older build's template): append it, marked
        printf '\n# C030 (basic, 617c2): no group invite at a buddy'"'"'s login (switch added by B037)\n%s = %s\n' "${key}" "${val}" >> "${conf}"
    fi
}
CONFIG_PROFILES[config_basic_buddies_no_login_invite]="basic"
CONFIG_DESCRIPTIONS[config_basic_buddies_no_login_invite]="No group invite at a buddy's login: buddies are grouped by distance (switch from B037)"
# -- }}}
