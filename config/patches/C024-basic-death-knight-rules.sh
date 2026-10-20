#!/usr/bin/env bash
# ==== header: 7 lines, footer: 3 lines ====
# id:         C024
# profiles:   basic
# priority:   1235
# kind:       settings
# about:      Basic Death Knight Rules (interim, until issue 718)
# ==== end of header ====
# C024 - Basic Death Knight Rules (interim, until issue 718)
# The user's rule for death knights on basic (2026-09-23): "allow stock
# DKs, but there are no bot DKs allowed and level 55 is required."
# Both halves are stock knobs, so no code:
#
#   CharacterCreating.MinLevelForHeroicCharacter = 55
#       An account needs a level-55 character on this realm before it
#       may create a death knight. 55 is also the upstream default; it
#       is written explicitly so the rule does not depend on the .dist.
#   CharacterCreating.Disabled.ClassMask = 0
#       Death knights are creatable (vanilla's C015 sets 32 to block them).
#   AiPlayerbot.DisableDeathKnightLogin = 1
#       No death-knight bot logs in.
#
# The rest of the user's design (creating a death knight consumes the
# level-55 character; Acherus as an open leveling zone) is issue 718,
# scheduled after the custom-class infrastructure.
# Profiles: basic

# -- {{{ config_basic_death_knight_rules
config_basic_death_knight_rules() {
    local conf_world="${INSTALL_DIR}/etc/worldserver.conf"
    local conf_bots="${INSTALL_DIR}/etc/modules/playerbots.conf"
    sed -i 's|^CharacterCreating\.MinLevelForHeroicCharacter[[:space:]]*=.*|CharacterCreating.MinLevelForHeroicCharacter = 55|' "${conf_world}"
    sed -i 's|^CharacterCreating\.Disabled\.ClassMask[[:space:]]*=.*|CharacterCreating.Disabled.ClassMask = 0|' "${conf_world}"
    sed -i 's|^AiPlayerbot\.DisableDeathKnightLogin[[:space:]]*=.*|AiPlayerbot.DisableDeathKnightLogin = 1|' "${conf_bots}"
}
CONFIG_DESCRIPTIONS[config_basic_death_knight_rules]="Death knights: need a level-55 character; no DK bots"
# -- }}}
# ==== footer of C024 ====
# lines:      40
# ==== end of footer ====
