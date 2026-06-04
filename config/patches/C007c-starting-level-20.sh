#!/usr/bin/env bash
# C007c - Starting Level 20 (Vanilla)
# Set starting level to 20 for the vanilla profile so new characters
# spawn at the midpoint of the vanilla 1..40 spread (decision pinned in 148).
# Replaces the skipped 2x-exp C005 patch — characters skip the slog directly.
# Profiles: vanilla

# -- {{{ config_starting_level_20
config_starting_level_20() {
    local START_LEVEL=20
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^StartPlayerLevel.*=.*|StartPlayerLevel = '"${START_LEVEL}"'|' "${conf}"
}
CONFIG_PROFILES[config_starting_level_20]="vanilla"
CONFIG_DESCRIPTIONS[config_starting_level_20]="Starting level 20"
# -- }}}
