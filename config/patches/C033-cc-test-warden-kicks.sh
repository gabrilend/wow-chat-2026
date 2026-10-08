#!/usr/bin/env bash
# C033 - cc-test: Warden Kicks on a Failed Check
# For a general audience: Warden is the server's way of asking the game
# client small questions (what is in a piece of its memory, what a
# function returns) that only the real client answers correctly. Stock
# AzerothCore notes a wrong answer in its log and lets the player stay.
# The cc-test profile (issue 176) is where the custom client is tested,
# and its pass mark is a session that leaves the server's logs empty, so
# here a wrong answer ends the session: the failure can't go unnoticed.
#
# What it tests: that the custom client answers Warden as the original
# client does. Until its replies exist, every session on cc-test ends in a
# kick (open question 5 in issue 176).
#
# Knob written into worldserver.conf:
#   Warden.ClientCheckFailAction=1   0 log only (stock), 1 kick, 2 ban
#   (each single check can still be given its own action in the
#   characters database's warden_action table)
#
# A missing key stops with an error rather than leaving the stock "log
# only" in place, which would look exactly like a passing client.
# Profiles: cc-test

# -- {{{ config_cc_test_warden_kicks
config_cc_test_warden_kicks() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"

    # key present: set it. key absent: the server would fall back to its
    # built-in default (log only), so refuse instead of passing silently.
    if ! grep -qE '^Warden\.ClientCheckFailAction[[:space:]]*=' "${conf}"; then
        echo "    ERROR: C033 found no Warden.ClientCheckFailAction line in ${conf}; Warden left at log-only"
        echo "           to debug: grep -n '^Warden' ${conf} — did upstream rename the key,"
        echo "           or was worldserver.conf generated from an old .dist (C016's case)?"
        return 1
    fi
    sed -i 's|^Warden\.ClientCheckFailAction[[:space:]]*=.*|Warden.ClientCheckFailAction = 1|' "${conf}"
}
CONFIG_PROFILES[config_cc_test_warden_kicks]="cc-test"
CONFIG_DESCRIPTIONS[config_cc_test_warden_kicks]="Warden kicks on a failed client check"
# -- }}}
