#!/usr/bin/env bash
# C028 - Basic: Honor Without a Cap
# On basic, honor is the currency gems are sold for at the goblin auction
# houses and glyphs are bought with (issue 155t: a major glyph costs 77,777,
# more than the stock cap). Ritz, 2026-09-26: "can we make that cap
# unlimited? it exists because of the patch cycle, which we don't really
# have."
#
# The server clamps a character's honor to MaxHonorPoints whenever it is set
# (Player::SetHonorPoints). There is no "off" value, so the cap is set to
# 2,147,483,647: the largest value that stays safe where the server adds
# honor as a signed 32-bit number. No character reaches it.
#
# Knob written into worldserver.conf:
#   MaxHonorPoints=2147483647   effectively no cap
# Profiles: basic

# -- {{{ config_basic_honor_uncapped
config_basic_honor_uncapped() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    # anchored with [[:space:]]*= so it can't match MaxHonorPointsMoneyPerPoint
    sed -i 's|^MaxHonorPoints[[:space:]]*=.*|MaxHonorPoints = 2147483647|' "${conf}"
}
CONFIG_PROFILES[config_basic_honor_uncapped]="basic"
CONFIG_DESCRIPTIONS[config_basic_honor_uncapped]="Honor effectively uncapped (glyphs cost more than the stock 75,000)"
# -- }}}
