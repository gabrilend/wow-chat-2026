#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C033
# profiles:   cc-test
# priority:   1280
# kind:       settings
# about:      cc-test: Warden Kicks on a Failed Check
# ==== end of header ====
# C033 - cc-test: Warden Kicks on a Failed Check
# For a general audience: Warden is the server's way of asking the game
# client small questions (what is in a piece of its memory, what a
# function returns) that only the real client answers correctly. Stock
# AzerothCore notes a wrong answer in its log and lets the player stay.
# The cc-test profile (issue 176) is where the custom client is tested,
# and its pass mark is a session that leaves the server's logs empty, so
# here a wrong answer is meant to end the session.
#
# For now it only logs (owner, 2026-10-08: "only log failures until we can
# answer."): the custom client does not answer Warden yet, and with kicks on
# every session would end within seconds. Set WARDEN_FAIL_ACTION below to 1
# once the client's replies exist; the logged failures meanwhile list what it
# still gets wrong.
#
# Knob written into worldserver.conf:
#   Warden.ClientCheckFailAction   0 log only (stock; now), 1 kick (later), 2 ban
#   (each single check can still be given its own action in the
#   characters database's warden_action table)
#
# A missing key stops with an error rather than leaving the stock "log
# only" in place, which would look exactly like a passing client.
# Profiles: cc-test

# -- {{{ config_cc_test_warden_kicks
config_cc_test_warden_kicks() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    local WARDEN_FAIL_ACTION=0   # 0 log only, until the custom client answers Warden; then 1 (kick)

    # key present: set it. key absent: the server would fall back to its
    # built-in default (log only), so refuse instead of passing silently.
    if ! grep -qE '^Warden\.ClientCheckFailAction[[:space:]]*=' "${conf}"; then
        echo "    ERROR: C033 found no Warden.ClientCheckFailAction line in ${conf}; Warden left at log-only"
        echo "           to debug: grep -n '^Warden' ${conf} — did upstream rename the key,"
        echo "           or was worldserver.conf generated from an old .dist (C016's case)?"
        return 1
    fi
    sed -i 's|^Warden\.ClientCheckFailAction[[:space:]]*=.*|Warden.ClientCheckFailAction = '"${WARDEN_FAIL_ACTION}"'|' "${conf}"
}
CONFIG_DESCRIPTIONS[config_cc_test_warden_kicks]="Warden failures logged (kicks once the custom client answers Warden)"
# -- }}}
# ==== footer of C033 ====
# lines:      52
# ==== end of footer ====
