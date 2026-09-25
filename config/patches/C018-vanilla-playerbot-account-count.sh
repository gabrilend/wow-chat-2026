#!/usr/bin/env bash
# C018 - Vanilla Playerbot Account Count
# Pin AiPlayerbot.RandomBotAccountCount to a value above the auto-mode
# threshold so the bot factory provisions enough accounts to host all
# of MaxRandomBots + AddClassAccountPoolSize, without the factory's
# auto-create lazy path lagging by a handful of accounts on first boot.
#
# The mod-playerbots conf comment at
# installed-files-vanilla/etc/modules/playerbots.conf:96 documents the
# required formula:
#
#     RandomBotAccountCount >= MaxRandomBots / 10 + AddClassAccountPoolSize
#
# For the vanilla profile that's 500/10 + 50 = 100 accounts. The
# factory's auto-mode (= 0) is supposed to fill in lazily but in
# practice under-provisions by ~5 accounts on a cold boot, producing
# the "Can't log-in all the requested bots. Try increasing
# RandomBotAccountCount in your conf file. N more accounts needed."
# warning. Pinning explicitly to 110 (round-up for headroom) makes
# the factory pre-allocate the full set on first boot, so the warning
# never fires.
#
# Profiles: vanilla (basic dropped 2026-09-24: basic runs no random bots, C023)
# (Release and beta currently use MaxRandomBots = 500 too; if their
# auto-mode shows the same lag, the same patch can be added under
# CONFIG_PROFILES with their profile names appended. Not done here
# because release/beta haven't been observed to hit the warning.)

# -- {{{ config_vanilla_playerbot_account_count
config_vanilla_playerbot_account_count() {
    local ACCOUNT_COUNT=110
    local conf="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^AiPlayerbot\.RandomBotAccountCount.*=.*|AiPlayerbot.RandomBotAccountCount = '"${ACCOUNT_COUNT}"'|' "${conf}"
}
CONFIG_PROFILES[config_vanilla_playerbot_account_count]="vanilla"
CONFIG_DESCRIPTIONS[config_vanilla_playerbot_account_count]="Playerbot RandomBotAccountCount = 110 (cold-boot pre-provision)"
# -- }}}
