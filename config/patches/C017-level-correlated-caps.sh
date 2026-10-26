#!/usr/bin/env bash

config_level_correlated_caps() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"

    local max_level
    max_level=$(grep -E "^MaxPlayerLevel[[:space:]]*=" "${conf}" \
                | head -1 \
                | sed 's|.*=[[:space:]]*||' \
                | tr -d '[:space:]')

    if [[ -z "${max_level}" || ! "${max_level}" =~ ^[0-9]+$ ]]; then
        echo "    WARNING: MaxPlayerLevel unparseable in ${conf}; skipping C017"
        return 1
    fi

    local -A DK_START_BY_PROFILE=(
        ["beta"]=1                                          # issue 206
    )
    local dk_start=$(( max_level < 55 ? max_level : 55 ))
    if [[ -n "${DK_START_BY_PROFILE[${PROFILE}]:-}" ]]; then
        dk_start="${DK_START_BY_PROFILE[${PROFILE}]}"
    fi
    sed -i "s|^StartHeroicPlayerLevel[[:space:]]*=.*|StartHeroicPlayerLevel = ${dk_start}|" "${conf}"
    sed -i "s|^RecruitAFriend\.MaxLevel[[:space:]]*=.*|RecruitAFriend.MaxLevel = ${max_level}|" "${conf}"
}
CONFIG_DESCRIPTIONS[config_level_correlated_caps]="Death knights start at 55 (or the cap if lower; beta: 1); RecruitAFriend.MaxLevel pinned to MaxPlayerLevel"
