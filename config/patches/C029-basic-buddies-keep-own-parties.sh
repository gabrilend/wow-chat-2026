#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C029
# profiles:   buddy-set
# priority:   1260
# kind:       settings
# about:      Basic: Buddies Keep Their Own Parties
# ==== end of header ====
# C029 - Basic: Buddies Keep Their Own Parties
# On basic, buddies group by distance from their owner (issue 617c2): near
# ones in the owner's party, far ones in parties of their own, led by a
# buddy. The bot module, when a bot logs in, makes it leave any group that
# its player is not in; that would break up the far parties at every
# login. This switch makes it keep a bot in a group of other players' alts
# (here: other buddies, which are not random bots), so the far parties
# last; the module's distance pass (modules/mod-buddies/src/buddies_party.cpp)
# then regroups everyone as the distances say.
#
# Knob written into playerbots.conf:
#   AiPlayerbot.KeepAltsInGroup=1   a bot stays in a group of alts at login
# cc-test (issue 176) builds the buddy module too (2026-10-08) and takes the
# same buddy settings.
# Profiles: basic cc-test

# -- {{{ config_basic_buddies_keep_own_parties
config_basic_buddies_keep_own_parties() {
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.KeepAltsInGroup[[:space:]]*=.*|AiPlayerbot.KeepAltsInGroup = 1|' "${conf}"
}
CONFIG_DESCRIPTIONS[config_basic_buddies_keep_own_parties]="Buddies' far parties survive a login: the bot module keeps a bot in a group of alts"
# -- }}}
# ==== footer of C029 ====
# lines:      34
# ==== end of footer ====
