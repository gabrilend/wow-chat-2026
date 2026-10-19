#!/usr/bin/env bash
# C036 - Beta: Death Knights for Everyone
# Any beta account may make a death knight, without first having a
# level-55 character.
#
# For a general audience: the stock game lets an account make a death
# knight only once it has another character of level 55
# (CharacterCreating.MinLevelForHeroicCharacter = 55; game-master accounts
# are exempt). Beta caps every character at level 20 and starts death
# knights at level 1 beside every other class (issue 206: "DKs are an
# option, not an exception"), so on beta nobody but a game master could
# ever make one. 0 switches the requirement off. The server does not check
# this value against the level cap, so nothing warned about it.
# Added 2026-10-17 (issue 200's open question 2, answered by 206's design;
# the owner may still say otherwise).
#
# Profiles: beta

# -- {{{ config_beta_death_knights_for_everyone
config_beta_death_knights_for_everyone() {
    local conf="${INSTALL_DIR}/etc/worldserver.conf"
    sed -i 's|^CharacterCreating\.MinLevelForHeroicCharacter[[:space:]]*=.*|CharacterCreating.MinLevelForHeroicCharacter = 0|' "${conf}"
}
CONFIG_PROFILES[config_beta_death_knights_for_everyone]="beta"
CONFIG_DESCRIPTIONS[config_beta_death_knights_for_everyone]="Death knights need no level-55 character first (beta)"
# -- }}}
