#!/usr/bin/env bash
# C017 - Level-correlated caps
# Two worldserver knobs are validated against CONFIG_MAX_PLAYER_LEVEL at
# boot and both ship with values (55, 60) tuned for the upstream max
# level of 80. Every profile here caps below 80, so both keys fail their
# bounds check on every start and fall back to the upstream default,
# which still fails the check the next time it's looked up.
#
# Strategy: read whatever MaxPlayerLevel the .conf currently holds (set
# upstream by the C006* family) and keep both knobs within it, so
# the validator passes on first read. The runner (apply_config_values
# in patches/E-patches.sh) applies patches in filename order, so C006*
# runs before C017 and the value parsed here is the profile-correct one.
# Until 2026-09-29 it applied them in alphabetical function-name order,
# which ran this patch first and pinned both knobs to the stock 80.
#
# StartHeroicPlayerLevel — the level a new death knight starts at (the
#                          "heroic class"). Stock is 55. Kept at 55 where
#                          the cap allows (basic: 60); lowered to the cap
#                          where it doesn't (vanilla: 40, where death
#                          knights are disabled anyway). Until 2026-09-29
#                          this comment called it a heroic-dungeon entry
#                          level and the patch pinned it to the cap: with
#                          the patch order fixed, that made basic's death
#                          knights start at 60 (owner: "death knights are
#                          starting at level 60 and they should start at
#                          55").
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

    local dk_start=$(( max_level < 55 ? max_level : 55 ))   # stock 55, or the cap if lower
    sed -i "s|^StartHeroicPlayerLevel[[:space:]]*=.*|StartHeroicPlayerLevel = ${dk_start}|" "${conf}"
    sed -i "s|^RecruitAFriend\.MaxLevel[[:space:]]*=.*|RecruitAFriend.MaxLevel = ${max_level}|" "${conf}"
}
CONFIG_PROFILES[config_level_correlated_caps]="release beta vanilla basic"
CONFIG_DESCRIPTIONS[config_level_correlated_caps]="Death knights start at 55 (or the cap if lower); RecruitAFriend.MaxLevel pinned to MaxPlayerLevel"
# -- }}}
