#!/usr/bin/env bash
# C003 - Run Speed 80%
# Set player run speed to 80% (slower, more deliberate exploration)
# Profiles: all

# -- {{{ config_run_speed_80_percent
config_run_speed_80_percent() {
    local RUN_SPEED=0.8
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^Rate\.Run\.Speed.*=.*|Rate.Run.Speed = '"${RUN_SPEED}"'|' "${conf}"
}
CONFIG_PROFILES[config_run_speed_80_percent]="all"
CONFIG_DESCRIPTIONS[config_run_speed_80_percent]="Run speed 80% (slower exploration)"
# -- }}}
