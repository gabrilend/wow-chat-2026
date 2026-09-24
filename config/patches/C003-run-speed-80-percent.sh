#!/usr/bin/env bash
# C003 - Run Speed 80%
# Set player run speed to 80% (slower, more deliberate exploration)
# Profiles: all
#
# The key's name depends on the source tree the profile builds from:
#   source-beta  (release, beta, vanilla, basic): Rate.MoveSpeed.Player
#                players only; NPCs keep Rate.MoveSpeed.NPC = 1
#   source-alpha (alpha): Rate.MoveSpeed — one rate for every unit
#
# Until 2026-09-23 this patch wrote "Rate.Run.Speed", a key neither tree
# has. The sed matched nothing, so the 80% speed was never in effect on
# any profile, and nothing said so. It now names the real key and stops
# with an error if that key is missing from the generated config, rather
# than silently doing nothing again.

# -- {{{ config_run_speed_80_percent
config_run_speed_80_percent() {
    local RUN_SPEED=0.8
    local conf="${INSTALL_DIR}/etc/worldserver.conf"

    # source tree → key name; one row per tree (see header)
    local -A SPEED_KEY_BY_PROFILE=(
        [release]="Rate.MoveSpeed.Player"
        [beta]="Rate.MoveSpeed.Player"
        [vanilla]="Rate.MoveSpeed.Player"
        [basic]="Rate.MoveSpeed.Player"
        [alpha]="Rate.MoveSpeed"
    )
    local key="${SPEED_KEY_BY_PROFILE[${PROFILE}]:-}"
    if [[ -z "${key}" ]]; then
        echo "    ERROR: C003 has no move-speed key for profile '${PROFILE}' (add a row to SPEED_KEY_BY_PROFILE)"
        return 1
    fi

    local key_re="${key//./\\.}"
    if ! grep -qE "^${key_re}[[:space:]]*=" "${conf}"; then
        echo "    ERROR: C003 found no '${key}' line in ${conf}; run speed NOT set"
        echo "           to debug: grep -n MoveSpeed ${conf} — did upstream rename the key?"
        return 1
    fi
    sed -i "s|^${key_re}[[:space:]]*=.*|${key} = ${RUN_SPEED}|" "${conf}"
}
CONFIG_PROFILES[config_run_speed_80_percent]="all"
CONFIG_DESCRIPTIONS[config_run_speed_80_percent]="Run speed 80% (slower exploration)"
# -- }}}
