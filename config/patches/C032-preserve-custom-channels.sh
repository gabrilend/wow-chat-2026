#!/usr/bin/env bash

config_preserve_custom_channels() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^PreserveCustomChannels[[:space:]]*=.*|PreserveCustomChannels = 1|' "${conf}"
}
CONFIG_PROFILES[config_preserve_custom_channels]="all"
CONFIG_DESCRIPTIONS[config_preserve_custom_channels]="Keep custom chat channels, so they have ids (neuron's channel)"
