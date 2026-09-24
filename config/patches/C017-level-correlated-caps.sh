#!/usr/bin/env bash
# C017 - Level-correlated caps
# Two worldserver knobs are validated against CONFIG_MAX_PLAYER_LEVEL at
# boot and both ship with values (55, 60) tuned for the upstream max
# level of 80. Every profile here caps below 80, so both keys fail their
# bounds check on every start and fall back to the upstream default,
# which still fails the check the next time it's looked up.
#
# Strategy: read whatever MaxPlayerLevel the .conf currently holds (set
# upstream by the C006* family) and pin both knobs to that value, so
# the validator passes on first read. C-patches are sourced in
# filename-sorted order, so C006* runs before C017 and the value
# parsed here is the profile-correct one.
#
# StartHeroicPlayerLevel — required level to enter a heroic dungeon.
#                          No heroic dungeons exist below the level cap
#                          on any of these profiles, so pinning to the
#                          cap is benign (and just silences the warning).
# RecruitAFriend.MaxLevel — ceiling on the RAF level-up bonus. Likewise
#                          pinning to the level cap covers the full
#                          progression range and silences the warning.
#
# Profiles: release beta vanilla basic
# Alpha is excluded for the same reason as C016: different binary,
# different validation surface.

# -- {{{ config_level_correlated_caps
config_level_correlated_caps() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"

    # Parse MaxPlayerLevel from whatever the upstream C006* family wrote.
    # head -1 in case the file ever grows a second match (it shouldn't,
    # but a defensive single-line pick keeps the sed targets stable).
    local max_level
    max_level=$(grep -E "^MaxPlayerLevel[[:space:]]*=" "${conf}" \
                | head -1 \
                | sed 's|.*=[[:space:]]*||' \
                | tr -d '[:space:]')

    if [[ -z "${max_level}" || ! "${max_level}" =~ ^[0-9]+$ ]]; then
        echo "    WARNING: MaxPlayerLevel unparseable in ${conf}; skipping C017"
        return 1
    fi

    sed -i "s|^StartHeroicPlayerLevel[[:space:]]*=.*|StartHeroicPlayerLevel = ${max_level}|" "${conf}"
    sed -i "s|^RecruitAFriend\.MaxLevel[[:space:]]*=.*|RecruitAFriend.MaxLevel = ${max_level}|" "${conf}"
}
CONFIG_PROFILES[config_level_correlated_caps]="release beta vanilla basic"
CONFIG_DESCRIPTIONS[config_level_correlated_caps]="StartHeroicPlayerLevel + RecruitAFriend.MaxLevel pinned to MaxPlayerLevel"
# -- }}}
