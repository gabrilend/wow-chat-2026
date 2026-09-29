#!/usr/bin/env bash
# C032 - Preserve Custom Channels (so a script can tell one channel from another)
# Keep player-made chat channels in the characters database, which is what
# gives each one an id and a row naming it. The first user is neuron's in-game
# channel (wow-chat-neuron issue 1003, shared build pass 2): a script inside
# the world hears every channel message through ALE's chat hook, and the hook
# hands over only a channel's database id -- never its name. With this off,
# every custom channel arrives as id 0 and the neuron channel cannot be told
# apart from anyone's private channel. With it on, the script looks the ids up
# by name in the `channels` table.
#
# Knob written into worldserver.conf:
#   PreserveCustomChannels = 1   custom channels get a database id and a row
#
# Side effect, stated: custom channels (their name, announce setting and
# password) now survive a worldserver restart, and players' channel
# memberships are restored on login. Built-in channels (General, Trade, ...)
# are unaffected -- they were never stored.
#
# Boot-time note: read once at startup, so it takes effect after one
# worldserver restart.
# Profiles: all

# -- {{{ config_preserve_custom_channels
config_preserve_custom_channels() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    # Anchored with [[:space:]]*= per the C020 lesson: a bare `.*=` after the
    # key name is greedy and can swallow longer keys sharing the prefix.
    sed -i 's|^PreserveCustomChannels[[:space:]]*=.*|PreserveCustomChannels = 1|' "${conf}"
}
CONFIG_PROFILES[config_preserve_custom_channels]="all"
CONFIG_DESCRIPTIONS[config_preserve_custom_channels]="Keep custom chat channels, so they have ids (neuron's channel)"
# -- }}}
